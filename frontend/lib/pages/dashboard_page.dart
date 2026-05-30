import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  static const _cyan = Color(0xFF44CABD);
  static const _bg = Color(0xFF0A1929);
  static const _card = Color(0xFF0D2137);

  late AnimationController _headerCtrl;
  late AnimationController _logoCtrl;
  late Animation<double> _headerFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _logoCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _logoScale =
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _logoCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isEmpresa = auth.tipo == 'empresa';
    final nome = auth.user?.nome ?? 'Usuário';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerFade,
            child: _buildHeader(nome, isEmpresa),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ScaleTransition(
                    scale: _logoScale,
                    child: _buildLogoSection(),
                  ),
                  const SizedBox(height: 32),
                  _buildMenuGrid(isEmpresa),
                  const SizedBox(height: 20),
                  _buildTip(isEmpresa),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String nome, bool isEmpresa) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF102A43)],
        ),
        border: Border(
          bottom: BorderSide(color: _cyan.withValues(alpha: 0.20), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _cyan,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.computer, color: _bg, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LogPass',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _cyan,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Olá, $nome',
                      style: TextStyle(
                        fontSize: 12,
                        color: _cyan.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _cyan.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        isEmpresa ? 'Empresa' : 'Consumidor',
                        style: const TextStyle(
                          fontSize: 9,
                          color: _cyan,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_rounded, size: 15, color: _cyan),
            label: const Text(
              'Sair',
              style: TextStyle(
                color: _cyan,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: _cyan.withValues(alpha: 0.25)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: _cyan.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: _cyan.withValues(alpha: 0.30), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.20),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.computer, color: _cyan, size: 38),
    );
  }

  Widget _buildMenuGrid(bool isEmpresa) {
    final consumerItems = [
      _MenuItem(Icons.assignment_outlined, 'Nova\nSolicitação', '/nova-reclamacao'),
      _MenuItem(Icons.list_alt_outlined, 'Minhas\nSolicitações', '/minhas-reclamacoes'),
      _MenuItem(Icons.star_outline_rounded, 'Avaliação\nde Satisfação', '/satisfacao'),
      _MenuItem(Icons.person_outline, 'Meus\nDados', '/perfil/consumidor'),
    ];

    final empresaItems = [
      _MenuItem(Icons.inventory_2_outlined, 'Consultar\nDados', '/empresa/consulta'),
      _MenuItem(Icons.notifications_outlined, 'Notificações\nProblemas', '/empresa/problemas'),
      _MenuItem(Icons.person_outline, 'Perfil\nEmpresa', '/perfil/empresa'),
      _MenuItem(Icons.analytics_outlined, 'Relatórios\ne Análises', '/empresa/relatorios'),
    ];

    final items = isEmpresa ? empresaItems : consumerItems;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (_, i) => _buildMenuCard(items[i], i),
    );
  }

  Widget _buildMenuCard(_MenuItem item, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + index * 80),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => Transform.scale(
        scale: 0.65 + 0.35 * value,
        child: Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Semantics(
            button: true,
            label: item.label.replaceAll('\n', ' '),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(item.route),
                borderRadius: BorderRadius.circular(16),
                splashColor: _cyan.withValues(alpha: 0.12),
                highlightColor: _cyan.withValues(alpha: 0.06),
                child: Ink(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cyan.withValues(alpha: 0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _cyan.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _cyan.withValues(alpha: 0.25)),
                          ),
                          child: Icon(item.icon, color: _cyan, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label.replaceAll('\n', ' '),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFCCEEEC),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(bool isEmpresa) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (_, value, __) => Opacity(
        opacity: value,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cyan.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: _cyan.withValues(alpha: 0.6), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEmpresa
                      ? 'Verifique as notificações regularmente para manter a satisfação dos clientes.'
                      : 'Use Nova Solicitação sempre que precisar registrar um problema com um produto.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _cyan.withValues(alpha: 0.70),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  const _MenuItem(this.icon, this.label, this.route);
}
