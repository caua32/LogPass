import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ChatNotificationBell extends StatefulWidget {
  final String token;
  const ChatNotificationBell({super.key, required this.token});

  @override
  State<ChatNotificationBell> createState() => _ChatNotificationBellState();
}

class _ChatNotificationBellState extends State<ChatNotificationBell> {
  static const _cyan = Color(0xFF44CABD);
  static const _red  = Color(0xFFFF6B6B);
  static const _card = Color(0xFF0D2137);

  List<Map<String, dynamic>> _notificacoes = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final lista = await ApiService.getChatNotificacoes(widget.token);
      final prefs = await SharedPreferences.getInstance();

      final novas = lista
          .map((e) => e as Map<String, dynamic>)
          .where((n) {
            final id = n['reclamacao_id'];
            final createdAt = n['created_at']?.toString() ?? '';
            final visto = prefs.getString('chat_seen_$id');
            if (visto == null) return true;
            // Compara via DateTime para ser imune a diferenças de precisão
            final dtMsg   = DateTime.tryParse(createdAt);
            final dtVisto = DateTime.tryParse(visto);
            if (dtMsg == null || dtVisto == null) return true;
            return dtMsg.isAfter(dtVisto);
          })
          .toList();

      if (mounted) setState(() => _notificacoes = novas);
    } catch (_) {
      // silencioso — não interrompe o dashboard
    }
  }

  Future<void> _marcarComoVisto(List<Map<String, dynamic>> notifs) async {
    final prefs = await SharedPreferences.getInstance();
    // Salva o momento atual como referência — imune a variações de formato do backend
    final agora = DateTime.now().toUtc().toIso8601String();
    for (final n in notifs) {
      final id = n['reclamacao_id'];
      await prefs.setString('chat_seen_$id', agora);
    }
  }

  Future<void> _abrirPainel() async {
    final snapshot = List<Map<String, dynamic>>.from(_notificacoes);
    // Aguarda o save completar antes de limpar o badge
    await _marcarComoVisto(snapshot);
    if (!mounted) return;
    setState(() => _notificacoes = []);

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PainelNotificacoes(
        notificacoes: snapshot,
        onIrParaConversa: (reclamacaoId, numeroPedido) {
          Navigator.pop(context);
          context.push(
            '/chat/$reclamacaoId',
            extra: {'titulo': numeroPedido},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _notificacoes.length;
    return GestureDetector(
      onTap: _abrirPainel,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: _cyan.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.support_agent_rounded, color: _cyan, size: 20),
            if (count > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: _red, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PainelNotificacoes extends StatelessWidget {
  final List<Map<String, dynamic>> notificacoes;
  final void Function(int reclamacaoId, String numeroPedido) onIrParaConversa;

  const _PainelNotificacoes({
    required this.notificacoes,
    required this.onIrParaConversa,
  });

  static const _cyan = Color(0xFF44CABD);
  static const _card = Color(0xFF0D2137);
  static const _bg   = Color(0xFF0A1929);

  String _labelRemetente(String tipo) {
    switch (tipo) {
      case 'empresa':    return 'Empresa';
      case 'consumidor': return 'Consumidor';
      case 'admin':      return 'Suporte';
      default:           return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = notificacoes.isEmpty;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: isEmpty ? 0.38 : 0.65,
      minChildSize: 0.28,
      maxChildSize: 0.90,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Cabeçalho
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: _cyan, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mensagens Novas',
                  style: TextStyle(
                      color: Color(0xFFE8F8F7),
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (!isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _cyan.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '${notificacoes.length}',
                    style: const TextStyle(
                        color: _cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ]),
          ),

          const Divider(color: Color(0xFF1A3A55), height: 1, thickness: 1),

          // Conteúdo
          Expanded(
            child: isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_chat_read_outlined,
                            size: 52,
                            color: _cyan.withValues(alpha: 0.25)),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma mensagem nova',
                          style: TextStyle(
                              color: Color(0xFFCCEEEC),
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Todas as conversas estão em dia',
                          style: TextStyle(
                              color: _cyan.withValues(alpha: 0.45),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    itemCount: notificacoes.length,
                    itemBuilder: (_, i) {
                      final n = notificacoes[i];
                      final reclamacaoId = n['reclamacao_id'] as int;
                      final numeroPedido =
                          (n['numero_pedido'] ?? 'Pedido #$reclamacaoId')
                              .toString();
                      final mensagem = (n['mensagem'] ?? '').toString();
                      final tipo =
                          (n['remetente_tipo'] ?? '').toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _cyan.withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Número do pedido + tipo
                              Row(children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 15,
                                    color: _cyan.withValues(alpha: 0.6)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    numeroPedido,
                                    style: const TextStyle(
                                        color: _cyan,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _cyan.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: _cyan.withValues(alpha: 0.25)),
                                  ),
                                  child: Text(
                                    _labelRemetente(tipo),
                                    style: TextStyle(
                                        color: _cyan.withValues(alpha: 0.8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ]),

                              const SizedBox(height: 12),

                              // Mensagem
                              Text(
                                mensagem,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: _cyan.withValues(alpha: 0.75),
                                    fontSize: 14,
                                    height: 1.45),
                              ),

                              const SizedBox(height: 16),

                              // Botão
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () => onIrParaConversa(
                                      reclamacaoId, numeroPedido),
                                  icon: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 16),
                                  label: const Text(
                                    'Ir para conversa',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cyan,
                                    foregroundColor: _card,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SafeArea(
            top: false,
            child: const SizedBox(height: 8),
          ),
        ],
      ),
    );
  }
}
