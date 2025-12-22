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
  var totalLF = 0;
  var totalLH = 0;

  for (final line in lines) {
    if (line.startsWith('LF:')) {
      totalLF += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      totalLH += int.parse(line.substring(3));
    }
  }

  if (totalLF == 0) {
    print('No lines found in coverage report.');
  } else {
    final coverage = (totalLH / totalLF) * 100;
    print('Total Lines Found (LF): $totalLF');
    print('Total Lines Hit (LH): $totalLH');
    print('Total Project Coverage: ${coverage.toStringAsFixed(2)}%');
  }
}
