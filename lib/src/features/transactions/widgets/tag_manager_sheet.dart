import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/expense_tag.dart';
import 'tag_colors.dart';

class TagManagerSheet extends StatefulWidget {
  const TagManagerSheet({
    required this.tags,
    super.key,
  });

  final List<ExpenseTag> tags;

  @override
  State<TagManagerSheet> createState() => _TagManagerSheetState();
}

class _TagManagerSheetState extends State<TagManagerSheet> {
  late List<ExpenseTag> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List<ExpenseTag>.of(widget.tags);
  }

  bool get _canCreateTag {
    return _tags.length < maxExpenseTagCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.74;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: <Widget>[
                  Text(
                    'Tags',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_tags.length}/$maxExpenseTagCount',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.56,
                      ),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _canCreateTag ? _createTag : null,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'New tag',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop(_tags);
                    },
                    icon: const Icon(Icons.check_rounded),
                    tooltip: 'Done',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _tags.length,
                separatorBuilder: (context, index) {
                  return Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
                  );
                },
                itemBuilder: (context, index) {
                  final tag = _tags[index];

                  return _ManagedTagRow(
                    tag: tag,
                    position: index + 1,
                    canMoveUp: index > 0,
                    canMoveDown: index < _tags.length - 1,
                    onEdit: () => _editTag(index),
                    onMoveUp: () => _moveTag(index, index - 1),
                    onMoveDown: () => _moveTag(index, index + 1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTag() async {
    if (!_canCreateTag) {
      return;
    }

    final tag = await showModalBottomSheet<ExpenseTag>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const _TagEditorSheet();
      },
    );

    if (!mounted || tag == null) {
      return;
    }

    setState(() {
      _tags.add(tag);
    });
  }

  Future<void> _editTag(int index) async {
    final tag = await showModalBottomSheet<ExpenseTag>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _TagEditorSheet(tag: _tags[index]);
      },
    );

    if (!mounted || tag == null) {
      return;
    }

    setState(() {
      _tags[index] = tag;
    });
  }

  void _moveTag(int fromIndex, int toIndex) {
    if (toIndex < 0 || toIndex >= _tags.length) {
      return;
    }

    setState(() {
      final tag = _tags.removeAt(fromIndex);
      _tags.insert(toIndex, tag);
    });
  }
}

