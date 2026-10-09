import 'package:todo/features/ambient/domain/entities/ambient_sound.dart';

/// Data layer model extending [AmbientSound] with JSON serialization capabilities.
class AmbientSoundModel extends AmbientSound {
  const AmbientSoundModel({
    required super.id,
    required super.title,
    required super.description,
    required super.iconKey,
  });

  factory AmbientSoundModel.fromJson(Map<String, dynamic> json) {
    return AmbientSoundModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconKey': iconKey,
    };
  }

  factory AmbientSoundModel.fromEntity(AmbientSound entity) {
    return AmbientSoundModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      iconKey: entity.iconKey,
    );
  }
}
