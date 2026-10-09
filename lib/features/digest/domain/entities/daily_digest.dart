/// Immutable domain entity representing a generated AI Daily Digest.
class DailyDigest {
  final String headline;
  final String topFocus;
  final String productivitySlot;
  final String summary;
  final DateTime generatedAt;
  final bool isFallback;

  const DailyDigest({
    required this.headline,
    required this.topFocus,
    required this.productivitySlot,
    required this.summary,
    required this.generatedAt,
    this.isFallback = false,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'headline': headline,
      'topFocus': topFocus,
      'productivitySlot': productivitySlot,
      'summary': summary,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
      'isFallback': isFallback,
    };
  }

  factory DailyDigest.fromMap(Map<String, dynamic> map) {
    return DailyDigest(
      headline: (map['headline'] as String?) ?? 'Утренний бриф',
      topFocus: (map['topFocus'] as String?) ?? 'Фокус не определен',
      productivitySlot: (map['productivitySlot'] as String?) ?? 'Утро',
      summary: (map['summary'] as String?) ?? '',
      generatedAt: map['generatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['generatedAt'] as int)
          : DateTime.now(),
      isFallback: (map['isFallback'] as bool?) ?? false,
    );
  }

  DailyDigest copyWith({
    String? headline,
    String? topFocus,
    String? productivitySlot,
    String? summary,
    DateTime? generatedAt,
    bool? isFallback,
  }) {
    return DailyDigest(
      headline: headline ?? this.headline,
      topFocus: topFocus ?? this.topFocus,
      productivitySlot: productivitySlot ?? this.productivitySlot,
      summary: summary ?? this.summary,
      generatedAt: generatedAt ?? this.generatedAt,
      isFallback: isFallback ?? this.isFallback,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyDigest &&
          other.headline == headline &&
          other.topFocus == topFocus &&
          other.productivitySlot == productivitySlot &&
          other.summary == summary &&
          other.generatedAt == generatedAt &&
          other.isFallback == isFallback);

  @override
  int get hashCode => Object.hash(
        headline,
        topFocus,
        productivitySlot,
        summary,
        generatedAt,
        isFallback,
      );
}
