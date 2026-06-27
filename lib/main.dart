import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';
import 'views/client/profile_screen.dart'; // Importez le themeModeProvider
import 'utils/couleur.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // Charger les variables d'environnement
  await dotenv.load(fileName: ".env");

  // Initialiser Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ReviewApp',
      themeMode: themeMode, // Applique le thème sélectionné
      theme: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.light,
          primary: AppColors.primaryBlue,
          secondary: AppColors.cyanTeal,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textMainLight,
          onSurfaceVariant: AppColors.textSecondaryLight,
          surfaceContainerHighest: AppColors.surfaceSecondaryLight,
          error: AppColors.outcomeRed,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textTitleLight),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMainLight),
          titleSmall: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSmallLight),
          labelLarge: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMainLight),
          labelMedium: TextStyle(color: AppColors.textSecondaryLight),
          labelSmall: TextStyle(color: AppColors.textSecondaryLight),
          bodyLarge: TextStyle(color: AppColors.textMainLight),
          bodyMedium: TextStyle(color: AppColors.textBodyLight),
          bodySmall: TextStyle(color: AppColors.textSecondaryLight),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textTitleLight,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textMutedLight,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.surfaceLight,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          hintStyle: const TextStyle(color: AppColors.textMutedLight),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.outcomeRed, width: 1),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: const TextStyle(color: AppColors.textTitleLight, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
          contentTextStyle: const TextStyle(color: AppColors.textSmallLight, fontSize: 16, fontFamily: 'Poppins'),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.surfaceSecondaryLight,
          thickness: 1,
          space: 24,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondaryLight,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryBlue,
          secondary: AppColors.cyanTeal,
          surface: AppColors.backgroundDark,
          surfaceContainerHighest: AppColors.cardDark,
          onSurface: AppColors.textMain,
          onSurfaceVariant: AppColors.textSecondary,
          error: AppColors.outcomeRed,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textMain),
          bodyMedium: TextStyle(color: AppColors.textMain),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          titleLarge: TextStyle(color: AppColors.textMain),
          titleMedium: TextStyle(color: AppColors.textMain),
          titleSmall: TextStyle(color: AppColors.textSecondary),
          labelLarge: TextStyle(color: AppColors.textMain),
          labelMedium: TextStyle(color: AppColors.textSecondary),
          labelSmall: TextStyle(color: AppColors.textSecondary),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textMain,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundDark,
          selectedItemColor: AppColors.navActive,
          unselectedItemColor: AppColors.textSecondary,
        ),
      ),
      routerConfig: goRouter,
    );
  }
}
