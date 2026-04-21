import 'package:flutter/material.dart';

PreferredSizeWidget buildBrandedAppBar({
  required BuildContext context,
  required Widget title,
  Widget? leading,
  double? leadingWidth,
  List<Widget>? actions,
  bool centerTitle = true,
  PreferredSizeWidget? bottom,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final titleColor = isDark
      ? Colors.white.withValues(alpha: 0.98)
      : scheme.onSurface.withValues(alpha: 0.94);

  return AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    foregroundColor: titleColor,
    iconTheme: IconThemeData(color: titleColor),
    actionsIconTheme: IconThemeData(color: titleColor),
    titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: titleColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.42 : 0.20),
              scheme.surface,
            ),
            Color.alphaBlend(
              scheme.tertiary.withValues(alpha: isDark ? 0.34 : 0.16),
              scheme.surface,
            ),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: scheme.outline.withValues(alpha: isDark ? 0.38 : 0.22),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    ),
    leading: leading,
    leadingWidth: leadingWidth,
    title: title,
    centerTitle: centerTitle,
    actions: actions,
    bottom: bottom,
  );
}

Widget buildBrandedHeaderIconAction({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onTap,
  required String tooltip,
  EdgeInsets padding = const EdgeInsets.all(8),
  EdgeInsets margin = const EdgeInsets.only(right: 10, top: 8, bottom: 8),
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: margin,
    child: Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surface.withValues(alpha: isDark ? 0.20 : 0.32),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Icon(icon),
          ),
        ),
      ),
    ),
  );
}
