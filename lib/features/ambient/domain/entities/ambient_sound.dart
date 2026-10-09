/// Pure Dart domain entity representing an ambient soundscape preset.
/// Contains no Flutter framework dependencies and no serialization logic.
class AmbientSound {
  const AmbientSound({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmbientSound &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
