import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data/auth_repository.dart';
import '../models/terreno.dart';
import '../state/terreno_store.dart';
import 'diagnostico_page.dart';
import 'inicio_page.dart';
import 'mapa_page.dart';
import 'terrenos_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.terrenoStore,
    required this.ownsStore,
    required this.authenticatedUser,
    required this.onLogout,
    this.mapTileProviderFactory,
  });

  final TerrenoStore terrenoStore;
  final bool ownsStore;
  final AuthenticatedUser authenticatedUser;
  final VoidCallback onLogout;
  final TileProvider Function()? mapTileProviderFactory;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
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

  int _selectedIndex = 0;
  Terreno? _terrenoParaMapa;

  @override
  void initState() {
    super.initState();
    widget.terrenoStore.cargar();
  }

  @override
  void dispose() {
    if (widget.ownsStore) widget.terrenoStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selectedIndex) {
      0 => InicioPage(
        terrenoStore: widget.terrenoStore,
        onOpenSection: _selectSection,
        authenticatedUser: widget.authenticatedUser,
        onLogout: widget.onLogout,
      ),
      1 => TerrenosPage(
        terrenoStore: widget.terrenoStore,
        onShowOnMap: _showTerrenoOnMap,
      ),
      2 => MapaPage(
        terrenoStore: widget.terrenoStore,
        terrenoInicial: _terrenoParaMapa,
        tileProviderFactory: widget.mapTileProviderFactory,
      ),
      _ => const DiagnosticoPage(),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiStyle,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            reverseDuration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final scale = Tween<double>(
                begin: 0.985,
                end: 1,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            child: KeyedSubtree(key: ValueKey(_selectedIndex), child: page),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          maintainBottomViewPadding: true,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectSection,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Terrenos',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on),
              label: 'Mapa',
            ),
            NavigationDestination(
              icon: Icon(Icons.eco_outlined),
              selectedIcon: Icon(Icons.eco),
              label: 'Diagnóstico',
            ),
          ],
        ),
      ),
    );
  }

  void _selectSection(int index) {
    setState(() {
      _selectedIndex = index;
      _terrenoParaMapa = null;
    });
  }

  void _showTerrenoOnMap(Terreno terreno) {
    setState(() {
      _terrenoParaMapa = terreno;
      _selectedIndex = 2;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Mostrando “${terreno.nombre}” en el mapa.')),
      );
  }
}
