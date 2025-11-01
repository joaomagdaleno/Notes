import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../updater.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  String _updateStatus = '';
  bool _isCheckingForUpdates = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingForUpdates) return;
    setState(() {
      _isCheckingForUpdates = true;
      _updateStatus = 'Verificando atualizações...';
    });

    final updater = Updater();
    await updater.checkForUpdates(
      context: context,
      onStatusChange: (status) {
        setState(() {
          _updateStatus = status;
        });
      },
    );

    setState(() {
      _isCheckingForUpdates = false;
    });
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Versão atual do aplicativo:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _version,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isCheckingForUpdates ? null : _checkForUpdates,
              child: const Text('Buscar Atualizações'),
            ),
            const SizedBox(height: 16),
            Text(_updateStatus),
          ],
        ),
      ),
    );
  }
}
