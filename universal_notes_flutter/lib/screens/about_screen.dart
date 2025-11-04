import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/update_helper.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _currentVersion = '...';
  bool _isChecking = false;
  ReceivePort? _port;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    if (Platform.isAndroid || Platform.isIOS) {
      _port = ReceivePort();
      _bindBackgroundIsolate();
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid || Platform.isIOS) {
      _unbindBackgroundIsolate();
    }
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    if (_port != null) {
      IsolateNameServer.registerPortWithName(_port!.sendPort, 'downloader_send_port');
      _port!.listen((dynamic data) {
        final status = DownloadTaskStatus.fromInt(data[1]);
        final String taskId = data[0];

        if (status == DownloadTaskStatus.complete) {
          _openDownloadedFile(taskId);
        }
      });
    }
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future<void> _openDownloadedFile(String taskId) async {
    final tasks = await FlutterDownloader.loadTasksWithRawQuery(query: 'SELECT * FROM task WHERE task_id="$taskId"');
    if (tasks != null && tasks.isNotEmpty) {
      final task = tasks.first;
      OpenFile.open('${task.savedDir}/${task.filename}');
    }
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isChecking = true;
    });

    await UpdateHelper.checkForUpdate(context, isManual: true);

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
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
          children: [
            Text('Versão atual: $_currentVersion'),
            const SizedBox(height: 20),
            _isChecking
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _checkForUpdate,
                    child: const Text('Verificar Atualizações'),
                  ),
          ],
        ),
      ),
    );
  }
}
