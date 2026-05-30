import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';
import '../../core/app_header.dart';

class ProblemsNotificationPage extends StatefulWidget {
  const ProblemsNotificationPage({super.key});

  @override
  State<ProblemsNotificationPage> createState() => _ProblemsNotificationPageState();
}

class _ProblemsNotificationPageState extends State<ProblemsNotificationPage>
    with SingleTickerProviderStateMixin {
  List<Reclamacao> _urgentes = [];
  bool _loading = true;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
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
      final lista = await ApiService.getReclamacoesEmpresa(token);
      final todas = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _urgentes = todas.where((r) => r.idStatus == 1 || r.idStatus == 2).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar alertas.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(children: [
          AppHeader(
            title: 'Notificações de Problemas',
            subtitle: 'Reclamações pendentes e em análise',
            icon: Icons.warning_amber_outlined,
            actions: [
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: Color(0xFF44CABD), size: 20),
                tooltip: 'Atualizar',
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF44CABD), strokeWidth: 2))
                : _error != null
                    ? _buildError()
                    : _urgentes.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ]),
        ),
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
              style: TextStyle(color: Color(0xFF44CABD))),
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
            color: const Color(0xFF44CABD).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.check_circle_outline,
              size: 42, color: Color(0xFF44CABD)),
        ),
        const SizedBox(height: 16),
        const Text('Tudo em dia!', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF44CABD),
        )),
        const SizedBox(height: 6),
        Text('Nenhum alerta pendente no momento.', style: TextStyle(
          fontSize: 13, color: const Color(0xFF44CABD).withValues(alpha: 0.6),
        )),
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
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Text('${_urgentes.length} alerta${_urgentes.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: _urgentes.length,
            itemBuilder: (_, i) => _buildCard(_urgentes[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Reclamacao r, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 60).clamp(0, 300)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Transform.translate(
        offset: Offset(0, 24 * (1 - value)),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.statusColor.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 130,
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
                  Expanded(child: Text(r.titulo, style: const TextStyle(
                    color: Color(0xFF44CABD), fontWeight: FontWeight.bold, fontSize: 14,
                  ), overflow: TextOverflow.ellipsis)),
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
                const SizedBox(height: 6),
                Text(r.descricao, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF44CABD).withValues(alpha: 0.65),
                      fontSize: 12,
                    )),
                if (r.nomeConsumidor != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.person_outline,
                        size: 13, color: const Color(0xFF44CABD).withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(r.nomeConsumidor!, style: TextStyle(
                      fontSize: 11, color: const Color(0xFF44CABD).withValues(alpha: 0.5),
                    )),
                  ]),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/chat/${r.id}', extra: {'titulo': r.titulo}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF44CABD).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                color: Color(0xFF44CABD), size: 13),
                            const SizedBox(width: 5),
                            const Text('Chat', style: TextStyle(
                              color: Color(0xFF44CABD), fontSize: 11, fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
