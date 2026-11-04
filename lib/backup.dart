import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' show openFile;
import 'package:share_plus/share_plus.dart';

import 'dates.dart';
import 'db.dart';
import 'images.dart';

const _tables = ['products', 'customers', 'sales', 'sale_items'];
const _backupFormat = 1;

class BackupData {
  final Map<String, List<Map<String, Object?>>> tables;
  final Map<String, String> images;
  const BackupData(this.tables, [this.images = const {}]);

  int count(String table) => tables[table]?.length ?? 0;
}

class BackupService {
  /// همه اطلاعات (و عکس‌ها) را به متن JSON تبدیل می‌کند
  static Future<String> buildJson() async {
    final db = await AppDatabase.instance.database;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final t in _tables) {
      tables[t] = await db.query(t);
    }
    final images = <String, String>{};
    for (final row in tables['products']!) {
      final name = (row['image'] as String?) ?? '';
      if (name.isEmpty) continue;
      final b64 = await ImageStore.readBase64(name);
      if (b64 != null) images[name] = b64;
    }
    final data = <String, Object?>{
      'app': 'kasebbashi',
      'format': _backupFormat,
      'created_at': DateTime.now().toIso8601String(),
      ...tables,
      'images': images,
    };
    return const JsonEncoder.withIndent(' ').convert(data);
  }

  /// فایل پشتیبان می‌سازد و پنجره اشتراک‌گذاری را باز می‌کند
  static Future<void> exportAndShare() async {
    final json = await buildJson();
    final name = 'kasebbashi-backup-${fileStamp(DateTime.now())}.json';
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(json)),
            mimeType: 'application/json',
          ),
        ],
        fileNameOverrides: [name],
        subject: 'پشتیبان کاسب‌باشی',
      ),
    );
  }

  /// کاربر فایل را انتخاب می‌کند؛ اگر انصراف دهد null برمی‌گردد
  static Future<BackupData?> pickBackup() async {
    final file = await openFile();
    if (file == null) return null;
    final text = await file.readAsString();
    return parse(text);
  }

  static BackupData parse(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map || decoded['app'] != 'kasebbashi') {
      throw const FormatException('این فایل، پشتیبان کاسب‌باشی نیست');
    }
    if (decoded['format'] != _backupFormat) {
      throw const FormatException('نسخه این فایل پشتیبان پشتیبانی نمی‌شود');
    }
    final tables = <String, List<Map<String, Object?>>>{};
    for (final t in _tables) {
      final raw = decoded[t];
      if (raw is! List) {
        throw const FormatException('فایل پشتیبان ناقص است');
      }
      tables[t] = [
        for (final r in raw) Map<String, Object?>.from(r as Map),
      ];
    }
    final images = <String, String>{};
    final rawImages = decoded['images'];
    if (rawImages is Map) {
      rawImages.forEach((k, v) {
        if (k is String && v is String) images[k] = v;
      });
    }
    return BackupData(tables, images);
  }

  /// همه اطلاعات فعلی را پاک و با پشتیبان جایگزین می‌کند.
  /// اگر مشکلی پیش بیاید، تراکنش لغو می‌شود و اطلاعات فعلی سالم می‌ماند.
  static Future<void> restore(BackupData data) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      for (final t in _tables) {
        await txn.delete(t);
      }
      for (final t in _tables) {
        for (final row in data.tables[t]!) {
          await txn.insert(t, row);
        }
      }
    });
    await ImageStore.clearAll();
    for (final e in data.images.entries) {
      try {
        await ImageStore.writeBase64(e.key, e.value);
      } catch (_) {
        // عکس خراب را رد می‌کنیم
      }
    }
  }
}
