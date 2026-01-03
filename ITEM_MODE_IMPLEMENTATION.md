# 아이템 모드 구현 상태

## ✅ 완료된 구현

### 1. 기본 구조

- [x] 아이템 모델 생성 (`game_item.dart`)
  - 5가지 아이템 타입 정의
  - 이름, 설명, 이모지 포함
- [x] GameRuleConfig에 `useItemMode` 추가
- [x] Team 모델에 `items` 인벤토리 추가
- [x] GameState에 아이템 관련 필드 추가
  - `itemTiles`: 아이템이 있는 노드 ID
  - `pendingItem`: 획득 대기 중인 아이템
  - `showItemChoice`: 인벤토리 꽉 찬 경우 선택 UI

### 2. UI 설정

- [x] 기본 설정 화면에 아이템 모드 스위치 추가
- [x] 게임 시작 설정 화면에 아이템 모드 스위치 추가
- [x] 설정 저장/로드 로직 구현

### 3. 게임 로직

- [x] 게임 시작 시 아이템 타일 생성 (30% 비율)

## 🚧 남은 구현 사항

### 4. 게임판 시각화 (Flame Engine)

**파일**: `lib/game/components/board_component.dart`

```dart
// TODO: 아이템 타일 표시
// itemTiles Set에 포함된 노드에 황금색/노란색 원 또는 별 표시
// 예: Paint()..color = Colors.amber.withOpacity(0.7)
```

### 5. 아이템 획득 로직

**파일**: `lib/presentation/providers/game_provider.dart`
**함수**: `_applyMoveResult()`

```dart
// TODO: 말이 아이템 타일에 도착했을 때
if (state.itemTiles.contains(destinationId)) {
  // 랜덤 아이템 생성
  final randomItem = GameItem.allItems[Random().nextInt(GameItem.allItems.length)].type;

  // 인벤토리 확인
  if (team.items.length < 2) {
    // 바로 추가
    final newItems = List<ItemType>.from(team.items)..add(randomItem);
    nextTeams[teamIndex] = team.copyWith(items: newItems);

    // 타일에서 아이템 제거
    final newItemTiles = Set<int>.from(state.itemTiles)..remove(destinationId);
    state = state.copyWith(itemTiles: newItemTiles);
  } else {
    // 인벤토리 꽉 참 - 선택 UI 표시
    state = state.copyWith(
      pendingItem: randomItem,
      showItemChoice: true,
    );
  }
}
```

### 6. 아이템 선택 UI

**파일**: `lib/presentation/screens/game_screen.dart`

```dart
// TODO: showItemChoice가 true일 때 다이얼로그 표시
if (state.showItemChoice && state.pendingItem != null)
  _buildItemChoiceDialog(state)

Widget _buildItemChoiceDialog(GameState state) {
  return AlertDialog(
    title: Text('아이템 획득'),
    content: Column(
      children: [
        Text('인벤토리가 꽉 찼습니다!'),
        Text('새 아이템: ${GameItem.fromType(state.pendingItem!).name}'),
        // 기존 아이템 2개 표시
        // 선택 버튼: 교체 or 포기
      ],
    ),
  );
}
```

### 7. 아이템 인벤토리 UI

**파일**: `lib/presentation/widgets/item_inventory.dart` (새 파일)

```dart
class ItemInventory extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final team = state.currentTeam;

    // 화면 크기에 따라 레이아웃 변경
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      // 태블릿: 우측 세로 정렬
      return Positioned(
        right: 20,
        top: 100,
        child: Column(children: _buildItemSlots(team.items)),
      );
    } else {
      // 모바일: 상단 가로 정렬
      return Positioned(
        top: 80,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildItemSlots(team.items),
        ),
      );
    }
  }

  List<Widget> _buildItemSlots(List<ItemType> items) {
    return [
      _buildItemSlot(items.length > 0 ? items[0] : null),
      SizedBox(width: 8, height: 8),
      _buildItemSlot(items.length > 1 ? items[1] : null),
    ];
  }

  Widget _buildItemSlot(ItemType? item) {
    return GestureDetector(
      onTap: item != null ? () => _useItem(item) : null,
      onLongPress: item != null ? () => _showItemDescription(item) : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: item != null ? Colors.amber : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            item != null ? GameItem.fromType(item).emoji : '?',
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
```

