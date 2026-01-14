import 'package:flutter/material.dart';
import 'package:spas_web/accueil/widgets/site_status_dialog.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/notes/imprime_rapport.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/models/date_filter.dart';

import '../model.dart';
import 'nombrePointageStatut.dart';

class SitePointingListWithStatus extends StatefulWidget {
  final List<Supervisor> supList;
  const SitePointingListWithStatus({super.key, required this.supList});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SitePointingListWithStatus> {
  String _keyword = "";
  DateFilter _selectedDateFilter = DateFilter.today;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  List<Supervisor> get _filteredSupervisors {
    if (_keyword.isEmpty) return widget.supList;
    final keyword = _keyword.toLowerCase();
    return widget.supList.where((sup) {
      final fullName = '${sup.firstName} ${sup.lastName}'.toLowerCase();
      return fullName.contains(keyword);
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8.0),
        height: MediaQuery.of(context).size.height - 192,
        decoration: BoxDecoration(
            color: AppConstants.secondaryColor,
            borderRadius: BorderRadius.circular(20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text(
                  "Pointages site",
                  style: TextStyle(fontSize: 16, color: Colors.white,fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
            Row(
              children: [
               
                Expanded(
                  child: SearchTextField(
                      fillColor: AppConstants.bgColor,
                      hintColor: AppConstants.secondaryColor,
                      textColor: Colors.white,
                      onSearch: (value) {
                        setState(() {
                          _keyword = value;
                        });
                      },
                      onPress: () {}),
                ),
                const SizedBox(width: 5),
                _buildDateFilterDropdown(),
              ],
            ),
            const Divider(),
            Expanded(
              child: _buildSupervisorList(),
            ),
          ],
        ));
  }

  Widget _buildSupervisorList() {
    final data = _filteredSupervisors;
    
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Aucun superviseur trouvé',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final supervisor = data[index];
        return Card(
          elevation: 0.2,
          color: AppConstants.secondaryColor.withValues(alpha: 0.3),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              '${supervisor.firstName} ${supervisor.lastName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: NbPointageStatus(
              supervisor: supervisor,
              dateFilter: _selectedDateFilter,
              customStartDate: _customStartDate,
              customEndDate: _customEndDate,
            ),
            trailing: IconButton(
              tooltip: "Rapport",
              icon: const Icon(Icons.description, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImprimeRapport(
                      source: "${supervisor.firstName} ${supervisor.lastName}",
                    ),
                  ),
                );
              },
            ),
            onTap: () => _showSiteStatusDialog(supervisor),
          ),
        );
      },
    );
  }

  void _showSiteStatusDialog(Supervisor supervisor) {
    showDialog(
      context: context,
      builder: (_) => SiteStatusDialog.forSupervisor(
        supervisor: supervisor,
        dateFilter: _selectedDateFilter,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: AppConstants.bgColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateFilter>(
          value: _selectedDateFilter,
          padding: const EdgeInsets.all(0),
          dropdownColor: AppConstants.bgColor,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          items: DateFilter.values.map((DateFilter filter) {
            return DropdownMenuItem<DateFilter>(
              value: filter,
              child: Text(
                filter.label,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (DateFilter? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedDateFilter = newValue;
                if (newValue == DateFilter.custom) {
                  _showCustomDatePicker();
                } else {
                  _customStartDate = null;
                  _customEndDate = null;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _customEndDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _customEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    } else {
      // Si l'utilisateur annule, revenir au filtre précédent
      setState(() {
        _selectedDateFilter = DateFilter.today;
      });
    }
  }
}
