import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'updater.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Universal Notes'),
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