### 8. 아이템 사용 로직

**파일**: `lib/presentation/providers/game_provider.dart`

```dart
void useItem(ItemType itemType) {
  final teamIndex = state.turnIndex % state.teams.length;
  final team = state.teams[teamIndex];

  // 아이템이 인벤토리에 있는지 확인
  if (!team.items.contains(itemType)) return;

  switch (itemType) {
    case ItemType.reroll:
      // 다시 던지기
      _handleReroll(teamIndex);
      break;
    case ItemType.shield:
      // 낙 방지권 (자동 적용이므로 사용 불가)
      break;
    case ItemType.magnet:
      // 자석
      _handleMagnet(teamIndex);
      break;
    case ItemType.moonwalk:
      // 뒷걸음질
      _handleMoonwalk(teamIndex);
      break;
    case ItemType.typhoon:
      // 태풍
      _handleTyphoon(teamIndex);
      break;
  }

  // 아이템 제거
  final newItems = List<ItemType>.from(team.items)..remove(itemType);
  final nextTeams = List<Team>.from(state.teams);
  nextTeams[teamIndex] = team.copyWith(items: newItems);
  state = state.copyWith(teams: nextTeams);
}

void _handleReroll(int teamIndex) {
  // 현재 결과 무시하고 다시 던지기
  state = state.copyWith(
    currentThrows: [],
    lastResult: null,
    status: GameStatus.throwing,
  );
}

void _handleMagnet(int teamIndex) {
  // 내 말 앞 3칸 이내 상대 말 찾아서 잡기
  // TODO: 구현
}

void _handleMoonwalk(int teamIndex) {
  // 뒤로 가기 옵션 제공
  // TODO: 구현
}

void _handleTyphoon(int teamIndex) {
  // 모든 말 위치 섞기
  final random = Random();
  final nextTeams = List<Team>.from(state.teams);

  // 모든 팀의 말 위치 수집
  final allPositions = <int>[];
  for (var team in nextTeams) {
    for (var mal in team.mals) {
      if (mal.currentNodeId != null && !mal.isFinished) {
        allPositions.add(mal.currentNodeId!);
      }
    }
  }

  // 위치 섞기
  allPositions.shuffle(random);

  // 다시 배치
  int posIndex = 0;
  for (int i = 0; i < nextTeams.length; i++) {
    final team = nextTeams[i];
    final newMals = team.mals.map((mal) {
      if (mal.currentNodeId != null && !mal.isFinished) {
        return mal.copyWith(currentNodeId: allPositions[posIndex++]);
      }
      return mal;
    }).toList();
    nextTeams[i] = team.copyWith(mals: newMals);
  }

  state = state.copyWith(teams: nextTeams);
}
```

### 9. 낙 방지권 자동 적용

**파일**: `lib/presentation/providers/game_provider.dart`
**함수**: `throwYut()`

```dart
// TODO: 낙이 나왔을 때 Shield 아이템 확인
if (result == YutResult.nak) {
  final team = state.currentTeam;
  if (team.items.contains(ItemType.shield)) {
    // Shield 사용하여 '도'로 변경
    final newItems = List<ItemType>.from(team.items)..remove(ItemType.shield);
    final teamIndex = state.turnIndex % state.teams.length;
    final nextTeams = List<Team>.from(state.teams);
    nextTeams[teamIndex] = team.copyWith(items: newItems);

    // 결과를 '도'로 변경
    result = YutResult.do_;
    state = state.copyWith(teams: nextTeams);
  }
}
```

## 📝 구현 우선순위

1. **높음**: 아이템 획득 로직 (5번)
2. **높음**: 아이템 인벤토리 UI (7번)
3. **중간**: 게임판 시각화 (4번)
4. **중간**: 아이템 선택 UI (6번)
5. **낮음**: 각 아이템 사용 로직 (8번, 9번)

## 💡 참고사항

- 아이템은 현재 턴의 플레이어만 사용 가능
- Shield는 자동 적용되므로 별도 사용 버튼 불필요
- Moonwalk는 도/개/걸이 나왔을 때만 활성화
- Magnet은 선택 가능한 상대 말이 있을 때만 활성화
