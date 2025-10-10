import 'dart:async';

import 'package:spas_web/services/pointerSite.dart';

class AggregationHelper {
  final PointingSiteService _ps = PointingSiteService();

  /// supervisorsUIDs: liste des UID des superviseurs
  /// days: liste de DateTime (une par jour du mois)
  Future<List<Map<String, dynamic>>> getCountsForMonth(
    List<String> supervisorsUIDs,
    List<DateTime> days, {
    int concurrency = 6,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <Map<String, dynamic>>[];
    int totalTasks = supervisorsUIDs.length * days.length;
    int completed = 0;

    final queue = <Future>[];
    final semaphore = StreamController<int>(sync: true);
    // Simple pool: we create up to [concurrency] futures at once.
    for (final uid in supervisorsUIDs) {
      final perSupervisor = <Map<String, dynamic>>[];
      for (final day in days) {
        // Start a task
        final task = () async {
          final count = await _ps.countForSupervisorOnDate(uid, day);
          completed++;
          if (onProgress != null) onProgress(completed, totalTasks);
          return {'uid': uid, 'date': day, 'count': count};
        }();
        queue.add(task);
        // If queue big, await a batch
        if (queue.length >= concurrency) {
          final batch = await Future.wait(queue);
          perSupervisor.addAll(batch.cast<Map<String, dynamic>>());
          queue.clear();
        }
      }
      // Flush remaining in queue for this supervisor
      if (queue.isNotEmpty) {
        final batch = await Future.wait(queue);
        perSupervisor.addAll(batch.cast<Map<String, dynamic>>());
        queue.clear();
      }
      results.add({'supervisorUID': uid, 'data': perSupervisor});
    }

    return results;
  }
}
