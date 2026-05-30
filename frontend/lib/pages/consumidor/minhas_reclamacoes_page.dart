import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';
import '../../core/app_header.dart';

class MinhasReclamacoesPage extends StatefulWidget {
  const MinhasReclamacoesPage({super.key});

  @override
  State<MinhasReclamacoesPage> createState() => _MinhasReclamacoesPageState();
}

class _MinhasReclamacoesPageState extends State<MinhasReclamacoesPage>
    with SingleTickerProviderStateMixin {
  List<Reclamacao> _reclamacoes = [];
  bool _loading = true;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final token = context.read<AuthProvider>().token!;
    try {
      final lista = await ApiService.getReclamacoesConsumidor(token);
      setState(() {
        _reclamacoes = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar solicitações.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(children: [
          AppHeader(
            title: 'Minhas Solicitações',
            subtitle: 'Histórico e acompanhamento',
            icon: Icons.list_alt_outlined,
            actions: [
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: Color(0xFF4CE0D2), size: 20),
                tooltip: 'Atualizar',
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF4CE0D2), strokeWidth: 2))
                : _error != null
                    ? _buildError()
                    : _reclamacoes.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _load,
          child: const Text('Tentar novamente',
              style: TextStyle(color: Color(0xFF4CE0D2))),
        ),
      ],
    ));
  }

  Widget _buildEmpty() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4CE0D2).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.inbox_outlined, size: 42, color: Color(0xFF4CE0D2)),
        ),
        const SizedBox(height: 16),
        const Text('Nenhuma solicitação', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
        )),
        const SizedBox(height: 6),
        Text('Você ainda não abriu nenhuma solicitação.', style: TextStyle(
          fontSize: 13, color: const Color(0xFF4CE0D2).withValues(alpha: 0.6),
        )),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => context.push('/nova-reclamacao'),
          icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF4CE0D2)),
          label: const Text('Abrir nova solicitação',
              style: TextStyle(color: Color(0xFF4CE0D2))),
        ),
      ],
    ));
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CE0D2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${_reclamacoes.length} solicitaç${_reclamacoes.length != 1 ? 'ões' : 'ão'}',
                  style: const TextStyle(
                    color: Color(0xFF4CE0D2), fontSize: 12, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: _reclamacoes.length,
            itemBuilder: (_, i) => _buildCard(_reclamacoes[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Reclamacao r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: r.statusColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 120,
            decoration: BoxDecoration(
              color: r.statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Text(r.titulo, style: const TextStyle(
                      color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold, fontSize: 14,
                    ), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: r.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: r.statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(r.statusNome, style: TextStyle(
                      color: r.statusColor, fontSize: 10, fontWeight: FontWeight.bold,
                    )),
                  ),
                ]),
                if (r.nomeEmpresa != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.business_outlined,
                        size: 13, color: const Color(0xFF4CE0D2).withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(r.nomeEmpresa!, style: TextStyle(
                        fontSize: 12, color: const Color(0xFF4CE0D2).withValues(alpha: 0.65),
                      ), overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
                const SizedBox(height: 8),
                Text(r.descricao, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.5),
                      fontSize: 11,
                    )),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/chat/${r.id}', extra: {'titulo': r.titulo}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CE0D2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                color: Color(0xFF4CE0D2), size: 13),
                            SizedBox(width: 5),
                            Text('Chat', style: TextStyle(
                              color: Color(0xFF4CE0D2), fontSize: 11, fontWeight: FontWeight.w600,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
