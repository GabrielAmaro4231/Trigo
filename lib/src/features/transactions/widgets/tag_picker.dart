import 'package:flutter/material.dart';

import '../../../models/expense_tag.dart';
import '../../../widgets/glass_surface.dart';
import 'tag_colors.dart';

class TagShortcutButton extends StatelessWidget {
  const TagShortcutButton({
    required this.tag,
    required this.onPressed,
    super.key,
  });

  final ExpenseTag? tag;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTag = tag;
    final foreground = selectedTag == null
        ? theme.colorScheme.onSurface
        : foregroundFor(selectedTag.color);
    final label = selectedTag?.name ?? 'Tag';

    return Tooltip(
      message: selectedTag == null ? 'Choose tag' : 'Selected tag: $label',
      child: SizedBox(
        width: 136,
        height: 52,
        child: GlassSurface(
          radius: 999,
          tint: selectedTag?.color,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      selectedTag?.icon ?? Icons.sell_rounded,
                      color: foreground,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingTagPicker extends StatelessWidget {
  const FloatingTagPicker({
    required this.tags,
    required this.selectedTagId,
    required this.onSelected,
    required this.onManage,
    super.key,
  });

  final List<ExpenseTag> tags;
  final String? selectedTagId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 268, maxHeight: 284),
      child: GlassSurface(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.sell_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tags',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onManage,
                  icon: const Icon(Icons.tune_rounded),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Manage tags',
                ),
              ],
            ),
            Flexible(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tags.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.95,
                ),
                itemBuilder: (context, index) {
                  final tag = tags[index];

                  return _FloatingTagChip(
                    tag: tag,
                    selected: tag.id == selectedTagId,
                    onPressed: () {
                      onSelected(tag.id == selectedTagId ? null : tag.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingTagChip extends StatelessWidget {
  const _FloatingTagChip({
    required this.tag,
    required this.selected,
    required this.onPressed,
  });

  final ExpenseTag tag;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        selected ? foregroundFor(tag.color) : theme.colorScheme.onSurface;
    final iconColor = selected ? foreground : foregroundFor(tag.color);
    final iconBackground =
        selected ? foreground.withValues(alpha: 0.16) : tag.color;

    return Tooltip(
      message: selected ? 'Clear ${tag.name}' : tag.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? tag.color
                  : theme.colorScheme.surface.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? tag.color : tag.color.withValues(alpha: 0.28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: SizedBox.square(
                      dimension: 22,
                      child: Icon(
                        tag.icon,
                        color: iconColor,
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      tag.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
