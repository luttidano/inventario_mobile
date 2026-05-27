import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SucursalFormScreen extends StatefulWidget {
  const SucursalFormScreen({super.key, required this.api, this.sucursal});
  final ApiService api;
  final Map<String, dynamic>? sucursal;

  @override
  State<SucursalFormScreen> createState() => _SucursalFormScreenState();
}

class _SucursalFormScreenState extends State<SucursalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nombreController;
  late final TextEditingController _codigoController;
  late final TextEditingController _direccionController;
  bool _activa = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.sucursal?['nombre'] ?? '');
    _codigoController = TextEditingController(text: widget.sucursal?['codigo'] ?? '');
    _direccionController = TextEditingController(text: widget.sucursal?['direccion'] ?? '');
    _activa = widget.sucursal?['activa'] ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final data = {
      'nombre': _nombreController.text.trim(),
      'codigo': _codigoController.text.trim().toUpperCase(),
      'direccion': _direccionController.text.trim(),
      'activa': _activa,
    };

    try {
      if (widget.sucursal == null) {
        await widget.api.createSucursal(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sucursal creada con éxito'),
              backgroundColor: Color(0xFF0F4C5C),
            ),
          );
        }
      } else {
        await widget.api.updateSucursal(widget.sucursal!['id'], data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sucursal actualizada con éxito'),
              backgroundColor: Color(0xFF0F4C5C),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving branch: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar sucursal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sucursal != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(isEditing ? 'Editar Sucursal' : 'Nueva Sucursal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información de la Sucursal',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      TextFormField(
                        controller: _nombreController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.store_outlined, size: 20),
                          hintText: 'Ej. Sucursal Norte, Depósito Central',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Code Field
                      TextFormField(
                        controller: _codigoController,
                        maxLength: 10,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Código de Sucursal',
                          prefixIcon: Icon(Icons.pin_outlined, size: 20),
                          hintText: 'Ej. SUCNOR, DEPCEN',
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el código';
                          }
                          if (value.trim().length > 10) {
                            return 'El código debe tener máximo 10 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address Field
                      TextFormField(
                        controller: _direccionController,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Active Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sucursal Activa',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Habilitada para recibir stock',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Switch(
                            value: _activa,
                            activeColor: const Color(0xFF1F7A8C),
                            onChanged: (value) {
                              setState(() {
                                _activa = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Guardar Sucursal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}