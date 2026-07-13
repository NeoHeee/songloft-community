from pathlib import Path

path = Path("lib/features/home/presentation/home_page.dart")
text = path.read_text(encoding="utf-8")

import_anchor = "import 'package:cached_network_image/cached_network_image.dart';\n"
foundation_import = "import 'package:flutter/foundation.dart';\n"
if foundation_import not in text:
    if import_anchor not in text:
        raise SystemExit("cached_network_image import anchor not found")
    text = text.replace(import_anchor, import_anchor + foundation_import, 1)

start = text.index("class _DashboardHeader extends StatelessWidget")
end = text.index("class _GlowCircle extends StatelessWidget", start)
section = text[start:end]

old_flags = """    final isWide = context.isWideScreen;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
"""
new_flags = """    final isWide = context.isWideScreen;
    final useDesktopHeroLayout =
        context.screenWidth >= ResponsiveBreakpoints.desktop &&
        (kIsWeb || defaultTargetPlatform == TargetPlatform.windows);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: useDesktopHeroLayout ? 1220 : 1380,
        ),
"""
if old_flags not in section:
    raise SystemExit("dashboard header width block not found")
section = section.replace(old_flags, new_flags, 1)

old_metrics = """                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 600;
                        final metrics = <Widget>[
                          _Metric(
                            icon: Icons.queue_music_rounded,
                            value: '$normalCount',
                            label: '歌单',
                            compact: compact,
                          ),
                          _Metric(
                            icon: Icons.radio_rounded,
                            value: '$radioCount',
                            label: '电台',
                            compact: compact,
                          ),
                          _Metric(
                            icon: Icons.cloud_done_rounded,
                            value: '在线',
                            label: '音乐库',
                            compact: compact,
                          ),
                        ];

                        if (!compact) {
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: metrics,
                          );
                        }

                        return Row(
                          children: [
                            for (var i = 0; i < metrics.length; i++) ...[
                              Expanded(child: metrics[i]),
                              if (i != metrics.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        );
                      },
                    ),
"""
new_metrics = """                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 600;
                        final metrics = <Widget>[
                          _Metric(
                            icon: Icons.queue_music_rounded,
                            value: '$normalCount',
                            label: '歌单',
                            compact: compact,
                          ),
                          _Metric(
                            icon: Icons.radio_rounded,
                            value: '$radioCount',
                            label: '电台',
                            compact: compact,
                          ),
                          _Metric(
                            icon: Icons.cloud_done_rounded,
                            value: '在线',
                            label: '音乐库',
                            compact: compact,
                          ),
                        ];

                        if (useDesktopHeroLayout) {
                          return Row(
                            children: [
                              for (var i = 0; i < metrics.length; i++) ...[
                                Expanded(child: metrics[i]),
                                if (i != metrics.length - 1)
                                  const SizedBox(width: 12),
                              ],
                            ],
                          );
                        }

                        if (!compact) {
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: metrics,
                          );
                        }

                        return Row(
                          children: [
                            for (var i = 0; i < metrics.length; i++) ...[
                              Expanded(child: metrics[i]),
                              if (i != metrics.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        );
                      },
                    ),
"""
if old_metrics not in section:
    raise SystemExit("dashboard metric block not found")
section = section.replace(old_metrics, new_metrics, 1)

text = text[:start] + section + text[end:]
path.write_text(text, encoding="utf-8")
