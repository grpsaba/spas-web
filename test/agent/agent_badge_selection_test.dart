import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/agent/providers/agent_badge_provider.dart';
import 'package:spas_web/agent/widgets/agent_badge_results_list.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agent.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/department.dart';

Agent _agent(int index,
        {bool active = true,
        String type = 'FIXE',
        String department = 'Sécurité'}) =>
    Agent.fromJson({
      'code': 'AGENT-${index.toString().padLeft(5, '0')}',
      'firstName': 'Amadou',
      'lastName': 'Traoré $index',
      'phone': '',
      'email': '',
      'tracking': false,
      'actif': active,
      'AgentType': {'label': type},
      'department': {'label': department},
    });

class _Agents extends Fake implements AgentService {
  _Agents(this.load);
  final Future<List<Agent>> Function() load;
  int calls = 0;

  @override
  Future<List<Agent>> allFuture() {
    calls++;
    return load();
  }
}

class _Departments extends Fake implements DepartmentService {
  @override
  Future<List<Department>> allFuture() async =>
      [Department(label: 'Sécurité'), Department(label: 'Nettoyage')];
}

AgentBadgeProvider _provider(_Agents agents) => AgentBadgeProvider(
      agentService: agents,
      departmentService: _Departments(),
    );

Widget _screen(AgentBadgeProvider provider, bool withPhoto) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: provider,
            builder: (_, __) => Column(children: [
              TextField(
                  controller: provider.searchController,
                  onChanged: provider.setSearchQuery),
              AgentBadgeResultsList(provider: provider, withPhoto: withPhoto),
            ]),
          ),
        ),
      ),
    );

