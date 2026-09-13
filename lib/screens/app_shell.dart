import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data/auth_repository.dart';
import '../data/parcela_repository.dart';
import '../models/terreno.dart';
import '../state/terreno_creation.dart';
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
    this.parcelaRepository,
    this.mapTileProviderFactory,
  });

  final TerrenoStore terrenoStore;
  final bool ownsStore;
  final AuthenticatedUser authenticatedUser;
  final Future<void> Function() onLogout;
  final ParcelaRepository? parcelaRepository;
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
        onCreateTerreno: _crearTerreno,
        onUpdateTerreno: _editarTerreno,
        onDeleteTerreno: _eliminarTerreno,
      ),
      2 => MapaPage(
        terrenoStore: widget.terrenoStore,
        terrenoInicial: _terrenoParaMapa,
        tileProviderFactory: widget.mapTileProviderFactory,
        onCreateTerreno: _crearTerreno,
        onUpdateTerreno: _editarTerreno,
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

  Future<TerrenoCreationResult> _crearTerreno(Terreno terreno) async {
    final parcelas = widget.parcelaRepository;
    if (parcelas == null) {
      await widget.terrenoStore.crear(terreno);
      return const TerrenoCreationResult(
        isSuccess: true,
        message: 'Terreno guardado en el teléfono.',
      );
    }

    final workerPublicId = widget.authenticatedUser.workerPublicId;
    if (workerPublicId.isEmpty) {
      return const TerrenoCreationResult(
        isSuccess: false,
        message:
            'Esta sesión no tiene el identificador del trabajador. Cierra sesión y vuelve a ingresar.',
      );
    }

    final remoteResult = await parcelas.crear(
      workerPublicId: workerPublicId,
      terreno: terreno,
    );
    if (!remoteResult.isSuccess) {
      return TerrenoCreationResult(
        isSuccess: false,
        message: remoteResult.message ?? 'No se pudo registrar la parcela.',
      );
    }

    try {
      await widget.terrenoStore.crear(
        terreno.copyWith(parcelaPublicId: remoteResult.parcelaPublicId),
      );
      if (remoteResult.parcelaPublicId.isEmpty) {
        return const TerrenoCreationResult(
          isSuccess: true,
          message:
              'La parcela se registró, pero el servidor no devolvió parcela_public_id. No podrá eliminarse desde la app todavía.',
        );
      }
      return TerrenoCreationResult(
        isSuccess: true,
        message: remoteResult.message ?? 'Parcela registrada correctamente.',
      );
    } catch (_) {
      return const TerrenoCreationResult(
        isSuccess: true,
        message:
            'La parcela se registró en el servidor, pero no se pudo guardar la copia del teléfono.',
      );
    }
  }

  Future<TerrenoDeletionResult> _eliminarTerreno(Terreno terreno) async {
    final localId = terreno.id;
    if (localId == null) {
      return const TerrenoDeletionResult(
        isSuccess: false,
        message: 'No se encontró el identificador local de la parcela.',
      );
    }

    final parcelas = widget.parcelaRepository;
    if (parcelas == null) {
      await widget.terrenoStore.eliminar(localId);
      return const TerrenoDeletionResult(
        isSuccess: true,
        message: 'Terreno eliminado.',
      );
    }

    final workerPublicId = widget.authenticatedUser.workerPublicId;
    if (workerPublicId.isEmpty) {
      return const TerrenoDeletionResult(
        isSuccess: false,
        message:
            'Esta sesión no tiene el identificador del trabajador. Cierra sesión y vuelve a ingresar.',
      );
    }
    if (terreno.parcelaPublicId.isEmpty) {
      return const TerrenoDeletionResult(
        isSuccess: false,
        message:
            'Esta parcela fue guardada antes de recibir su identificador del servidor. No se puede eliminar desde la app todavía.',
      );
    }

    final remoteResult = await parcelas.eliminar(
      workerPublicId: workerPublicId,
      parcelaPublicId: terreno.parcelaPublicId,
    );
    if (!remoteResult.isSuccess) {
      return TerrenoDeletionResult(
        isSuccess: false,
        message: remoteResult.message ?? 'No se pudo eliminar la parcela.',
      );
    }

    try {
      await widget.terrenoStore.eliminar(localId);
      return TerrenoDeletionResult(
        isSuccess: true,
        message: remoteResult.message ?? 'Parcela eliminada correctamente.',
      );
    } catch (_) {
      return const TerrenoDeletionResult(
        isSuccess: true,
        message:
            'La parcela se eliminó del servidor, pero no se pudo borrar la copia del teléfono.',
      );
    }
  }

  Future<TerrenoUpdateResult> _editarTerreno(Terreno terreno) async {
    final localId = terreno.id;
    if (localId == null) {
      return const TerrenoUpdateResult(
        isSuccess: false,
        message: 'No se encontró el identificador local de la parcela.',
      );
    }

    final parcelas = widget.parcelaRepository;
    if (parcelas == null) {
      await widget.terrenoStore.actualizar(terreno);
      return const TerrenoUpdateResult(
        isSuccess: true,
        message: 'Terreno actualizado.',
      );
    }

    final workerPublicId = widget.authenticatedUser.workerPublicId;
    if (workerPublicId.isEmpty) {
      return const TerrenoUpdateResult(
        isSuccess: false,
        message:
            'Esta sesión no tiene el identificador del trabajador. Cierra sesión y vuelve a ingresar.',
      );
    }
    if (terreno.parcelaPublicId.isEmpty) {
      return const TerrenoUpdateResult(
        isSuccess: false,
        message:
            'Esta parcela fue guardada antes de recibir su identificador del servidor. No se puede editar desde la app todavía.',
      );
    }

    final remoteResult = await parcelas.editar(
      workerPublicId: workerPublicId,
      parcelaPublicId: terreno.parcelaPublicId,
      terreno: terreno,
    );
    if (!remoteResult.isSuccess) {
      return TerrenoUpdateResult(
        isSuccess: false,
        message: remoteResult.message ?? 'No se pudo actualizar la parcela.',
      );
    }

    try {
      await widget.terrenoStore.actualizar(terreno);
      return TerrenoUpdateResult(
        isSuccess: true,
        message: remoteResult.message ?? 'Parcela actualizada correctamente.',
      );
    } catch (_) {
      return const TerrenoUpdateResult(
        isSuccess: true,
        message:
            'La parcela se actualizó en el servidor, pero no se pudo actualizar la copia del teléfono.',
      );
    }
  }
}
