import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStore {
  static late Directory _dir;

  static Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory(p.join(base.path, 'product_images'));
    if (!await _dir.exists()) await _dir.create(recursive: true);
  }

  static File fileSync(String name) => File(p.join(_dir.path, p.basename(name)));

  /// عکس را از گالری یا دوربین می‌گیرد، کوچک می‌کند و در حافظه اپ ذخیره می‌کند.
  /// اسم فایل را برمی‌گرداند (یا null اگر کاربر انصراف داد).
  static Future<String?> pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 720,
      imageQuality: 70,
    );
    if (picked == null) return null;
    final name = 'img_${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(picked.path).copy(fileSync(name).path);
    return name;
  }

  static Future<void> delete(String? name) async {
    if (name == null || name.isEmpty) return;
    final f = fileSync(name);
    if (await f.exists()) await f.delete();
  }

  static Future<String?> readBase64(String name) async {
    final f = fileSync(name);
    if (!await f.exists()) return null;
    return base64Encode(await f.readAsBytes());
  }

  static Future<void> writeBase64(String name, String data) async {
    await fileSync(name).writeAsBytes(base64Decode(data), flush: true);
  }

  static Future<void> clearAll() async {
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
      return;
    }
    await for (final e in _dir.list()) {
      if (e is File) await e.delete();
    }
  }
}