void main() {
  for (final withPhoto in [false, true]) {
    testWidgets(
        '10,000 agents: bounded rows, page selection and global search '
        '(photo: $withPhoto)', (tester) async {
      final source = List.generate(10000, _agent);
      final service = _Agents(() async => source);
      final provider = _provider(service);
      addTearDown(provider.dispose);
      if (withPhoto) {
        provider.setMode(useCurrentList: false);
        await provider.loadAgentsFromFirebase();
      } else {
        provider.setCurrentAgents(source);
      }
      await tester.pumpWidget(_screen(provider, withPhoto));

      expect(tester.takeException(), isNull);
      expect(find.byType(CheckboxListTile), findsNWidgets(25));
      expect(provider.selectedCount, 10000);
      expect(provider.pageCount, 400);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      expect(provider.selectedCount, 9999);
      await tester.tap(find.byTooltip('Page suivante').first);
      await tester.pump();
      expect(provider.pageStart, 26);
      expect(find.byType(CheckboxListTile), findsNWidgets(25));
      await tester.tap(find.byTooltip('Page précédente').first);
      await tester.pump();
      expect(
          tester
              .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
              .value,
          isFalse);

      // Broad one-letter results still render only one page.
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 260));
      expect(provider.visibleCount, 10000);
      expect(find.byType(CheckboxListTile), findsNWidgets(25));

      provider.setPage(399);
      await tester.pump();
      // Search must include agents outside the page previously displayed.
      await tester.enterText(find.byType(TextField), 'AGENT-05000');
      await tester.pump(const Duration(milliseconds: 260));
      expect(provider.pageIndex, 0);
      expect(provider.visibleCount, 1);
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('AGENT-05000'), findsOneWidget);
      expect(provider.selectedCount, 9999);
      expect(service.calls, withPhoto ? 1 : 0);
      expect(tester.takeException(), isNull);

      provider.resetFilters(currentAgents: source);
      await tester.pump();
      expect(provider.visibleCount, 10000);
      expect(find.byType(CheckboxListTile), findsNWidgets(25));
      expect(provider.searchController.text, isEmpty);
      expect(service.calls, withPhoto ? 1 : 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('Filters and reset reuse a load; explicit reload fetches fresh agents',
      () async {
    var source = [
      _agent(1),
      _agent(2, type: 'RONDIER', department: 'Nettoyage'),
      _agent(3, active: false),
    ];
    final service = _Agents(() async => source);
    final provider = _provider(service)..setMode(useCurrentList: false);
    addTearDown(provider.dispose);

    await provider.loadAgentsFromFirebase();
    expect(provider.loadedCount, 2);
    await provider.setType('RONDIER');
    expect(provider.visibleAgents.single.code, source[1].code);
    await provider.setType('Tous');
    await provider.setDepartment('Nettoyage');
    expect(provider.visibleCount, 1);
    await provider.setDepartment('Tous');
    await provider.setStatus(false);
    expect(provider.visibleAgents.single.code, source[2].code);
    provider.resetFilters();
    expect(provider.visibleCount, 2);
    expect(provider.selectedCount, 2);
    expect(service.calls, 1);

    source = [_agent(4)];
    await provider.loadAgentsFromFirebase();
    expect(service.calls, 2);
    expect(provider.visibleAgents.single.code, source.single.code);
  });

  test('Select and generate include results beyond the displayed page',
      () async {
    final source = List.generate(80, _agent);
    final provider = _provider(_Agents(() async => source))
      ..setCurrentAgents(source)
      ..clearSelection()
      ..selectAllVisible()
      ..setPage(2);
    addTearDown(provider.dispose);
    expect(provider.selectedCount, 80);
    provider.setPage(3);
    expect(provider.pageAgents, hasLength(5));
    expect(provider.pageEnd, 80);
    List<Agent>? generated;
    await provider.generateSelectedBadges(onGenerate: (agents) async {
      generated = agents;
    });
    expect(generated, hasLength(80));

    provider.setSearchQuery('AGENT-0007');
    await Future<void>.delayed(const Duration(milliseconds: 270));
    provider.selectOnlyVisible();
    expect(provider.selectedCount, 10);
    expect(provider.selectedAgents.map((agent) => agent.code),
        source.skip(70).map((agent) => agent.code));
  });

  test('Repeated clicks share pending load and use latest filter values',
      () async {
    final pending = Completer<List<Agent>>();
    final service = _Agents(() => pending.future);
    final provider = _provider(service)..setMode(useCurrentList: false);
    addTearDown(provider.dispose);
    final loading = provider.loadAgentsFromFirebase();
    await provider.loadAgentsFromFirebase();
    provider.resetFilters();
    await provider.setType('RONDIER');
    expect(service.calls, 1);
    pending.complete([_agent(1), _agent(2, type: 'RONDIER')]);
    await loading;
    expect(provider.visibleAgents.single.typeAgent!.label, 'RONDIER');
    expect(provider.isLoadingAgents, isFalse);
  });

  test('Cached selection is reloaded after a tenant or department scope change',
      () async {
    final previousManager = AuthService.currentManager;
    final manager = Manager(
      UID: 'test-manager',
      email: '',
      phone: '',
      firstName: '',
      lastName: '',
      poste: '',
      token: '',
      profil: null,
      tenantId: 'tenant-a',
    );
    AuthService.currentManager = manager;
    addTearDown(() => AuthService.currentManager = previousManager);
    final service = _Agents(() async => [_agent(1)]);
    final provider = _provider(service)..setMode(useCurrentList: false);
    addTearDown(provider.dispose);
    await provider.loadAgentsFromFirebase();
    manager.tenantId = 'tenant-b';
    await provider.setStatus(null);
    expect(service.calls, 2);
    manager.departmentScope = DepartmentScopeValue.limited;
    manager.departmentIds = ['security'];
    await provider.setStatus(true);
    expect(service.calls, 3);
  });

  test('Old request cannot replace a newly chosen source', () async {
    final pending = Completer<List<Agent>>();
    final provider = _provider(_Agents(() => pending.future))
      ..setMode(useCurrentList: false);
    addTearDown(provider.dispose);
    final loading = provider.loadAgentsFromFirebase();
    final current = _agent(9);
    provider.setMode(useCurrentList: true, currentAgents: [current]);
    pending.complete([_agent(1)]);
    await loading;
    expect(provider.visibleAgents.single, same(current));
    expect(provider.isLoadingAgents, isFalse);
  });

  test('Leaving the page during loading ignores the eventual response',
      () async {
    final pending = Completer<List<Agent>>();
    final provider = _provider(_Agents(() => pending.future))
      ..setMode(useCurrentList: false);
    final loading = provider.loadAgentsFromFirebase();
    provider.dispose();
    pending.complete([_agent(1)]);
    await expectLater(loading, completes);
  });
}
