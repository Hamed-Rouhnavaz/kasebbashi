import 'package:flutter/material.dart';

import 'app_lock.dart';
import 'pin_flow_page.dart';

class LockSettingsPage extends StatefulWidget {
  const LockSettingsPage({super.key});

  @override
  State<LockSettingsPage> createState() => _LockSettingsPageState();
}

class _LockSettingsPageState extends State<LockSettingsPage> {
  final _lock = AppLock.instance;
  bool _canBio = false;

  static const _delays = {10: '۱۰ ثانیه', 60: '۱ دقیقه', 300: '۵ دقیقه'};

  @override
  void initState() {
    super.initState();
    _lock.enabled.addListener(_refresh);
    _checkBio();
  }

  @override
  void dispose() {
    _lock.enabled.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _checkBio() async {
    final ok = await _lock.canUseBiometric();
    if (mounted) setState(() => _canBio = ok);
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _verifyCurrent() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const PinFlowPage(mode: PinMode.verify, title: 'تأیید رمز'),
      ),
    );
    return ok == true;
  }

  Future<void> _createPin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const PinFlowPage(mode: PinMode.create, title: 'تنظیم رمز'),
      ),
    );
    if (ok == true && mounted) _msg('رمز ذخیره شد');
  }

  Future<void> _toggle(bool on) async {
    if (on) {
      await _createPin();
    } else if (await _verifyCurrent()) {
      await _lock.disable();
      if (mounted) _msg('قفل اپ غیرفعال شد');
    }
    if (mounted) setState(() {});
  }

  Future<void> _changePin() async {
    if (await _verifyCurrent()) await _createPin();
  }

  Future<void> _toggleBio(bool on) async {
    if (on) {
      final ok = await _lock.authenticateBiometric();
      if (!ok) {
        if (mounted) _msg('تأیید انجام نشد');
        return;
      }
    }
    await _lock.setBiometric(on);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _lock.enabled.value;
    return Scaffold(
      appBar: AppBar(title: const Text('قفل اپ')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('قفل اپ با رمز ۴ رقمی'),
            subtitle: Text(enabled ? 'فعال است' : 'غیرفعال است'),
            value: enabled,
            onChanged: _toggle,
          ),
          if (enabled) ...[
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('تغییر رمز'),
              onTap: _changePin,
            ),
            if (_canBio)
              SwitchListTile(
                title: const Text('ورود با اثر انگشت یا چهره'),
                value: _lock.biometric,
                onChanged: _toggleBio,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'قفل شدن بعد از خروج از اپ برای:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final e in _delays.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _lock.delaySeconds == e.key,
                      onSelected: (_) async {
                        await _lock.setDelay(e.key);
                        if (mounted) setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'این قفل جلوی دیده‌شدن اطلاعات توسط دیگران را می‌گیرد. اگر رمز را '
              'فراموش کنید راه بازیابی ندارد و فقط با پاک‌کردن اطلاعات اپ '
              'می‌توانید دوباره وارد شوید. پس مرتب پشتیبان بگیرید.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
