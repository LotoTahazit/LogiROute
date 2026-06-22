import 'package:flutter/material.dart';

/// Палитра одной темы LogiRoute (цвета живого демо).
class AppPalette {
  final Color bg; // фон экранов
  final Color surface; // карточки, панели, бары
  final Color surfaceHi; // поля ввода, приподнятое
  final Color accent; // брендовый синий
  final Color accentSoft; // синий для иконок/ссылок
  final Color green; // успех
  final Color greenSoft;
  final Color warning;
  final Color danger;
  final Color text;
  final Color muted; // вторичный текст
  final Color border;
  final Color tile; // KPI-плитки

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.accent,
    required this.accentSoft,
    required this.green,
    required this.greenSoft,
    required this.warning,
    required this.danger,
    required this.text,
    required this.muted,
    required this.border,
    required this.tile,
  });
}

/// Единая тема LogiRoute — тёмный премиум из живого демо + светлый вариант
/// в тех же брендовых цветах. Активная палитра переключается [setDark]
/// (вызывает ThemeService при старте и переключении темы).
class AppTheme {
  AppTheme._();

  static const AppPalette darkPalette = AppPalette(
    bg: Color(0xFF0A1430),
    surface: Color(0xFF0E1A38),
    surfaceHi: Color(0xFF16284E),
    accent: Color(0xFF2F7BE5),
    accentSoft: Color(0xFF7FB2FF),
    green: Color(0xFF34C759),
    greenSoft: Color(0xFF6FE6A6),
    warning: Color(0xFFF5B43C),
    danger: Color(0xFFE96B6B),
    text: Colors.white,
    muted: Color(0xFF9FB0CE),
    border: Color(0x1FFFFFFF),
    tile: Color(0x14FFFFFF),
  );

  static const AppPalette lightPalette = AppPalette(
    bg: Color(0xFFF2F5FB),
    surface: Colors.white,
    surfaceHi: Color(0xFFE9EEF8),
    accent: Color(0xFF2F7BE5),
    accentSoft: Color(0xFF1D5FC4),
    green: Color(0xFF1FA34A),
    greenSoft: Color(0xFF157A3A),
    warning: Color(0xFFB97908),
    danger: Color(0xFFC53A3A),
    text: Color(0xFF11203F),
    muted: Color(0xFF5A6B8C),
    border: Color(0x1F11203F),
    tile: Color(0x0F0E1A38),
  );

  static bool _isDark = false;
  static bool get isDark => _isDark;

  /// Переключение активной палитры. Вызывается ThemeService ДО notifyListeners,
  /// чтобы перестроенные виджеты сразу читали корректные цвета.
  static void setDark(bool value) => _isDark = value;

  static AppPalette get p => _isDark ? darkPalette : lightPalette;

  // ── Статические геттеры активной палитры (используются по всему коду) ──
  static Color get bg => p.bg;
  static Color get surface => p.surface;
  static Color get surfaceHi => p.surfaceHi;
  static Color get accent => p.accent;
  static Color get accentSoft => p.accentSoft;
  static Color get green => p.green;
  static Color get greenSoft => p.greenSoft;
  static Color get warning => p.warning;
  static Color get danger => p.danger;
  static Color get text => p.text;
  static Color get muted => p.muted;
  static Color get border => p.border;
  static Color get tile => p.tile;

  static ThemeData dark() => _build(darkPalette, Brightness.dark);
  static ThemeData light() => _build(lightPalette, Brightness.light);

  static ThemeData _build(AppPalette c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: Colors.white,
      secondary: c.green,
      onSecondary: isDark ? const Color(0xFF06320F) : Colors.white,
      surface: c.surface,
      onSurface: c.text,
      surfaceContainerHighest: c.surfaceHi,
      onSurfaceVariant: c.muted,
      error: c.danger,
      onError: Colors.white,
      outline: c.border,
      outlineVariant: c.border,
    );

    TextStyle s(Color col, {double? size, FontWeight w = FontWeight.w700}) =>
        TextStyle(color: col, fontWeight: w, fontSize: size);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // Часть экранов использует theme.primaryColor напрямую.
      primaryColor: c.accent,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.surface,
      cardColor: c.surface,
      dividerColor: c.border,
      fontFamily: 'NotoSansHebrew',
      fontFamilyFallback: const ['NotoSans'],
      textTheme: TextTheme(
        bodyLarge: s(c.text),
        bodyMedium: s(c.text),
        bodySmall: s(c.muted, size: 13),
        displayLarge: s(c.text),
        displayMedium: s(c.text),
        displaySmall: s(c.text),
        headlineLarge: s(c.text),
        headlineMedium: s(c.text),
        headlineSmall: s(c.text),
        titleLarge: s(c.text),
        titleMedium: s(c.text),
        titleSmall: s(c.text),
        labelLarge: s(c.text),
        labelMedium: s(c.muted, size: 13),
        labelSmall: s(c.muted, size: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'NotoSansHebrew',
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border, width: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: c.text,
        iconColor: c.muted,
        subtitleTextStyle: TextStyle(
          color: c.muted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          fontFamily: 'NotoSansHebrew',
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: c.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'NotoSansHebrew',
        ),
        contentTextStyle: TextStyle(
          color: c.muted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSansHebrew',
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceHi,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          color: c.text,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          fontFamily: 'NotoSansHebrew',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? c.surfaceHi : Colors.white,
        hintStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w600),
        prefixIconColor: c.muted,
        suffixIconColor: c.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accentSoft,
          side: BorderSide(color: c.border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accentSoft,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c.accent
                : c.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : c.text,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: c.border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceHi,
        selectedColor: c.accent,
        disabledColor: c.surfaceHi,
        labelStyle: TextStyle(
          color: c.text,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      tabBarTheme: const TabBarThemeData(
        // Legacy TabBar — предпочитайте LogiRouteTabBar / LogiRouteAppBarTabBar.
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        dividerColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.accentSoft,
        unselectedItemColor: c.muted,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.accent.withValues(alpha: 0.22),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color:
                states.contains(WidgetState.selected) ? c.accentSoft : c.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? c.text : c.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansHebrew',
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        selectedIconTheme: IconThemeData(color: c.accentSoft),
        unselectedIconTheme: IconThemeData(color: c.muted),
        selectedLabelTextStyle:
            TextStyle(color: c.text, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle:
            TextStyle(color: c.muted, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? c.surfaceHi : const Color(0xFF22335C),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSansHebrew',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceHi,
        circularTrackColor: c.surfaceHi,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : c.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.accent
              : c.surfaceHi,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.accent
              : Colors.transparent,
        ),
        side: BorderSide(color: c.muted, width: 1.6),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceHi),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.surfaceHi,
        headerForegroundColor: c.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? c.surfaceHi : const Color(0xFF22335C),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      iconTheme: IconThemeData(color: c.muted),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: c.accentSoft,
        collapsedIconColor: c.muted,
        textColor: c.text,
        collapsedTextColor: c.text,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          color: c.muted,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        dataTextStyle: TextStyle(
          color: c.text,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dividerThickness: 0.6,
      ),
    );
  }
}
