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

  const Reclamacao({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.idStatus,
    this.nomeEmpresa,
    this.nomeConsumidor,
    this.createdAt,
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
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      idStatus: json['id_status'] ?? json['status'] ?? 1,
      nomeEmpresa: json['nome_empresa'] ?? json['empresa'],
      nomeConsumidor: json['nome_consumidor'] ?? json['consumidor'],
      createdAt: json['created_at']?.toString(),
    );
  }
}
