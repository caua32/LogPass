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
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF102A43)],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF44CABD).withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF44CABD).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF44CABD).withValues(alpha: 0.30),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF44CABD),
                  size: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF44CABD).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF44CABD).withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF44CABD)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE8F8F7),
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF44CABD).withValues(alpha: 0.70),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

InputDecoration appInputDeco(String hint, {IconData? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: const Color(0xFF44CABD).withValues(alpha: 0.35),
      fontSize: 14,
    ),
    filled: true,
    fillColor: const Color(0xFF071520),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon,
            color: const Color(0xFF44CABD).withValues(alpha: 0.5), size: 18)
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
          color: const Color(0xFF44CABD).withValues(alpha: 0.20)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
          color: const Color(0xFF44CABD).withValues(alpha: 0.20)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          const BorderSide(color: Color(0xFF44CABD), width: 1.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
          color: const Color(0xFF44CABD).withValues(alpha: 0.10)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.7)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
    ),
    errorStyle:
        const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
  );
}

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF44CABD).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon,
                    color: const Color(0xFF44CABD), size: 16),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF44CABD),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF44CABD).withValues(alpha: 0.30),
                  const Color(0xFF44CABD).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
