import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';

void main() {
  final mockPackageInfo = PackageInfo(
    appName: 'Universal Notes',
    version: '1.0.0',
    buildNumber: '1',
    packageName: 'com.example.universal_notes',
  );

  group('AboutScreen General Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('AboutScreen renders correctly in light and dark themes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);
    });

    testWidgets('AboutScreen displays social media links if they exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );
      await tester.pumpAndSettle();

      final githubIcon = find.byIcon(Icons.code);
      final twitterIcon = find.byIcon(Icons.alternate_email);

      expect(githubIcon, findsNothing);
      expect(twitterIcon, findsNothing);
    });

    testWidgets('AboutScreen handles long press actions without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Versão atual: 1.0.0'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });

  group('AboutScreen Platform and Accessibility Tests', () {
    testWidgets('AboutScreen displays Material Design on Android',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('AboutScreen has correct accessibility label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );
      await tester.pumpAndSettle();

      final semanticsWidgets = find.byType(Semantics);
      expect(semanticsWidgets, findsWidgets);

      var foundCorrectLabel = false;
      for (final element in semanticsWidgets.evaluate()) {
        final semantics = element.widget as Semantics;
        if (semantics.properties.label == 'About Universal Notes') {
          foundCorrectLabel = true;
          break;
        }
      }

      expect(
        foundCorrectLabel,
        isTrue,
        reason:
            'Nenhum widget Semantics com rótulo "About Universal Notes" foi encontrado',
      );
    });
  });

  group('AboutScreen Integration Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('AboutScreen can be navigated to', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Home')),
                  body: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () async {
                        final packageInfo = await PackageInfo.fromPlatform();
                        if (!context.mounted) return;
                        await Navigator.pushNamed(
                          context,
                          '/about',
                          arguments: packageInfo,
                        );
                      },
                      child: const Text('Go to About'),
                    ),
                  ),
                ),
            '/about': (context) {
              final packageInfo =
                  ModalRoute.of(context)!.settings.arguments as PackageInfo;
              return AboutScreen(packageInfo: packageInfo);
            },
          },
        ),
      );

      await tester.tap(find.text('Go to About'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });
}
