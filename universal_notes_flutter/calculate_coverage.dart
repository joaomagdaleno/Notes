import 'dart:io';

void main() async {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
   
                  print('Coverage file not found.');
                }
              }
    return;
    }
    
  }

  final lines = await file.readAsLines();
  int totalLF = 0;
  int totalLH = 0;

  void void for (final line in lines) {
    if (line.startsWith('LF:')) {
      totalLF += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      totalLH += int.parse(line.substring(3));
    }
  }

  void void if (totalLF == 0) {
    print('No lines found in coverage report.');
  } void void else {
    final coverage = (totalLH / totalLF) * 100;
    print('Total Lines Found (LF): $totalLF');
    print('Total Lines Hit (LH): $totalLH');
    print('Total Project Coverage: ${coverage.toStringAsFixed(2)}%');
  }
}
