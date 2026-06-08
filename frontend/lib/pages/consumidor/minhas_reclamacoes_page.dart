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
  Map<String, int> _config = {
    'nivel_aceitavel_horas': 24,
    'nivel_ruim_horas': 48,
    'nivel_critico_horas': 72,
  };
  String? _filtroNivel; // null = Todas
  bool _loading = true;
  String? _error;

  static const _cyan = Color(0xFF44CABD);
  static const _bg = Color(0xFF0A1929);
  static const _card = Color(0xFF0D2137);
  static const _red = Color(0xFFFF6B6B);

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
      final lista = await ApiService.getReclamacoesConsumidor(token);

      // Carrega config (opcional — usa defaults se endpoint não disponível)
      Map<String, int> config = Map.of(_config);
      try {
        final cfgData = await ApiService.getConfiguracoesConsumidor(token);
        final cfgRaw = cfgData['configuracoes'] as Map<String, dynamic>? ?? {};
        if (cfgRaw.isNotEmpty) {
          config = cfgRaw.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
      } catch (_) { /* endpoint não deployado ainda — mantém defaults */ }

      setState(() {
        _reclamacoes = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
        _config = config;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar solicitações.'; _loading = false; });
    }
  }

  String _nivelSeveridade(Reclamacao r) {
    if (r.createdAt == null) return 'aceitavel';
    try {
      final horas = DateTime.now().difference(DateTime.parse(r.createdAt!)).inHours;
      final limA = _config['nivel_aceitavel_horas'] ?? 24;
      final limR = _config['nivel_ruim_horas'] ?? 48;
      if (horas <= limA) return 'aceitavel';
      if (horas <= limR) return 'ruim';
      return 'critico';
    } catch (_) {
      return 'aceitavel';
    }
  }

  List<Reclamacao> get _filtradas => _filtroNivel == null
      ? _reclamacoes
      : _reclamacoes.where((r) => _nivelSeveridade(r) == _filtroNivel).toList();

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : _cyan,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _abrirModal(Reclamacao r) {
    final isPendente = r.idStatus == 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: _cyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pedido: ${r.titulo}',
                      style: const TextStyle(
                        color: Color(0xFFE8F8F7),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: r.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: r.statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(r.statusNome,
                        style: TextStyle(
                            color: r.statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            if (!isPendente)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Editar e excluir disponíveis apenas para solicitações Pendentes.',
                  style: TextStyle(fontSize: 11, color: _cyan.withValues(alpha: 0.45)),
                ),
              ),
            const Divider(color: Color(0xFF1A3A55), height: 1),
            ListTile(
              leading: Icon(Icons.edit_outlined,
                  color: isPendente ? _cyan : Colors.grey.shade700),
              title: Text(
                'Editar Solicitação',
                style: TextStyle(
                    color: isPendente ? const Color(0xFFCCEEEC) : Colors.grey.shade700),
              ),
              onTap: isPendente
                  ? () {
                      Navigator.pop(context);
                      _abrirDialogoEdicao(r);
                    }
                  : null,
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: isPendente ? _red : Colors.grey.shade700),
              title: Text(
                'Excluir Solicitação',
                style: TextStyle(
                    color: isPendente ? _red : Colors.grey.shade700),
              ),
              onTap: isPendente
                  ? () {
                      Navigator.pop(context);
                      _confirmarExclusao(r);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: _cyan),
              title: const Text('Abrir Chat',
                  style: TextStyle(color: Color(0xFFCCEEEC))),
              onTap: () {
                Navigator.pop(context);
                context.push('/chat/${r.id}', extra: {'titulo': r.titulo});
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoEdicao(Reclamacao r) {
    final formKey = GlobalKey<FormState>();
    final pedidoCtrl = TextEditingController(text: r.titulo);
    final motivoCtrl = TextEditingController(text: r.descricao);
    const _opcoesValidas = ['Não Informado', 'Troca', 'Reembolso'];
    String formaSolucao = _opcoesValidas.contains(r.formaSolucao)
        ? r.formaSolucao!
        : 'Não Informado';
    bool salvando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Editar Solicitação',
            style: TextStyle(color: _cyan, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: pedidoCtrl,
                    style: const TextStyle(color: Color(0xFFE0F7F5), fontSize: 14),
                    decoration: appInputDeco('Número do pedido',
                        prefixIcon: Icons.receipt_outlined),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: formaSolucao,
                    dropdownColor: _card,
                    style: const TextStyle(color: Color(0xFFE0F7F5), fontSize: 14),
                    decoration: appInputDeco('Forma de solução',
                        prefixIcon: Icons.handshake_outlined),
                    items: const [
                      DropdownMenuItem(value: 'Não Informado', child: Text('Não Informado')),
                      DropdownMenuItem(value: 'Troca', child: Text('Troca')),
                      DropdownMenuItem(value: 'Reembolso', child: Text('Reembolso')),
                    ],
                    onChanged: (v) => setDialogState(() => formaSolucao = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: motivoCtrl,
                    style: const TextStyle(color: Color(0xFFE0F7F5), fontSize: 14),
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    decoration: appInputDeco('Descreva o motivo detalhadamente...'),
                    validator: (v) {
                      if (v == null || v.trim().length < 10) {
                        return 'Mínimo de 10 caracteres';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: _cyan)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: _bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => salvando = true);
                      final token = context.read<AuthProvider>().token!;
                      try {
                        await ApiService.editarReclamacao(token, r.id, {
                          'numero_pedido': pedidoCtrl.text.trim(),
                          'motivo': motivoCtrl.text.trim(),
                          'forma_solucao': formaSolucao,
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _showSnack('Solicitação atualizada com sucesso!');
                        _load();
                      } on ApiException catch (e) {
                        setDialogState(() => salvando = false);
                        _showSnack(e.message, error: true);
                      } catch (_) {
                        setDialogState(() => salvando = false);
                        _showSnack('Erro ao editar. Tente novamente.', error: true);
                      }
                    },
              child: salvando
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: _bg, strokeWidth: 2))
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(Reclamacao r) {
    bool excluindo = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Excluir Solicitação',
            style: TextStyle(color: _red, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Tem certeza que deseja excluir a solicitação "${r.titulo}"?\nEsta ação não pode ser desfeita.',
            style: TextStyle(color: _cyan.withValues(alpha: 0.8), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: _cyan)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: excluindo
                  ? null
                  : () async {
                      setDialogState(() => excluindo = true);
                      final token = context.read<AuthProvider>().token!;
                      try {
                        await ApiService.deletarReclamacao(token, r.id);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _showSnack('Solicitação excluída.');
                        _load();
                      } on ApiException catch (e) {
                        setDialogState(() => excluindo = false);
                        _showSnack(e.message, error: true);
                      } catch (_) {
                        setDialogState(() => excluindo = false);
                        _showSnack('Erro ao excluir. Tente novamente.', error: true);
                      }
                    },
              child: excluindo
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Excluir'),
            ),
          ],
        ),
      ),
    );
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
              title: 'Minhas Solicitações',
              subtitle: 'Histórico e acompanhamento',
              icon: Icons.list_alt_outlined,
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
                      : _reclamacoes.isEmpty
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
        const Icon(Icons.error_outline, color: _red, size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: _red)),
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
          child: const Icon(Icons.inbox_outlined, size: 42, color: _cyan),
        ),
        const SizedBox(height: 16),
        const Text('Nenhuma solicitação', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: _cyan,
        )),
        const SizedBox(height: 6),
        Text('Você ainda não abriu nenhuma solicitação.', style: TextStyle(
          fontSize: 13, color: _cyan.withValues(alpha: 0.6),
        )),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => context.push('/nova-reclamacao'),
          icon: const Icon(Icons.add_circle_outline, size: 16, color: _cyan),
          label: const Text('Abrir nova solicitação', style: TextStyle(color: _cyan)),
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
                  color: _cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cyan.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${_reclamacoes.length} solicitaç${_reclamacoes.length != 1 ? 'ões' : 'ão'}',
                  style: const TextStyle(
                    color: _cyan, fontSize: 12, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '— toque para ver opções',
                style: TextStyle(fontSize: 11, color: _cyan.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: _cyan,
            backgroundColor: _card,
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: _reclamacoes.length,
              itemBuilder: (_, i) => _buildCard(_reclamacoes[i], i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    final a = _config['nivel_aceitavel_horas'] ?? 24;
    final r = _config['nivel_ruim_horas'] ?? 48;

    final niveis = [
      (null,         _cyan,                    Icons.list_alt_outlined,    'Todas',      ''),
      ('aceitavel',  const Color(0xFF44CABD),  Icons.check_circle_outline, 'Aceitável',  '≤${a}h'),
      ('ruim',       const Color(0xFFFFA726),  Icons.error_outline,        'Ruim',       '≤${r}h'),
      ('critico',    const Color(0xFFFF4444),  Icons.warning_rounded,      'Crítico',    '>${r}h'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: niveis.map((nivel) {
          final key = nivel.$1;
          final cor = nivel.$2;
          final icone = nivel.$3;
          final label = nivel.$4;
          final tempo = nivel.$5;
          final count = key == null
              ? _reclamacoes.length
              : _reclamacoes.where((rec) => _nivelSeveridade(rec) == key).length;
          final selected = _filtroNivel == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filtroNivel = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? cor.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? cor : cor.withValues(alpha: 0.30),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icone, size: 13,
                        color: selected ? cor : cor.withValues(alpha: 0.55)),
                    const SizedBox(width: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: TextStyle(
                          color: selected ? cor : cor.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        )),
                        if (tempo.isNotEmpty)
                          Text(tempo, style: TextStyle(
                            color: selected ? cor : cor.withValues(alpha: 0.45),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          )),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected
                            ? cor.withValues(alpha: 0.25)
                            : cor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$count', style: TextStyle(
                        color: selected ? cor : cor.withValues(alpha: 0.55),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      )),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(Reclamacao r, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 60).clamp(0, 300)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutQuart,
      builder: (_, value, child) => Transform.translate(
        offset: Offset(0, 24 * (1 - value)),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: GestureDetector(
        onTap: () => _abrirModal(r),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: r.statusColor.withValues(alpha: 0.25)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10, offset: const Offset(0, 4),
            )],
          ),
          child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
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
                          color: _cyan, fontWeight: FontWeight.bold, fontSize: 14,
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
                            size: 13, color: _cyan.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(r.nomeEmpresa!, style: TextStyle(
                            fontSize: 12, color: _cyan.withValues(alpha: 0.65),
                          ), overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Text(r.descricao, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _cyan.withValues(alpha: 0.5), fontSize: 11,
                        )),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (r.idStatus == 1)
                          Row(children: [
                            Icon(Icons.edit_outlined, size: 12, color: _cyan.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text('Editável', style: TextStyle(
                                fontSize: 10, color: _cyan.withValues(alpha: 0.5))),
                          ])
                        else
                          const SizedBox.shrink(),
                        Row(children: [
                          Icon(Icons.touch_app_outlined,
                              size: 12, color: _cyan.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Text('ver opções', style: TextStyle(
                              fontSize: 10, color: _cyan.withValues(alpha: 0.4))),
                        ]),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
