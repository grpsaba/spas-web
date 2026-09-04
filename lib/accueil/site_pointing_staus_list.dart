import 'package:flutter/material.dart';
import 'package:spas_web/accueil/widgets/site_status_dialog.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/models/date_filter.dart';
import 'package:spas_web/notes/imprime_rapport.dart';

import 'nombrePointageStatut.dart';

class SitePointingListWithStatus extends StatefulWidget {
  const SitePointingListWithStatus({
    super.key,
    required this.supList,
    this.height = 540,
  });

  final List<Supervisor> supList;
  final double height;

  @override
  State<SitePointingListWithStatus> createState() =>
      _SitePointingListWithStatusState();
}

class _SitePointingListWithStatusState
    extends State<SitePointingListWithStatus> {
  static const _primary = Color(0xFF4657C8);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF667085);
  static const _border = Color(0xFFE5EAF2);
  static const _surface = Color(0xFFFBFCFE);

  String _keyword = '';
  DateFilter _selectedDateFilter = DateFilter.today;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  List<Supervisor> get _filteredSupervisors {
    final activeSupervisors =
        widget.supList.where((supervisor) => supervisor.actif == true).toList();
    if (_keyword.isEmpty) return activeSupervisors;

    final keyword = _keyword.toLowerCase();
    return activeSupervisors.where((supervisor) {
      final fullName =
          '${supervisor.firstName} ${supervisor.lastName}'.toLowerCase();
      final code = supervisor.code.toLowerCase();
      return fullName.contains(keyword) || code.contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final supervisors = _filteredSupervisors;

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08172033),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(supervisors.length),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: supervisors.isEmpty
                  ? const _EmptyProgressList(
                      key: ValueKey('empty-supervisors'),
                      label: 'Aucun superviseur trouvé',
                    )
                  : ListView.separated(
                      key: ValueKey(
                        'supervisors-${_selectedDateFilter.name}-$_keyword',
                      ),
                      itemCount: supervisors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _buildSupervisorRow(supervisors[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.supervisor_account_outlined,
            color: _primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Superviseurs',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Progression journalière des sites pointés',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          onChanged: (value) => setState(() => _keyword = value.trim()),
          style: const TextStyle(color: _ink, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Rechercher un superviseur',
            hintStyle: const TextStyle(color: _muted, fontSize: 12),
            prefixIcon: const Icon(Icons.search, size: 19, color: _muted),
            filled: true,
            fillColor: _surface,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary, width: 1.4),
            ),
          ),
        );
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 8),
              _buildDateFilterDropdown(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 10),
            SizedBox(width: 165, child: _buildDateFilterDropdown()),
          ],
        );
      },
    );
  }

  Widget _buildDateFilterDropdown() {
    return Container(
      constraints: const BoxConstraints(minWidth: 135),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateFilter>(
          value: _selectedDateFilter,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _muted, size: 18),
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: DateFilter.values.map((filter) {
            return DropdownMenuItem<DateFilter>(
              value: filter,
              child: Text(filter.label, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) return;
            if (value == DateFilter.custom) {
              await _showCustomDatePicker();
              return;
            }
            setState(() {
              _selectedDateFilter = value;
              _customStartDate = null;
              _customEndDate = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSupervisorRow(Supervisor supervisor) {
    final name = '${supervisor.firstName} ${supervisor.lastName}'.trim();
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _showSiteStatusDialog(supervisor),
        hoverColor: _primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 6, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _primary.withValues(alpha: 0.11),
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Superviseur sans nom' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    NbPointageStatus(
                      supervisor: supervisor,
                      dateFilter: _selectedDateFilter,
                      customStartDate: _customStartDate,
                      customEndDate: _customEndDate,
                      lightTheme: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Ouvrir le rapport',
                onPressed: () => _openReport(supervisor),
                icon: const Icon(
                  Icons.description_outlined,
                  color: _muted,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSiteStatusDialog(Supervisor supervisor) {
    showDialog<void>(
      context: context,
      builder: (_) => SiteStatusDialog.forSupervisor(
        supervisor: supervisor,
        dateFilter: _selectedDateFilter,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
      ),
    );
  }

  void _openReport(Supervisor supervisor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImprimeRapport(
          source: '${supervisor.firstName} ${supervisor.lastName}',
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? now.subtract(const Duration(days: 7)),
        end: _customEndDate ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;
    if (picked == null) return;
    setState(() {
      _selectedDateFilter = DateFilter.custom;
      _customStartDate =
          DateTime(picked.start.year, picked.start.month, picked.start.day);
      _customEndDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
    });
  }
}

class _EmptyProgressList extends StatelessWidget {
  const _EmptyProgressList({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, color: Color(0xFF98A2B3), size: 36),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
