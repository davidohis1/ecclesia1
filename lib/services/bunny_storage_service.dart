import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';

class BunnyStorageService {
  final Dio _dio = Dio();

  String _buildUrl(String folder, String filename) {
    return '${AppConstants.bunnyStorageApiUrl}/${AppConstants.bunnyStorageZone}/$folder/$filename';
  }

  String getPublicUrl(String folder, String filename) {
    return '${AppConstants.bunnyBaseUrl}/$folder/$filename';
  }

  /// Upload a file to Bunny.net, returns the public CDN URL
  Future<String?> uploadFile({
    required File file,
    required String folder,
    required String filename,
    Function(double)? onProgress,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final uploadUrl = _buildUrl(folder, filename);

      await _dio.put(
        uploadUrl,
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: {
            'AccessKey': AppConstants.bunnyApiKey,
            'Content-Type': 'application/octet-stream',
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      return getPublicUrl(folder, filename);
    } catch (e) {
      print('Bunny upload error: $e');
      return null;
    }
  }

  /// Upload bytes directly (for profile pics etc.)
  Future<String?> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String filename,
    Function(double)? onProgress,
  }) async {
    try {
      final uploadUrl = _buildUrl(folder, filename);

      await _dio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'AccessKey': AppConstants.bunnyApiKey,
            'Content-Type': 'application/octet-stream',
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      return getPublicUrl(folder, filename);
    } catch (e) {
      print('Bunny upload bytes error: $e');
      return null;
    }
  }

  /// Delete a file
  Future<bool> deleteFile({
    required String folder,
    required String filename,
  }) async {
    try {
      final deleteUrl = _buildUrl(folder, filename);
      await _dio.delete(
        deleteUrl,
        options: Options(
          headers: {'AccessKey': AppConstants.bunnyApiKey},
        ),
      );
      return true;
    } catch (e) {
      print('Bunny delete error: $e');
      return false;
    }
  }

  /// Generate a unique filename with extension
  String generateFilename(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
  }
}
