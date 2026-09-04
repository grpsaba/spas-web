import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/profil.dart';
import 'module_list.dart';

class ProfilList extends StatefulWidget {
  ProfilList({
    super.key,
  });

  @override
  State<ProfilList> createState() => _ProfilListState();
}

class _ProfilListState extends State<ProfilList> {
  final ProfilService _service = ProfilService();
  final TextEditingController _profileNameController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  Profil selectedProfil = Profil(name: "", modules: []);

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 330,
          child: _buildProfilePanel(context),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: selectedProfil.name.isEmpty
              ? const _NoProfileSelected()
              : ModuleList(profil: selectedProfil),
        ),
      ],
    );
  }

  Widget _buildProfilePanel(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedShieldUser,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Profils',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (AuthService.currentManager!.profil!
                    .getModule(ModuleName.MANAGER)!
                    .add)
                  Form(
                    key: _key,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _profileNameController,
                            validator: (value) {
                              return value!.trim().isEmpty
                                  ? "Nom du profil obligatoire"
                                  : null;
                            },
                            decoration: InputDecoration(
                              hintText: "Nouveau profil",
                              prefixIcon: const Icon(
                                HugeIcons.strokeRoundedAddCircle,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: "Ajouter un profil",
                          child: Material(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _addProfile,
                              child: const SizedBox(
                                width: 46,
                                height: 46,
                                child: Icon(
                                  HugeIcons.strokeRoundedAdd01,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder(
              stream: _service.all(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Loading(
                      size: 64,
                      inline: true,
                    ),
                  );
                }

                final docs = snapshot.data?.docs
                    .map((e) => jsonDecode(jsonEncode(e.data())))
                    .toList();
                final profiles =
                    docs?.map((e) => Profil.fromJson(e)).toList() ?? <Profil>[];
                profiles.sort((a, b) => a.name.compareTo(b.name));

                if (profiles.isEmpty) {
                  return const _EmptyProfiles();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: profiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final profil = profiles[index];
                    final selected = profil.name == selectedProfil.name;

                    return _ProfileTile(
                      profile: profil,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          selectedProfil = profil;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addProfile() {
    if (!_key.currentState!.validate()) return;
    final profileName = _profileNameController.text.trim();

    ProfilService().add(Profil(name: profileName, modules: [])).then((_) {
      _profileNameController.clear();
      setState(() {
        selectedProfil = Profil(name: profileName, modules: []);
      });
    });
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final Profil profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return Material(
      color: selected ? color.withOpacity(0.1) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color.withOpacity(0.35) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedShieldUser,
                  color: selected ? Colors.white : color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${profile.modules.length} modules',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                HugeIcons.strokeRoundedArrowRight01,
                color: selected ? color : const Color(0xFFCBD5E1),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoProfileSelected extends StatelessWidget {
  const _NoProfileSelected();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              HugeIcons.strokeRoundedShieldUser,
              size: 42,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Text(
              'Selectionnez un profil',
              style: TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Les autorisations du profil s afficheront ici.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  const _EmptyProfiles();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Aucun profil disponible',
        style: TextStyle(color: Color(0xFF64748B)),
      ),
    );
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
