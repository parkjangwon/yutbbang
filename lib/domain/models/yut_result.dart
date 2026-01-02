enum YutResult {
  do_(1, "도"),
  gae(2, "개"),
  geol(3, "걸"),
  yut(4, "윷"),
  mo(5, "모"),
  backDo(-1, "빽도"),
  nak(0, "낙");

  final int moveCount;
  final String label;
  const YutResult(this.moveCount, this.label);

  bool get isBonusTurn => this == YutResult.yut || this == YutResult.mo;
  bool get isFail => this == YutResult.nak;
}
