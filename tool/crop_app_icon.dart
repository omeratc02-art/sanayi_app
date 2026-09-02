// Fixes assets/icon/app_icon.png so it's a full-bleed square with no
// visible background padding: flood-fills the light background margin and
// the four corner regions outside the rounded-square artwork with the
// icon's own teal fill color, turning the pre-rounded artwork into a plain
// solid square. That's what flutter_launcher_icons / iOS / Android expect
// as source input — each platform applies its own corner-rounding/masking
// on top, so a source that's already rounded leaves background showing
// through in the gap between the two roundings.
//
// Run with `dart run tool/crop_app_icon.dart`. Overwrites app_icon.png
// in place.
import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

const _inputPath = 'assets/icon/app_icon.png';
const _outputSize = 1024;

// How far a pixel's channels may differ from the sampled background color
// (per channel) and still be treated as background for flood-fill purposes.
// Looser than a strict color match so the thin anti-aliased blend pixels
// right at the artwork's rounded edge get pulled in too, instead of being
// left behind as a faint ring.
const _bgThreshold = 40;

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

  final bg = image.getPixel(0, 0);

  // Mode color (most frequent pixel) — with the rounded-square fill
  // covering far more area than the margin, the car outline, or the
  // wrench, this reliably lands on the teal fill rather than requiring a
  // hand-picked sample coordinate.
  final counts = HashMap<int, int>();
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final key = (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt();
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  final tealKey = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  final teal = img.ColorRgb8((tealKey >> 16) & 0xFF, (tealKey >> 8) & 0xFF, tealKey & 0xFF);
  stdout.writeln('Detected fill color: rgb(${teal.r.toInt()}, ${teal.g.toInt()}, ${teal.b.toInt()})');

  bool isBackground(int x, int y) {
    final p = image.getPixel(x, y);
    return (p.r - bg.r).abs() <= _bgThreshold &&
        (p.g - bg.g).abs() <= _bgThreshold &&
        (p.b - bg.b).abs() <= _bgThreshold;
  }

  // BFS flood-fill from every border pixel that's background-colored. The
  // margin forms one connected ring around the artwork touching all four
  // sides, so seeding from the whole border (not just one corner) covers
  // cases where a corner pixel itself happens to fall outside threshold.
  final visited = List.generate(image.height, (_) => List.filled(image.width, false));
  final queue = Queue<(int, int)>();
  void seed(int x, int y) {
    if (x < 0 || y < 0 || x >= image.width || y >= image.height) return;
    if (visited[y][x] || !isBackground(x, y)) return;
    visited[y][x] = true;
    queue.add((x, y));
  }

  for (var x = 0; x < image.width; x++) {
    seed(x, 0);
    seed(x, image.height - 1);
  }
  for (var y = 0; y < image.height; y++) {
    seed(0, y);
    seed(image.width - 1, y);
  }

  var filledCount = 0;
  while (queue.isNotEmpty) {
    final (x, y) = queue.removeFirst();
    filledCount++;
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= image.width || ny >= image.height) continue;
      if (visited[ny][nx] || !isBackground(nx, ny)) continue;
      visited[ny][nx] = true;
      queue.add((nx, ny));
    }
  }

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (visited[y][x]) image.setPixelRgb(x, y, teal.r, teal.g, teal.b);
    }
  }
  stdout.writeln('Flood-filled $filledCount background pixels with the fill color.');

  final resized = img.copyResize(
    image,
    width: _outputSize,
    height: _outputSize,
    interpolation: img.Interpolation.cubic,
  );

  file.writeAsBytesSync(img.encodePng(resized));
  stdout.writeln('Overwrote $_inputPath (${resized.width}x${resized.height}).');
}
