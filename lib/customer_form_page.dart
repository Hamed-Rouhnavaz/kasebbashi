import 'package:flutter/material.dart';

import 'customer.dart';
import 'db.dart';

class CustomerFormPage extends StatefulWidget {
  final Customer? customer;
  const CustomerFormPage({super.key, this.customer});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _instagram;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c?.name ?? '');
    _instagram = TextEditingController(text: c?.instagram ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _address = TextEditingController(text: c?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _instagram.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    var insta = _instagram.text.trim();
    if (insta.startsWith('@')) insta = insta.substring(1);
    final customer = Customer(
      id: widget.customer?.id,
      name: _name.text.trim(),
      instagram: insta,
      phone: _phone.text.trim(),
      address: _address.text.trim(),
    );
    await AppDatabase.instance.saveCustomer(customer);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف مشتری'),
        content: Text('«${widget.customer!.name}» حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppDatabase.instance.deleteCustomer(widget.customer!.id!);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.customer != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'ویرایش مشتری' : 'مشتری جدید'),
        actions: [
          if (editing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'حذف مشتری',
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'نام مشتری',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'نام را وارد کنید' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instagram,
              decoration: const InputDecoration(
                labelText: 'آیدی اینستاگرام (اختیاری)',
                hintText: 'مثلاً ali_shop',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'شماره تماس (اختیاری)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'آدرس (اختیاری)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('ذخیره')),
          ],
        ),
      ),
    );
  }
}
