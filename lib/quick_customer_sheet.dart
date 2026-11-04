import 'package:flutter/material.dart';

import 'customer.dart';
import 'db.dart';

extension CustomerInsert on AppDatabase {
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert('customers', customer.toMap());
  }
}

/// فرم سریع افزودن مشتری.
/// اگر ذخیره شود، شناسه مشتری جدید را برمی‌گرداند؛ اگر انصراف دهد null.
Future<int?> showQuickCustomerSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _QuickCustomerForm(),
  );
}

class _QuickCustomerForm extends StatefulWidget {
  const _QuickCustomerForm();

  @override
  State<_QuickCustomerForm> createState() => _QuickCustomerFormState();
}

class _QuickCustomerFormState extends State<_QuickCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _instagram = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _instagram.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    var insta = _instagram.text.trim();
    if (insta.startsWith('@')) insta = insta.substring(1);
    final id = await AppDatabase.instance.insertCustomer(
      Customer(
        name: _name.text.trim(),
        instagram: insta,
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('مشتری جدید',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'نام مشتری'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'نام را وارد کنید'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instagram,
                  decoration: const InputDecoration(
                    labelText: 'آیدی اینستاگرام (اختیاری)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'شماره تماس (اختیاری)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'آدرس (اختیاری)',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('ذخیره و انتخاب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
