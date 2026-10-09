/// Pure Dart domain entity representing speech recognition result.
/// Contains no Flutter framework dependencies and no serialization logic.
class SpeechRecognitionResult {
  const SpeechRecognitionResult({
    required this.recognizedWords,
    this.confidence = 0.0,
    this.isFinal = false,
    this.soundLevelDb = 0.0,
  });

  final String recognizedWords;
  final double confidence; // 0.0 .. 1.0
  final bool isFinal;
  final double soundLevelDb;

  SpeechRecognitionResult copyWith({
    String? recognizedWords,
    double? confidence,
    bool? isFinal,
    double? soundLevelDb,
  }) {
    return SpeechRecognitionResult(
      recognizedWords: recognizedWords ?? this.recognizedWords,
      confidence: confidence ?? this.confidence,
      isFinal: isFinal ?? this.isFinal,
      soundLevelDb: soundLevelDb ?? this.soundLevelDb,
    );
  }
}
