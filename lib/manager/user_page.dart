import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/manager/manager_list.dart';
import 'package:spas_web/manager/profil_list.dart';

class UserPage extends StatefulWidget {
  const UserPage({
    super.key,
  });

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 1,
      title: "Gestion utilisateurs",
      child: Container(
        color: const Color(0xFFF6F7FB),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UsersPageHeader(
                selectedIndex: _selectedIndex,
                onChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
              const SizedBox(height: 18),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    ManagerList(),
                    ProfilList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersPageHeader extends StatelessWidget {
  const _UsersPageHeader({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            HugeIcons.strokeRoundedComputerUser,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PC',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Utilisateurs, profils et droits applicatifs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
          ),
        ),
        _SegmentedNav(
          selectedIndex: selectedIndex,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SegmentedNav extends StatelessWidget {
  const _SegmentedNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

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
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentedNavItem(
            icon: HugeIcons.strokeRoundedUserGroup,
            label: 'Utilisateurs',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _SegmentedNavItem(
            icon: HugeIcons.strokeRoundedShieldUser,
            label: 'Profils',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SegmentedNavItem extends StatelessWidget {
  const _SegmentedNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return Material(
      color: selected ? color.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? color : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : const Color(0xFF475569),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