class _ManagedTagRow extends StatelessWidget {
  const _ManagedTagRow({
    required this.tag,
    required this.position,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onEdit,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final ExpenseTag tag;
  final int position;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          _TagAvatar(tag: tag, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tag.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Position $position',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            tooltip: 'Move up',
          ),
          IconButton(
            onPressed: canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            tooltip: 'Move down',
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }
}

class _TagEditorSheet extends StatefulWidget {
  const _TagEditorSheet({
    this.tag,
  });

  final ExpenseTag? tag;

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  late final TextEditingController _nameController;
  late IconData _selectedIcon;
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    final tag = widget.tag;
    final fallbackTag = defaultExpenseTags().first;

    _selectedIcon = tag?.icon ?? fallbackTag.icon;
    _selectedColorValue = tag?.colorValue ?? fallbackTag.colorValue;
    _nameController = TextEditingController(text: tag?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _nameController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final iconOptions = tagIconOptions();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    widget.tag == null ? 'New tag' : 'Edit tag',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _canSave ? _save : null,
                    icon: const Icon(Icons.check_rounded),
                    tooltip: 'Save',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(_selectedIcon),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Icon',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: iconOptions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final option = iconOptions[index];
                  final selected = option.icon == _selectedIcon;

                  return _IconChoiceButton(
                    option: option,
                    selected: selected,
                    color: Color(_selectedColorValue),
                    onPressed: () {
                      setState(() {
                        _selectedIcon = option.icon;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Color',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              _ColorWheelButton(
                color: Color(_selectedColorValue),
                onPressed: _openColorWheel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openColorWheel() async {
    final color = await showModalBottomSheet<Color>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _ColorWheelSheet(
          initialColor: Color(_selectedColorValue),
        );
      },
    );

    if (!mounted || color == null) {
      return;
    }

    setState(() {
      _selectedColorValue = color.toARGB32();
    });
  }

  void _save() {
    if (!_canSave) {
      return;
    }

    Navigator.of(context).pop(
      ExpenseTag(
        id: widget.tag?.id ?? 'tag_${DateTime.now().microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        colorValue: _selectedColorValue,
      ),
    );
  }
}

class _IconChoiceButton extends StatelessWidget {
  const _IconChoiceButton({
    required this.option,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final TagIconOption option;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        selected ? foregroundFor(color) : theme.colorScheme.onSurface;

    return Tooltip(
      message: option.name,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(option.icon),
        color: foreground,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? color
              : theme.colorScheme.surface.withValues(alpha: 0.56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _ColorWheelButton extends StatelessWidget {
  const _ColorWheelButton({
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundFor(color);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox.square(
              dimension: 32,
              child: Icon(
                Icons.palette_rounded,
                color: foreground,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Choose color'),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }
}

class _ColorWheelSheet extends StatefulWidget {
  const _ColorWheelSheet({
    required this.initialColor,
  });

  final Color initialColor;

  @override
  State<_ColorWheelSheet> createState() => _ColorWheelSheetState();
}

class _ColorWheelSheetState extends State<_ColorWheelSheet> {
  late HSVColor _color;

  @override
  void initState() {
    super.initState();
    _color = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Color',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(_color.toColor());
                  },
                  icon: const Icon(Icons.check_rounded),
                  tooltip: 'Done',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: _ColorWheelPicker(
                color: _color,
                onChanged: (color) {
                  setState(() {
                    _color = color;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Icon(Icons.light_mode_rounded),
                Expanded(
                  child: Slider(
                    value: _color.value,
                    min: 0.16,
                    onChanged: (value) {
                      setState(() {
                        _color = _color.withValue(value);
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorWheelPicker extends StatelessWidget {
  const _ColorWheelPicker({
    required this.color,
    required this.onChanged,
  });

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 260.0;
        final dimension = math.min(maxWidth, 260.0);
        final size = Size.square(dimension);

        return Semantics(
          label: 'Color hue and saturation',
          value: 'Hue ${color.hue.round()}, '
              'saturation ${(color.saturation * 100).round()} percent',
          child: GestureDetector(
            onPanDown: (details) {
              _selectColor(details.localPosition, size);
            },
            onPanUpdate: (details) {
              _selectColor(details.localPosition, size);
            },
            child: SizedBox.square(
              dimension: dimension,
              child: CustomPaint(
                painter: _ColorWheelPainter(color: color),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectColor(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final vector = localPosition - center;
    final distance = math.min(vector.distance, radius);
    final saturation = (distance / radius).clamp(0.0, 1.0).toDouble();
    final radians = math.atan2(vector.dy, vector.dx);
    final hue = (radians * 180 / math.pi + 360) % 360;

    onChanged(color.withHue(hue).withSaturation(saturation));
  }
}

class _ColorWheelPainter extends CustomPainter {
  const _ColorWheelPainter({
    required this.color,
  });

  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    final huePaint = Paint()
      ..shader = const SweepGradient(
        colors: <Color>[
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(bounds);
    canvas.drawCircle(center, radius, huePaint);

    final saturationPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white,
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(bounds);
    canvas.drawCircle(center, radius, saturationPaint);

    if (color.value < 1) {
      final valuePaint = Paint()
        ..color = Colors.black.withValues(alpha: 1 - color.value);
      canvas.drawCircle(center, radius, valuePaint);
    }

    final selectedRadians = color.hue * math.pi / 180;
    final selectedOffset = Offset(
      math.cos(selectedRadians) * color.saturation * radius,
      math.sin(selectedRadians) * color.saturation * radius,
    );
    final selectedCenter = center + selectedOffset;

    canvas
      ..drawCircle(
        selectedCenter,
        9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      )
      ..drawCircle(
        selectedCenter,
        6,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TagAvatar extends StatelessWidget {
  const _TagAvatar({
    required this.tag,
    this.size = 26,
  });

  final ExpenseTag tag;
  final double size;

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundFor(tag.color);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tag.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          tag.icon,
          color: foreground,
          size: size * 0.52,
        ),
      ),
    );
  }
}
