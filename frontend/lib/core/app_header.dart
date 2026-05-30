import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool showBack;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.showBack = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.2)),
        ),
        boxShadow: [BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )],
      ),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CE0D2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF4CE0D2), size: 16),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Icon(icon, size: 26, color: const Color(0xFF4CE0D2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: Color(0xFF4CE0D2), letterSpacing: 0.3,
                )),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.6),
                  )),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

// Decoração padrão para inputs nas páginas internas
InputDecoration appInputDeco(String hint, {IconData? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: const Color(0xFF4CE0D2).withValues(alpha: 0.4), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFF0A1929).withValues(alpha: 0.8),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: const Color(0xFF4CE0D2).withValues(alpha: 0.6), size: 18)
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.35)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.35)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF4CE0D2), width: 1.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.15)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.6)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
    ),
    errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
  );
}

// Card de seção padrão
class SectionCard extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    this.titleIcon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, color: const Color(0xFF4CE0D2), size: 18),
                const SizedBox(width: 8),
              ],
              Text(title, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold,
                color: Color(0xFF4CE0D2), letterSpacing: 0.3,
              )),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            height: 1,
            color: const Color(0xFF4CE0D2).withValues(alpha: 0.15),
          ),
          ...children,
        ],
      ),
    );
  }
}
