import 'dart:io';

class DriveException implements Exception {
  const DriveException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}

class DriveErrorMapper {
  DriveErrorMapper._();

  static DriveException fromError(Object error) {
    final message = error.toString().toLowerCase();

    if (error is SocketException ||
        message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('no internet') ||
        message.contains('network is unreachable') ||
        message.contains('connection failed')) {
      return DriveException(
        'No internet connection. Please check your network and try again.',
        cause: error,
      );
    }

    if (message.contains('quotaexceeded') ||
        message.contains('storage quota') ||
        message.contains('storagequotaexceeded')) {
      return DriveException(
        'Google Drive storage quota exceeded.',
        statusCode: 403,
        cause: error,
      );
    }

    // Try to extract HTTP status code from message.
    final statusCode = _extractStatusCode(message);
    if (statusCode == 401 || statusCode == 403) {
      if (statusCode == 401) {
        return DriveException(
          'Google Drive authentication expired. Please sign in again.',
          statusCode: statusCode,
          cause: error,
        );
      }
      return DriveException(
        'Access denied to Google Drive. Please sign in again.',
        statusCode: statusCode,
        cause: error,
      );
    }

    if (message.contains('401') || message.contains('unauthenticated')) {
      return DriveException(
        'Google Drive authentication expired. Please sign in again.',
        statusCode: 401,
        cause: error,
      );
    }
    if (message.contains('403') || message.contains('forbidden')) {
      return DriveException(
        'Access denied to Google Drive. Please sign in again.',
        statusCode: 403,
        cause: error,
      );
    }

    if (error is DriveException) return error;

    return DriveException(messageForUnknown(error), cause: error);
  }

  static String messageForUnknown(Object error) =>
      'Google Drive operation failed: $error';

  static int? _extractStatusCode(String message) {
    final regex = RegExp(r'\b(401|403|404|429|500|503)\b');
    final match = regex.firstMatch(message);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }
}
