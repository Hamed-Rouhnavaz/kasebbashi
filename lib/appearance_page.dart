import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'theme_controller.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final titleStyle = Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700);
        return Scaffold(
          appBar: AppBar(title: const Text('ظاهر اپ')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('پالت رنگ', style: titleStyle),
              const SizedBox(height: 12),
              for (final p in AppPalette.values)
                _PaletteCard(
                  palette: p,
                  selected: controller.palette == p,
                  onTap: () => controller.setPalette(p),
                ),
              const SizedBox(height: 16),
              Text('حالت نمایش', style: titleStyle),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('روشن'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('تیره'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('خودکار'),
                    icon: Icon(Icons.brightness_auto_outlined),
                  ),
                ],
                selected: {controller.mode},
                onSelectionChanged: (s) => controller.setMode(s.first),
              ),
              const SizedBox(height: 8),
              const Text(
                '«خودکار» از تنظیم روشن یا تیره بودن گوشی شما پیروی می‌کند.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaletteCard extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteCard({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.secondary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [palette.heroTop, palette.heroBottom],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: palette.heroAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palette.description,
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: scheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
