import 'package:fluent_ui/fluent_ui.dart';

class WriterToolbar extends StatelessWidget {
  const WriterToolbar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onStrikethrough,
    required this.onColor,
    required this.onFontSize,
    required this.onAlignment,
    required this.onIndent,
    required this.onList,
    required this.onImage,
    required this.onLink,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.onStyleToggle,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onStrikethrough;
  final VoidCallback onColor;
  final VoidCallback onFontSize;
  final ValueChanged<String> onAlignment;
  final ValueChanged<int> onIndent;
  final ValueChanged<String> onList;
  final VoidCallback onImage;
  final VoidCallback onLink;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<String> onStyleToggle;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.resources.dividerStrokeColorDefault,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            // Undo/Redo Group
            _buildAction(
              icon: FluentIcons.undo,
              onPressed: canUndo ? onUndo : null,
              tooltip: 'Desfazer (Ctrl+Z)',
            ),
            _buildAction(
              icon: FluentIcons.redo,
              onPressed: canRedo ? onRedo : null,
              tooltip: 'Refazer (Ctrl+Y)',
            ),
            _buildDivider(theme),

            // Style Group (H1, H2, H3, Body)
            Tooltip(
              message: 'Estilo do Texto',
              child: DropDownButton(
                leading: const Icon(FluentIcons.text_field, size: 14),
                title: const Text('Texto normal', style: TextStyle(fontSize: 12)),
                items: [
                  MenuFlyoutItem(text: const Text('Texto normal'), onPressed: () => onStyleToggle('normal')),
                  MenuFlyoutItem(text: const Text('Título 1'), onPressed: () => onStyleToggle('h1')),
                  MenuFlyoutItem(text: const Text('Título 2'), onPressed: () => onStyleToggle('h2')),
                  MenuFlyoutItem(text: const Text('Título 3'), onPressed: () => onStyleToggle('h3')),
                ],
              ),
            ),
            _buildDivider(theme),

            // Formatting Group
            _buildAction(
              icon: FluentIcons.bold,
              onPressed: onBold,
              tooltip: 'Negrito (Ctrl+B)',
            ),
            _buildAction(
              icon: FluentIcons.italic,
              onPressed: onItalic,
              tooltip: 'Itálico (Ctrl+I)',
            ),
            _buildAction(
              icon: FluentIcons.underline,
              onPressed: onUnderline,
              tooltip: 'Sublinhado (Ctrl+U)',
            ),
            _buildAction(
              icon: FluentIcons.strikethrough,
              onPressed: onStrikethrough,
              tooltip: 'Tachado',
            ),
            _buildAction(
              icon: FluentIcons.font_color,
              onPressed: onColor,
              tooltip: 'Cor do Texto',
            ),
            _buildDivider(theme),

            // Link & Image
            _buildAction(
              icon: FluentIcons.link,
              onPressed: onLink,
              tooltip: 'Inserir Link',
            ),
            _buildAction(
              icon: FluentIcons.photo2,
              onPressed: onImage,
              tooltip: 'Inserir Imagem',
            ),
            _buildDivider(theme),

            // Alignment Group
            _buildAction(
              icon: FluentIcons.align_left,
              onPressed: () => onAlignment('left'),
              tooltip: 'Alinhar à Esquerda',
            ),
            _buildAction(
              icon: FluentIcons.align_center,
              onPressed: () => onAlignment('center'),
              tooltip: 'Centralizar',
            ),
            _buildAction(
              icon: FluentIcons.align_right,
              onPressed: () => onAlignment('right'),
              tooltip: 'Alinhar à Direita',
            ),
            _buildDivider(theme),

            // Lists Group
            _buildAction(
              icon: FluentIcons.bulleted_list,
              onPressed: () => onList('unordered'),
              tooltip: 'Lista com Marcadores',
            ),
            _buildAction(
              icon: FluentIcons.numbered_list,
              onPressed: () => onList('ordered'),
              tooltip: 'Lista Numerada',
            ),
            _buildAction(
              icon: FluentIcons.check_list,
              onPressed: () => onList('checklist'),
              tooltip: 'Lista de Verificação',
            ),
            _buildDivider(theme),

            // Indent Group
            _buildAction(
              icon: FluentIcons.decrease_indent,
              onPressed: () => onIndent(-1),
              tooltip: 'Diminuir Recuo',
            ),
            _buildAction(
              icon: FluentIcons.increase_indent,
              onPressed: () => onIndent(1),
              tooltip: 'Aumentar Recuo',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: IconButton(
          icon: Icon(icon, size: 14),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildDivider(FluentThemeData theme) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: 24,
        child: Divider(
          direction: Axis.vertical,
        ),
      ),
    );
  }
}
