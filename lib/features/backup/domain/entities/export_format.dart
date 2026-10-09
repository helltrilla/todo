/// Pure Dart domain enum representing supported export file formats.
enum ExportFormat {
  json('json', 'JSON (Полный бэкап)', 'application/json', '.json'),
  csv('csv', 'CSV Таблица (Excel / Numbers)', 'text/csv', '.csv'),
  markdown(
    'markdown',
    'Markdown Документ (Notion / Obsidian)',
    'text/markdown',
    '.md',
  );

  const ExportFormat(this.id, this.label, this.mimeType, this.extension);

  final String id;
  final String label;
  final String mimeType;
  final String extension;
}
