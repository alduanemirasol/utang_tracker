import 'package:equatable/equatable.dart';

enum BackupConnectionStatus { signedIn, signedOut, expired }

class BackupConnectionDetails extends Equatable {
  const BackupConnectionDetails({required this.status, this.email});

  final BackupConnectionStatus status;
  final String? email;

  @override
  List<Object?> get props => [status, email];
}
