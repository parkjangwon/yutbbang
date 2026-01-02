import 'package:flutter/material.dart';

class YutGuideScreen extends StatelessWidget {
  const YutGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('윷놀이 가이드'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _SectionTitle('간단한 개요'),
          _SectionBody(
            '윷놀이는 윷(막대기 4개)을 던져 나온 결과만큼 말을 이동하는 전통 보드게임입니다. '
            '말을 잡아 상대를 되돌리고, 보너스 턴을 활용해 먼저 모든 말을 완주시키면 승리합니다.',
          ),
          _SectionTitle('윷놀이 기본 규칙'),
          _BulletList(
            items: [
              '윷을 던져 나온 결과(도/개/걸/윷/모)만큼 말이 이동합니다.',
              '윷/모가 나오면 보너스 턴이 주어집니다.',
              '상대 말이 있는 칸에 도착하면 잡아서 상대 말을 시작점으로 돌려보냅니다.',
              '같은 팀 말이 같은 칸에 있으면 겹쳐 이동할 수 있습니다.',
              '지름길(대각선)이 있는 칸에서는 직진/지름길 중 선택할 수 있습니다.',
            ],
          ),
          _SectionTitle('판 경로와 지름길'),
          _BulletList(
            items: [
              '기본 경로는 사각형 테두리를 따라 이동합니다.',
              '첫 번째/두 번째 꼭지점(우상/좌상)에서는 대각선 지름길로 진입할 수 있습니다.',
              '중앙(한복판)에서는 내려오는 방향에 따라 좌/우 대각선으로 내려갑니다.',
              '세 번째 꼭지점(좌하)에서는 지름길 선택 없이 직진만 가능합니다.',
            ],
          ),
          _SectionTitle('빽도 / 낙 규칙'),
          _BulletList(
            items: [
              '빽도는 직전 이동 방향의 반대로 1칸 이동합니다.',
              '보드에 들어온 이후 빽도가 나오면 최소한 시작점(0)으로 되돌아갑니다.',
              '낙은 이번 턴에 이동하지 못하고 턴이 바로 넘어갑니다.',
            ],
          ),
          _SectionTitle('특수 규칙 (House Rules)'),
          _BulletList(
            items: [
              '빽도 날기: 말이 출발 전(대기 상태)일 때 빽도가 나오면 즉시 완주(골인) 처리됩니다.',
              '자동 임신: 중앙 지점(방석)에 말이 도착하면 대기 중인 내 말 하나를 자동으로 불러와 업습니다.',
              '전낙: 윷/모를 던져 이동권이 남은 상태에서 낙이 나오면, 이번 턴의 모든 이전 결과가 취소되고 턴이 종료됩니다.',
              '군밤 모드: 지름길 구간(첫 번째/두 번째 꼭지점)에서 항상 최단 거리로 자동 선택됩니다.',
            ],
          ),
          _SectionTitle('윷빵 게임 설명'),
          _BulletList(
            items: [
              '게임 시작 설정에서 팀 수, 팀 이름, 말 수, 빽도 사용, 낙 확률을 선택합니다.',
              '컨트롤 모드: 버튼을 누르고 있다가 원하는 게이지 위치(낙 영역 회피)에서 떼어 결과를 결정합니다.',
              '턴 인디케이터: 상단 바의 배경색이 현재 턴 팀의 색상으로 변하여 턴 정보를 알려줍니다.',
              '팀별로 CPU 또는 플레이어(로컬)로 지정할 수 있습니다.',
              '잡으면 보너스 턴을 얻고, 잡힌 말은 대기 공간으로 돌아갑니다.',
            ],
          ),
          _SectionTitle('전략 팁'),
          _BulletList(
            items: [
              '중앙 지점(방석)에 도착하면 무조건 완주 지점 방향으로 최단 경로가 고정됩니다.',
              '상대 말을 잡는 것이 가장 큰 우선순위입니다. 보너스 턴도 얻습니다.',
              '지름길은 빠르지만 위험할 수 있으니 상황에 따라 선택하세요.',
            ],
          ),
          _SectionTitle('승리 조건과 완주'),
          _BulletList(
            items: [
              '모든 말이 완주하면 승리합니다.',
              '완주는 보드를 한 바퀴 돌아 도착점을 넘길 때 이루어집니다.',
              '완주한 말은 보드에서 제외되고 더 이상 이동하지 않습니다.',
            ],
          ),
          _SectionTitle('용어 정리'),
          _BulletList(
            items: [
              '도/개/걸/윷/모: 이동 칸 수(1~5)를 의미합니다.',
              '빽도: 직전 이동 방향의 반대로 1칸 이동합니다.',
              '낙: 이동하지 못하고 턴이 넘어갑니다.',
              '컨트롤 모드: 게이지 시스템으로 윷 던지기 결과를 조절하는 모드입니다.',
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 15, height: 1.5));
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
