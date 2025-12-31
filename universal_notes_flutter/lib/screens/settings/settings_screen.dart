import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about/about_screen.dart';
import 'package:universal_notes_flutter/screens/settings/views/fluent_settings_view.dart';
import 'package:universal_notes_flutter/screens/settings/views/material_settings_view.dart';

/// SettingsScreen controller - platform-adaptive
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    unawaited(_initPackageInfo());
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  void _openAbout() {
    if (_packageInfo == null) return;
    
    if (defaultTargetPlatform == TargetPlatform.windows) {
      unawaited(
        Navigator.of(context).push(
          fluent.FluentPageRoute<void>(
            builder: (context) => AboutScreen(packageInfo: _packageInfo!),
          ),
        ),
      );
    } else {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => AboutScreen(packageInfo: _packageInfo!),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentSettingsView(
        isLoadingInfo: _packageInfo == null,
        onOpenAbout: _openAbout,
      );
    } else {
      return MaterialSettingsView(
        isLoadingInfo: _packageInfo == null,
        onOpenAbout: _openAbout,
      );
    }
  }
}
