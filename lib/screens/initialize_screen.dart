import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_initializer.dart';
import '../theme/app_theme.dart';

class InitializeScreen extends StatefulWidget {
  const InitializeScreen({
    super.key,
    required this.onDone,
  });

  final VoidCallback onDone;

  @override
  State<InitializeScreen> createState() => _InitializeScreenState();
}

class _InitializeScreenState extends State<InitializeScreen> {
  double _progress = 0;
  String _label = 'Initializing…';
  bool _done = false;

  StreamSubscription<InitProgress>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = AppInitializer.instance.progressStream.listen((p) {
      if (!mounted) return;
      setState(() {
        _progress = p.progress.clamp(0.0, 1.0);
        _label = p.label;
      });
      if (p.isDone && !_done) {
        _done = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onDone();
        });
      }
    });
    AppInitializer.instance.run();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: scaffoldGradient),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Syncing data',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _label,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryIndigo),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(_progress * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

