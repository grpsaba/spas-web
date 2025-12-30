import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';

/// Compact error stats card for the home dashboard
class ErrorStatsCard extends StatelessWidget {
  final ErrorLogStats stats;
  final bool isLoading;

  const ErrorStatsCard({
    super.key,
    required this.stats,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/errorlogs'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150, // Fixed width for horizontal scroll context
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF44336),
              const Color(0xFFF44336).withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF44336).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                if (stats.unresolved > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${stats.unresolved}',
                      style: const TextStyle(
                        color: Color(0xFFF44336),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
               
              
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
                    Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniStat('Total', stats.total),
                const SizedBox(width: 16),
                _buildMiniStat('Résolus', stats.resolved),
              ],
            ),
            //   Row(
            //     children: [
            //       Text(
            //     '${stats.unresolved}',
            //     style: const TextStyle(
            //       color: Colors.white,
            //       fontSize: 20,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // const SizedBox(width: 12),
            // const Text(
            //   'Erreurs non résolues',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: 16,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            //     ],
            //   ),
            // Mini stats row
          
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Minimal error indicator for sidebar or compact views
class ErrorIndicatorBadge extends StatelessWidget {
  final int unresolvedCount;

  const ErrorIndicatorBadge({super.key, required this.unresolvedCount});

  @override
  Widget build(BuildContext context) {
    if (unresolvedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        unresolvedCount > 99 ? '99+' : '$unresolvedCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
