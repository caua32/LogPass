import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/app_header.dart';

class ChatPage extends StatefulWidget {
  final int reclamacaoId;
  final String titulo;

  const ChatPage({super.key, required this.reclamacaoId, required this.titulo});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _mensagens = [];
  bool _loadingInicial = true;
  bool _enviando = false;
  String? _error;
  Timer? _pollTimer;
  String? _meuTipo;

  static const _cyan = Color(0xFF44CABD);
  static const _bg = Color(0xFF0A1929);
  static const _card = Color(0xFF102A43);

  @override
  void initState() {
    super.initState();
    _meuTipo = context.read<AuthProvider>().tipo;
    _carregarMensagens(inicial: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _carregarMensagens();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarMensagens({bool inicial = false}) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final lista = await ApiService.getMensagensChat(token, widget.reclamacaoId);
      if (!mounted) return;
      final novas = lista.cast<Map<String, dynamic>>();
      final tinhaNovas = novas.length > _mensagens.length;
      setState(() {
        _mensagens = novas;
        if (inicial) _loadingInicial = false;
        _error = null;
      });
      if (tinhaNovas || inicial) _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (inicial) setState(() { _loadingInicial = false; _error = e.message; });
    } catch (_) {
      if (!mounted) return;
      if (inicial) setState(() { _loadingInicial = false; _error = 'Erro ao carregar mensagens.'; });
    }
  }

  Future<void> _enviar() async {
    final texto = _inputCtrl.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    _inputCtrl.clear();
    final token = context.read<AuthProvider>().token!;
    try {
      await ApiService.enviarMensagemChat(token, widget.reclamacaoId, texto);
      await _carregarMensagens();
    } on ApiException catch (e) {
      if (!mounted) return;
      _inputCtrl.text = texto;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    } catch (_) {
      if (!mounted) return;
      _inputCtrl.text = texto;
    }
    if (mounted) setState(() => _enviando = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _eMinha(Map<String, dynamic> m) => m['remetente_tipo'] == _meuTipo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        AppHeader(
          title: 'Chat',
          subtitle: 'Pedido: ${widget.titulo}',
          icon: Icons.chat_bubble_outline,
        ),
        Expanded(child: _buildBody()),
        _buildInput(),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loadingInicial) {
      return const Center(child: CircularProgressIndicator(color: _cyan, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 40),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() { _loadingInicial = true; _error = null; });
              _carregarMensagens(inicial: true);
            },
            child: const Text('Tentar novamente', style: TextStyle(color: _cyan)),
          ),
        ]),
      );
    }
    if (_mensagens.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chat_bubble_outline,
              color: _cyan.withValues(alpha: 0.3), size: 56),
          const SizedBox(height: 16),
          Text(
            'Nenhuma mensagem ainda.\nInicie a conversa!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _cyan.withValues(alpha: 0.5), fontSize: 14, height: 1.5),
          ),
        ]),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _mensagens.length,
      itemBuilder: (_, i) => _buildBolha(_mensagens[i]),
    );
  }

  Widget _buildBolha(Map<String, dynamic> m) {
    final minha = _eMinha(m);
    final nome = m['remetente_nome'] as String? ?? m['remetente_tipo'] as String;
    final texto = m['mensagem'] as String;
    final hora = _formatarHora(m['created_at'] as String?);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: minha ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!minha) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: _card,
                shape: BoxShape.circle,
                border: Border.all(color: _cyan.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                  style: TextStyle(color: _cyan.withValues(alpha: 0.8), fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: minha ? _cyan.withValues(alpha: 0.18) : _card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(minha ? 16 : 4),
                  bottomRight: Radius.circular(minha ? 4 : 16),
                ),
                border: Border.all(
                  color: minha
                      ? _cyan.withValues(alpha: 0.45)
                      : _cyan.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!minha)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(nome,
                          style: TextStyle(
                              color: _cyan.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  Text(texto,
                      style: const TextStyle(
                          color: Color(0xFFE0F7F5), fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(hora,
                      style: TextStyle(
                          color: _cyan.withValues(alpha: 0.55), fontSize: 11)),
                ],
              ),
            ),
          ),
          if (minha) ...[
            const SizedBox(width: 8),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _cyan.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Icon(Icons.person_outline, color: _cyan, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _cyan.withValues(alpha: 0.2))),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _inputCtrl,
            style: const TextStyle(color: Color(0xFFE0F7F5), fontSize: 14),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: appInputDeco('Digite uma mensagem...').copyWith(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
            ),
            onSubmitted: (_) => _enviar(),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'Enviar mensagem',
          child: GestureDetector(
          onTap: _enviar,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _enviando
                  ? _cyan.withValues(alpha: 0.3)
                  : _cyan.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.3),
                  blurRadius: 8, spreadRadius: 1,
                )
              ],
            ),
            child: _enviando
                ? const Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Color(0xFF0A1929), strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Color(0xFF0A1929), size: 20),
          ),
          ),
        ),
      ]),
    );
  }

  String _formatarHora(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$d/$mo $h:$m';
    } catch (_) {
      return '';
    }
  }
}
