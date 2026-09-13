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
  static const _greenDark = Color(0xFF071F16);
  static const _greenLight = Color(0xFF2A7650);
  static const _systemUiStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: _greenDark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
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
        backgroundColor: _greenDark,
        body: Stack(
          children: [
            const Positioned.fill(child: _LoginBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 820;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      22,
                      compact ? 18 : 28,
                      22,
                      compact ? 18 : 26,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 460,
                          minHeight: constraints.maxHeight > (compact ? 36 : 54)
                              ? constraints.maxHeight - (compact ? 36 : 54)
                              : 0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _EntranceTransition(
                              animation: _interval(0, 0.5),
                              offset: 18,
                              child: _buildBrand(compact),
                            ),
                            SizedBox(height: compact ? 20 : 30),
                            _EntranceTransition(
                              animation: _interval(0.18, 0.82),
                              offset: 28,
                              child: _buildLoginCard(context, compact),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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

  Widget _buildBrand(bool compact) {
    return Column(
      children: [
        Container(
          width: compact ? 68 : 78,
          height: compact ? 68 : 78,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: compact ? 38 : 44,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'AgroVida',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 31 : 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cultiva información. Mejora tus decisiones.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, bool compact) {
    return Material(
      color: const Color(0xFFF8FBF8),
      elevation: 12,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 26,
          compact ? 22 : 28,
          compact ? 20 : 26,
          compact ? 20 : 26,
        ),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Color(0xFF102219),
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Ingrese sus datos',
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
                              : () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
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
              ],
            ),
          ),
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
      fillColor: Colors.white,
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

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _LoginPageState._greenDark,
            _LoginPageState._green,
            _LoginPageState._greenLight,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -65,
            child: _GlowCircle(size: 250, opacity: 0.08),
          ),
          Positioned(
            bottom: -120,
            left: -85,
            child: _GlowCircle(size: 310, opacity: 0.07),
          ),
          Positioned(
            top: 110,
            left: -26,
            child: Transform.rotate(
              angle: -0.45,
              child: Icon(
                Icons.eco_outlined,
                size: 118,
                color: Colors.white.withValues(alpha: 0.035),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
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
