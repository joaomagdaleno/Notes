import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/sync_conflict.dart';
import 'package:notes_hub/services/sync_service.dart';
import 'package:notes_hub/widgets/conflict_resolver_dialog.dart';

/// A widget that listens for sync conflicts and shows a resolver dialog.
class SyncConflictListener extends StatefulWidget {
  /// Creates a new [SyncConflictListener].
  const SyncConflictListener({required this.child, super.key});

  /// The child widget to display.
  final Widget child;

  @override
  State<SyncConflictListener> createState() => _SyncConflictListenerState();
}

class _SyncConflictListenerState extends State<SyncConflictListener> {
  StreamSubscription<SyncConflict>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = SyncService.instance.conflictsStream.listen((conflict) {
      if (mounted) {
        unawaited(showConflictResolver(context, conflict));
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
