import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/reclamacao_model.dart';
import '../../services/api_service.dart';
import '../../services/admin_auth_service.dart';
import '../../core/constants.dart';

class AdminReclamacaoDetailPage extends StatefulWidget {
  final Reclamacao reclamacao;
  const AdminReclamacaoDetailPage({super.key, required this.reclamacao});

  @override
  State<AdminReclamacaoDetailPage> createState() =>
      _AdminReclamacaoDetailPageState();
}

class _AdminReclamacaoDetailPageState
    extends State<AdminReclamacaoDetailPage> {
  static const _bg    = Color(0xFF0A1929);
  static const _dark  = Color(0xFF0D2137);
  static const _card  = Color(0xFF1A3558);
  static const _cyan  = Color(0xFF44CABD);

  late Reclamacao _rec;
  String? _token;

  List<Map<String, dynamic>> _mensagens = [];
  bool _loadingChat = true;
  bool _enviando = false;
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _rec = widget.reclamacao;
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _token = await AdminAuthService.getToken();
    await _carregarMensagens();
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => _carregarMensagens());
  }

  Future<void> _carregarMensagens() async {
    if (_token == null) return;
    try {
      final lista = await ApiService.getMensagensChat(_token!, _rec.id);
      if (mounted) {
        setState(() {
          _mensagens = lista.map((e) => e as Map<String, dynamic>).toList();
          _loadingChat = false;
        });
        _scrollFim();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingChat = false);
    }
  }

  void _scrollFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty || _token == null || _enviando) return;
    setState(() => _enviando = true);
    try {
      await ApiService.enviarMensagemChat(_token!, _rec.id, texto);
      _msgCtrl.clear();
      await _carregarMensagens();
    } catch (_) {} finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _confirmarEAlterar(int novoStatus) {
    final comentarioCtrl = TextEditingController();
    final nomeStatus = kStatusNomes[novoStatus] ?? 'novo status';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: _dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Alterar para "$nomeStatus"',
          style: const TextStyle(
              color: _cyan, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comentário para o solicitante (opcional)',
                style: TextStyle(
                    color: _cyan.withOpacity(0.65), fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: comentarioCtrl,
              maxLines: 3,
              style: const TextStyle(
                  color: Color(0xFFE0F7F5), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ex: Estamos analisando seu caso...',
                hintStyle: TextStyle(
                    color: _cyan.withOpacity(0.35), fontSize: 12),
                filled: true,
                fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: _cyan.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: _cyan.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: _cyan.withOpacity(0.6)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: _cyan.withOpacity(0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              foregroundColor: _bg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () {
              final comentario = comentarioCtrl.text.trim();
              Navigator.pop(ctx);
              _alterarStatus(novoStatus, comentario: comentario);
            },
            child: const Text('Confirmar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _alterarStatus(int novoStatus, {String comentario = ''}) async {
    if (_token == null) return;
    try {
      await ApiService.updateReclamacaoStatus(_token!, _rec.id, novoStatus);

      // Envia mensagem no chat com o status e comentário (ou mensagem automática)
      final nomeStatus = kStatusNomes[novoStatus] ?? '';
      final msgChat = comentario.isNotEmpty
          ? '🔄 Status alterado para "$nomeStatus".\n\n$comentario'
          : '🔄 Status alterado para "$nomeStatus".';
      await ApiService.enviarMensagemChat(_token!, _rec.id, msgChat);

      if (mounted) {
        setState(() {
          _rec = Reclamacao(
            id: _rec.id,
            titulo: _rec.titulo,
            descricao: _rec.descricao,
            idStatus: novoStatus,
            nomeEmpresa: _rec.nomeEmpresa,
            nomeConsumidor: _rec.nomeConsumidor,
            createdAt: _rec.createdAt,
          );
        });
        await _carregarMensagens();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline,
                  color: Color(0xFF0A1929), size: 16),
              const SizedBox(width: 8),
              Text('Status → $nomeStatus'),
            ]),
            backgroundColor: _cyan,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ));
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao alterar status. Tente novamente.'),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Color _statusColor(int s) {
    switch (s) {
      case 1: return Colors.orange;
      case 2: return Colors.blueAccent;
      case 3: return Colors.green;
      case 4: return const Color(0xFFFF6B6B);
      default: return Colors.grey;
    }
  }

  bool _eMinha(Map<String, dynamic> m) =>
      (m['remetente_tipo'] as String? ?? '') == 'admin';

  String _hora(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_rec.idStatus);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: _cyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _cyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_rec.titulo,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                _rec.statusNome,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _cyan.withOpacity(0.15)),
        ),
      ),
      body: Column(
        children: [
          _buildInfoCard(),
          _buildStatusSection(),
          _buildChatDivider(),
          Expanded(child: _buildChat()),
          _buildInput(),
        ],
      ),
    );
  }

  // ─── Seção de informações ────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo colorido com gradiente sutil
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cyan.withOpacity(0.10),
                  _cyan.withOpacity(0.02),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                  bottom: BorderSide(color: _cyan.withOpacity(0.12))),
            ),
            child: Row(
              children: [
                if (_rec.nomeEmpresa != null) ...[
                  Icon(Icons.business_outlined,
                      size: 15, color: _cyan.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_rec.nomeEmpresa!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _cyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
                if (_rec.nomeConsumidor != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.person_outline,
                      size: 15, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(_rec.nomeConsumidor!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          // Motivo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Text(
              _rec.descricao,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Botões de status ────────────────────────────────────────────────────

  Widget _buildStatusSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.tune_outlined, size: 14, color: _cyan.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text('ALTERAR STATUS',
                style: TextStyle(
                    color: _cyan.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 10),
          Row(
            children: kStatusNomes.entries.map((e) {
              final isActive = _rec.idStatus == e.key;
              final color = _statusColor(e.key);
              return Expanded(
                child: GestureDetector(
                  onTap: isActive ? null : () => _confirmarEAlterar(e.key),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: e.key < kStatusNomes.length ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withOpacity(0.22)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? color : color.withOpacity(0.3),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isActive ? color : color.withOpacity(0.4),
                          size: 14,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isActive ? color : color.withOpacity(0.55),
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Divisor Chat ────────────────────────────────────────────────────────

  Widget _buildChatDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: Container(height: 1, color: _cyan.withOpacity(0.12))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Icon(Icons.chat_bubble_outline,
                  size: 12, color: _cyan.withOpacity(0.45)),
              const SizedBox(width: 5),
              Text('MENSAGENS',
                  style: TextStyle(
                      color: _cyan.withOpacity(0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
            ]),
          ),
          Expanded(
              child: Container(height: 1, color: _cyan.withOpacity(0.12))),
        ],
      ),
    );
  }

  // ─── Chat ────────────────────────────────────────────────────────────────

  Widget _buildChat() {
    if (_loadingChat) {
      return const Center(
          child:
              CircularProgressIndicator(color: _cyan, strokeWidth: 2));
    }
    if (_mensagens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 40, color: _cyan.withOpacity(0.2)),
            const SizedBox(height: 10),
            Text('Sem mensagens ainda',
                style: TextStyle(
                    color: _cyan.withOpacity(0.4), fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _mensagens.length,
      itemBuilder: (_, i) => _buildBolha(_mensagens[i]),
    );
  }

  Widget _buildBolha(Map<String, dynamic> m) {
    final minha = _eMinha(m);
    final nome  = (m['remetente_nome'] as String?) ?? 'Admin';
    final texto = (m['mensagem'] as String?) ?? '';
    final hora  = _hora(m['created_at']?.toString());
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    final bolhaColor = minha ? _cyan : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            minha ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!minha) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: bolhaColor.withOpacity(0.2),
              child: Text(inicial,
                  style: TextStyle(
                      color: bolhaColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: minha ? _cyan.withOpacity(0.18) : _card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(minha ? 16 : 4),
                  bottomRight: Radius.circular(minha ? 4 : 16),
                ),
                border: Border.all(
                  color: minha
                      ? _cyan.withOpacity(0.4)
                      : Colors.white.withOpacity(0.07),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: minha
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(nome,
                      style: TextStyle(
                          color: minha ? _cyan : Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Text(texto,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 5),
                  Text(hora,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 10)),
                ],
              ),
            ),
          ),
          if (minha) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: _cyan.withOpacity(0.2),
              child: Text(inicial,
                  style: const TextStyle(
                      color: _cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Input ───────────────────────────────────────────────────────────────

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: _dark,
        border: Border(top: BorderSide(color: _cyan.withOpacity(0.12))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _cyan.withOpacity(0.18)),
              ),
              child: TextField(
                controller: _msgCtrl,
                style:
                    const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                decoration: InputDecoration(
                  hintText: 'Escreva uma mensagem...',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _enviando
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: _cyan, strokeWidth: 2)),
                  ))
              : GestureDetector(
                  onTap: _enviar,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _cyan,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFF0A1929), size: 20),
                  ),
                ),
        ],
      ),
    );
  }
}
