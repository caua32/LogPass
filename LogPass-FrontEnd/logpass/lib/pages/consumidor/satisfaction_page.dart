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
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CE0D2),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5,
                  )],
                ),
                child: const Icon(Icons.check, size: 60, color: Color(0xFF0A1929)),
              ),
              const SizedBox(height: 32),
              const Text('Reclamação Enviada!', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2))),
              const SizedBox(height: 12),
              Text(
                'Sua solicitação foi registrada com sucesso. Em breve a empresa entrará em contato.',
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFF4CE0D2).withValues(alpha: 0.8), fontSize: 16),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home),
                label: const Text('Voltar ao início'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CE0D2),
                  foregroundColor: const Color(0xFF0A1929),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pushReplacement('/nova-reclamacao'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CE0D2),
                  side: const BorderSide(color: Color(0xFF4CE0D2)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Abrir outra solicitação'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

