import 'package:flutter/material.dart';

import '../models/terreno.dart';
import '../state/terreno_creation.dart';
import '../state/terreno_store.dart';
import '../widgets/terreno_form_dialog.dart';
import 'terreno_detalle_page.dart';

enum _TerrenoSort { recientes, nombre, propietario }

class TerrenosPage extends StatefulWidget {
  const TerrenosPage({
    super.key,
    required this.terrenoStore,
    required this.onShowOnMap,
    this.onCreateTerreno,
    this.onUpdateTerreno,
    this.onDeleteTerreno,
  });

  final TerrenoStore terrenoStore;
  final ValueChanged<Terreno> onShowOnMap;
  final TerrenoCreator? onCreateTerreno;
  final TerrenoUpdater? onUpdateTerreno;
  final TerrenoDeleter? onDeleteTerreno;

  @override
  State<TerrenosPage> createState() => _TerrenosPageState();
}

class _TerrenosPageState extends State<TerrenosPage> {
  String _query = '';
  _TerrenoSort _sort = _TerrenoSort.recientes;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: widget.terrenoStore,
        builder: (context, _) {
          final store = widget.terrenoStore;
          final terrenos = _filteredTerrenos(store.terrenos);

          return RefreshIndicator(
            onRefresh: store.cargar,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mis terrenos',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text('Parcelas registradas en AgroVida'),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _createTerreno,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            hintText: 'Buscar por terreno o propietario',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<_TerrenoSort>(
                          segments: const [
                            ButtonSegment(
                              value: _TerrenoSort.recientes,
                              label: Text('Recientes'),
                            ),
                            ButtonSegment(
                              value: _TerrenoSort.nombre,
                              label: Text('Nombre'),
                            ),
                            ButtonSegment(
                              value: _TerrenoSort.propietario,
                              label: Text('Propietario'),
                            ),
                          ],
                          selected: {_sort},
                          showSelectedIcon: false,
                          onSelectionChanged: (selected) {
                            setState(() => _sort = selected.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (store.cargando && store.terrenos.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (store.error != null)
                  SliverFillRemaining(
                    child: _MessageState(
                      icon: Icons.cloud_off_outlined,
                      title: store.error!,
                      actionLabel: 'Reintentar',
                      onAction: store.cargar,
                    ),
                  )
                else if (terrenos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: _query.isEmpty
                          ? Icons.grid_view_outlined
                          : Icons.search_off,
                      title: _query.isEmpty
                          ? 'Todavía no hay terrenos'
                          : 'No encontramos coincidencias',
                      description: _query.isEmpty
                          ? 'Agrega el primero desde aquí o tocando una ubicación en el mapa.'
                          : 'Prueba con otro nombre o propietario.',
                      actionLabel: _query.isEmpty ? 'Agregar terreno' : null,
                      onAction: _query.isEmpty ? _createTerreno : null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    sliver: SliverList.separated(
                      itemCount: terrenos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final terreno = terrenos[index];
                        return _TerrenoCard(
                          terreno: terreno,
                          onOpen: () => _openTerreno(terreno),
                          onShowOnMap: () => widget.onShowOnMap(terreno),
                          onEdit: () => _editTerreno(terreno),
                          onDelete: () => _deleteTerreno(terreno),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Terreno> _filteredTerrenos(List<Terreno> source) {
    final query = _query.trim().toLowerCase();
    final result = source.where((terreno) {
      return query.isEmpty ||
          terreno.nombre.toLowerCase().contains(query) ||
          terreno.propietario.toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case _TerrenoSort.nombre:
        result.sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );
      case _TerrenoSort.propietario:
        result.sort(
          (a, b) => a.propietario.toLowerCase().compareTo(
            b.propietario.toLowerCase(),
          ),
        );
      case _TerrenoSort.recientes:
        result.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    }
    return result;
  }

  Future<void> _createTerreno() async {
    final terreno = await showTerrenoFormDialog(context);
    if (terreno == null || !mounted) return;
    try {
      final creator = widget.onCreateTerreno;
      final result = creator == null
          ? await _crearSoloEnTelefono(terreno)
          : await creator(terreno);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la parcela.')),
      );
    }
  }

  Future<TerrenoCreationResult> _crearSoloEnTelefono(Terreno terreno) async {
    await widget.terrenoStore.crear(terreno);
    return const TerrenoCreationResult(
      isSuccess: true,
      message: 'Terreno guardado en el teléfono.',
    );
  }

  Future<void> _openTerreno(Terreno terreno) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => TerrenoDetallePage(terreno: terreno),
      ),
    );
  }

  Future<void> _editTerreno(Terreno terreno) async {
    final updated = await showTerrenoFormDialog(context, terreno: terreno);
    if (updated == null || !mounted) return;
    try {
      final updater = widget.onUpdateTerreno;
      final result = updater == null
          ? await _actualizarSoloEnTelefono(updated)
          : await updater(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la parcela.')),
      );
    }
  }

  Future<TerrenoUpdateResult> _actualizarSoloEnTelefono(Terreno terreno) async {
    await widget.terrenoStore.actualizar(terreno);
    return const TerrenoUpdateResult(
      isSuccess: true,
      message: 'Terreno actualizado.',
    );
  }

  Future<void> _deleteTerreno(Terreno terreno) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar terreno'),
        content: Text('¿Deseas eliminar “${terreno.nombre}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || terreno.id == null) return;

    try {
      final deleter = widget.onDeleteTerreno;
      final result = deleter == null
          ? await _eliminarSoloDelTelefono(terreno)
          : await deleter(terreno);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la parcela.')),
      );
    }
  }

  Future<TerrenoDeletionResult> _eliminarSoloDelTelefono(
    Terreno terreno,
  ) async {
    await widget.terrenoStore.eliminar(terreno.id!);
    return const TerrenoDeletionResult(
      isSuccess: true,
      message: 'Terreno eliminado.',
    );
  }
}

class _TerrenoCard extends StatelessWidget {
  const _TerrenoCard({
    required this.terreno,
    required this.onOpen,
    required this.onShowOnMap,
    required this.onEdit,
    required this.onDelete,
  });

  final Terreno terreno;
  final VoidCallback onOpen;
  final VoidCallback onShowOnMap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.grid_view_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          terreno.nombre,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${terreno.propietario}\n'
            '${terreno.latitud.toStringAsFixed(5)}, ${terreno.longitud.toStringAsFixed(5)}',
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              tooltip: 'Ver en mapa',
              onPressed: onShowOnMap,
              icon: const Icon(Icons.location_on_outlined),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
