import 'package:flutter/material.dart';

import 'backup_page.dart';
import 'lock_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('قفل اپ'),
            subtitle: const Text('رمز و اثر انگشت'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LockSettingsPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('پشتیبان‌گیری و بازیابی'),
            subtitle: const Text('ذخیره اطلاعات در فایل'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupPage()),
            ),
          ),
        ],
      ),
    );
  }
}
