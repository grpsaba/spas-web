import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class AgentService {
  AgentService({FirebaseFirestore? firestore})
      : _collectionReference =
            (firestore ?? FirebaseFirestore.instance).collection("Agents");

  final CollectionReference _collectionReference;

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(Agent agent) async {
    TenantScope.applyTenantIdForWrite(agent);
    agent.genererCode();
    await _collectionReference.doc(agent.code).set(agent.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'AgentService.all',
      _scopedQuery,
    );
  }

  Stream<QuerySnapshot> allOfficePersonnel() {
    return TenantScope.watchQuery(
      'AgentService.allOfficePersonnel',
      _scopedQuery
          .where("actif", isEqualTo: true)
          .where("site.UID", isEqualTo: "rXkVVl9AH8MYSPn25FSHS7eESpc2"),
    );
  }

  Future<List<Agent>> allFuture() async {
    final snapshot = await TenantScope.getQuery(
      'AgentService.allFuture',
      _scopedQuery,
    );
    return snapshot.docs.map(_mapSnapshotToAgent).toList();
  }

  Future<List<Agent>> allByDomaine(String domaine) async {
    final snapshot = await TenantScope.getQuery(
      'AgentService.allByDomaine',
      _scopedQuery
          .where("AgentType.label", isEqualTo: domaine)
          .where("site", isNotEqualTo: null)
          .where("actif", isEqualTo: true),
    );

    return snapshot.docs.map(_mapSnapshotToAgent).toList();
  }

  Future<List<Agent>> allBySupervisor(dynamic uid) async {
    final snapshot = await TenantScope.getQuery(
      'AgentService.allBySupervisor',
      _scopedQuery,
    );
    return snapshot.docs
        .map(_mapSnapshotToAgent)
        .where(
          (element) =>
              element.actif == true &&
              element.site?.actif == true &&
              (element.site?.supervisor?.UID == uid ||
                  element.site?.supervisor_2?.UID == uid),
        )
        .toList();
  }

  Future<List<Agent>> allBySite(dynamic uid) async {
    final snapshot = await TenantScope.getQuery(
      'AgentService.allBySite',
      _scopedQuery
          .where("site.UID", isEqualTo: uid),
    );

    return snapshot.docs.map(_mapSnapshotToAgent).toList();
  }

  Future<Agent> one(dynamic code) async {
    final snapshot = await _collectionReference.doc(code).get();
    final data = _asMap(snapshot.data());

    if (data == null) {
      throw StateError('Agent not found for code: $code');
    }

    if (!TenantScope.matchesTenant(tenantIdFromJson(data)) ||
        !DepartmentScope.matchesDepartment(departmentIdFromJson(data))) {
      throw StateError('Agent outside the active tenant or department scope.');
    }

    return Agent.fromJson(data);
  }

  Future<void> delete(Agent agent) async {
    return _collectionReference.doc(agent.code).delete();
  }

  Future<void> update(Agent agent) {
    TenantScope.applyTenantIdForWrite(agent);
    return _collectionReference.doc(agent.code).update(agent.toJson());
  }

  Future<void> bulkUpdate(List<Agent> agents) async {
    if (agents.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final agent in agents) {
      TenantScope.applyTenantIdForWrite(agent);
      batch.update(_collectionReference.doc(agent.code), agent.toJson());
    }

    await batch.commit();
  }

  Future<void> bulkDelete(List<Agent> agents) async {
    if (agents.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final agent in agents) {
      batch.delete(_collectionReference.doc(agent.code));
    }

    await batch.commit();
  }

  Future<PaginatedAgentResult> fetchPage({
    int limit = 20,
    DocumentSnapshot? startAfterDocument,
    bool? actif,
    String? agentTypeLabel,
    String? departmentLabel,
    bool descending = false,
  }) async {
    try {
      Query query = _scopedQuery.orderBy('code', descending: descending);

      if (actif != null) {
        query = query.where('actif', isEqualTo: actif);
      }

      if (agentTypeLabel != null && agentTypeLabel.trim().isNotEmpty) {
        query =
            query.where('AgentType.label', isEqualTo: agentTypeLabel.trim());
      }

      if (departmentLabel != null && departmentLabel.trim().isNotEmpty) {
        query =
            query.where('department.label', isEqualTo: departmentLabel.trim());
      }

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await TenantScope.getQuery(
        'AgentService.fetchPage',
        query.limit(limit),
      );

      final agents = snapshot.docs.map(_mapSnapshotToAgent).toList();
      final lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return PaginatedAgentResult(
        agents: agents,
        lastDocument: lastDocument,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      debugPrint('Error fetching agents page: $e');
      rethrow;
    }
  }

  Future<List<Agent>> searchPage({
    required String query,
    int limit = 100,
    DocumentSnapshot? startAfterDocument,
    bool? actif,
    String? agentTypeLabel,
    String? departmentLabel,
    bool descending = false,
  }) async {
    final page = await fetchPage(
      limit: limit,
      startAfterDocument: startAfterDocument,
      actif: actif,
      agentTypeLabel: agentTypeLabel,
      departmentLabel: departmentLabel,
      descending: descending,
    );

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return page.agents;
    }

    return page.agents.where((agent) {
      return _matchesSearch(agent, normalizedQuery);
    }).toList();
  }

  Future<List<Agent>> searchByPrefix({
    required String query,
    int limit = 100,
    bool? actif,
    String? agentTypeLabel,
    String? departmentLabel,
  }) async {
    final rawQuery = query.trim();
    final normalizedQuery = rawQuery.toLowerCase();
    if (rawQuery.isEmpty) return <Agent>[];

    final searchPlans = <_AgentSearchPlan>[
      _AgentSearchPlan('code', _queryVariants(rawQuery, includeTitle: false)),
      _AgentSearchPlan('firstName', _queryVariants(rawQuery)),
      _AgentSearchPlan('lastName', _queryVariants(rawQuery)),
      _AgentSearchPlan('phone', <String>{rawQuery}),
    ];

    final snapshots = await Future.wait(
      searchPlans.expand((plan) {
        return plan.terms.map((term) {
          Query searchQuery = _scopedQuery;

          if (actif != null) {
            searchQuery = searchQuery.where('actif', isEqualTo: actif);
          }

          if (agentTypeLabel != null && agentTypeLabel.trim().isNotEmpty) {
            searchQuery = searchQuery.where(
              'AgentType.label',
              isEqualTo: agentTypeLabel.trim(),
            );
          }

          if (departmentLabel != null && departmentLabel.trim().isNotEmpty) {
            searchQuery = searchQuery.where(
              'department.label',
              isEqualTo: departmentLabel.trim(),
            );
          }

          searchQuery = searchQuery
              .orderBy(plan.field)
              .startAt(<String>[term])
              .endAt(<String>['$term\uf8ff'])
              .limit(limit);

          return TenantScope.getQuery(
            'AgentService.searchByPrefix.${plan.field}',
            searchQuery,
          );
        });
      }),
    );

    final agentsByCode = <String, Agent>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        final agent = _mapSnapshotToAgent(doc);
        if (_matchesSearch(agent, normalizedQuery)) {
          agentsByCode[agent.code] = agent;
        }
      }
    }

    final agents = agentsByCode.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));

    return agents.take(limit).toList();
  }

  bool _matchesSearch(Agent agent, String normalizedQuery) {
    final values = <String>[
      agent.code,
      agent.firstName,
      agent.lastName,
      agent.phone,
      agent.email,
      agent.site?.name ?? '',
      agent.department?.label ?? '',
      agent.typeAgent?.label ?? '',
    ];

    return values.any(
      (value) => value.toLowerCase().contains(normalizedQuery),
    );
  }

  Set<String> _queryVariants(String value, {bool includeTitle = true}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return <String>{};

    final variants = <String>{
      trimmed,
      trimmed.toUpperCase(),
      trimmed.toLowerCase(),
    };

    if (includeTitle) {
      variants.add(
        trimmed
            .split(RegExp(r'\s+'))
            .map((part) {
              if (part.isEmpty) return part;
              return part[0].toUpperCase() + part.substring(1).toLowerCase();
            })
            .join(' '),
      );
    }

    return variants.where((variant) => variant.trim().isNotEmpty).toSet();
  }

  Agent _mapSnapshotToAgent(QueryDocumentSnapshot snapshot) {
    final data = _asMap(snapshot.data());

    if (data == null) {
      throw StateError('Invalid agent document data for id: ${snapshot.id}');
    }

    return Agent.fromJson(data);
  }

  Map<String, dynamic>? _asMap(dynamic rawData) {
    if (rawData == null) {
      return null;
    }

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return jsonDecode(jsonEncode(rawData)) as Map<String, dynamic>;
  }
}

class _AgentSearchPlan {
  const _AgentSearchPlan(this.field, this.terms);

  final String field;
  final Set<String> terms;
}

class PaginatedAgentResult {
  const PaginatedAgentResult({
    required this.agents,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<Agent> agents;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}
