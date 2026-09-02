// Generates assets/icon/app_icon_foreground.png for Android's adaptive
// icon: the car+wrench artwork alone (teal background made transparent),
// scaled and centered so it sits within Android's 66% safe zone on a
// 1024x1024 canvas — outside that zone gets clipped differently by every
// launcher's own mask (circle, squircle, rounded square, ...), which is
// why a flat, unmasked icon shows a background ring on Android 8+.
//
// Run with `dart run tool/generate_adaptive_foreground.dart`.
import 'dart:io';

import 'package:image/image.dart' as img;

const _inputPath = 'assets/icon/app_icon.png';
const _outputPath = 'assets/icon/app_icon_foreground.png';
const _canvasSize = 1024;

// Android's adaptive icon spec: only the center 66% (72dp of a 108dp
// layer) is guaranteed visible across all mask shapes.
const _safeZoneFraction = 0.66;

// The artwork uses exactly two non-background colors (sampled from the
// image): the white car outline and the mint wrench. Allowlisting these
// two, rather than blocklisting the teal background, is what's needed
// here — the original source's rounded-square edge left a thin ring of
// anti-aliased teal/gray blend pixels that the earlier corner flood-fill
// didn't fully absorb (they weren't "background enough" for that script's
// own threshold either), and a blocklist keeps re-including that ring as
// artwork. Those blend pixels aren't close to white or mint, so they
// correctly drop out here instead.
const _white = (r: 255, g: 255, b: 255);
const _mint = (r: 148, g: 229, b: 217);
const _foregroundThreshold = 40;

// The anti-aliased ring sits close to app_icon.png's own outer edge (it's
// what's left of the source's original rounded-square boundary, which
// nearly touched that edge before the earlier corner fill). The real
// car+wrench artwork sits well clear of it, so pixels this close to any
// border are never treated as foreground, regardless of color match.
const _edgeMargin = 90;

void main() {
  final file = File(_inputPath);
  if (!file.existsSync()) {
    stderr.writeln('Not found: $_inputPath');
    exit(1);
  }

  final image = img.decodePng(file.readAsBytesSync());
  if (image == null) {
    stderr.writeln('Could not decode $_inputPath as PNG');
    exit(1);
  }

  bool isCloseTo(img.Pixel p, ({int r, int g, int b}) target) {
    return (p.r - target.r).abs() <= _foregroundThreshold &&
        (p.g - target.g).abs() <= _foregroundThreshold &&
        (p.b - target.b).abs() <= _foregroundThreshold;
  }

  bool isForeground(img.Pixel p) => isCloseTo(p, _white) || isCloseTo(p, _mint);

  // Keep only pixels matching one of the two known artwork colors; make
  // everything else (the background fill, and its leftover edge ring)
  // transparent.
  final cutout = img.Image(width: image.width, height: image.height, numChannels: 4);
  var minX = image.width, minY = image.height, maxX = 0, maxY = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final nearEdge = x < _edgeMargin || y < _edgeMargin || x >= image.width - _edgeMargin || y >= image.height - _edgeMargin;
      final p = image.getPixel(x, y);
      if (!nearEdge && isForeground(p)) {
        cutout.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      } else {
        cutout.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  if (minX > maxX || minY > maxY) {
    stderr.writeln('No artwork detected — white/mint colors may not match this source image.');
    exit(1);
  }

  final artworkWidth = maxX - minX + 1;
  final artworkHeight = maxY - minY + 1;
  final cropped = img.copyCrop(cutout, x: minX, y: minY, width: artworkWidth, height: artworkHeight);

  // Scale so the artwork's longer side exactly fills the safe zone,
  // preserving aspect ratio.
  final safeZonePx = (_canvasSize * _safeZoneFraction).round();
  final scale = safeZonePx / (artworkWidth > artworkHeight ? artworkWidth : artworkHeight);
  final scaledWidth = (artworkWidth * scale).round();
  final scaledHeight = (artworkHeight * scale).round();
  final scaled = img.copyResize(
    cropped,
    width: scaledWidth,
    height: scaledHeight,
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(width: _canvasSize, height: _canvasSize, numChannels: 4);
  // Fully transparent canvas (img.Image defaults to transparent black,
  // but this is explicit rather than relying on that default).
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  img.compositeImage(
    canvas,
    scaled,
    dstX: (_canvasSize - scaledWidth) ~/ 2,
    dstY: (_canvasSize - scaledHeight) ~/ 2,
  );

  File(_outputPath).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln(
    'Artwork bbox: ${artworkWidth}x$artworkHeight -> scaled to ${scaledWidth}x$scaledHeight '
    '(safe zone target: ${safeZonePx}px of $_canvasSize).',
  );
  stdout.writeln('Wrote $_outputPath (${_canvasSize}x$_canvasSize, transparent background).');
}
