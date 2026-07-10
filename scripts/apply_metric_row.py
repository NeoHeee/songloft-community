from pathlib import Path


SOURCE_PATH = Path("lib/features/home/presentation/home_page.dart")


def main() -> None:
    text = SOURCE_PATH.read_text(encoding="utf-8")

    if "final compact = constraints.maxWidth < 600;" in text:
        print("Mobile metric row is already applied")
        return

    old_metrics = """                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Metric(
                          icon: Icons.queue_music_rounded,
                          value: '$normalCount',
                          label: '歌单',
                        ),
                        _Metric(
                          icon: Icons.radio_rounded,
                          value: '$radioCount',
                          label: '电台',
                        ),
                        const _Metric(
                          icon: Icons.cloud_done_rounded,
                          value: '在线',
                          label: '音乐库',
                        ),
                      ],
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

    if old_metrics not in text:
        raise RuntimeError("Dashboard metric block was not found")
    text = text.replace(old_metrics, new_metrics, 1)

    metric_start = text.index("class _Metric extends StatelessWidget {")
    metric_end = text.index(
        "class _QuickActions extends StatelessWidget {", metric_start
    )
    metric_class = """class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 16 : 17, color: Colors.white),
            SizedBox(width: compact ? 5 : 8),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 14 : null,
              ),
            ),
            SizedBox(width: compact ? 3 : 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                fontSize: compact ? 14 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

"""
    text = text[:metric_start] + metric_class + text[metric_end:]
    SOURCE_PATH.write_text(text, encoding="utf-8")
    print("Applied the mobile one-row dashboard metric layout")


if __name__ == "__main__":
    main()
