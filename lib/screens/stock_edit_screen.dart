import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StockEditScreen extends StatefulWidget {
  const StockEditScreen({
    super.key,
    required this.api,
    required this.productoId,
    required this.productoNombre,
    required this.stockId,
    required this.cantidadActual,
  });

  final ApiService api;
  final int productoId;
  final String productoNombre;
  final int? stockId;
  final int cantidadActual;

  @override
  State<StockEditScreen> createState() => _StockEditScreenState();
}

class _StockEditScreenState extends State<StockEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cantidadActual.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final cantidad = int.tryParse(_controller.text) ?? 0;
    
    try {
      await widget.api.upsertStock(
        productoId: widget.productoId,
        stockId: widget.stockId,
        cantidad: cantidad,
      );
      
      if (!mounted) return;
      setState(() => _saving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Existencias actualizadas con éxito'),
          backgroundColor: Color(0xFF0F4C5C),
        ),
      );
      
      Navigator.of(context).pop(cantidad);
    } catch (e) {
      debugPrint('Error updating stock: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar existencias: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Editar Existencias'),
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
                        widget.productoNombre,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              color: const Color(0xFF0F4C5C),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ajustar la cantidad de stock físico disponible.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),

                      // Quantity Input Field
                      TextFormField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad Física',
                          prefixIcon: Icon(Icons.numbers_rounded, size: 20),
                          hintText: '0',
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

              // Save Button
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Actualizar Stock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}