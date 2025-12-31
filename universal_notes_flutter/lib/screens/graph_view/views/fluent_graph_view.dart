import 'package:fluent_ui/fluent_ui.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// Fluent UI view for GraphView - WinUI 3 styling
/// Fluent UI view for GraphView - WinUI 3 styling
class FluentGraphView extends StatelessWidget {
  /// Creates a [FluentGraphView].
  const FluentGraphView({
    required this.notes,
    required this.isLoading,
    required this.painter,
    super.key,
  });

  /// The list of notes to display.
  final List<Note> notes;
  /// Whether the app is currently loading.
  final bool isLoading;
  /// The custom painter for the graph.
  final CustomPainter painter;

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
