import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SatisfactionPage extends StatelessWidget {
  const SatisfactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ícone de sucesso com glow
              Center(
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 700),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (_, value, __) => Transform.scale(
                    scale: value,
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CE0D2).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4CE0D2).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF4CE0D2).withValues(alpha: 0.3),
                          blurRadius: 32, spreadRadius: 4,
                        )],
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          size: 50, color: Color(0xFF4CE0D2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Solicitação Enviada!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold,
                    color: Color(0xFF4CE0D2), letterSpacing: 0.5,
                  )),
              const SizedBox(height: 10),
              Text(
                'Sua solicitação foi registrada com sucesso.\nEm breve a empresa entrará em contato.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF4CE0D2).withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Linha decorativa
              Center(
                child: Container(
                  width: 60, height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Voltar ao início', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15,
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CE0D2),
                    foregroundColor: const Color(0xFF0A1929),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.pushReplacement('/nova-reclamacao'),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Abrir outra solicitação', style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14,
                  )),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CE0D2),
                    side: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
