import 'package:flutter/material.dart';

import 'appearance_page.dart';
import 'backup_page.dart';
import 'build_info.dart';
import 'lock_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('ظاهر اپ'),
            subtitle: const Text('پالت رنگ و حالت روشن یا تیره'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => open(const AppearancePage()),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('قفل اپ'),
            subtitle: const Text('رمز و اثر انگشت'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => open(const LockSettingsPage()),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('پشتیبان‌گیری و بازیابی'),
            subtitle: const Text('ذخیره اطلاعات در فایل'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => open(const BackupPage()),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'کاسب‌باشی  •  شماره ساخت: $kBuild',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
