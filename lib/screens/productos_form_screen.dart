import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, required this.api, this.producto});
  final ApiService api;
  final Map<String, dynamic>? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _precioController;
  late final TextEditingController _skuController;
  
  int? _selectedCategoriaId;
  List<dynamic> _categorias = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto?['nombre'] ?? '');
    _descripcionController = TextEditingController(text: widget.producto?['descripcion'] ?? '');
    _precioController = TextEditingController(text: widget.producto?['precio']?.toString() ?? '');
    _skuController = TextEditingController(text: widget.producto?['sku'] ?? '');
    _selectedCategoriaId = widget.producto?['categoria'] as int?;
    
    _loadCategorias();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    try {
      final cats = await widget.api.getCategorias();
      setState(() {
        // Filter to only active categories (activa = true)
        _categorias = cats.where((c) => c['activa'] == true).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories for form: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar las categorías')),
        );
      }
    }
  }

  Future<void> _suggestSKU(int categoryId) async {
    final cat = _categorias.firstWhere((c) => c['id'] == categoryId, orElse: () => null);
    if (cat == null) return;
    
    final prefix = (cat['prefijo_sku'] ?? 'GEN').toString().toUpperCase().trim();
    
    setState(() {
      _isSaving = true; // Show loading temporarily during SKU suggestion
    });

    try {
      final productos = await widget.api.getProductos();
      int maxNumber = 0;
      
      for (var prod in productos) {
        final sku = (prod['sku'] ?? '').toString();
        if (sku.startsWith('$prefix-')) {
          final parts = sku.split('-');
          if (parts.length == 2) {
            final numPart = int.tryParse(parts[1]);
            if (numPart != null && numPart > maxNumber) {
              maxNumber = numPart;
            }
          }
        }
      }
      
      final nextNumber = maxNumber + 1;
      final numberStr = nextNumber.toString().padLeft(3, '0');
      
      if (mounted) {
        setState(() {
          _skuController.text = '$prefix-$numberStr';
          _isSaving = false;
        });
      }
    } catch (e) {
      debugPrint('Error suggesting SKU: $e');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final data = {
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'precio': double.tryParse(_precioController.text.trim()) ?? 0.0,
      'sku': _skuController.text.trim().toUpperCase(),
      'categoria': _selectedCategoriaId,
    };

    try {
      if (widget.producto == null) {
        await widget.api.createProducto(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado con éxito'),
              backgroundColor: Color(0xFF0F4C5C),
            ),
          );
        }
      } else {
        await widget.api.updateProducto(widget.producto!['id'], data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado con éxito'),
              backgroundColor: Color(0xFF0F4C5C),
            ),
          );
        }
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar producto: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.producto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F7A8C)))
          : SingleChildScrollView(
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
                              'Detalles del Producto',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 20),

                            // Name Field
                            TextFormField(
                              controller: _nombreController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del Producto',
                                prefixIcon: Icon(Icons.shopping_bag_outlined, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa el nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Category Selector
                            DropdownButtonFormField<int>(
                              value: _selectedCategoriaId,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                prefixIcon: Icon(Icons.category_outlined, size: 20),
                              ),
                              items: _categorias.map<DropdownMenuItem<int>>((cat) {
                                return DropdownMenuItem<int>(
                                  value: cat['id'],
                                  child: Text(cat['nombre'] ?? ''),
                                );
                              }).toList(),
                              onChanged: isEditing
                                  ? null // Disable changing category on edit if preferred or needed, but let's allow it if they want. Let's allow it.
                                  : (value) {
                                      setState(() {
                                        _selectedCategoriaId = value;
                                      });
                                      if (value != null) {
                                        _suggestSKU(value);
                                      }
                                    },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor selecciona una categoría';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // SKU Field (with autogenerate helper)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _skuController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'SKU',
                                      prefixIcon: Icon(Icons.qr_code_outlined, size: 20),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Por favor ingresa el SKU';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (!isEditing && _selectedCategoriaId != null) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 54,
                                    child: OutlinedButton(
                                      onPressed: _isSaving ? null : () => _suggestSKU(_selectedCategoriaId!),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        side: const BorderSide(color: Color(0xFF1F7A8C)),
                                      ),
                                      child: const Icon(Icons.auto_awesome, color: Color(0xFF1F7A8C)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Price Field
                            TextFormField(
                              controller: _precioController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                                hintText: '0.00',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa el precio';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price < 0) {
                                  return 'Por favor ingresa un precio válido positivo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Description Field
                            TextFormField(
                              controller: _descripcionController,
                              maxLines: 3,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Descripción',
                                prefixIcon: Icon(Icons.description_outlined, size: 20),
                                alignLabelWithHint: true,
                              ),
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
                          : const Text('Guardar Producto'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}