// Roda com: dart run tool/generate_icon.dart
// Requer: image package em dev_dependencies do pubspec.yaml

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // ── Fundo cyan #44CABD ──────────────────────────────────────────────────
  img.fill(image, color: img.ColorRgb8(0x44, 0xCA, 0xBD));

  // ── Monitor ─────────────────────────────────────────────────────────────
  const monW = 580;
  const monH = 390;
  const monX = (size - monW) ~/ 2;
  const monY = 200;
  const radius = 28;

  _fillRoundedRect(image, monX, monY, monW, monH, radius,
      img.ColorRgb8(255, 255, 255));

  // Tela interna
  const screenPad = 20;
  _fillRoundedRect(
    image,
    monX + screenPad,
    monY + screenPad,
    monW - screenPad * 2,
    monH - screenPad * 2,
    12,
    img.ColorRgb8(0x0A, 0x19, 0x29),
  );

  // ── Suporte ──────────────────────────────────────────────────────────────
  const stW = 80;
  const stH = 70;
  const stX = (size - stW) ~/ 2;
  const stY = monY + monH;
  _fillRect(image, stX, stY, stW, stH, img.ColorRgb8(255, 255, 255));

  // ── Base/teclado ─────────────────────────────────────────────────────────
  const baseW = 380;
  const baseH = 36;
  const baseX = (size - baseW) ~/ 2;
  const baseY = stY + stH;
  _fillRoundedRect(
      image, baseX, baseY, baseW, baseH, 10, img.ColorRgb8(255, 255, 255));

  // ── Salvar ───────────────────────────────────────────────────────────────
  final outDir = Directory('assets/icon');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final outFile = File('assets/icon/app_icon.png');
  outFile.writeAsBytesSync(img.encodePng(image));
  print('✅ Ícone gerado em assets/icon/app_icon.png (${size}x$size)');
}

void _fillRect(img.Image image, int x, int y, int w, int h, img.Color color) {
  for (var py = y; py < y + h; py++) {
    for (var px = x; px < x + w; px++) {
      image.setPixel(px, py, color);
    }
  }
}

void _fillRoundedRect(
    img.Image image, int x, int y, int w, int h, int r, img.Color color) {
  for (var py = y; py < y + h; py++) {
    for (var px = x; px < x + w; px++) {
      final dx = (px < x + r)
          ? (x + r - px)
          : (px >= x + w - r)
              ? (px - (x + w - r - 1))
              : 0;
      final dy = (py < y + r)
          ? (y + r - py)
          : (py >= y + h - r)
              ? (py - (y + h - r - 1))
              : 0;
      if (dx * dx + dy * dy <= r * r) {
        image.setPixel(px, py, color);
      }
    }
  }
}
