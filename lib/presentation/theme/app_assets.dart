/// 이미지 에셋 경로. 생성 원본과 프롬프트는 `assets/images/README.md` 참고.
abstract final class AppAssets {
  /// 게임·로비 배경(종이 질감 + 파스텔 언덕). 가운데는 비어 있다.
  static const background = 'assets/images/ui/bg_game.jpg';

  /// 윷가락: 배(평평한 면), 빽도 표시가 있는 배, 등(둥근 면).
  static const yutFlat = 'assets/images/yut/yut_flat.png';
  static const yutFlatBackDo = 'assets/images/yut/yut_flat_backdo.png';
  static const yutRound = 'assets/images/yut/yut_round.png';

  static const all = [background, yutFlat, yutFlatBackDo, yutRound];
}
