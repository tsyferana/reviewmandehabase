import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bgColor =
        backgroundColor ??
        (selected ? colorScheme.primary : colorScheme.surfaceContainerHighest);
    final fgColor =
        foregroundColor ??
        (selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant);
    final border =
        borderColor ??
        (selected ? colorScheme.primary : colorScheme.outlineVariant);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.15),
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fgColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
