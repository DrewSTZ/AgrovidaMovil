import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onContinue,
    required this.authRepository,
  });

  final Future<void> Function(AuthenticatedUser) onContinue;
  final AuthRepository authRepository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF123D2A);
  static const _systemUiStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  late final AnimationController _entranceController;
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _hidePassword = true;
  bool _isEntering = false;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFFDDEFE5),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            final heroHeight = compact
                ? 205.0
                : (constraints.maxHeight * 0.37).clamp(255.0, 320.0);

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    SizedBox(
                      height: heroHeight,
                      child: _EntranceTransition(
                        animation: _interval(0, 0.56),
                        offset: 12,
                        child: _AgroHero(compact: compact),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - heroHeight,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        compact ? 24 : 30,
                        24,
                        22 + MediaQuery.paddingOf(context).bottom,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(34),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x22071F16),
                            blurRadius: 24,
                            offset: Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _EntranceTransition(
                            animation: _interval(0.18, 0.86),
                            offset: 26,
                            child: _buildLoginPanel(context, compact),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildLoginPanel(BuildContext context, bool compact) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF102219),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'a AgroVida',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _green,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tus datos para gestionar tus terrenos y cultivos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            SizedBox(height: compact ? 20 : 26),
            TextFormField(
              controller: _usuarioController,
              enabled: !_isEntering,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: _validateUsuario,
              decoration: _inputDecoration(
                label: 'Correo electrónico',
                hint: 'nombre@empresa.com',
                icon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contrasenaController,
              enabled: !_isEntering,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: _validateContrasena,
              onFieldSubmitted: (_) => _login(),
              decoration:
                  _inputDecoration(
                    label: 'Contraseña',
                    hint: 'Ingresa tu contraseña',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      onPressed: _isEntering
                          ? null
                          : () =>
                                setState(() => _hidePassword = !_hidePassword),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          key: ValueKey(_hidePassword),
                        ),
                      ),
                    ),
                  ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _loginError == null
                  ? const SizedBox.shrink(key: ValueKey('without-error'))
                  : Padding(
                      key: const ValueKey('login-error'),
                      padding: const EdgeInsets.only(top: 14),
                      child: Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _loginError!,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isEntering ? null : _login,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: _isEntering
                    ? const Row(
                        key: ValueKey('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Ingresando…'),
                        ],
                      )
                    : const Row(
                        key: ValueKey('ready'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Iniciar sesión'),
                          SizedBox(width: 9),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFF557064)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Acceso protegido a tu información de campo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF557064), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF1F6F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE1EAE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _green, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    );
  }

  String? _validateUsuario(String? value) {
    final usuario = value?.trim() ?? '';
    if (usuario.isEmpty) return 'Ingrese su correo electrónico.';
    final separator = usuario.indexOf('@');
    if (separator <= 0 || separator == usuario.length - 1) {
      return 'Ingrese un correo electrónico válido.';
    }
    return null;
  }

  String? _validateContrasena(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese su contraseña.';
    return null;
  }

  Future<void> _login() async {
    if (_isEntering) return;
    setState(() => _loginError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isEntering = true);

    final result = await widget.authRepository.login(
      usuario: _usuarioController.text.trim(),
      contrasena: _contrasenaController.text,
    );
    if (!mounted) return;
    if (result.isSuccess) {
      final authenticatedUser = AuthenticatedUser.fromLoginData(
        result.data,
        fallbackIdentifier: _usuarioController.text.trim(),
      );
      _contrasenaController.clear();
      TextInput.finishAutofillContext();
      await widget.onContinue(authenticatedUser);
      return;
    }

    setState(() {
      _isEntering = false;
      _loginError = result.message ?? 'No se pudo iniciar sesión.';
    });
  }
}

class _AgroHero extends StatelessWidget {
  const _AgroHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _AgroLandscapePainter()),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, compact ? 8 : 14, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22071F16),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/branding/agrovida_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AgroVida',
                      style: TextStyle(
                        color: Color(0xFF0A2A1D),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.86,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2A1D).withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Tu campo, siempre contigo',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AgroLandscapePainter extends CustomPainter {
  const _AgroLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDDF4EB), Color(0xFFAED9C4)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final sun = Paint()..color = const Color(0xFFFFD77A);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.23), 30, sun);
    _drawCloud(canvas, Offset(size.width * 0.12, size.height * 0.33), 0.75);
    _drawCloud(canvas, Offset(size.width * 0.72, size.height * 0.4), 0.58);

    final distantHill = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.35,
        size.width * 0.4,
        size.height * 0.57,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.32,
        size.width,
        size.height * 0.57,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(distantHill, Paint()..color = const Color(0xFF78AB87));

    final nearHill = Path()
      ..moveTo(0, size.height * 0.69)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.48,
        size.width * 0.5,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.47,
        size.width,
        size.height * 0.64,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(nearHill, Paint()..color = const Color(0xFF3F8054));

    final field = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.67,
        size.width,
        size.height * 0.74,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(field, Paint()..color = const Color(0xFF236542));

    final horizon = Offset(size.width * 0.52, size.height * 0.7);
    final rowPaint = Paint()
      ..color = const Color(0xFF8BC276)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var index = -3; index <= 3; index++) {
      final destinationX = size.width * (0.08 + ((index + 3) * 0.15));
      canvas.drawLine(
        horizon + Offset(index * 9, 0),
        Offset(destinationX, size.height + 8),
        rowPaint,
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 72 * scale, height: 25 * scale),
      cloud,
    );
    canvas.drawCircle(
      center + Offset(-18 * scale, -7 * scale),
      15 * scale,
      cloud,
    );
    canvas.drawCircle(
      center + Offset(8 * scale, -12 * scale),
      20 * scale,
      cloud,
    );
  }

  @override
  bool shouldRepaint(covariant _AgroLandscapePainter oldDelegate) => false;
}

class _EntranceTransition extends StatelessWidget {
  const _EntranceTransition({
    required this.animation,
    required this.child,
    required this.offset,
  });

  final Animation<double> animation;
  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }
}
