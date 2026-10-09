import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackupNativeException implements Exception {
  const BackupNativeException(this.message);
  final String message;

  @override
  String toString() => 'BackupNativeException: $message';
}

/// Native datasource interfacing with iOS UIActivityViewController and Android share sheets.
class BackupNativeDataSource {
  const BackupNativeDataSource({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('com.helltrilla.todoapp/notifications');

  final MethodChannel _channel;

  Future<void> shareFile({
    required String fileName,
    required String content,
    required String mimeType,
  }) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('shareFile', <String, dynamic>{
        'fileName': fileName,
        'content': content,
        'mimeType': mimeType,
      });
    } on PlatformException catch (e) {
      throw BackupNativeException(e.message ?? 'Ошибка экспорта файла');
    } catch (e) {
      throw BackupNativeException('Не удалось поделиться файлом: $e');
    }
  }
}
