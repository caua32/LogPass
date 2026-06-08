import '../core/constants.dart';
import 'package:flutter/material.dart';

class Reclamacao {
  final int id;
  final String titulo;
  final String descricao;
  final int idStatus;
  final String? nomeEmpresa;
  final String? nomeConsumidor;
  final String? createdAt;
  final int? avaliacao;
  final String? comentario;
  final String? ultimaRespostaEmpresa;
  final String? formaSolucao;

  const Reclamacao({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.idStatus,
    this.nomeEmpresa,
    this.nomeConsumidor,
    this.createdAt,
    this.avaliacao,
    this.comentario,
    this.ultimaRespostaEmpresa,
    this.formaSolucao,
  });

  String get statusNome => kStatusNomes[idStatus] ?? 'Desconhecido';

  Color get statusColor {
    switch (idStatus) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  factory Reclamacao.fromJson(Map<String, dynamic> json) {
    return Reclamacao(
      id: json['id'] ?? 0,
      titulo: json['numero_pedido'] ?? json['titulo'] ?? '',
      descricao: json['motivo'] ?? json['descricao'] ?? '',
      idStatus: _parseStatus(json),
      nomeEmpresa: json['nomeempresa'] ?? json['nome_empresa'] ?? json['empresa'],
      nomeConsumidor: json['consumidor_nome'] ?? json['nome_consumidor'] ?? json['consumidor'],
      createdAt: (json['data_abertura'] ?? json['created_at'])?.toString(),
      avaliacao: json['avaliacao'] as int?,
      comentario: json['comentario'] as String?,
      ultimaRespostaEmpresa: json['ultima_resposta_empresa']?.toString(),
      formaSolucao: json['forma_solucao'] as String?,
    );
  }

  static int _parseStatus(Map<String, dynamic> json) {
    final raw = json['status_id'] ?? json['id_status'] ?? json['status'];
    if (raw is int) return raw;
    if (raw is String) {
      const map = {'Pendente': 1, 'Em Análise': 2, 'Resolvida': 3, 'Não Resolvida': 4};
      return map[raw] ?? 1;
    }
    return 1;
  }
}
