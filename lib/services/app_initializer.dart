import 'dart:async';

import '../services/realtime_service.dart';

class InitProgress {
  final double progress; // 0..1
  final String label;
  final bool isDone;

  const InitProgress({
    required this.progress,
    required this.label,
    required this.isDone,
  });
}

class AppInitializer {
  AppInitializer._();
  static final AppInitializer instance = AppInitializer._();

  final StreamController<InitProgress> _progress = StreamController<InitProgress>.broadcast();
  Stream<InitProgress> get progressStream => _progress.stream;

  bool _running = false;
  bool _done = false;

  /// Runs once per app session. Safe to call multiple times.
  Future<void> run() async {
    if (_done) {
      _progress.add(const InitProgress(progress: 1, label: 'Ready', isDone: true));
      return;
    }
    if (_running) return;
    _running = true;
    try {
      // Fast init: do minimal calls to avoid delaying the UI.
      _emit(0.10, 'Connecting…');
      await RealtimeService.instance.fetchBranches();
      _emit(0.35, 'Loading summary…');
      await RealtimeService.instance.fetchDashboardSummary();
      _emit(0.70, 'Loading branch performance…');
      await RealtimeService.instance.fetchBranchPerformance();

      _emit(1.0, 'Ready', true);
      _done = true;
    } catch (_) {
      // Even if init fails, proceed to app; cached data (if any) still helps.
      _emit(1.0, 'Ready', true);
      _done = true;
    } finally {
      _running = false;
    }
  }

  void _emit(double p, String label, [bool done = false]) {
    _progress.add(InitProgress(progress: p, label: label, isDone: done));
  }
}

