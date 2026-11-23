import 'dart:ui' show instantiateImageCodec;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutbbang/presentation/theme/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('모든 이미지 에셋이 번들에 포함되어 디코딩된다', () async {
    for (final path in AppAssets.all) {
      final data = await rootBundle.load(path);
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: path);
    }
  });

  test('윷가락 스프라이트는 세로로 긴 투명 PNG', () async {
    for (final path in [
      AppAssets.yutFlat,
      AppAssets.yutFlatBackDo,
      AppAssets.yutRound,
    ]) {
      expect(path, endsWith('.png'));
      final data = await rootBundle.load(path);
      final frame = await (await instantiateImageCodec(
        data.buffer.asUint8List(),
      )).getNextFrame();
      expect(
        frame.image.height / frame.image.width,
        greaterThan(3),
        reason: path,
      );
    }
  });
}
