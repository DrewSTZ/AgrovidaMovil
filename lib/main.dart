import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/terreno_repository.dart';
import 'data/auth_repository.dart';
import 'data/parcela_repository.dart';
import 'data/session_repository.dart';
import 'screens/app_shell.dart';
import 'screens/login_page.dart';
import 'screens/splash_page.dart';
import 'state/terreno_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const AgroVidaApp());
}

class AgroVidaApp extends StatelessWidget {
  const AgroVidaApp({
    super.key,
    this.terrenoStore,
    this.authRepository,
    this.parcelaRepository,
    this.sessionRepository,
  });

  final TerrenoStore? terrenoStore;
  final AuthRepository? authRepository;
  final ParcelaRepository? parcelaRepository;
  final SessionRepository? sessionRepository;

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF123D2A);
    const brandGreenDark = Color(0xFF0A2A1D);
    const brandGreenSoft = Color(0xFFDCECE1);
    const appBackground = Color(0xFFF4F7F4);
    const ink = Color(0xFF17231C);
    const outline = Color(0xFFD4DED6);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: brandGreen,
          brightness: Brightness.light,
        ).copyWith(
          primary: brandGreen,
          onPrimary: Colors.white,
          primaryContainer: brandGreenSoft,
          onPrimaryContainer: brandGreenDark,
          secondary: const Color(0xFF406B54),
          surface: Colors.white,
          onSurface: ink,
          outline: outline,
          surfaceContainerHighest: const Color(0xFFE8EEE9),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgroVida',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: appBackground,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
          fontFamily: 'Roboto',
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 1,
          indicatorColor: brandGreenSoft,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? brandGreen
                  : const Color(0xFF526158),
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? brandGreen
                  : const Color(0xFF526158),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brandGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandGreen,
            minimumSize: const Size(0, 44),
            side: const BorderSide(color: outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandGreen, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: outline),
          ),
        ),
        dividerTheme: const DividerThemeData(color: outline, thickness: 1),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: brandGreenDark,
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: _AppEntry(
        terrenoStore: terrenoStore,
        authRepository: authRepository,
        parcelaRepository: parcelaRepository,
        sessionRepository: sessionRepository,
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({
    this.terrenoStore,
    this.authRepository,
    this.parcelaRepository,
    this.sessionRepository,
  });

  final TerrenoStore? terrenoStore;
  final AuthRepository? authRepository;
  final ParcelaRepository? parcelaRepository;
  final SessionRepository? sessionRepository;

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  late final TerrenoStore _terrenoStore;
  late final bool _ownsStore;
  late final AuthRepository _authRepository;
  late final bool _ownsAuthRepository;
  late final ParcelaRepository _parcelaRepository;
  late final bool _ownsParcelaRepository;
  late final SessionRepository _sessionRepository;
  bool _splashFinished = false;
  bool _sessionRestored = false;
  AuthenticatedUser? _authenticatedUser;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.terrenoStore == null;
    _terrenoStore =
        widget.terrenoStore ?? TerrenoStore(SqliteTerrenoRepository.instance);
    _ownsAuthRepository = widget.authRepository == null;
    _authRepository = widget.authRepository ?? HttpAuthRepository();
    _ownsParcelaRepository = widget.parcelaRepository == null;
    _parcelaRepository = widget.parcelaRepository ?? HttpParcelaRepository();
    _sessionRepository = widget.sessionRepository ?? SecureSessionRepository();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await _sessionRepository.read();
    if (!mounted) return;
    setState(() {
      _authenticatedUser = user;
      _sessionRestored = true;
    });
  }

  Future<void> _handleLogin(AuthenticatedUser user) async {
    try {
      await _sessionRepository.save(user);
    } catch (_) {
      // El acceso continúa aunque el almacenamiento seguro no esté disponible.
    }
    if (mounted) setState(() => _authenticatedUser = user);
  }

  Future<void> _logout() async {
    try {
      await _sessionRepository.clear();
    } finally {
      if (mounted) setState(() => _authenticatedUser = null);
    }
  }

  @override
  void dispose() {
    if (_ownsStore) _terrenoStore.dispose();
    if (_ownsAuthRepository) _authRepository.dispose();
    if (_ownsParcelaRepository) _parcelaRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget page;
    if (!_splashFinished || !_sessionRestored) {
      page = SplashPage(
        key: const ValueKey('splash'),
        onFinished: () {
          if (mounted) setState(() => _splashFinished = true);
        },
      );
    } else if (_authenticatedUser case final authenticatedUser?) {
      page = AppShell(
        key: const ValueKey('app'),
        terrenoStore: _terrenoStore,
        ownsStore: false,
        authenticatedUser: authenticatedUser,
        onLogout: _logout,
        parcelaRepository: _parcelaRepository,
      );
    } else {
      page = LoginPage(
        key: const ValueKey('login'),
        authRepository: _authRepository,
        onContinue: _handleLogin,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: page,
    );
  }
}
