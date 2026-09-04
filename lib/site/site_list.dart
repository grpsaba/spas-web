import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/pdf/api/pdf_api.dart';
import 'package:spas_web/pointage_redesign/models/pointage_exception.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/error_display.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/site.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/export.dart';
import '../services/loading.dart';
import '../services/pointerSite.dart';
import 'bulk_pointing_dialog.dart';
import 'manual_pointing_dialog.dart';

class SiteList extends StatefulWidget {
  const SiteList({
    super.key,
  });

  @override
  State<SiteList> createState() => _SiteListState();
}

class _SiteListState extends State<SiteList> {
  final SiteService _service = SiteService();
  final TextEditingController _rowsController = TextEditingController();
  String _keyword = "";
  int rowParPage = 10;
  final int defauldRowParPage = 10;
  bool _showActiveSites = true;
  bool _sortAscending = true;
  int _sortColumnIndex = 1;

  @override
  void initState() {
    super.initState();
    _rowsController.text = defauldRowParPage.toString();
  }

  @override
  void dispose() {
    _rowsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 2,
      title: "Gestion des sites",
      child: Container(
        color: const Color(0xFFF6F7FB),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: StreamBuilder(
            stream: _service.all(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ErrorDisplay(
                    exception: PointageException.query(),
                    customMessage: snapshot.error.toString(),
                    onRetry: () => setState(() {}),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Center(
                  child: Loading(
                    size: 64,
                    inline: true,
                  ),
                );
              }

              final allSites = snapshot.data?.docs
                      .map((e) => Site.fromJson(e.data() as Map<String, dynamic>))
                      .toList() ??
                  <Site>[];
              final activeCount =
                  allSites.where((site) => site.actif == true).length;
              final inactiveCount =
                  allSites.where((site) => site.actif != true).length;
              final totalAgents =
                  allSites.fold<int>(0, (sum, site) => sum + site.nbAgent);
              final visibleSites = _sortSites(_filterSites(
                allSites
                    .where((site) => (site.actif ?? false) == _showActiveSites)
                    .toList(),
              ));

              return Column(
                children: [
                  _SitesHeader(
                    totalSites: allSites.length,
                    activeSites: activeCount,
                    inactiveSites: inactiveCount,
                    totalAgents: totalAgents,
                    visibleSites: visibleSites.length,
                    showActiveSites: _showActiveSites,
                    onSearch: (value) {
                      setState(() {
                        _keyword = value;
                      });
                    },
                    onStatusChanged: (value) {
                      setState(() {
                        _showActiveSites = value;
                      });
                    },
                    onAdd: _canAddSite ? _goToAddSite : null,
                    onQrCodes: _canGenerateSiteQr
                        ? () => CarteGenerator.generateMiltiQrSite(visibleSites)
                        : null,
                    onBulkPointing: _canAddSite
                        ? () => _showBulkPointingDialog(context, visibleSites)
                        : null,
                    onExportPdf: _canPrintSite
                        ? () async {
                            final document =
                                await SiteListToPDF.export(visibleSites);
                            PdfApi.openFile(document);
                          }
                        : null,
                    onExportExcel: _canPrintSite
                        ? () => ExportData.SitesToExcel(visibleSites)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _SitesTableCard(
                      sites: visibleSites,
                      rowsPerPage: rowParPage,
                      rowsController: _rowsController,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      onSort: _setSort,
                      onIncreaseRows: () {
                        setState(() {
                          rowParPage += 1;
                          _rowsController.text = rowParPage.toString();
                        });
                      },
                      onDecreaseRows: () {
                        setState(() {
                          rowParPage = rowParPage <= defauldRowParPage
                              ? defauldRowParPage
                              : rowParPage - 1;
                          _rowsController.text = rowParPage.toString();
                        });
                      },
                      onOpenDetails: _showSiteDetails,
                      onEdit: (site) => context.go('/sites/add', extra: site),
                      onGenerateQr: CarteGenerator.generateQrSite,
                      onManualPointing: (site) {
                        _showManualPointingDialog(context, site);
                      },
                      onToggleStatus: _toggleSiteStatus,
                      onStopSos: _stopSos,
                      onDelete: _deleteSite,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool get _canAddSite =>
      AuthService.currentManager!.profil!.getModule(ModuleName.SITE)!.add;

  bool get _canValidateSite => AuthService.currentManager!.profil!
      .getModule(ModuleName.SITE)!
      .validation;

  bool get _canDeleteSite =>
      AuthService.currentManager!.profil!.getModule(ModuleName.SITE)!.delete;

  bool get _canPrintSite =>
      AuthService.currentManager!.profil!.getModule(ModuleName.SITE)!.print;

  bool get _canGenerateSiteQr => AuthService.currentManager!.profil!
      .getModule(ModuleName.SITE)!
      .generBadge;

  List<Site> _filterSites(List<Site> sites) {
    final keyword = _keyword.trim().toLowerCase();
    if (keyword.isEmpty) return sites;

    return sites.where((site) {
      final supervisors = [
        _supervisorName(site.supervisor),
        _supervisorName(site.supervisor_2),
      ];
      final values = [
        site.codeSite,
        site.name,
        site.phone,
        site.email,
        site.adresse,
        site.zone?.name ?? '',
        site.zone?.codeZone ?? '',
        site.pointageType,
        ...supervisors,
      ];
      return values.any((value) => value.toLowerCase().contains(keyword));
    }).toList();
  }

  List<Site> _sortSites(List<Site> sites) {
    int compare(Site a, Site b) {
      switch (_sortColumnIndex) {
        case 0:
          return a.codeSite.compareTo(b.codeSite);
        case 2:
          return (a.zone?.name ?? '').compareTo(b.zone?.name ?? '');
        case 3:
          return a.phone.compareTo(b.phone);
        case 4:
          return a.nbAgent.compareTo(b.nbAgent);
        case 1:
        default:
          return a.name.compareTo(b.name);
      }
    }

    final sorted = List<Site>.from(sites)..sort(compare);
    if (!_sortAscending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  void _setSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _goToAddSite() {
    final site = Site(
      UID: "",
      codeSite: "",
      name: "",
      adresse: "",
      email: "",
      phone: "",
      latLng: LatLngModel(lat: 0, lng: 0),
      token: "",
      nbAgent: 0,
      supervisor_2: null,
      supervisor: null,
      actif: false,
      zone: null,
      dateContrat: null,
      nbRonde: null,
    );
    context.go('/sites/add', extra: site);
  }

  void _showManualPointingDialog(BuildContext context, Site site) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ManualPointingDialog(site: site);
      },
    );
  }

  void _showBulkPointingDialog(BuildContext context, List<Site> sites) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BulkPointingDialog(sites: sites);
      },
    );
  }

  void _showSiteDetails(Site site) {
    final pageContext = context;

    showDialog(
      context: context,
      builder: (context) {
        return _SiteDetailsDialog(
          site: site,
          canEdit: _canAddSite,
          canToggleStatus: _canValidateSite,
          canDelete: _canDeleteSite,
          canGenerateQr: _canGenerateSiteQr,
          onEdit: (site) => pageContext.go('/sites/add', extra: site),
          onGenerateQr: CarteGenerator.generateQrSite,
          onManualPointing: (site) =>
              _showManualPointingDialog(pageContext, site),
          onToggleStatus: _toggleSiteStatus,
          onStopSos: _stopSos,
          onDelete: _deleteSite,
        );
      },
    );
  }

  Future<void> _toggleSiteStatus(Site site) async {
    // final wasInactive = !(site.actif ?? false);
    site.actif = !(site.actif ?? false);

    await _service.update(site);

    // Generation automatique des pointages desactivee lors de l'activation.
    // if (wasInactive && site.actif == true) {
    //   _generateMonthlyPointingsForSite(site);
    // }
  }

  Future<void> _stopSos(Site site) async {
    await _service.stopSos(site);
    site.sos = false;
  }

  Future<void> _deleteSite(Site site) {
    return _service.delete(site);
  }

  Future<void> _generateMonthlyPointingsForSite(Site site) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final today = DateTime(now.year, now.month, now.day);

      final supervisors = <Supervisor>[
        if (site.supervisor != null) site.supervisor!,
        if (site.supervisor_2 != null) site.supervisor_2!,
      ];

      if (supervisors.isEmpty) return;

      for (final supervisor in supervisors) {
        for (DateTime date = startOfMonth;
            date.isBefore(today.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          final pointingSite = PointingSite(
            site: site,
            supervisor: supervisor,
            latlng: LatLngModel(lat: site.latLng.lat, lng: site.latLng.lng),
            date: DateTime(date.year, date.month, date.day, 8),
            distance: 0,
          );

          await PointingSiteService().add(pointingSite);
        }
      }
    } catch (error) {
      debugPrint(
        'Erreur lors de la generation des pointages pour ${site.name}: $error',
      );
    }
  }
}

class _SitesHeader extends StatelessWidget {
  const _SitesHeader({
    required this.totalSites,
    required this.activeSites,
    required this.inactiveSites,
    required this.totalAgents,
    required this.visibleSites,
    required this.showActiveSites,
    required this.onSearch,
    required this.onStatusChanged,
    required this.onAdd,
    required this.onQrCodes,
    required this.onBulkPointing,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  final int totalSites;
  final int activeSites;
  final int inactiveSites;
  final int totalAgents;
  final int visibleSites;
  final bool showActiveSites;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool> onStatusChanged;
  final VoidCallback? onAdd;
  final VoidCallback? onQrCodes;
  final VoidCallback? onBulkPointing;
  final Future<void> Function()? onExportPdf;
  final VoidCallback? onExportExcel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 980 ? 2 : 4;
            final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: _MetricTile(
                    icon: HugeIcons.strokeRoundedBuilding03,
                    label: 'Total sites',
                    value: totalSites.toString(),
                    color: const Color(0xFF2563EB),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetricTile(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    label: 'Sites actifs',
                    value: activeSites.toString(),
                    color: const Color(0xFF059669),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetricTile(
                    icon: HugeIcons.strokeRoundedCancelCircle,
                    label: 'Sites inactifs',
                    value: inactiveSites.toString(),
                    color: const Color(0xFFDC2626),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetricTile(
                    icon: HugeIcons.strokeRoundedUserGroup,
                    label: 'Agents affectes',
                    value: totalAgents.toString(),
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SearchField(
                hintText: 'Rechercher un site',
                onChanged: onSearch,
              ),
            ),
            const SizedBox(width: 12),
            _StatusSegmentedFilter(
              showActiveSites: showActiveSites,
              onChanged: onStatusChanged,
            ),
            const SizedBox(width: 12),
            _CountPill(
              icon: HugeIcons.strokeRoundedFilter,
              label: '$visibleSites affiches',
            ),
            const SizedBox(width: 12),
            if (onAdd != null)
              _PrimaryActionButton(
                tooltip: 'Ajouter un site',
                icon: HugeIcons.strokeRoundedPropertyAdd,
                label: 'Ajouter',
                onPressed: onAdd!,
              ),
            if (onQrCodes != null) ...[
              const SizedBox(width: 8),
              _IconActionButton(
                tooltip: 'Generer les QR codes',
                icon: HugeIcons.strokeRoundedQrCode,
                color: const Color(0xFF059669),
                onPressed: onQrCodes!,
              ),
            ],
            if (onBulkPointing != null) ...[
              const SizedBox(width: 8),
              _IconActionButton(
                tooltip: 'Pointage en lot',
                icon: HugeIcons.strokeRoundedCheckList,
                color: const Color(0xFF7C3AED),
                onPressed: onBulkPointing!,
              ),
            ],
            if (onExportPdf != null || onExportExcel != null) ...[
              const SizedBox(width: 8),
              _ExportMenu(
                onPdf: onExportPdf,
                onExcel: onExportExcel,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SitesTableCard extends StatelessWidget {
  const _SitesTableCard({
    required this.sites,
    required this.rowsPerPage,
    required this.rowsController,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onIncreaseRows,
    required this.onDecreaseRows,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onGenerateQr,
    required this.onManualPointing,
    required this.onToggleStatus,
    required this.onStopSos,
    required this.onDelete,
  });

  final List<Site> sites;
  final int rowsPerPage;
  final TextEditingController rowsController;
  final int sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;
  final VoidCallback onIncreaseRows;
  final VoidCallback onDecreaseRows;
  final ValueChanged<Site> onOpenDetails;
  final ValueChanged<Site> onEdit;
  final ValueChanged<Site> onGenerateQr;
  final ValueChanged<Site> onManualPointing;
  final Future<void> Function(Site) onToggleStatus;
  final Future<void> Function(Site) onStopSos;
  final Future<void> Function(Site) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = math.max(constraints.maxWidth, 1540.0);

            return SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: PaginatedDataTable(
                  
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: sortAscending,
                    headingRowColor:
                        WidgetStateProperty.all( Colors.white),
                    horizontalMargin: 20,
                    columnSpacing: 30,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 72,
                    rowsPerPage: rowsPerPage,
                    showFirstLastButtons: true,
                    showEmptyRows: false,
                    showCheckboxColumn: false,
                    header: Container(
                      height: 100,
                     width: double.infinity,
                      color: Colors.white,
                      child: _TableHeader(
                      icon: HugeIcons.strokeRoundedLayoutTable01,
                      title: 'Liste des sites',
                    )) ,
                    actions: [
                      RowPerPageWidget(
                        controller: rowsController,
                        incremente: onIncreaseRows,
                        decremente: onDecreaseRows,
                      ),
                    ],
                    columns: [
                      DataColumn(
                        label: const Text('Code'),
                        onSort: onSort,
                      ),
                      DataColumn(
                        label: const Text('Site'),
                        onSort: onSort,
                      ),
                      DataColumn(
                        label: const Text('Zone'),
                        onSort: onSort,
                      ),
                      const DataColumn(label: Text('Contact')),
                      DataColumn(
                        label: const Text('Agents'),
                        numeric: true,
                        onSort: onSort,
                      ),
                      const DataColumn(label: Text('GPS')),
                      const DataColumn(label: Text('Superviseurs')),
                      const DataColumn(label: Text('Statut')),
                      const DataColumn(label: Text('')),
                    ],
                    source: _SiteDataSource(
                      context: context,
                      data: sites,
                      onOpenDetails: onOpenDetails,
                      onEdit: onEdit,
                      onGenerateQr: onGenerateQr,
                      onManualPointing: onManualPointing,
                      onToggleStatus: onToggleStatus,
                      onStopSos: onStopSos,
                      onDelete: onDelete,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SiteDataSource extends DataTableSource {
  _SiteDataSource({
    required this.context,
    required this.data,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onGenerateQr,
    required this.onManualPointing,
    required this.onToggleStatus,
    required this.onStopSos,
    required this.onDelete,
  });

  final BuildContext context;
  final List<Site> data;
  final ValueChanged<Site> onOpenDetails;
  final ValueChanged<Site> onEdit;
  final ValueChanged<Site> onGenerateQr;
  final ValueChanged<Site> onManualPointing;
  final Future<void> Function(Site) onToggleStatus;
  final Future<void> Function(Site) onStopSos;
  final Future<void> Function(Site) onDelete;

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;

    final site = data[index];

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return Theme.of(context).primaryColor.withOpacity(0.04);
        }
        return null;
      }),
      onSelectChanged: (_) => onOpenDetails(site),
      cells: [
        DataCell(Text(
          site.codeSite,
          style: const TextStyle(fontWeight: FontWeight.w700),
        )),
        DataCell(_SiteIdentity(site: site)),
        DataCell(_SoftChip(
          label: site.zone?.name ?? 'Aucune zone',
          color: const Color(0xFF2563EB),
        )),
        DataCell(_ContactCell(site: site)),
        DataCell(Text(site.nbAgent.toString())),
        DataCell(Text(_formatGps(site))),
        DataCell(_SupervisorCell(site: site)),
        DataCell(_StatusChip(active: site.actif == true)),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: _SiteActionsMenu(
              site: site,
              onOpenDetails: onOpenDetails,
              onEdit: onEdit,
              onGenerateQr: onGenerateQr,
              onManualPointing: onManualPointing,
              onToggleStatus: onToggleStatus,
              onStopSos: onStopSos,
              onDelete: onDelete,
            ),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}

class _SiteActionsMenu extends StatelessWidget {
  const _SiteActionsMenu({
    required this.site,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onGenerateQr,
    required this.onManualPointing,
    required this.onToggleStatus,
    required this.onStopSos,
    required this.onDelete,
  });

  final Site site;
  final ValueChanged<Site> onOpenDetails;
  final ValueChanged<Site> onEdit;
  final ValueChanged<Site> onGenerateQr;
  final ValueChanged<Site> onManualPointing;
  final Future<void> Function(Site) onToggleStatus;
  final Future<void> Function(Site) onStopSos;
  final Future<void> Function(Site) onDelete;

  @override
  Widget build(BuildContext context) {
    final module = AuthService.currentManager!.profil!.getModule(ModuleName.SITE)!;
    final isActive = site.actif == true;

    return PopupMenuButton<_SiteRowAction>(
      tooltip: 'Actions',
      icon: const Icon(
        HugeIcons.strokeRoundedMoreVertical,
        size: 20,
      ),
      onSelected: (action) async {
        switch (action) {
          case _SiteRowAction.details:
            onOpenDetails(site);
            break;
          case _SiteRowAction.edit:
            onEdit(site);
            break;
          case _SiteRowAction.qr:
            onGenerateQr(site);
            break;
          case _SiteRowAction.manualPointing:
            onManualPointing(site);
            break;
          case _SiteRowAction.toggleStatus:
            await onToggleStatus(site);
            break;
          case _SiteRowAction.stopSos:
            await onStopSos(site);
            break;
          case _SiteRowAction.delete:
            final confirmed = await _confirmDelete(context);
            if (confirmed == true) {
              await onDelete(site);
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _SiteRowAction.details,
          child: _MenuItemLabel(
            icon: HugeIcons.strokeRoundedView,
            label: 'Details',
          ),
        ),
        if (module.add && isActive)
          const PopupMenuItem(
            value: _SiteRowAction.edit,
            child: _MenuItemLabel(
              icon: HugeIcons.strokeRoundedEdit02,
              label: 'Modifier',
            ),
          ),
        if (module.generBadge && isActive)
          const PopupMenuItem(
            value: _SiteRowAction.qr,
            child: _MenuItemLabel(
              icon: HugeIcons.strokeRoundedQrCode,
              label: 'QR code',
            ),
          ),
        if (module.add && isActive)
          const PopupMenuItem(
            value: _SiteRowAction.manualPointing,
            child: _MenuItemLabel(
              icon: HugeIcons.strokeRoundedLocationUser01,
              label: 'Pointage manuel',
            ),
          ),
        if (module.validation)
          PopupMenuItem(
            value: _SiteRowAction.toggleStatus,
            child: _MenuItemLabel(
              icon: isActive
                  ? HugeIcons.strokeRoundedCancelCircle
                  : HugeIcons.strokeRoundedCheckmarkCircle01,
              label: isActive ? 'Desactiver' : 'Activer',
            ),
          ),
        if (site.sos)
          const PopupMenuItem(
            value: _SiteRowAction.stopSos,
            child: _MenuItemLabel(
              icon: HugeIcons.strokeRoundedAlertCircle,
              label: 'Arreter SOS',
            ),
          ),
        if (!isActive && module.delete)
          const PopupMenuItem(
            value: _SiteRowAction.delete,
            child: _MenuItemLabel(
              icon: HugeIcons.strokeRoundedDelete02,
              label: 'Supprimer',
              destructive: true,
            ),
          ),
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le site'),
          content: Text('Supprimer definitivement ${site.name} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}

class _SiteDetailsDialog extends StatefulWidget {
  const _SiteDetailsDialog({
    required this.site,
    required this.canEdit,
    required this.canToggleStatus,
    required this.canDelete,
    required this.canGenerateQr,
    required this.onEdit,
    required this.onGenerateQr,
    required this.onManualPointing,
    required this.onToggleStatus,
    required this.onStopSos,
    required this.onDelete,
  });

  final Site site;
  final bool canEdit;
  final bool canToggleStatus;
  final bool canDelete;
  final bool canGenerateQr;
  final ValueChanged<Site> onEdit;
  final ValueChanged<Site> onGenerateQr;
  final ValueChanged<Site> onManualPointing;
  final Future<void> Function(Site) onToggleStatus;
  final Future<void> Function(Site) onStopSos;
  final Future<void> Function(Site) onDelete;

  @override
  State<_SiteDetailsDialog> createState() => _SiteDetailsDialogState();
}

class _SiteDetailsDialogState extends State<_SiteDetailsDialog> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final active = site.actif == true;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                color: const Color(0xFF111827),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        HugeIcons.strokeRoundedBuilding03,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            site.codeSite,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(active: active, dark: true),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        HugeIcons.strokeRoundedCancelCircle,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.62,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _InfoTile(
                            icon: HugeIcons.strokeRoundedMapsCircle01,
                            label: 'Zone',
                            value: site.zone?.name ?? 'Aucune zone',
                          ),
                          _InfoTile(
                            icon: HugeIcons.strokeRoundedCall,
                            label: 'Telephone',
                            value: site.phone,
                          ),
                          _InfoTile(
                            icon: HugeIcons.strokeRoundedMail01,
                            label: 'Email',
                            value: site.email,
                          ),
                          _InfoTile(
                            icon: HugeIcons.strokeRoundedUserGroup,
                            label: 'Agents',
                            value: site.nbAgent.toString(),
                          ),
                          _InfoTile(
                            icon: HugeIcons.strokeRoundedGps01,
                            label: 'Position GPS',
                            value: _formatGps(site),
                          ),
                          _InfoTile(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            label: 'Contrat',
                            value: _formatDate(site.dateContrat),
                          ),
                          _InfoTile(
                            icon: HugeIcons.strokeRoundedRoute03,
                            label: 'Rondes',
                            value: '${site.nbRonde ?? 0}',
                          ),
                          _InfoTile(
                            icon: HugeIcons.strokeRoundedClock03,
                            label: 'Pointage',
                            value: _formatPointageType(site.pointageType),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SectionTitle(
                        icon: HugeIcons.strokeRoundedLocationUser01,
                        label: 'Supervision',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _PersonBlock(
                              title: 'Superviseur 1',
                              value: _supervisorName(site.supervisor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PersonBlock(
                              title: 'Superviseur 2',
                              value: _supervisorName(site.supervisor_2),
                            ),
                          ),
                        ],
                      ),
                      if (site.adresse.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _SectionTitle(
                          icon: HugeIcons.strokeRoundedPinLocation01,
                          label: 'Adresse',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          site.adresse,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (site.sos) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                HugeIcons.strokeRoundedAlertCircle,
                                color: Color(0xFFDC2626),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'SOS en cours sur ce site',
                                  style: TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_updating) Loading(size: 26, inline: true),
                    if (widget.canEdit && active)
                      _DialogActionButton(
                        icon: HugeIcons.strokeRoundedEdit02,
                        label: 'Modifier',
                        onPressed: _updating
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                widget.onEdit(site);
                              },
                      ),
                    if (widget.canGenerateQr && active)
                      _DialogActionButton(
                        icon: HugeIcons.strokeRoundedQrCode,
                        label: 'QR code',
                        onPressed:
                            _updating ? null : () => widget.onGenerateQr(site),
                      ),
                    if (active)
                      _DialogActionButton(
                        icon: HugeIcons.strokeRoundedLocationUser01,
                        label: 'Pointer',
                        onPressed: _updating
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                widget.onManualPointing(site);
                              },
                      ),
                    if (site.sos)
                      _DialogActionButton(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        label: 'Arreter SOS',
                        danger: true,
                        onPressed: _updating
                            ? null
                            : () async {
                                await _runAction(() => widget.onStopSos(site));
                              },
                      ),
                    if (widget.canToggleStatus)
                      _DialogActionButton(
                        icon: active
                            ? HugeIcons.strokeRoundedCancelCircle
                            : HugeIcons.strokeRoundedCheckmarkCircle01,
                        label: active ? 'Desactiver' : 'Activer',
                        danger: active,
                        onPressed: _updating
                            ? null
                            : () async {
                                await _runAction(
                                  () => widget.onToggleStatus(site),
                                );
                              },
                      ),
                    if (!active && widget.canDelete)
                      _DialogActionButton(
                        icon: HugeIcons.strokeRoundedDelete02,
                        label: 'Supprimer',
                        danger: true,
                        onPressed: _updating ? null : _confirmDelete,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    setState(() {
      _updating = true;
    });

    try {
      await action();
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action impossible: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le site'),
          content: Text('Supprimer definitivement ${widget.site.name} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final deleted = await _runAction(() => widget.onDelete(widget.site));
    if (mounted && deleted) {
      Navigator.of(context).pop();
    }
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: const Icon(
          HugeIcons.strokeRoundedSearch01,
          size: 20,
          color: Color(0xFF64748B),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}

class _StatusSegmentedFilter extends StatelessWidget {
  const _StatusSegmentedFilter({
    required this.showActiveSites,
    required this.onChanged,
  });

  final bool showActiveSites;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _StatusFilterItem(
            label: 'Actifs',
            icon: HugeIcons.strokeRoundedCheckmarkCircle01,
            selected: showActiveSites,
            onTap: () => onChanged(true),
          ),
          _StatusFilterItem(
            label: 'Inactifs',
            icon: HugeIcons.strokeRoundedCancelCircle,
            selected: !showActiveSites,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterItem extends StatelessWidget {
  const _StatusFilterItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? (label == 'Actifs' ? const Color(0xFF059669) : const Color(0xFFDC2626))
        : const Color(0xFF64748B);

    return Material(
      color: selected ? color.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class _ExportMenu extends StatelessWidget {
  const _ExportMenu({
    required this.onPdf,
    required this.onExcel,
  });

  final Future<void> Function()? onPdf;
  final VoidCallback? onExcel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exporter',
      child: PopupMenuButton<_ExportAction>(
        onSelected: (action) async {
          switch (action) {
            case _ExportAction.pdf:
              await onPdf?.call();
              break;
            case _ExportAction.excel:
              onExcel?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          if (onPdf != null)
            const PopupMenuItem(
              value: _ExportAction.pdf,
              child: _MenuItemLabel(
                icon: HugeIcons.strokeRoundedPdf01,
                label: 'PDF',
              ),
            ),
          if (onExcel != null)
            const PopupMenuItem(
              value: _ExportAction.excel,
              child: _MenuItemLabel(
                icon: HugeIcons.strokeRoundedTable,
                label: 'Excel',
              ),
            ),
        ],
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            HugeIcons.strokeRoundedFileExport,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _SiteIdentity extends StatelessWidget {
  const _SiteIdentity({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          site.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (site.adresse.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            site.adresse,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactCell extends StatelessWidget {
  const _ContactCell({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(site.phone),
        if (site.email.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            site.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _SupervisorCell extends StatelessWidget {
  const _SupervisorCell({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    final supervisor1 = _supervisorName(site.supervisor);
    final supervisor2 = _supervisorName(site.supervisor_2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(supervisor1),
        if (supervisor2 != 'Non affecte') ...[
          const SizedBox(height: 3),
          Text(
            supervisor2,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.active,
    this.dark = false,
  });

  final bool active;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.1) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? Colors.white.withOpacity(0.22) : color.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? HugeIcons.strokeRoundedCheckmarkCircle01
                : HugeIcons.strokeRoundedCancelCircle,
            color: dark ? Colors.white : color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Actif' : 'Inactif',
            style: TextStyle(
              color: dark ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 18),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isEmpty ? 'Non renseigne' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonBlock extends StatelessWidget {
  const _PersonBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              HugeIcons.strokeRoundedLocationUser01,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFDC2626) : Theme.of(context).primaryColor;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _MenuItemLabel extends StatelessWidget {
  const _MenuItemLabel({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFDC2626) : const Color(0xFF334155);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

enum _ExportAction { pdf, excel }

enum _SiteRowAction {
  details,
  edit,
  qr,
  manualPointing,
  toggleStatus,
  stopSos,
  delete,
}

String _supervisorName(Supervisor? supervisor) {
  if (supervisor == null) return 'Non affecte';
  final fullName = '${supervisor.firstName} ${supervisor.lastName}'.trim();
  return fullName.isEmpty ? 'Non affecte' : fullName;
}

String _formatGps(Site site) {
  return '${site.latLng.lat.toStringAsFixed(5)}, ${site.latLng.lng.toStringAsFixed(5)}';
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Non renseigne';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatPointageType(String value) {
  switch (value) {
    case 'nuit':
      return 'Nuit';
    case 'jour_nuit':
      return 'Jour / Nuit';
    case 'jour':
    default:
      return 'Jour';
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
