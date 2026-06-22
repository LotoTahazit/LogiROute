import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LogiRouteTabItem {
  const LogiRouteTabItem({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

enum LogiRouteTabBarVariant { onPrimary, surface }

/// Единые pill-вкладки для всего приложения: hover, press, контраст.
class LogiRouteTabBar extends StatelessWidget {
  const LogiRouteTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.selectedIndex,
    this.onChanged,
    this.variant = LogiRouteTabBarVariant.surface,
    this.isScrollable = true,
    this.padding,
  }) : assert(
          controller != null || (selectedIndex != null && onChanged != null),
          'Provide TabController or selectedIndex+onChanged',
        );

  final List<LogiRouteTabItem> tabs;
  final TabController? controller;
  final int? selectedIndex;
  final ValueChanged<int>? onChanged;
  final LogiRouteTabBarVariant variant;
  final bool isScrollable;
  final EdgeInsetsGeometry? padding;

  factory LogiRouteTabBar.appBar({
    Key? key,
    required TabController controller,
    required List<LogiRouteTabItem> tabs,
    bool isScrollable = true,
  }) {
    return LogiRouteTabBar(
      key: key,
      controller: controller,
      tabs: tabs,
      variant: LogiRouteTabBarVariant.onPrimary,
      isScrollable: isScrollable,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) => _buildBar(context, controller!.index),
      );
    }
    return _buildBar(context, selectedIndex ?? 0);
  }

  Widget _buildBar(BuildContext context, int idx) {
    final accent = Theme.of(context).colorScheme.primary;
    final items = List.generate(
      tabs.length,
      (i) => _PillTabItem(
        item: tabs[i],
        selected: idx == i,
        variant: variant,
        accent: accent,
        onTap: () {
          if (controller != null) {
            if (controller!.index != i) controller!.animateTo(i);
          } else {
            onChanged!(i);
          }
        },
      ),
    );
    final row = Row(
      mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment:
          isScrollable ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: items,
    );
    final child = isScrollable
        ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: row)
        : row;

    return Padding(
      padding: padding ??
          (variant == LogiRouteTabBarVariant.onPrimary
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      child: variant == LogiRouteTabBarVariant.surface
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surfaceHi.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: child,
              ),
            )
          : child,
    );
  }
}

/// Вкладки в [AppBar.bottom].
class LogiRouteAppBarTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LogiRouteAppBarTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable = true,
  });

  LogiRouteAppBarTabBar.labels({
    super.key,
    required this.controller,
    required List<String> labels,
    this.isScrollable = true,
  }) : tabs = _labelsToItems(labels);

  final TabController controller;
  final List<LogiRouteTabItem> tabs;
  final bool isScrollable;

  static List<LogiRouteTabItem> _labelsToItems(List<String> labels) =>
      labels.map((l) => LogiRouteTabItem(label: l)).toList();

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return LogiRouteTabBar.appBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable,
    );
  }
}

/// Однострочный pill-переключатель (фильтры, периоды) — тот же стиль, что вкладки.
class LogiRoutePillSelector extends StatelessWidget {
  const LogiRoutePillSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.isScrollable = true,
    this.variant = LogiRouteTabBarVariant.surface,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isScrollable;
  final LogiRouteTabBarVariant variant;

  @override
  Widget build(BuildContext context) {
    return LogiRouteTabBar(
      selectedIndex: selectedIndex,
      onChanged: onSelected,
      isScrollable: isScrollable,
      variant: variant,
      tabs: labels.map((l) => LogiRouteTabItem(label: l)).toList(),
    );
  }
}

/// Мультивыбор pill-кнопок (зоны доставки и т.п.).
class LogiRoutePillToggleBar extends StatelessWidget {
  const LogiRoutePillToggleBar({
    super.key,
    required this.labels,
    required this.selectedIndices,
    required this.onToggle,
    this.isScrollable = true,
  });

  final List<String> labels;
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggle;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final items = List.generate(
      labels.length,
      (i) => _PillTabItem(
        item: LogiRouteTabItem(label: labels[i]),
        selected: selectedIndices.contains(i),
        variant: LogiRouteTabBarVariant.surface,
        accent: accent,
        onTap: () => onToggle(i),
      ),
    );
    final row = Row(
      mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
      children: items,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceHi.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: isScrollable
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: row,
                )
              : row,
        ),
      ),
    );
  }
}

class _PillTabItem extends StatefulWidget {
  const _PillTabItem({
    required this.item,
    required this.selected,
    required this.variant,
    required this.accent,
    required this.onTap,
  });

  final LogiRouteTabItem item;
  final bool selected;
  final LogiRouteTabBarVariant variant;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_PillTabItem> createState() => _PillTabItemState();
}

class _PillTabItemState extends State<_PillTabItem> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final onPrimary = widget.variant == LogiRouteTabBarVariant.onPrimary;
    final fg = _foreground(onPrimary);
    final bg = _background(onPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: widget.selected
                    ? null
                    : Border.all(
                        color: onPrimary
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppTheme.border,
                      ),
                boxShadow: widget.selected && !onPrimary
                    ? [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : widget.selected && onPrimary
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.item.icon != null) ...[
                    Icon(widget.item.icon, size: 16, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      color: fg,
                      fontWeight:
                          widget.selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
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

  Color _foreground(bool onPrimary) {
    if (onPrimary) {
      return widget.selected ? widget.accent : Colors.white;
    }
    return widget.selected ? Colors.white : AppTheme.text;
  }

  Color _background(bool onPrimary) {
    if (onPrimary) {
      return widget.selected
          ? Colors.white
          : Colors.white.withValues(alpha: _hover ? 0.28 : 0.16);
    }
    if (widget.selected) return widget.accent;
    return _hover
        ? AppTheme.surfaceHi
        : AppTheme.surface.withValues(alpha: 0.85);
  }
}
