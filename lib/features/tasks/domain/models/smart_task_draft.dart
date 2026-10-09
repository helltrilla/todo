class SmartTaskDraft {
  const SmartTaskDraft({
    required this.name,
    this.description = '',
    this.dueDate,
    this.reminderOffsetMinutes,
    this.priorityIndex = -1,
    this.category,
    this.subtasks = const [],
    this.source = 'ai',
  });

  final String name;
  final String description;
  final DateTime? dueDate;
  final int? reminderOffsetMinutes;
  final int priorityIndex; // -1 = default, 0 = P1 Urgent, 1 = P2 High, 2 = P3 Medium, 3 = P4 Low
  final String? category;
  final List<String> subtasks;
  final String source; // 'gemini' or 'local_nlp'

  SmartTaskDraft copyWith({
    String? name,
    String? description,
    DateTime? dueDate,
    int? reminderOffsetMinutes,
    int? priorityIndex,
    String? category,
    List<String>? subtasks,
    String? source,
  }) {
    return SmartTaskDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderOffsetMinutes:
          reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'reminderOffsetMinutes': reminderOffsetMinutes,
    'priorityIndex': priorityIndex,
    'category': category,
    'subtasks': subtasks,
    'source': source,
  };

  factory SmartTaskDraft.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['dueDate'] != null) {
      parsedDate = DateTime.tryParse(json['dueDate'].toString());
    } else if (json['dueDateIso'] != null) {
      parsedDate = DateTime.tryParse(json['dueDateIso'].toString());
    }

    final subtasksRaw = json['subtasks'];
    List<String> parsedSubtasks = [];
    if (subtasksRaw is List) {
      parsedSubtasks = subtasksRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return SmartTaskDraft(
      name: (json['name'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      dueDate: parsedDate,
      reminderOffsetMinutes: (json['reminderOffsetMinutes'] as num?)?.toInt(),
      priorityIndex: (json['priorityIndex'] as num?)?.toInt() ?? -1,
      category: json['category'] as String?,
      subtasks: parsedSubtasks,
      source: (json['source'] as String?) ?? 'ai',
    );
  }
}
