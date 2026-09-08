import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_log_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_history_entry.dart';

class BackupLocalDatasource {
  BackupLocalDatasource({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  static const int maxEntries = 100;

  Future<SharedPreferences> _getPrefs() async => _prefs ?? await SharedPreferences.getInstance();

  Future<List<AuditLogEntry>> loadAuditLog() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(BackupPrefsKeys.auditLog);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((auditEntry) => AuditLogEntry.fromJson(auditEntry as Map<String, dynamic>)).toList();
  }

  Future<void> saveAuditLog(List<AuditLogEntry> entries) async {
    final prefs = await _getPrefs();
    final trimmed = entries.length > maxEntries ? entries.sublist(entries.length - maxEntries) : entries;
    final encoded = jsonEncode(trimmed.map((entry) => entry.toJson()).toList());
    await prefs.setString(BackupPrefsKeys.auditLog, encoded);
  }

  Future<void> appendAuditLog(AuditLogEntry entry) async {
    final current = await loadAuditLog();
    current.add(entry);
    await saveAuditLog(current);
  }

  Future<List<BackupHistoryEntry>> loadHistory() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(BackupPrefsKeys.history);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((historyEntry) => BackupHistoryEntry.fromJson(historyEntry as Map<String, dynamic>)).toList();
  }

  Future<void> saveHistory(List<BackupHistoryEntry> entries) async {
    final prefs = await _getPrefs();
    final trimmed = entries.length > maxEntries ? entries.sublist(entries.length - maxEntries) : entries;
    final encoded = jsonEncode(trimmed.map((entry) => entry.toJson()).toList());
    await prefs.setString(BackupPrefsKeys.history, encoded);
  }

  Future<void> appendHistory(BackupHistoryEntry entry) async {
    final current = await loadHistory();
    current.add(entry);
    await saveHistory(current);
  }

  Future<void> clearAuditLog() async {
    final prefs = await _getPrefs();
    await prefs.remove(BackupPrefsKeys.auditLog);
  }

  Future<void> clearHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(BackupPrefsKeys.history);
  }
}
