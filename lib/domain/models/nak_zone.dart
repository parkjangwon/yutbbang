/// 게이지(컨트롤 모드)에서 멈추면 '낙'이 되는 구간. 값 범위는 0.0 ~ 1.0.
class NakZone {
  final double start;
  final double end;
  const NakZone(this.start, this.end);

  bool contains(double value) => value >= start && value <= end;
}
