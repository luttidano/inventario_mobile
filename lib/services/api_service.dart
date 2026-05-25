import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'auth_service.dart';

class ApiService {
  ApiService(this._authService);
  final AuthService _authService;

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$apiBaseUrl$path');
    final token = await _authService.getAccessToken();

    http.Response response;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (method == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(url, headers: headers, body: jsonEncode(body));
    } else if (method == 'PATCH') {
      response = await http.patch(url, headers: headers, body: jsonEncode(body));
    } else if (method == 'DELETE') {
      response = await http.delete(url, headers: headers);
    } else {
      throw Exception('Metodo no soportado');
    }

    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (!refreshed) return response;

      final newToken = await _authService.getAccessToken();
      final retryHeaders = <String, String>{
        'Content-Type': 'application/json',
        if (newToken != null) 'Authorization': 'Bearer $newToken',
      };

      if (method == 'GET') {
        response = await http.get(url, headers: retryHeaders);
      } else if (method == 'POST') {
        response = await http.post(url, headers: retryHeaders, body: jsonEncode(body));
      } else if (method == 'PATCH') {
        response = await http.patch(url, headers: retryHeaders, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: retryHeaders);
      }
    }

    return response;
  }

  Future<List<dynamic>> getProductos() async {
    final res = await _request('GET', '/api/productos/');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al listar productos');
  }

  Future<List<dynamic>> getStocks() async {
    final res = await _request('GET', '/api/stocks/');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al listar stocks');
  }

  Future<void> upsertStock({
    required int productoId,
    required int? stockId,
    required int cantidad,
  }) async {
    if (stockId == null) {
      final res = await _request('POST', '/api/stocks/', body: {
        'producto': productoId,
        'sucursal': defaultSucursalId,
        'cantidad': cantidad,
      });
      if (res.statusCode != 201) {
        throw Exception('Error al crear stock');
      }
    } else {
      final res = await _request('PATCH', '/api/stocks/$stockId/', body: {
        'cantidad': cantidad,
      });
      if (res.statusCode != 200) {
        throw Exception('Error al actualizar stock');
      }
    }
  }

  Future<Map<String, dynamic>> createProducto(Map<String, dynamic> data) async {
    final res = await _request('POST', '/api/productos/', body: data);
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Error al crear producto');
  }

  Future<void> updateProducto(int id, Map<String, dynamic> data) async {
    final res = await _request('PATCH', '/api/productos/$id/', body: data);
    if (res.statusCode != 200) throw Exception('Error al actualizar producto');
  }

  Future<void> deleteProducto(int id) async {
    final res = await _request('DELETE', '/api/productos/$id/');
    if (res.statusCode != 204) throw Exception('Error al eliminar producto');
  }

  Future<List<dynamic>> getCategorias() async {
    final res = await _request('GET', '/api/categorias/');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al listar categorias');
  }

  Future<void> createCategoria(Map<String, dynamic> data) async {
    final res = await _request('POST', '/api/categorias/', body: data);
    if (res.statusCode != 201) throw Exception('Error al crear categoria');
  }

  Future<void> updateCategoria(int id, Map<String, dynamic> data) async {
    final res = await _request('PATCH', '/api/categorias/$id/', body: data);
    if (res.statusCode != 200) throw Exception('Error al actualizar categoria');
  }

  Future<void> deleteCategoria(int id) async {
    final res = await _request('DELETE', '/api/categorias/$id/');
    if (res.statusCode != 204) throw Exception('Error al eliminar categoria');
  }
  Future<Map<String, dynamic>> getMe() async {
    final res = await _request('GET', '/api/auth/me/');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener usuario: ${res.statusCode} ${res.body}');
  }
  Future<void> createStock(Map<String, dynamic> data) async {
    final res = await _request('POST', '/api/stocks/', body: data);
    if (res.statusCode != 201) throw Exception('Error al crear stock');
  }

  Future<void> updateStock(int id, Map<String, dynamic> data) async {
    final res = await _request('PATCH', '/api/stocks/$id/', body: data);
    if (res.statusCode != 200) throw Exception('Error al actualizar stock');
  }

  Future<void> deleteStock(int id) async {
    final res = await _request('DELETE', '/api/stocks/$id/');
    if (res.statusCode != 204) throw Exception('Error al eliminar stock');
  }

  Future<List<dynamic>> getSucursales() async {
    final res = await _request('GET', '/api/sucursales/');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al listar sucursales');
  }

  Future<void> createSucursal(Map<String, dynamic> data) async {
    final res = await _request('POST', '/api/sucursales/', body: data);
    if (res.statusCode != 201) throw Exception('Error al crear sucursal');
  }

  Future<void> updateSucursal(int id, Map<String, dynamic> data) async {
    final res = await _request('PATCH', '/api/sucursales/$id/', body: data);
    if (res.statusCode != 200) throw Exception('Error al actualizar sucursal');
  }

  Future<void> deleteSucursal(int id) async {
    final res = await _request('DELETE', '/api/sucursales/$id/');
    if (res.statusCode != 204) throw Exception('Error al eliminar sucursal');
  }
}