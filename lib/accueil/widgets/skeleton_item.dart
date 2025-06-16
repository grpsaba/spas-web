import 'package:flutter/material.dart';

class SkeletonBuilder extends StatelessWidget {
  const SkeletonBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 8,
        itemBuilder: (context, index) => const SiteSkeletonItem(),
      ),
    );
  }
}

class SiteSkeletonItem extends StatelessWidget {
  const SiteSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro et titre du site
          Row(
            children: [
              Container(
                width: 20,
                height: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          // Agents info
          Container(
            width: 80,
            height: 10,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Statistiques
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (_) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),
          ),
        ),

        // 2. Progress bar Pointages site
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 10, width: 60, color: Colors.white),
              const SizedBox(height: 8),
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),

        // 3. Barre de recherche
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4. Liste des sites (squelettes)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 8,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: SiteSkeletonItem(),
            ),
          ),
        )
      ],
    );
  }
}
