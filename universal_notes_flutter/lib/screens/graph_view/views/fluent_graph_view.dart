import 'package:fluent_ui/fluent_ui.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// Fluent UI view for GraphView - WinUI 3 styling
class FluentGraphView extends StatelessWidget {
  final List<Note> notes;
  final bool isLoading;
  final CustomPainter painter;

  const FluentGraphView({
    super.key,
    required this.notes,
    required this.isLoading,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: ProgressRing());
    }

    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Local Graph View'),
      ),
      content: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: CustomPaint(
          painter: painter,
          child: Container(),
        ),
      ),
    );
  }
}
