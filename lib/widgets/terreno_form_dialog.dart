import 'package:flutter/material.dart';

import '../models/terreno.dart';

Future<Terreno?> showTerrenoFormDialog(
  BuildContext context, {
  Terreno? terreno,
  double? latitud,
  double? longitud,
  List<PuntoBorde> limite = const [],
}) {
  return showDialog<Terreno>(
    context: context,
    builder: (context) => _TerrenoFormDialog(
      terreno: terreno,
      latitud: latitud,
      longitud: longitud,
      limite: limite,
    ),
  );
}

class _TerrenoFormDialog extends StatefulWidget {
  const _TerrenoFormDialog({
    this.terreno,
    this.latitud,
    this.longitud,
    this.limite = const [],
  });

  final Terreno? terreno;
  final double? latitud;
  final double? longitud;
  final List<PuntoBorde> limite;

  @override
  State<_TerrenoFormDialog> createState() => _TerrenoFormDialogState();
}

class _TerrenoFormDialogState extends State<_TerrenoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fincaNombreController;
  late final TextEditingController _fincaDescripcionController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _propietarioController;
  late final TextEditingController _latitudController;
  late final TextEditingController _longitudController;

  @override
  void initState() {
    super.initState();
    final terreno = widget.terreno;
    _fincaNombreController = TextEditingController(
      text: terreno == null
          ? ''
          : (terreno.fincaNombre.isNotEmpty
                ? terreno.fincaNombre
                : terreno.nombre),
    );
    _fincaDescripcionController = TextEditingController(
      text: terreno?.fincaDescripcion ?? '',
    );
    _nombreController = TextEditingController(text: terreno?.nombre ?? '');
    _descripcionController = TextEditingController(
      text: terreno?.descripcion ?? '',
    );
    _propietarioController = TextEditingController(
      text: terreno?.propietario ?? '',
    );
    _latitudController = TextEditingController(
      text: (terreno?.latitud ?? widget.latitud)?.toStringAsFixed(6) ?? '',
    );
    _longitudController = TextEditingController(
      text: (terreno?.longitud ?? widget.longitud)?.toStringAsFixed(6) ?? '',
    );
  }

  @override
  void dispose() {
    _fincaNombreController.dispose();
    _fincaDescripcionController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _propietarioController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.terreno != null;

    return AlertDialog(
      title: Text(editing ? 'Editar terreno' : 'Nuevo terreno'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fincaNombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la finca',
                    prefixIcon: Icon(Icons.agriculture_outlined),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _propietarioController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Propietario o responsable',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fincaDescripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la finca (opcional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Datos de la parcela',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del terreno',
                    prefixIcon: Icon(Icons.grid_view_outlined),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la parcela (opcional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _latitudController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitud'),
                  validator: (value) => _coordinateValidator(
                    value,
                    min: -90,
                    max: 90,
                    label: 'latitud',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _longitudController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitud'),
                  validator: (value) => _coordinateValidator(
                    value,
                    min: -180,
                    max: 180,
                    label: 'longitud',
                  ),
                ),
                if (!editing && widget.latitud == null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'También puedes tocar una ubicación en el mapa para completar las coordenadas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (!editing && widget.limite.length >= 3) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Se guardarán ${widget.limite.length} puntos para el borde del lote.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(editing ? 'Guardar cambios' : 'Crear terreno'),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _coordinateValidator(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    final parsed = _parseCoordinate(value);
    if (parsed == null) return 'Escribe una $label válida.';
    if (parsed < min || parsed > max) return 'La $label está fuera de rango.';
    return null;
  }

  double? _parseCoordinate(String? value) {
    return double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final original = widget.terreno;
    Navigator.pop(
      context,
      Terreno(
        id: original?.id,
        parcelaPublicId: original?.parcelaPublicId ?? '',
        nombre: _nombreController.text.trim(),
        propietario: _propietarioController.text.trim(),
        fincaNombre: _fincaNombreController.text.trim(),
        fincaDescripcion: _fincaDescripcionController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        latitud: _parseCoordinate(_latitudController.text)!,
        longitud: _parseCoordinate(_longitudController.text)!,
        creadoEn: original?.creadoEn ?? DateTime.now(),
        limite: original?.limite ?? widget.limite,
      ),
    );
  }
}
