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
  List<Reclamacao> _abertas = [];
  Map<String, int> _config = {
    'nivel_aceitavel_horas': 24,
    'nivel_ruim_horas': 48,
    'nivel_critico_horas': 72,
  };
  bool _loading = true;
  String? _error;

  static const _bg = Color(0xFF0A1929);
  static const _card = Color(0xFF0D2137);
  static const _cyan = Color(0xFF44CABD);
  static const _critico = Color(0xFFFF4444);
  static const _ruim = Color(0xFFFFA726);

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 420), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutQuart));
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
      // Carrega reclamações (obrigatório)
      final lista = await ApiService.getReclamacoesEmpresa(token);
      final todas = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();

      // Carrega config (opcional — usa defaults se endpoint não disponível)
      Map<String, int> config = Map.of(_config);
      try {
        final cfgData = await ApiService.getConfiguracoes(token);
        final cfgRaw = cfgData['configuracoes'] as Map<String, dynamic>? ?? {};
        if (cfgRaw.isNotEmpty) {
          config = cfgRaw.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      } catch (_) { /* endpoint não deployado ainda — mantém defaults */ }

      setState(() {
        _abertas = todas;
        _config = config;
        _loading = false;
      });
      _fadeCtrl.forward(from: 0);
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar alertas.'; _loading = false; });
    }
  }

  String _nivelSeveridade(Reclamacao r) {
    if (r.createdAt == null) return 'aceitavel';
    try {
      final horas = DateTime.now().difference(DateTime.parse(r.createdAt!)).inHours;
      final limAceitavel = _config['nivel_aceitavel_horas'] ?? 24;
      final limRuim = _config['nivel_ruim_horas'] ?? 48;
      if (horas <= limAceitavel) return 'aceitavel';
      if (horas <= limRuim) return 'ruim';
      return 'critico';
    } catch (_) {
      return 'aceitavel';
    }
  }

  String _formatarTempo(String? iso) {
    if (iso == null) return 'Data desconhecida';
    try {
      final abertura = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(abertura);
      if (diff.inDays >= 1) {
        final h = diff.inHours % 24;
        return '${diff.inDays}d ${h}h aberta';
      }
      final m = diff.inMinutes % 60;
      return '${diff.inHours}h ${m}min aberta';
    } catch (_) {
      return '';
    }
  }

  Color _corNivel(String nivel) {
    switch (nivel) {
      case 'critico': return _critico;
      case 'ruim': return _ruim;
      default: return _cyan;
    }
  }

  IconData _iconeNivel(String nivel) {
    switch (nivel) {
      case 'critico': return Icons.warning_rounded;
      case 'ruim': return Icons.error_outline;
      default: return Icons.check_circle_outline;
    }
  }

  String _labelNivel(String nivel) {
    switch (nivel) {
      case 'critico': return 'Crítico';
      case 'ruim': return 'Ruim';
      default: return 'Aceitável';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(children: [
            AppHeader(
              title: 'Notificações de Problemas',
              subtitle: 'Histórico completo por nível de severidade',
              icon: Icons.warning_amber_outlined,
              actions: [
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, color: _cyan, size: 20),
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _cyan, strokeWidth: 2))
                  : _error != null
                      ? _buildError()
                      : _abertas.isEmpty
                          ? _buildEmpty()
                          : _buildContent(),
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
          child: const Text('Tentar novamente', style: TextStyle(color: _cyan)),
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
            color: _cyan.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _cyan.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.check_circle_outline, size: 42, color: _cyan),
        ),
        const SizedBox(height: 16),
        const Text('Sem reclamações', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: _cyan,
        )),
        const SizedBox(height: 6),
        Text('Nenhuma reclamação registrada para esta empresa.', style: TextStyle(
          fontSize: 13, color: _cyan.withValues(alpha: 0.6),
        )),
      ],
    ));
  }

  Widget _buildContent() {
    final criticos  = _abertas.where((r) => _nivelSeveridade(r) == 'critico').toList();
    final ruins     = _abertas.where((r) => _nivelSeveridade(r) == 'ruim').toList();
    final aceitaveis = _abertas.where((r) => _nivelSeveridade(r) == 'aceitavel').toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: _cyan,
      backgroundColor: _card,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildSummaryBar(criticos.length, ruins.length, aceitaveis.length),
          const SizedBox(height: 16),
          _buildLimitesInfo(),
          const SizedBox(height: 16),
          _buildSecao('critico', criticos),
          const SizedBox(height: 12),
          _buildSecao('ruim', ruins),
          const SizedBox(height: 12),
          _buildSecao('aceitavel', aceitaveis),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(int nCritico, int nRuim, int nAceitavel) {
    return Row(
      children: [
        _buildSummaryChip(_critico, Icons.warning_rounded, 'Crítico', nCritico),
        const SizedBox(width: 8),
        _buildSummaryChip(_ruim, Icons.error_outline, 'Ruim', nRuim),
        const SizedBox(width: 8),
        _buildSummaryChip(_cyan, Icons.check_circle_outline, 'Aceitável', nAceitavel),
      ],
    );
  }

  Widget _buildSummaryChip(Color cor, IconData icone, String label, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: cor, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count.toString(), style: TextStyle(
                  color: cor, fontSize: 18, fontWeight: FontWeight.w800, height: 1,
                )),
                Text(label, style: TextStyle(
                  color: cor.withValues(alpha: 0.70), fontSize: 9, fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitesInfo() {
    final a = _config['nivel_aceitavel_horas'] ?? 24;
    final r = _config['nivel_ruim_horas'] ?? 48;
    final c = _config['nivel_critico_horas'] ?? 72;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cyan.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _limiteChip(_cyan, '≤${a}h', 'Aceitável'),
          _dividerVert(),
          _limiteChip(_ruim, '≤${r}h', 'Ruim'),
          _dividerVert(),
          _limiteChip(_critico, '>${r}h', 'Crítico'),
        ],
      ),
    );
  }

  Widget _limiteChip(Color cor, String valor, String label) {
    return Column(children: [
      Text(valor, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(color: cor.withValues(alpha: 0.6), fontSize: 9)),
    ]);
  }

  Widget _dividerVert() => Container(
    width: 1, height: 24,
    color: _cyan.withValues(alpha: 0.1),
  );

  Widget _buildSecao(String nivel, List<Reclamacao> items) {
    final cor = _corNivel(nivel);
    final icone = _iconeNivel(nivel);
    final label = _labelNivel(nivel);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: cor.withValues(alpha: 0.08),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withValues(alpha: 0.25)),
        ),
        child: ExpansionTile(
          initiallyExpanded: nivel == 'critico' || items.isNotEmpty,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          leading: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: cor.withValues(alpha: 0.30)),
            ),
            child: Icon(icone, color: cor, size: 18),
          ),
          title: Row(children: [
            Text(label, style: TextStyle(
              color: cor, fontSize: 14, fontWeight: FontWeight.w700,
            )),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cor.withValues(alpha: 0.35)),
              ),
              child: Text('${items.length}', style: TextStyle(
                color: cor, fontSize: 10, fontWeight: FontWeight.w700,
              )),
            ),
          ]),
          iconColor: cor,
          collapsedIconColor: cor.withValues(alpha: 0.5),
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('Nenhum problema neste nível',
                          style: TextStyle(color: cor.withValues(alpha: 0.45), fontSize: 12)),
                    ),
                  ),
                ]
              : items.asMap().entries.map((e) => _buildCard(e.value, e.key, nivel)).toList(),
        ),
      ),
    );
  }

  Widget _buildCard(Reclamacao r, int index, String nivel) {
    final corNivel = _corNivel(nivel);
    final tempo = _formatarTempo(r.createdAt);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 250)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutQuart,
      builder: (_, value, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - value)),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: corNivel.withValues(alpha: 0.20)),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6, offset: const Offset(0, 3),
          )],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: corNivel,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                      child: Text(r.titulo, style: const TextStyle(
                        color: Color(0xFFE8F8F7), fontWeight: FontWeight.bold, fontSize: 13,
                      ), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: r.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: r.statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(r.statusNome, style: TextStyle(
                        color: r.statusColor, fontSize: 9, fontWeight: FontWeight.bold,
                      )),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  // Tempo de abertura em destaque
                  Row(children: [
                    Icon(Icons.schedule_outlined, size: 12, color: corNivel),
                    const SizedBox(width: 4),
                    Text(tempo, style: TextStyle(
                      color: corNivel, fontSize: 11, fontWeight: FontWeight.w700,
                    )),
                  ]),
                  const SizedBox(height: 6),
                  Text(r.descricao, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _cyan.withValues(alpha: 0.55), fontSize: 11,
                      )),
                  if (r.nomeConsumidor != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.person_outline, size: 11, color: _cyan.withValues(alpha: 0.45)),
                      const SizedBox(width: 4),
                      Text(r.nomeConsumidor!, style: TextStyle(
                        fontSize: 10, color: _cyan.withValues(alpha: 0.45),
                      )),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    GestureDetector(
                      onTap: () => context.push('/chat/${r.id}', extra: {'titulo': r.titulo}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _cyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _cyan.withValues(alpha: 0.30)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, color: _cyan, size: 12),
                            SizedBox(width: 5),
                            Text('Chat', style: TextStyle(
                              color: _cyan, fontSize: 11, fontWeight: FontWeight.w600,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
