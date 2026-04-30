import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model.dart';

class AgentService {
  AgentService({FirebaseFirestore? firestore})
      : _collectionReference =
            (firestore ?? FirebaseFirestore.instance).collection("Agents");

  final CollectionReference _collectionReference;

  Future<void> add(Agent agent) async {
    agent.genererCode();
    await _collectionReference.doc(agent.code).set(agent.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Stream<QuerySnapshot> allOfficePersonnel() {
    return _collectionReference
        .where("actif", isEqualTo: true)
        .where("site.UID", isEqualTo: "rXkVVl9AH8MYSPn25FSHS7eESpc2")
        .snapshots();
  }

  Future<List<Agent>> allFuture() async {
    final snapshot = await _collectionReference.get();
    return snapshot.docs.map(_mapSnapshotToAgent).toList();
  }

  Future<List<Agent>> allByDomaine(String domaine) async {
    final snapshot = await _collectionReference
        .where("AgentType.label", isEqualTo: domaine)
        .where("site", isNotEqualTo: null)
        .where("actif", isEqualTo: true)
        .get();

    return snapshot.docs.map(_mapSnapshotToAgent).toList();
  }

  Future<List<Agent>> allBySupervisor(dynamic uid) async {
    final snapshot = await _collectionReference.get();
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
    final snapshot =
        await _collectionReference.where("site.UID", isEqualTo: uid).get();

    return snapshot.docs.map(_mapSnapshotToAgent).toList();
  }

  Future<Agent> one(dynamic code) async {
    final snapshot = await _collectionReference.doc(code).get();
    final data = _asMap(snapshot.data());

    if (data == null) {
      throw StateError('Agent not found for code: $code');
    }

    return Agent.fromJson(data);
  }

  Future<void> delete(Agent agent) async {
    return _collectionReference.doc(agent.code).delete();
  }

  Future<void> update(Agent agent) {
    return _collectionReference.doc(agent.code).update(agent.toJson());
  }

  Future<void> bulkUpdate(List<Agent> agents) async {
    if (agents.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final agent in agents) {
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
      Query query =
          _collectionReference.orderBy('code', descending: descending);

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

      final snapshot = await query.limit(limit).get();

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
