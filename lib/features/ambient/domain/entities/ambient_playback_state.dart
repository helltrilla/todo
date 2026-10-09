/// Pure Dart domain entity representing the current state of ambient audio playback.
class AmbientPlaybackState {
  const AmbientPlaybackState({
    required this.soundId,
    required this.isPlaying,
    required this.volume,
  });

  final String soundId;
  final bool isPlaying;
  final double volume;

  AmbientPlaybackState copyWith({
    String? soundId,
    bool? isPlaying,
    double? volume,
  }) {
    return AmbientPlaybackState(
      soundId: soundId ?? this.soundId,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmbientPlaybackState &&
          runtimeType == other.runtimeType &&
          soundId == other.soundId &&
          isPlaying == other.isPlaying &&
          volume == other.volume;

  @override
  int get hashCode => Object.hash(soundId, isPlaying, volume);
}
