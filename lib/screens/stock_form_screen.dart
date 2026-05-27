import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StockFormScreen extends StatefulWidget {
  const StockFormScreen({super.key, required this.api, this.stock});
  final ApiService api;
  final Map<String, dynamic>? stock;

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _cantidadController;
  int? _selectedProductoId;
  int? _selectedSucursalId;

  List<dynamic> _productos = [];
  List<dynamic> _sucursales = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(
      text: widget.stock?['cantidad']?.toString() ?? '',
    );
    _selectedProductoId = widget.stock?['producto'] as int?;
    _selectedSucursalId = widget.stock?['sucursal'] as int?;

    _loadData();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        widget.api.getProductos(),
        widget.api.getSucursales(),
      ]);

      setState(() {
        _productos = results[0];
        // Filter to active branches
        _sucursales = results[1].where((b) => b['activa'] == true).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading form data for stock: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar productos o sucursales')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final qty = int.tryParse(_cantidadController.text.trim()) ?? 0;
    
    final data = {
      'producto': _selectedProductoId,
      'sucursal': _selectedSucursalId,
      'cantidad': qty,
    };

    try {
      if (widget.stock == null) {
        await widget.api.createStock(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock registrado con éxito'),
              backgroundColor: Color(0xFF0F4C5C),
            ),
          );
        }
      } else {
        await widget.api.updateStock(widget.stock!['id'], data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock actualizado con éxito'),
              backgroundColor: Color(0xFF0F4C5C),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving stock: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar stock: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.stock != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Stock' : 'Registrar Stock'),
      ),
      body: _isLoading
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
                              'Detalles del Inventario',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 20),

                            // Product Dropdown
                            DropdownButtonFormField<int>(
                              value: _selectedProductoId,
                              decoration: const InputDecoration(
                                labelText: 'Producto',
                                prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                              ),
                              items: _productos.map<DropdownMenuItem<int>>((prod) {
                                return DropdownMenuItem<int>(
                                  value: prod['id'],
                                  child: Text(prod['nombre'] ?? ''),
                                );
                              }).toList(),
                              onChanged: isEditing
                                  ? null // Cannot change product when editing existing stock entry
                                  : (value) {
                                      setState(() {
                                        _selectedProductoId = value;
                                      });
                                    },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor selecciona un producto';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Branch Dropdown
                            DropdownButtonFormField<int>(
                              value: _selectedSucursalId,
                              decoration: const InputDecoration(
                                labelText: 'Sucursal',
                                prefixIcon: Icon(Icons.store_outlined, size: 20),
                              ),
                              items: _sucursales.map<DropdownMenuItem<int>>((branch) {
                                return DropdownMenuItem<int>(
                                  value: branch['id'],
                                  child: Text(branch['nombre'] ?? ''),
                                );
                              }).toList(),
                              onChanged: isEditing
                                  ? null // Cannot change branch when editing existing stock entry
                                  : (value) {
                                      setState(() {
                                        _selectedSucursalId = value;
                                      });
                                    },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor selecciona una sucursal';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Quantity Text Field
                            TextFormField(
                              controller: _cantidadController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad de Stock',
                                prefixIcon: Icon(Icons.numbers_rounded, size: 20),
                                hintText: 'Ej. 10, 50, 100',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa la cantidad';
                                }
                                final qty = int.tryParse(value);
                                if (qty == null || qty < 0) {
                                  return 'Por favor ingresa un número entero positivo';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
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
                          : const Text('Guardar Existencia'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}