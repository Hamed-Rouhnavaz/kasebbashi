import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'backup.dart';
import 'db.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final db = await AppDatabase.instance.database;
    final counts = <String, int>{};
    for (final t in ['products', 'customers', 'sales']) {
      counts[t] =
          Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $t')) ??
              0;
    }
    if (!mounted) return;
    setState(() => _counts = counts);
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await BackupService.exportAndShare();
    } catch (e) {
      if (mounted) _msg('ساخت پشتیبان انجام نشد: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final data = await BackupService.pickBackup();
      if (data == null || !mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('بازیابی اطلاعات'),
          content: Text(
            'این فایل شامل ${data.count('products')} محصول، '
            '${data.count('customers')} مشتری و ${data.count('sales')} فروش است.\n\n'
            'با بازیابی، همه اطلاعات فعلی اپ پاک می‌شود و با اطلاعات این فایل '
            'جایگزین می‌شود. ادامه می‌دهید؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('بازیابی'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await BackupService.restore(data);
      await _loadCounts();
      if (mounted) _msg('اطلاعات با موفقیت بازیابی شد');
    } on FormatException catch (e) {
      if (mounted) _msg(e.message);
    } catch (_) {
      if (mounted) _msg('فایل انتخاب‌شده معتبر نیست یا خوانده نشد');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پشتیبان‌گیری')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('اطلاعات فعلی اپ'),
              subtitle: Text(
                '${_counts['products'] ?? 0} محصول  |  '
                '${_counts['customers'] ?? 0} مشتری  |  '
                '${_counts['sales'] ?? 0} فروش',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'اطلاعات اپ فقط روی همین گوشی ذخیره می‌شود. اگر گوشی گم یا خراب '
            'شود یا اپ را پاک کنید، همه چیز از بین می‌رود. پس مرتب پشتیبان '
            'بگیرید.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.upload_file),
            label: const Text('گرفتن پشتیبان و ارسال'),
          ),
          const SizedBox(height: 8),
          const Text(
            'بعد از زدن دکمه، پنجره اشتراک‌گذاری باز می‌شود. فایل را در '
            '«پیام‌های ذخیره‌شده» تلگرام، ایمیل خودتان یا Google Drive '
            'ذخیره کنید، نه فقط روی همین گوشی.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.download),
            label: const Text('بازیابی از فایل پشتیبان'),
          ),
          const SizedBox(height: 8),
          const Text(
            'هشدار: بازیابی همه اطلاعات فعلی را با اطلاعات فایل جایگزین می‌کند.',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 24),
          const Text(
            'فایل پشتیبان شامل اطلاعات مشتری‌های شماست. آن را فقط در جای '
            'امن نگه دارید.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
