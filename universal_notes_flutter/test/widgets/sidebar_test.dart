import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/widgets/sidebar.dart';

import 'sidebar_test.mocks.dart';

@GenerateMocks([SyncService, BackupService, NoteRepository])
void main() {
  late MockSyncService mockSyncService;
  late MockBackupService mockBackupService;
  late MockNoteRepository mockNoteRepository;
  late StreamController<List<Folder>> foldersController;
  late StreamController<List<String>> tagsController;

  setUp(() {
    mockSyncService = MockSyncService();
    mockBackupService = MockBackupService();
    mockNoteRepository = MockNoteRepository();

    SyncService.instance = mockSyncService;
    BackupService.instance = mockBackupService;
    NoteRepository.instance = mockNoteRepository;

    foldersController = StreamController<List<Folder>>.broadcast();
    tagsController = StreamController<List<String>>.broadcast();

    when(
      mockSyncService.foldersStream,
    ).thenAnswer((_) => foldersController.stream);
    when(mockSyncService.tagsStream).thenAnswer((_) => tagsController.stream);
  });

  tearDown(() {
    foldersController.close();
    tagsController.close();
  });

  Widget createWidgetUnderTest(
    void Function(SidebarSelection) onSelectionChanged,
  ) {
    return MaterialApp(
      home: Scaffold(
        drawer: Sidebar(onSelectionChanged: onSelectionChanged),
      ),
    );
  }

  group('Sidebar', () {
    testWidgets('renders basic items', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(createWidgetUnderTest((_) {}));

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('All Notes'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Trash'), findsOneWidget);
    });

    testWidgets('calls onSelectionChanged when favorites is tapped', (
      WidgetTester tester,
    ) async {
      SidebarSelection? selected;
      await tester.pumpWidget(createWidgetUnderTest((s) => selected = s));

      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(selected?.type, SidebarItemType.favorites);
    });

    testWidgets('displays folders from stream', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest((_) {}));
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      final folders = <Folder>[
        const Folder(id: '1', name: 'Work'),
      ];
      foldersController.add(folders);
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('displays tags from stream', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(createWidgetUnderTest((_) {}));
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      final tags = ['Flutter', 'Dart'];
      tagsController.add(tags);
      await tester.pumpAndSettle();

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
    });
  });
}
