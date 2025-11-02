import '../models/note.dart';

final List<Note> sampleNotes = [
  Note(
    title: 'Minhas Informações',
    contentPreview: '...',
    date: DateTime(2022, 2, 9),
    isFavorite: true,
  ),
  Note(
    title: 'Nota escrita à mão 24/10',
    contentPreview: '...',
    date: DateTime.now().subtract(const Duration(days: 7)),
  ),
  Note(
    title: 'Enade aula 1',
    contentPreview: '...',
    date: DateTime.now().subtract(const Duration(days: 50)),
    isLocked: true,
  ),
  Note(
    title: 'Fabio Giambiagi - Macroeconomia...',
    contentPreview: 'Capa do livro',
    date: DateTime.now().subtract(const Duration(days: 70)),
  ),
  Note(
    title: 'Site de musicas',
    contentPreview: '...',
    date: DateTime.now().subtract(const Duration(days: 110)),
  ),
  Note(
    title: 'Controle comida cachorros',
    contentPreview: '...',
    date: DateTime.now().subtract(const Duration(days: 150)),
  ),
  Note(
    title: 'Inovação nas organizações',
    contentPreview: '...',
    date: DateTime.now().subtract(const Duration(days: 160)),
  ),
  Note(
    title: 'Custos da Qualidade',
    contentPreview: '...',
    date: DateTime.now().subtract(const Duration(days: 170)),
  ),
];
