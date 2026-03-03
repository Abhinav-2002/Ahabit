// Run: dart run generate_icon.dart
// Generates assets/icon.png (1024x1024) from the AHabit icon design.

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size, numChannels: 4);

  // 1. Gradient background: #FF6B8A (255,107,138) → #FF4757 (255,71,87)
  //    Direction: top-left (0,0) → bottom-right (1024,1024)
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final t = ((x + y) / (2.0 * (size - 1))).clamp(0.0, 1.0);
      final r = 255;
      final g = (107 + (71 - 107) * t).round();
      final b = (138 + (87 - 138) * t).round();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // 2. Top shine overlay: white, opacity 0.12 → 0 over top 512px
  for (var y = 0; y < 512; y++) {
    final opacity = 0.12 * (1.0 - y / 512.0);
    final a = (opacity * 255).round();
    for (var x = 0; x < size; x++) {
      _blendPixel(image, x, y, 255, 255, 255, a);
    }
  }

  // 3. Decorative circles
  _blendCircle(image, 200, 200, 280, 255, 255, 255, 13);  // opacity ~0.05
  _blendCircle(image, 900, 900, 360, 255, 255, 255, 10);  // opacity ~0.04

  // 4. White card glow: x=172, y=172, 680x680, rx=150, opacity=0.15
  _blendRoundedRect(image, 172, 172, 680, 680, 150, 255, 255, 255, 38);

  // 5. White card: x=192, y=192, 640x640, rx=140, opacity=0.95
  _blendRoundedRect(image, 192, 192, 640, 640, 140, 255, 255, 255, 242);

  // 6. A left leg: (512,280) → (320,760), #FF6B8A (255,107,138), width=72
  _drawRoundLine(image, 512, 280, 320, 760, 255, 107, 138, 36);

  // 7. A right leg: (512,280) → (704,760), #FF6B8A (255,107,138), width=72
  _drawRoundLine(image, 512, 280, 704, 760, 255, 107, 138, 36);

  // 8. Checkmark segment 1: (370,540) → (468,638), #FF4757 (255,71,87), width=68
  _drawRoundLine(image, 370, 540, 468, 638, 255, 71, 87, 34);

  // 9. Checkmark segment 2: (468,638) → (680,426), #FF4757 (255,71,87), width=68
  _drawRoundLine(image, 468, 638, 680, 426, 255, 71, 87, 34);

  final pngBytes = img.encodePng(image);
  File('assets/icon.png').writeAsBytesSync(pngBytes);
  print('✓ Generated assets/icon.png (${size}x$size)');
}

// Alpha-blend a color onto a pixel
void _blendPixel(img.Image image, int x, int y, int r, int g, int b, int a) {
  if (x < 0 || x >= image.width || y < 0 || y >= image.height || a == 0) return;
  final px = image.getPixel(x, y);
  final pr = px.r.toInt();
  final pg = px.g.toInt();
  final pb = px.b.toInt();
  image.setPixelRgba(
    x, y,
    ((pr * (255 - a) + r * a) ~/ 255),
    ((pg * (255 - a) + g * a) ~/ 255),
    ((pb * (255 - a) + b * a) ~/ 255),
    255,
  );
}

// Fill a circle with alpha blending
void _blendCircle(
    img.Image image, int cx, int cy, int radius, int r, int g, int b, int a) {
  final x0 = (cx - radius).clamp(0, image.width - 1);
  final x1 = (cx + radius).clamp(0, image.width - 1);
  final y0 = (cy - radius).clamp(0, image.height - 1);
  final y1 = (cy + radius).clamp(0, image.height - 1);
  final r2 = radius * radius;
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= r2) {
        _blendPixel(image, x, y, r, g, b, a);
      }
    }
  }
}

// Check if point is inside a rounded rectangle
bool _inRoundedRect(
    int x, int y, int rx, int ry, int rw, int rh, int cr) {
  if (x < rx || x >= rx + rw || y < ry || y >= ry + rh) return false;
  final inLeft = x < rx + cr;
  final inRight = x >= rx + rw - cr;
  final inTop = y < ry + cr;
  final inBottom = y >= ry + rh - cr;
  if (inLeft && inTop) {
    final dx = x - (rx + cr);
    final dy = y - (ry + cr);
    return dx * dx + dy * dy <= cr * cr;
  }
  if (inRight && inTop) {
    final dx = x - (rx + rw - cr);
    final dy = y - (ry + cr);
    return dx * dx + dy * dy <= cr * cr;
  }
  if (inLeft && inBottom) {
    final dx = x - (rx + cr);
    final dy = y - (ry + rh - cr);
    return dx * dx + dy * dy <= cr * cr;
  }
  if (inRight && inBottom) {
    final dx = x - (rx + rw - cr);
    final dy = y - (ry + rh - cr);
    return dx * dx + dy * dy <= cr * cr;
  }
  return true;
}

// Fill a rounded rectangle with alpha blending
void _blendRoundedRect(img.Image image, int rx, int ry, int rw, int rh,
    int cr, int r, int g, int b, int a) {
  for (var y = ry; y < ry + rh && y < image.height; y++) {
    for (var x = rx; x < rx + rw && x < image.width; x++) {
      if (_inRoundedRect(x, y, rx, ry, rw, rh, cr)) {
        _blendPixel(image, x, y, r, g, b, a);
      }
    }
  }
}

// Draw a thick line with round caps by stamping circles along the path
void _drawRoundLine(img.Image image, int x1, int y1, int x2, int y2,
    int r, int g, int b, int halfWidth) {
  final dx = (x2 - x1).toDouble();
  final dy = (y2 - y1).toDouble();
  final len = math.sqrt(dx * dx + dy * dy);
  final steps = (len * 1.5).ceil();
  final hw2 = halfWidth * halfWidth;

  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final cx = (x1 + dx * t).round();
    final cy = (y1 + dy * t).round();
    final xMin = (cx - halfWidth).clamp(0, image.width - 1);
    final xMax = (cx + halfWidth).clamp(0, image.width - 1);
    final yMin = (cy - halfWidth).clamp(0, image.height - 1);
    final yMax = (cy + halfWidth).clamp(0, image.height - 1);
    for (var py = yMin; py <= yMax; py++) {
      for (var px = xMin; px <= xMax; px++) {
        final ox = px - cx;
        final oy = py - cy;
        if (ox * ox + oy * oy <= hw2) {
          image.setPixelRgba(px, py, r, g, b, 255);
        }
      }
    }
  }
}
