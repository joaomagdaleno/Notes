import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';

class Updater {
  static const String _updateUrl =
      'https://github.com/diegolima362/universal_notes_flutter/releases/latest/download';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final updateExe = _getUpdateExePath();
      if (updateExe == null) {
        _showErrorDialog(context, 'Update.exe não encontrado.');
        return;
      }

      _showInfoDialog(context, 'Buscando atualizações...', 'Aguarde um momento.');

      final process = await Process.start(updateExe, ['--update', _updateUrl]);
      final exitCode = await process.exitCode;

      Navigator.of(context).pop(); // Fecha o diálogo de "buscando"

      if (exitCode == 0) {
        // O Squirrel lida com a atualização em segundo plano.
        // Um exit code 0 aqui geralmente significa que o processo foi iniciado.
        // A atualização real, download e instalação são gerenciados pelo Update.exe
        _showInfoDialog(context, 'Atualização em andamento',
            'O aplicativo será reiniciado quando a atualização for concluída.');
      } else {
        _showErrorDialog(
            context, 'Erro ao buscar atualizações (código: $exitCode).');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Ocorreu um erro inesperado: $e');
    }
  }

  String? _getUpdateExePath() {
    final exePath = Platform.resolvedExecutable;
    final exeDir = path.dirname(exePath);
    // O Update.exe geralmente está no diretório pai do diretório do executável do app
    final updateExePath = path.join(exeDir, '..', 'Update.exe');

    if (File(updateExePath).existsSync()) {
      return updateExePath;
    }
    return null;
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erro de Atualização'),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
