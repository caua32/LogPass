import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 60);

  static Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (body is Map) {
        throw ApiException(body['message'] ?? body['mensagem'] ?? body['erro'] ?? 'Erro ${res.statusCode}');
      }
      throw ApiException('Erro ${res.statusCode}');
    }
    return body as Map<String, dynamic>;
  }

  static List<dynamic> _decodeList(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw ApiException(body['message'] ?? body['mensagem'] ?? body['erro'] ?? 'Erro ${res.statusCode}');
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Erro ${res.statusCode}');
      }
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['reclamacoes', 'data', 'items']) {
        if (decoded[key] is List) return decoded[key] as List;
      }
    }
    return [];
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String senha, String tipo) async {
    final res = await http
        .post(Uri.parse('$kBaseUrl/login'),
            headers: _headers(),
            body: jsonEncode({'email': email, 'senha': senha, 'tipo': tipo}))
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> registrar(
      String nome, String email, String senha, String tipo) async {
    final res = await http
        .post(Uri.parse('$kBaseUrl/registrar'),
            headers: _headers(),
            body: jsonEncode({'nome': nome, 'email': email, 'senha': senha, 'tipo': tipo}))
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getMe(String token) async {
    final res = await http
        .get(Uri.parse('$kBaseUrl/me'), headers: _headers(token: token))
        .timeout(_timeout);
    return _decode(res);
  }

  // Consumidor
  static Future<void> addConsumidor(String token, Map<String, dynamic> data) async {
    final res = await http
        .post(Uri.parse('$kBaseUrl/add-consumidor'),
            headers: _headers(token: token), body: jsonEncode(data))
        .timeout(_timeout);
    _decode(res);
  }

  static Future<Map<String, dynamic>> getConsumidorPerfil(String token) async {
    final res = await http
        .get(Uri.parse('$kBaseUrl/consumidor/perfil'), headers: _headers(token: token))
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<void> updateConsumidorPerfil(String token, Map<String, dynamic> data) async {
    final res = await http
        .put(Uri.parse('$kBaseUrl/consumidor/perfil'),
            headers: _headers(token: token), body: jsonEncode(data))
        .timeout(_timeout);
    _decode(res);
  }

  // Empresa
  static Future<void> addEmpresa(String token, Map<String, dynamic> data) async {
    final res = await http
        .post(Uri.parse('$kBaseUrl/add-empresa'),
            headers: _headers(token: token), body: jsonEncode(data))
        .timeout(_timeout);
    _decode(res);
  }

  static Future<Map<String, dynamic>> getEmpresaPerfil(String token) async {
    final res = await http
        .get(Uri.parse('$kBaseUrl/empresa/perfil'), headers: _headers(token: token))
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<void> updateEmpresaPerfil(String token, Map<String, dynamic> data) async {
    final res = await http
        .put(Uri.parse('$kBaseUrl/empresa/perfil'),
            headers: _headers(token: token), body: jsonEncode(data))
        .timeout(_timeout);
    _decode(res);
  }

  // Reclamaes
  static Future<Map<String, dynamic>> criarReclamacao(
      String token, Map<String, dynamic> data) async {
    final res = await http
        .post(Uri.parse('$kBaseUrl/reclamacao'),
            headers: _headers(token: token), body: jsonEncode(data))
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<List<dynamic>> getReclamacoesEmpresa(String token) async {
    final res = await http
        .get(Uri.parse('$kBaseUrl/reclamacao/empresa'), headers: _headers(token: token))
        .timeout(_timeout);
    return _decodeList(res);
  }

  static Future<List<dynamic>> getReclamacoesConsumidor(String token) async {
    final res = await http
        .get(Uri.parse('$kBaseUrl/reclamacao/consumidor'), headers: _headers(token: token))
        .timeout(_timeout);
    return _decodeList(res);
  }

  // Admin
  static Future<Map<String, dynamic>> adminLogin(String email, String senha) async {
    final res = await http
        .post(Uri.parse('$kBaseUrl/admin/login'),
            headers: _headers(),
            body: jsonEncode({'email': email, 'senha': senha}))
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<List<dynamic>> getAdminReclamacoes(String token) async {
    final res = await http
        .get(Uri.parse('$kBaseUrl/admin/reclamacoes'), headers: _headers(token: token))
        .timeout(_timeout);
    return _decodeList(res);
  }

  static Future<void> updateReclamacaoStatus(String token, int id, int idStatus) async {
    final res = await http
        .put(Uri.parse('$kBaseUrl/reclamacao/$id/status'),
            headers: _headers(token: token), body: jsonEncode({'status_id': idStatus}))
        .timeout(_timeout);
    _decode(res);
  }

  // Chat
  static Future<List<dynamic>> getMensagensChat(String token, int reclamacaoId) async {
    final res = await http
        .get(Uri.parse('$kBaseUrl/chat/$reclamacaoId'), headers: _headers(token: token))
        .timeout(_timeout);
    final body = _decode(res);
    return body['mensagens'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> enviarMensagemChat(
      String token, int reclamacaoId, String mensagem) async {
    final res = await http
        .post(Uri.parse('$kBaseUrl/chat/$reclamacaoId'),
            headers: _headers(token: token), body: jsonEncode({'mensagem': mensagem}))
        .timeout(_timeout);
    return _decode(res);
  }
}
