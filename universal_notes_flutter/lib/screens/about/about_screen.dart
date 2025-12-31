import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about/views/fluent_about_view.dart';
import 'package:universal_notes_flutter/screens/about/views/material_about_view.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';
import 'package:universal_notes_flutter/utils/windows_update_helper.dart';

/// AboutScreen controller - platform-adaptive
class AboutScreen extends StatefulWidget {
  final PackageInfo packageInfo;
  final TargetPlatform? debugPlatform;
  final UpdateService? updateService;

  const AboutScreen({
    required this.packageInfo,
    super.key,
    this.debugPlatform,
    this.updateService,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _isChecking = ValueNotifier<bool>(false);
  final _updateStatus = ValueNotifier<String>('');

  @override
  void dispose() {
    _isChecking.dispose();
    _updateStatus.dispose();
    super.dispose();
  }

  Future<void> _handleCheckUpdate() async {
    final isWindows = widget.debugPlatform != null
        ? widget.debugPlatform == TargetPlatform.windows
        : defaultTargetPlatform == TargetPlatform.windows;

    if (isWindows) {
      await _checkForUpdateWindows();
    } else {
      await _checkForUpdateMaterial();
    }
  }

  Future<void> _checkForUpdateMaterial() async {
    _isChecking.value = true;
    _updateStatus.value = '';

    if (!mounted) return;
    await UpdateHelper.checkForUpdate(
      context,
      isManual: true,
      updateService: widget.updateService,
    );

    if (mounted) {
      _isChecking.value = false;
    }
  }

  Future<void> _checkForUpdateWindows() async {
    _isChecking.value = true;
    _updateStatus.value = '';
    await WindowsUpdateHelper.checkForUpdate(
      onStatusChange: (message) {
        if (mounted) _updateStatus.value = message;
      },
      onError: (message) {
        if (mounted) _updateStatus.value = message;
      },
      onNoUpdate: () {
        if (mounted) {
          _updateStatus.value = 'Você já está na versão mais recente.';
        }
      },
      onCheckFinished: () {
        if (mounted) _isChecking.value = false;
      },
      updateService: widget.updateService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = widget.debugPlatform != null
        ? widget.debugPlatform == TargetPlatform.windows
        : defaultTargetPlatform == TargetPlatform.windows;

    return ValueListenableBuilder<bool>(
      valueListenable: _isChecking,
      builder: (context, isChecking, _) {
        return ValueListenableBuilder<String>(
          valueListenable: _updateStatus,
          builder: (context, updateStatus, _) {
            if (isWindows) {
              return FluentAboutView(
                packageInfo: widget.packageInfo,
                isChecking: isChecking,
                updateStatus: updateStatus,
                onCheckUpdate: _handleCheckUpdate,
                onBack: () => Navigator.pop(context),
              );
            } else {
              return MaterialAboutView(
                packageInfo: widget.packageInfo,
                isChecking: isChecking,
                onCheckUpdate: _handleCheckUpdate,
              );
            }
          },
        );
      },
    );
  }
}
