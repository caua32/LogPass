import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';
import '../../core/app_header.dart';

class DataConsultPage extends StatefulWidget {
  const DataConsultPage({super.key});

  @override
  State<DataConsultPage> createState() => _DataConsultPageState();
}

class _DataConsultPageState extends State<DataConsultPage> {
  final _searchCtrl = TextEditingController();
  List<Reclamacao> _todas = [];
  List<Reclamacao> _filtradas = [];
  String _filtroStatus = 'todos';
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _perPage = 5;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final token = context.read<AuthProvider>().token!;
    try {
      final lista = await ApiService.getReclamacoesEmpresa(token);
      setState(() {
        _todas = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
        _applyFilter();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar dados.'; _loading = false; });
    }
  }

  void _applyFilter() {
    final search = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtradas = _todas.where((r) {
        final matchStatus = _filtroStatus == 'todos' || r.idStatus.toString() == _filtroStatus;
        final matchSearch = search.isEmpty ||
            r.titulo.toLowerCase().contains(search) ||
            r.descricao.toLowerCase().contains(search);
        return matchStatus && matchSearch;
      }).toList();
      _page = 1;
    });
  }

  List<Reclamacao> get _paginadas {
    final start = (_page - 1) * _perPage;
    final end = (start + _perPage).clamp(0, _filtradas.length);
    return _filtradas.sublist(start, end);
  }

  int get _totalPages => (_filtradas.length / _perPage).ceil().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: Column(children: [
        AppHeader(
          title: 'Consulta de Dados',
          subtitle: 'Reclamações recebidas',
          icon: Icons.inventory_2_outlined,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Color(0xFF44CABD), size: 20),
              tooltip: 'Atualizar',
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              // Busca e filtro
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2137),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.filter_alt_outlined,
                          color: const Color(0xFF44CABD).withValues(alpha: 0.7), size: 16),
                      const SizedBox(width: 6),
                      Text('Filtros', style: TextStyle(
                        color: const Color(0xFF44CABD).withValues(alpha: 0.7),
                        fontSize: 12, letterSpacing: 0.5,
                      )),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(flex: 3, child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Color(0xFF44CABD), fontSize: 13),
                        decoration: appInputDeco('Buscar por título ou descrição...',
                            prefixIcon: Icons.search).copyWith(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      )),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1929).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.35)),
                        ),
                        child: DropdownButton<String>(
                          value: _filtroStatus,
                          dropdownColor: const Color(0xFF0D2137),
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(color: Color(0xFF44CABD), fontSize: 13),
                          iconEnabledColor: const Color(0xFF44CABD),
                          items: const [
                            DropdownMenuItem(value: 'todos', child: Text('Todos')),
                            DropdownMenuItem(value: '1', child: Text('Pendente')),
                            DropdownMenuItem(value: '2', child: Text('Em Análise')),
                            DropdownMenuItem(value: '3', child: Text('Resolvida')),
                            DropdownMenuItem(value: '4', child: Text('Não Resolvida')),
                          ],
                          onChanged: (v) {
                            setState(() => _filtroStatus = v ?? 'todos');
                            _applyFilter();
                          },
                        ),
                      )),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Resultados
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2137),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.2)),
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator(
                            color: Color(0xFF44CABD), strokeWidth: 2)),
                      )
                    : _error != null
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                          )
                        : _filtradas.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(child: Text('Nenhuma reclamação encontrada.',
                                    style: TextStyle(color: Color(0xFF44CABD)))),
                              )
                            : Column(children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${_filtradas.length} resultado${_filtradas.length != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            color: const Color(0xFF44CABD).withValues(alpha: 0.6),
                                            fontSize: 12,
                                          )),
                                      Text('Pág. $_page/$_totalPages',
                                          style: TextStyle(
                                            color: const Color(0xFF44CABD).withValues(alpha: 0.6),
                                            fontSize: 12,
                                          )),
                                    ],
                                  ),
                                ),
                                const Divider(color: Color(0xFF44CABD), height: 1),
                                ..._paginadas.map(_buildRow),
                                if (_totalPages > 1) ...[
                                  const Divider(color: Color(0xFF44CABD), height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _pageBtn(Icons.chevron_left,
                                            _page > 1 ? () => setState(() => _page--) : null),
                                        const SizedBox(width: 16),
                                        Text('$_page / $_totalPages', style: const TextStyle(
                                          color: Color(0xFF44CABD), fontSize: 13,
                                        )),
                                        const SizedBox(width: 16),
                                        _pageBtn(Icons.chevron_right,
                                            _page < _totalPages ? () => setState(() => _page++) : null),
                                      ],
                                    ),
                                  ),
                                ],
                              ]),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildRow(Reclamacao r) {
    final screenW = MediaQuery.of(context).size.width;
    final showName = screenW > 360;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: const Color(0xFF44CABD).withValues(alpha: 0.1),
        )),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text('#${r.id}', style: TextStyle(
            color: const Color(0xFF44CABD).withValues(alpha: 0.5),
            fontSize: 11, fontWeight: FontWeight.bold,
          )),
        ),
        Expanded(
          flex: showName ? 3 : 5,
          child: Text(r.titulo, style: const TextStyle(
            color: Color(0xFF44CABD), fontSize: 13, fontWeight: FontWeight.w500,
          ), overflow: TextOverflow.ellipsis),
        ),
        if (showName) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(r.nomeConsumidor ?? '-', style: TextStyle(
              color: const Color(0xFF44CABD).withValues(alpha: 0.65), fontSize: 12,
            ), overflow: TextOverflow.ellipsis),
          ),
        ],
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: r.statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: r.statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(r.statusNome, style: TextStyle(
            color: r.statusColor, fontSize: 10, fontWeight: FontWeight.bold,
          )),
        ),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: 'Abrir chat da reclamação ${r.titulo}',
          child: GestureDetector(
            onTap: () => context.push('/chat/${r.id}', extra: {'titulo': r.titulo}),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF44CABD).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF44CABD), size: 15),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF44CABD).withValues(alpha: 0.12)
              : const Color(0xFF44CABD).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onTap != null
                ? const Color(0xFF44CABD).withValues(alpha: 0.4)
                : const Color(0xFF44CABD).withValues(alpha: 0.1),
          ),
        ),
        child: Icon(icon,
            color: onTap != null
                ? const Color(0xFF44CABD)
                : const Color(0xFF44CABD).withValues(alpha: 0.25),
            size: 18),
      ),
    );
  }
}
