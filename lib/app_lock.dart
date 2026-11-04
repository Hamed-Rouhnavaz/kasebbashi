import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';

class AppLock {
  AppLock._();
  static final AppLock instance = AppLock._();

  final ValueNotifier<bool> enabled = ValueNotifier(false);
  bool biometric = false;
  int delaySeconds = 60;

  final LocalAuthentication _auth = LocalAuthentication();

  Future<Database> _db() async {
    final db = await AppDatabase.instance.database;
    await db.execute(
      'CREATE TABLE IF NOT EXISTS settings (name TEXT PRIMARY KEY, value TEXT)',
    );
    return db;
  }

  Future<String?> _get(String name) async {
    final db = await _db();
    final rows =
        await db.query('settings', where: 'name = ?', whereArgs: [name]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _set(String name, String value) async {
    final db = await _db();
    await db.insert(
      'settings',
      {'name': name, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _remove(String name) async {
    final db = await _db();
    await db.delete('settings', where: 'name = ?', whereArgs: [name]);
  }

  Future<void> load() async {
    enabled.value = (await _get('pin_hash')) != null;
    biometric = (await _get('biometric')) == '1';
    delaySeconds = int.tryParse(await _get('lock_delay') ?? '') ?? 60;
  }

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> setPin(String pin) async {
    final rnd = Random.secure();
    final salt =
        base64UrlEncode(List<int>.generate(16, (_) => rnd.nextInt(256)));
    await _set('pin_salt', salt);
    await _set('pin_hash', _hash(salt, pin));
    enabled.value = true;
  }

  Future<bool> verify(String pin) async {
    final salt = await _get('pin_salt');
    final hash = await _get('pin_hash');
    if (salt == null || hash == null) return false;
    return _hash(salt, pin) == hash;
  }

  Future<void> disable() async {
    await _remove('pin_salt');
    await _remove('pin_hash');
    await _remove('biometric');
    biometric = false;
    enabled.value = false;
  }

  Future<void> setBiometric(bool on) async {
    biometric = on;
    await _set('biometric', on ? '1' : '0');
  }

  Future<void> setDelay(int seconds) async {
    delaySeconds = seconds;
    await _set('lock_delay', '$seconds');
  }

  Future<bool> canUseBiometric() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'برای ورود به کاسب‌باشی هویت خود را تأیید کنید',
      );
    } catch (_) {
      return false;
    }
  }
}
