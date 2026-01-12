import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/sync_conflict.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/widgets/conflict_resolver_dialog.dart';

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
