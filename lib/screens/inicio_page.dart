import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../state/terreno_store.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({
    super.key,
    required this.terrenoStore,
    required this.onOpenSection,
    required this.authenticatedUser,
    required this.onLogout,
  });

  final TerrenoStore terrenoStore;
  final ValueChanged<int> onOpenSection;
  final AuthenticatedUser authenticatedUser;
  final Future<void> Function() onLogout;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _EntranceTransition(
            animation: CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0, 0.58, curve: Curves.easeOutCubic),
            ),
            verticalOffset: 10,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              color: Theme.of(context).colorScheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AgroVida',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Agricultura de precisión',
                              style: TextStyle(color: Color(0xFFDCECE1)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Información de AgroVida',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => showAboutDialog(
                          context: context,
                          applicationName: 'AgroVida',
                          applicationVersion: 'Prototipo móvil',
                          children: const [
                            Text(
                              'Gestión de parcelas y evidencias para el cultivo de banano.',
                            ),
                          ],
                        ),
                        icon: const Icon(Icons.info_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _AccountSummary(
                    user: widget.authenticatedUser,
                    onLogout: _confirmLogout,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Resumen de campo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Información disponible en este dispositivo.',
                    style: TextStyle(color: Color(0xFFE8F5E9)),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: widget.terrenoStore,
                    builder: (context, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _SummaryMetric(
                              value: '${widget.terrenoStore.terrenos.length}',
                              label: 'Terrenos\nregistrados',
                              icon: Icons.grid_view_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: _SummaryMetric(
                              value: 'GPS',
                              label: 'Mapa y\ndelimitación',
                              icon: Icons.location_searching_outlined,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EntranceTransition(
                  animation: CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(
                      0.18,
                      0.62,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: Text(
                    'Gestión de campo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _EntranceTransition(
                  animation: CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(
                      0.28,
                      0.72,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: _HomeModule(
                    icon: Icons.grid_view_rounded,
                    title: 'Gestión de parcelas',
                    description:
                        'Administra terrenos, responsables y coordenadas.',
                    status: 'Disponible',
                    onTap: () => widget.onOpenSection(1),
                  ),
                ),
                _EntranceTransition(
                  animation: CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(
                      0.38,
                      0.82,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: _HomeModule(
                    icon: Icons.location_on_outlined,
                    title: 'Mapa de parcelas',
                    description:
                        'Ubica y delimita los lotes directamente en el mapa.',
                    status: 'Disponible',
                    onTap: () => widget.onOpenSection(2),
                  ),
                ),
                _EntranceTransition(
                  animation: CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(
                      0.48,
                      0.92,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: _HomeModule(
                    icon: Icons.assignment_outlined,
                    title: 'Actividades y evidencias',
                    description:
                        'Registra labores y fotografías dentro de cada terreno.',
                    status: 'Por terreno',
                    onTap: () => widget.onOpenSection(1),
                  ),
                ),
                _EntranceTransition(
                  animation: CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(0.58, 1, curve: Curves.easeOutCubic),
                  ),
                  child: _HomeModule(
                    icon: Icons.eco_outlined,
                    title: 'Diagnóstico de banano',
                    description:
                        'Prepara el análisis preliminar de fotografías del cultivo.',
                    status: 'Próximamente',
                    onTap: () => widget.onOpenSection(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Cerrar sesión'),
        content: Text(
          '¿Deseas cerrar la sesión de '
          '${widget.authenticatedUser.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) await widget.onLogout();
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.user, required this.onLogout});

  final AuthenticatedUser user;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user.initials,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8FE0A8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Sesión conectada',
                      style: TextStyle(
                        color: Color(0xFFDCECE1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (user.accountIdentifier.isNotEmpty)
                  Text(
                    user.accountIdentifier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: onLogout,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFDCECE1), size: 20),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFFDCECE1))),
        ],
      ),
    );
  }
}

class _EntranceTransition extends StatelessWidget {
  const _EntranceTransition({
    required this.animation,
    required this.child,
    this.verticalOffset = 16,
  });

  final Animation<double> animation;
  final Widget child;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, verticalOffset * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

class _HomeModule extends StatelessWidget {
  const _HomeModule({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Disponible'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'Disponible'
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
