import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/particles_background.dart';

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
  late AnimationController _cardsCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _headerFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
        duration: const Duration(milliseconds: 380), vsync: this);
    _logoCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _cardsCtrl = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _pulseCtrl = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this)
      ..repeat(reverse: true);

    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutQuart);
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack);

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _logoCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _cardsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _logoCtrl.dispose();
    _cardsCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isEmpresa = auth.tipo == 'empresa';
    final nome = auth.user?.nome ?? 'Usuário';

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParticlesBackground(count: 50, showLines: true),
          ),
          Column(
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
                        child: _buildLogoSection(isEmpresa),
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
                    Flexible(
                      child: Text(
                        'Olá, $nome',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: _cyan.withValues(alpha: 0.65),
                        ),
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
                          fontSize: 10,
                          color: _cyan,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
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

  Widget _buildLogoSection(bool isEmpresa) {
    final glowAnim = Tween<double>(begin: 0.20, end: 0.45).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: glowAnim,
      builder: (_, __) => Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _cyan.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _cyan.withValues(alpha: glowAnim.value),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.computer, color: _cyan, size: 44),
          ),
          const SizedBox(height: 16),
          const Text(
            'LogPass',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _cyan,
              letterSpacing: 2.5,
              shadows: [Shadow(color: _cyan, blurRadius: 18)],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gerenciamento de Ocorrências',
            style: TextStyle(
              fontSize: 12,
              color: _cyan.withValues(alpha: 0.55),
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cyan.withValues(alpha: 0.18)),
            ),
            child: Text(
              isEmpresa
                  ? 'Painel de gerenciamento empresarial'
                  : 'Seus direitos protegidos em um só lugar',
              style: TextStyle(
                fontSize: 11,
                color: _cyan.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(bool isEmpresa) {
    final consumerItems = [
      _MenuItem(Icons.assignment_outlined, 'Nova Solicitação',
          'Registre um produto danificado ou extraviado', '/nova-reclamacao'),
      _MenuItem(Icons.list_alt_outlined, 'Minhas Solicitações',
          'Acompanhe o status das suas ocorrências', '/minhas-reclamacoes'),
      _MenuItem(Icons.star_outline_rounded, 'Avaliação de Satisfação',
          'Avalie como foi a resolução do seu caso', '/satisfacao'),
      _MenuItem(Icons.person_outline, 'Meus Dados',
          'Visualize e atualize suas informações pessoais', '/perfil/consumidor'),
    ];

    final empresaItems = [
      _MenuItem(Icons.inventory_2_outlined, 'Consultar Dados',
          'Visualize todos os registros e dados', '/empresa/consulta'),
      _MenuItem(Icons.notifications_outlined, 'Notificações Problemas',
          'Reclamações pendentes dos clientes', '/empresa/problemas'),
      _MenuItem(Icons.person_outline, 'Perfil Empresa',
          'Gerencie as informações da sua empresa', '/perfil/empresa'),
      _MenuItem(Icons.analytics_outlined, 'Relatórios e Análises',
          'Métricas e relatórios detalhados', '/empresa/relatorios'),
    ];

    final items = isEmpresa ? empresaItems : consumerItems;

    return Column(
      children: List.generate(
        items.length,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildMenuCard(items[i], i),
        ),
      ),
    );
  }

  Widget _buildMenuCard(_MenuItem item, int index) {
    final start = index * 0.15;
    final end = (start + 0.55).clamp(0.0, 1.0);

    final fade = CurvedAnimation(
      parent: _cardsCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardsCtrl,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    ));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Semantics(
          button: true,
          label: item.label,
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _cyan.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _cyan.withValues(alpha: 0.25)),
                        ),
                        child: Icon(item.icon, color: _cyan, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFCCEEEC),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: _cyan.withValues(alpha: 0.55),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: _cyan.withValues(alpha: 0.40),
                      ),
                    ],
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
    final title = isEmpresa ? 'Dica para Empresas' : 'Dica para Consumidores';
    final body = isEmpresa
        ? 'Verifique as notificações regularmente para manter a satisfação dos clientes.'
        : 'Use Nova Solicitação sempre que precisar registrar um problema com um produto.';
    final extra = isEmpresa
        ? 'Resolva ocorrências em até 48h para melhorar sua avaliação.'
        : 'Acompanhe o status em Minhas Solicitações e avalie após a resolução.';

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (_, value, __) => Opacity(
        opacity: value,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cyan.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lightbulb_outline_rounded,
                        color: _cyan, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFCCEEEC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: TextStyle(
                  fontSize: 13,
                  color: _cyan.withValues(alpha: 0.70),
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right,
                      color: _cyan.withValues(alpha: 0.45), size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      extra,
                      style: TextStyle(
                        fontSize: 12,
                        color: _cyan.withValues(alpha: 0.50),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
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
  final String description;
  final String route;
  const _MenuItem(this.icon, this.label, this.description, this.route);
}
