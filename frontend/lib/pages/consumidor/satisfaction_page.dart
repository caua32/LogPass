import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';
import '../../core/app_header.dart';

class SatisfactionPage extends StatefulWidget {
  const SatisfactionPage({super.key});

  @override
  State<SatisfactionPage> createState() => _SatisfactionPageState();
}

class _SatisfactionPageState extends State<SatisfactionPage> {
  static const _bg   = Color(0xFF0A1929);
  static const _card = Color(0xFF0D2137);
  static const _cyan = Color(0xFF44CABD);
  static const _red  = Color(0xFFFF6B6B);

  List<Reclamacao> _concluidas = [];
  final Map<int, int> _notasSelecionadas = {};
  final Map<int, TextEditingController> _comentarioCtrl = {};
  final Set<int> _enviando = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final ctrl in _comentarioCtrl.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final token = context.read<AuthProvider>().token!;
    try {
      final lista = await ApiService.getReclamacoesConsumidor(token);
      final todas = lista
          .map((e) => Reclamacao.fromJson(e as Map<String, dynamic>))
          .toList();

      // limpa controllers antigos antes de recriar
      for (final ctrl in _comentarioCtrl.values) ctrl.dispose();
      _comentarioCtrl.clear();

      setState(() {
        _concluidas = todas
            .where((r) => r.idStatus == 3 || r.idStatus == 4)
            .toList();
        for (final r in _concluidas) {
          if (r.avaliacao != null) {
            _notasSelecionadas[r.id] = r.avaliacao!;
          }
          _comentarioCtrl[r.id] = TextEditingController();
        }
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar solicitações.'; _loading = false; });
    }
  }

  Future<void> _enviarAvaliacao(Reclamacao r) async {
    final nota = _notasSelecionadas[r.id];
    if (nota == null) return;
    final comentario = _comentarioCtrl[r.id]?.text.trim() ?? '';
    if (comentario.length < 20) return;

    setState(() => _enviando.add(r.id));
    final token = context.read<AuthProvider>().token!;
    try {
      await ApiService.avaliarReclamacao(token, r.id, nota, comentario);
      if (!mounted) return;
      setState(() {
        final idx = _concluidas.indexWhere((x) => x.id == r.id);
        if (idx != -1) {
          _concluidas[idx] = Reclamacao(
            id: r.id,
            titulo: r.titulo,
            descricao: r.descricao,
            idStatus: r.idStatus,
            nomeEmpresa: r.nomeEmpresa,
            nomeConsumidor: r.nomeConsumidor,
            createdAt: r.createdAt,
            avaliacao: nota,
            comentario: comentario,
          );
        }
      });
      _showSnack('Avaliação enviada!');
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, error: true);
    } catch (_) {
      if (mounted) _showSnack('Erro ao enviar avaliação.', error: true);
    } finally {
      if (mounted) setState(() => _enviando.remove(r.id));
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : _cyan,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        AppHeader(
          title: 'Avaliação de Satisfação',
          subtitle: 'Como foi a resolução do seu pedido?',
          icon: Icons.star_outline_rounded,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: _cyan, size: 20),
              tooltip: 'Atualizar',
            ),
          ],
        ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _cyan, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: _red, size: 40),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: _red)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _load,
            child: const Text('Tentar novamente',
                style: TextStyle(color: _cyan)),
          ),
        ],
      ));
    }
    if (_concluidas.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _cyan.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.star_outline_rounded, size: 42, color: _cyan),
          ),
          const SizedBox(height: 16),
          const Text('Nenhuma solicitação concluída',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: _cyan)),
          const SizedBox(height: 6),
          Text(
            'Solicitações Resolvidas ou Não Resolvidas\naparecerão aqui para avaliação.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _cyan.withValues(alpha: 0.55)),
          ),
        ],
      ));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _cyan,
      backgroundColor: _card,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: _concluidas.length,
        itemBuilder: (_, i) => _buildCard(_concluidas[i]),
      ),
    );
  }

  Widget _buildCard(Reclamacao r) {
    final jaAvaliada = r.avaliacao != null;
    final notaAtual = _notasSelecionadas[r.id] ?? 0;
    final enviando = _enviando.contains(r.id);
    final feedbackOk =
        (_comentarioCtrl[r.id]?.text.trim().length ?? 0) >= 20;
    final podeEnviar = notaAtual > 0 && feedbackOk && !enviando;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.statusColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cabeçalho
          Row(children: [
            Expanded(
              child: Text(r.titulo,
                  style: const TextStyle(
                      color: _cyan, fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: r.statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: r.statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(r.statusNome,
                  style: TextStyle(
                      color: r.statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ]),

          // Empresa
          if (r.nomeEmpresa != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.business_outlined,
                  size: 13, color: _cyan.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(r.nomeEmpresa!,
                    style: TextStyle(
                        fontSize: 12, color: _cyan.withValues(alpha: 0.65)),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF1A3A55), height: 1),
          const SizedBox(height: 14),

          // Estrelas
          Row(children: [
            Text(
              jaAvaliada ? 'Sua avaliação:' : 'Avaliar:',
              style: TextStyle(
                  fontSize: 12,
                  color: _cyan.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            ...List.generate(5, (i) {
              final estrela = i + 1;
              final preenchida = estrela <= notaAtual;
              return GestureDetector(
                onTap: jaAvaliada
                    ? null
                    : () => setState(() => _notasSelecionadas[r.id] = estrela),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    preenchida ? Icons.star_rounded : Icons.star_border_rounded,
                    color: preenchida
                        ? Colors.amber
                        : Colors.amber.withValues(alpha: 0.3),
                    size: 30,
                  ),
                ),
              );
            }),
          ]),

          const SizedBox(height: 12),

          // Campo de feedback ou comentário salvo
          if (jaAvaliada) ...[
            if (r.comentario != null && r.comentario!.isNotEmpty) ...[
              Text('Seu comentário:',
                  style: TextStyle(
                      fontSize: 11,
                      color: _cyan.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cyan.withValues(alpha: 0.15)),
                ),
                child: Text(r.comentario!,
                    style: TextStyle(
                        fontSize: 13, color: _cyan.withValues(alpha: 0.75))),
              ),
              const SizedBox(height: 10),
            ],
            Row(children: [
              const Icon(Icons.check_circle_outline,
                  size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text('Já avaliado',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600)),
            ]),
          ] else ...[
            // Texto de hint com contador
            Builder(builder: (context) {
              final len =
                  _comentarioCtrl[r.id]?.text.trim().length ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _comentarioCtrl[r.id],
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(
                        color: Color(0xFFE0F7F5), fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Conte como foi sua experiência... (mín. 20 caracteres)',
                      hintStyle: TextStyle(
                          color: _cyan.withValues(alpha: 0.35),
                          fontSize: 12),
                      filled: true,
                      fillColor: _bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: _cyan.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: _cyan.withValues(alpha: 0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: _cyan.withValues(alpha: 0.6)),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$len / 20 mínimo',
                    style: TextStyle(
                      fontSize: 10,
                      color: len >= 20
                          ? Colors.green.withValues(alpha: 0.75)
                          : _cyan.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: podeEnviar ? () => _enviarAvaliacao(r) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: const Color(0xFF0A1929),
                  disabledBackgroundColor: _cyan.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: enviando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Color(0xFF0A1929), strokeWidth: 2))
                    : const Text('Enviar Avaliação',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
