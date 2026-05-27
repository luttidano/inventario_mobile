import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoriaFormScreen extends StatefulWidget {
  const CategoriaFormScreen({super.key, required this.api, this.categoria});
  final ApiService api;
  final Map<String, dynamic>? categoria;

  @override
  State<CategoriaFormScreen> createState() => _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends State<CategoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _prefijo;
  bool _activa = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.categoria?['nombre'] ?? '');
    _prefijo = TextEditingController(text: widget.categoria?['prefijo_sku'] ?? '');
    _activa = widget.categoria?['activa'] ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _prefijo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final data = {
      'nombre': _nombre.text.trim(),
      'prefijo_sku': _prefijo.text.trim().toUpperCase(),
      'activa': _activa,
    };

    try {
      if (widget.categoria == null) {
        await widget.api.createCategoria(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría creada con éxito'),
              backgroundColor: Color(0xFF0F4C5C),
            ),
          );
        }
      } else {
        await widget.api.updateCategoria(widget.categoria!['id'], data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría actualizada con éxito'),
              backgroundColor: Color(0xFF0F4C5C),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving category: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar categoría: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoria != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
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
                        'Información de la Categoría',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),

                      // Nombre Field
                      TextFormField(
                        controller: _nombre,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.bookmark_outline_rounded, size: 20),
                          hintText: 'Ej. Electrónica, Alimentos',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Prefijo SKU Field
                      TextFormField(
                        controller: _prefijo,
                        maxLength: 5,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Prefijo SKU',
                          prefixIcon: Icon(Icons.text_fields_rounded, size: 20),
                          hintText: 'Ej. ELEC, ALIM',
                          counterText: '', // Hide standard character counter for cleaner look
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el prefijo SKU';
                          }
                          if (value.trim().length > 5) {
                            return 'El prefijo debe tener máximo 5 caracteres';
                          }
                          return null;
                        },
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
                                'Categoría Activa',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Permite asociar nuevos productos',
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
                    : const Text('Guardar Categoría'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}