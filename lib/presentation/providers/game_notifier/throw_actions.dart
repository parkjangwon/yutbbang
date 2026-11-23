part of '../game_provider.dart';

/// 윷 던지기, 결과 처리(낙·빽도·윷/모 보너스), 게이지(컨트롤 모드), 다시 던지기.
mixin _ThrowActions on _GameNotifierBase {
  @override
  void throwYut({bool forceNak = false}) {
    if (state.status != GameStatus.throwing) return;
    state = state.copyWith(status: GameStatus.moving);

    final throwRes = state.isFixedDiceActive
        ? YutLogic.throwGolden(random: _random)
        : YutLogic.throwYut(
            forceNak: forceNak,
            // 컨트롤 모드에서는 게이지의 낙 구간이 낙을 결정한다.
            randomNakChance: _rules.useGaugeControl
                ? 0.0
                : _rules.nakChancePercent / 100.0,
            useBackDo: _rules.useBackDo,
            random: _random,
          );
    final result = throwRes.result;

    if (_isHumanTurn) _triggerThrowFeedback(result);
    _log('${state.currentTeam.name}: ${result.label}');

    state = state.copyWith(
      lastStickStates: throwRes.sticks,
      lastResult: result,
      isFixedDiceActive: false,
    );

    // 윷 애니메이션이 끝난 뒤 결과를 처리한다.
    _later(const Duration(milliseconds: 1000), () {
      final team = state.currentTeam;
      // 윷·모는 다시 던질 이유가 없으므로 묻지 않는다.
      if (team.items.contains(ItemType.reroll) && !result.isBonusTurn) {
        if (team.isHuman) {
          state = state.copyWith(showRerollChoice: true);
          return;
        }
        if (result == YutResult.nak) {
          // CPU는 낙일 때만 다시 던지기를 쓴다.
          confirmReroll(true);
          return;
        }
      }
      _processThrowResult(result);
    });
  }

  void _processThrowResult(YutResult result) {
    if (result == YutResult.nak) {
      _processNak();
      return;
    }

    if (result == YutResult.backDo && _isWastedBackDo()) {
      // 움직일 말이 없는 빽도는 버린다.
      _finalizeMove();
      return;
    }

    final newThrows = [...state.currentThrows, result];
    if (result.isBonusTurn) {
      _displayBonusTurn('한번 더!');
      state = state.copyWith(
        currentThrows: newThrows,
        status: GameStatus.throwing,
      );
      if (!_isHumanTurn) {
        _aiLater(1000, throwYut);
      }
      return;
    }

    state = state.copyWith(
      currentThrows: newThrows,
      status: GameStatus.selectingMal,
    );
    _promptMalSelection();
  }

  /// 낙 처리.
  /// - 낙 방지권이 있으면 자동으로 소모하고 '도'로 바꾼다.
  /// - 전낙 규칙이면 이번 턴에 모아둔 결과까지 모두 버리고 턴을 넘긴다.
  /// - 기본 규칙에서는 앞서 나온 윷/모 결과는 그대로 쓸 수 있다.
  void _processNak() {
    if (state.currentTeam.items.contains(ItemType.shield)) {
      _consumeItem(_teamIndex, ItemType.shield);
      state = state.copyWith(
        currentThrows: [...state.currentThrows, YutResult.do_],
        lastResult: YutResult.do_,
        status: GameStatus.selectingMal,
      );
      if (!_isHumanTurn) {
        _aiLater(1500, aiSelectAndMove);
      }
      return;
    }

    if (state.currentThrows.isEmpty) {
      nextTurn();
      return;
    }
    if (_rules.totalNak) {
      state = state.copyWith(currentThrows: []);
      nextTurn();
      return;
    }
    state = state.copyWith(status: GameStatus.selectingMal);
    if (!_isHumanTurn) {
      _aiLater(1500, aiSelectAndMove);
    }
  }

  /// 판 위에 말이 없고 빽도 날기도 못 하는 빽도인지.
  bool _isWastedBackDo() {
    final team = state.currentTeam;
    if (team.hasMalOnBoard) return false;
    final canFly = _rules.backDoFlying && team.mals.any((m) => m.isWaiting);
    return !canFly;
  }

  @override
  void confirmReroll(bool use) {
    state = state.copyWith(showRerollChoice: false);

    if (!use) {
      final last = state.lastResult;
      if (last != null) _processThrowResult(last);
      return;
    }

    final isHuman = _isHumanTurn;
    _consumeItem(_teamIndex, ItemType.reroll);
    state = state.copyWith(status: GameStatus.throwing, lastResult: null);
    HapticFeedback.mediumImpact();
    if (!isHuman) {
      _aiLater(1000, throwYut);
    }
  }

  /// 컨트롤 모드: 버튼을 누르면 게이지가 왕복하기 시작한다.
  /// CPU는 게이지 없이 낙 확률만 적용해서 바로 던진다.
  void startGauge() {
    if (state.status != GameStatus.throwing || state.isGaugeRunning) return;
    if (!_isHumanTurn) {
      final nakChance = _rules.nakChancePercent / 100.0;
      throwYut(forceNak: _random.nextDouble() < nakChance);
      return;
    }

    final settings = GaugeSettings.forNakChance(_rules.nakChancePercent);
    _gaugeDirection = 1.0;
    state = state.copyWith(
      isGaugeRunning: true,
      gaugeValue: 0.0,
      nakZones: GaugeLogic.generateNakZones(_rules.nakChancePercent, _random),
    );

    _gaugeTimer?.cancel();
    _gaugeTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final (value, direction) = GaugeLogic.step(
        state.gaugeValue,
        _gaugeDirection,
        settings.speedStep,
      );
      _gaugeDirection = direction;
      state = state.copyWith(gaugeValue: value);
    });
  }

  /// 버튼을 떼면 게이지를 멈추고, 낙 구간이면 낙으로 던진다.
  void stopGauge() {
    if (!state.isGaugeRunning) return;
    _cancelGauge();
    final forceNak = GaugeLogic.isInNakZone(state.gaugeValue, state.nakZones);
    state = state.copyWith(isGaugeRunning: false);
    throwYut(forceNak: forceNak);
  }
}
