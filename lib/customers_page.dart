import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'customer.dart';
import 'customer_form_page.dart';
import 'customer_stats.dart';
import 'db.dart';
import 'format.dart';
import 'search_box.dart';
import 'text_utils.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Customer> _customers = [];
  Map<int, CustomerStat> _stats = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getCustomers();
    final stats = await AppDatabase.instance.customerStats();
    if (!mounted) return;
    setState(() {
      _customers = items;
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _openForm([Customer? customer]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerFormPage(customer: customer)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = normalizeText(_query);
    final visible = _customers.where((c) {
      if (q.isEmpty) return true;
      return normalizeText('${c.name} ${c.instagram} ${c.phone}').contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشتری‌ها'),
        actions: [
          if (_customers.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Text(
                  '${_customers.length} مشتری',
                  style: TextStyle(fontSize: 13, color: scheme.outline),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('مشتری جدید'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: scheme.outline),
                        const SizedBox(height: 16),
                        const Text(
                          'هنوز مشتری‌ای ثبت نکرده‌اید',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'با دکمه پایین اولین مشتری‌تان را اضافه کنید. '
                          'می‌توانید هنگام ثبت فروش هم مشتری جدید بسازید.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.outline),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    SearchBox(
                      hint: 'جست‌وجوی نام، آیدی یا شماره',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('مشتری‌ای پیدا نشد'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              itemCount: visible.length,
                              itemBuilder: (context, i) => _CustomerCard(
                                customer: visible[i],
                                stat: _stats[visible[i].id],
                                onTap: () => _openForm(visible[i]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final CustomerStat? stat;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.stat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = customer;
    final initial = c.name.trim().isEmpty
        ? '؟'
        : String.fromCharCode(c.name.trim().runes.first);
    final hasContact = c.instagram.isNotEmpty || c.phone.isNotEmpty;
    final debt = stat?.debt ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hasContact) ...[
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (c.instagram.isNotEmpty)
                            _IconText(Icons.alternate_email, c.instagram),
                          if (c.phone.isNotEmpty)
                            _IconText(Icons.phone_outlined, c.phone),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (stat == null)
                          _Pill('هنوز خریدی نداشته', scheme.outline)
                        else ...[
                          _Pill('${stat!.count} خرید', scheme.secondary),
                          _Pill('جمع: ${toman(stat!.total)}', scheme.primary),
                        ],
                        if (debt > 0)
                          _Pill('مانده: ${toman(debt)}', AppColors.wine),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconText(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
