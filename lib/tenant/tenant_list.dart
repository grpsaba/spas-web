import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/access_control.dart';
import 'package:spas_web/services/loading.dart';
import 'package:spas_web/services/tenant.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  final TenantService _service = TenantService();

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 20,
      title: 'Gestion des pays',
      child: AccessControl.canBypassTenantFilter
          ? _buildContent()
          : const Center(
              child: Text("Acces reserve aux administrateurs."),
            ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder(
        stream: _service.all(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return Center(child: Loading(size: 64, inline: true));
          }

          final tenants = snapshot.data!.docs.map((doc) {
            final data =
                jsonDecode(jsonEncode(doc.data())) as Map<String, dynamic>;
            return Tenant.fromJson({
              'id': doc.id,
              ...data,
            });
          }).toList();

          return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).primaryColor.withOpacity(0.08),
                ),
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Pays')),
                  DataColumn(label: Text('Code pays')),
                  DataColumn(label: Text('Pointage superviseurs')),
                  DataColumn(label: Text('Pointage chefs zone')),
                  DataColumn(label: Text('Affectations')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  ...tenants.map(_buildRow),
                  DataRow(cells: [
                    DataCell(
                      TextButton.icon(
                        onPressed: _showTenantDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un pays'),
                      ),
                    ),
                    const DataCell(SizedBox.shrink()),
                    const DataCell(SizedBox.shrink()),
                    const DataCell(SizedBox.shrink()),
                    const DataCell(SizedBox.shrink()),
                    const DataCell(SizedBox.shrink()),
                    const DataCell(SizedBox.shrink()),
                    const DataCell(SizedBox.shrink()),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildRow(Tenant tenant) {
    return DataRow(cells: [
      DataCell(Text(
        tenant.id,
        style: const TextStyle(fontWeight: FontWeight.bold),
      )),
      DataCell(Text(tenant.label)),
      DataCell(Text(tenant.countryCode)),
      DataCell(_PointageModeLabel(mode: tenant.pointageMode)),
      DataCell(_PointageModeLabel(mode: tenant.zoneChiefPointageMode)),
      DataCell(_TenantUsage(service: _service, tenantId: tenant.id)),
      DataCell(_TenantStatus(active: tenant.active)),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: tenant.active,
              onChanged: (active) => _setActive(tenant, active),
            ),
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit),
              onPressed: () => _showTenantDialog(tenant: tenant),
            ),
          ],
        ),
      ),
    ]);
  }

  Future<void> _setActive(Tenant tenant, bool active) async {
    try {
      await _service.setActive(tenant, active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Pays active.' : 'Pays desactive.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _showTenantDialog({Tenant? tenant}) async {
    final idController = TextEditingController(text: tenant?.id ?? '');
    final labelController = TextEditingController(text: tenant?.label ?? '');
    final countryCodeController =
        TextEditingController(text: tenant?.countryCode ?? '');
    final formKey = GlobalKey<FormState>();
    bool active = tenant?.active ?? true;
    String pointageMode = tenant?.pointageMode ?? TenantPointageMode.photo;
    String zoneChiefPointageMode =
        tenant?.zoneChiefPointageMode ?? pointageMode;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tenant == null ? 'Ajouter un pays' : 'Modifier pays'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 460,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: idController,
                        enabled: tenant == null,
                        decoration: const InputDecoration(
                          labelText: 'Code tenant',
                          hintText: 'ex: bf',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final id = value?.trim();
                          if (id == null || id.isEmpty) {
                            return 'Code obligatoire';
                          }
                          if (id.contains(' ')) {
                            return 'Pas d espace dans le code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Libelle',
                          hintText: 'ex: Burkina Faso',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return value == null || value.trim().isEmpty
                              ? 'Libelle obligatoire'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: countryCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Code pays',
                          hintText: 'ex: BF',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          return value == null || value.trim().isEmpty
                              ? 'Code pays obligatoire'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: active,
                        onChanged: (value) {
                          setDialogState(() {
                            active = value;
                          });
                        },
                        title: const Text('Actif'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: pointageMode,
                        decoration: const InputDecoration(
                          labelText: 'Mode de pointage superviseurs',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TenantPointageMode.photo,
                            child: Text('Photo'),
                          ),
                          DropdownMenuItem(
                            value: TenantPointageMode.geo,
                            child: Text('Geolocalisation'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            if (zoneChiefPointageMode == pointageMode) {
                              zoneChiefPointageMode = value;
                            }
                            pointageMode = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: zoneChiefPointageMode,
                        decoration: const InputDecoration(
                          labelText: 'Mode de pointage chefs de zone',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TenantPointageMode.photo,
                            child: Text('Photo'),
                          ),
                          DropdownMenuItem(
                            value: TenantPointageMode.geo,
                            child: Text('Geolocalisation'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            zoneChiefPointageMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final updatedTenant = Tenant(
                              id: idController.text.trim().toLowerCase(),
                              label: labelController.text.trim(),
                              countryCode: countryCodeController.text
                                  .trim()
                                  .toUpperCase(),
                              active: active,
                              pointageMode: pointageMode,
                              zoneChiefPointageMode: zoneChiefPointageMode,
                            );

                            if (tenant != null && tenant.active != active) {
                              await _service.setActive(updatedTenant, active);
                            }
                            await _service.save(updatedTenant);
                            if (context.mounted) Navigator.pop(context);
                          } catch (error) {
                            setDialogState(() {
                              saving = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );

    idController.dispose();
    labelController.dispose();
    countryCodeController.dispose();
  }
}

class _TenantUsage extends StatelessWidget {
  const _TenantUsage({
    required this.service,
    required this.tenantId,
  });

  final TenantService service;
  final String tenantId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TenantUsageCount>(
      future: service.usageCount(tenantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final usage = snapshot.data!;
        return Text(
          '${usage.managers} manager(s), ${usage.supervisors} superviseur(s)',
        );
      },
    );
  }
}

class _TenantStatus extends StatelessWidget {
  const _TenantStatus({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 8),
        Text(active ? 'Actif' : 'Inactif'),
      ],
    );
  }
}

class _PointageModeLabel extends StatelessWidget {
  const _PointageModeLabel({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final isGeo = mode == TenantPointageMode.geo;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isGeo ? Icons.location_on_outlined : Icons.photo_camera_outlined,
          size: 18,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(isGeo ? 'Geolocalisation' : 'Photo'),
      ],
    );
  }
}
