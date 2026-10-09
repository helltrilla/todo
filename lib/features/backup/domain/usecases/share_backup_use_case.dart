import 'package:todo/core/errors/result.dart';
import 'package:todo/features/backup/domain/entities/export_result.dart';
import 'package:todo/features/backup/domain/repositories/i_backup_repository.dart';

/// Atomic use case that shares an exported backup artifact via the native system share sheet.
class ShareBackupUseCase {
  const ShareBackupUseCase(this._repository);

  final IBackupRepository _repository;

  Future<Result<void>> call(ExportResult exportResult) {
    return _repository.shareExport(exportResult);
  }
}
