import 'package:todo/core/errors/failures.dart';
import 'package:todo/core/errors/result.dart';
import 'package:todo/features/tasks/data/datasources/playlist_metadata_remote_data_source.dart';
import 'package:todo/features/tasks/domain/entities/playlist_metadata.dart';

/// UseCase responsible for resolving title, author, and cover art for a playlist URL.
class GetPlaylistMetadataUseCase {
  final IPlaylistMetadataRemoteDataSource _dataSource;

  const GetPlaylistMetadataUseCase(this._dataSource);

  Future<Result<PlaylistMetadata>> call(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return const Error(ServerFailure('URL не может быть пустым'));
    }
    return _dataSource.fetchMetadata(trimmed);
  }
}
