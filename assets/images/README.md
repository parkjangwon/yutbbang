# 이미지 에셋

디자인 기준: `docs/design/concept-modern-minimal.jpg` (모던 미니멀 시안, 2026-11-24 확정).
색과 테마는 코드(`lib/presentation/theme/app_palette.dart`, `app_theme.dart`)에 있고, 이미지는 질감이 필요한 것만 쓴다.

| 파일 | 용도 | 비고 |
|---|---|---|
| `ui/bg_game.jpg` | 로비·게임 배경 | 1024×1536, 가운데는 비어 있음. `BoxFit.cover`, 아래 정렬 |
| `yut/yut_flat.png` | 윷가락 배(평평한 면) | 투명 PNG, 높이 460 |
| `yut/yut_flat_backdo.png` | 빽도 표시가 있는 배 | 첫 번째 윷가락 전용 |
| `yut/yut_round.png` | 윷가락 등(둥근 면) | |
| `yutbbang.png` | 앱 아이콘 원본 | `flutter_launcher_icons` |

## 생성 방법

Codex CLI의 내장 이미지 생성(`image_gen`)으로 만들고, 시안 이미지를 스타일 참고로 넘겼다.

```bash
codex exec --skip-git-repo-check -i docs/design/concept-modern-minimal.jpg - < prompt.txt
```

공통 지시: "시안과 같은 스타일(따뜻한 아이보리, 테라코타·세이지·샌드 파스텔, 무광, 부드러운 그림자). UI·글자 없이 에셋만."

- 배경: 종이 질감 + 좌하·우하 파스텔 언덕(높이 18% 이하), 좌상단 세이가이하 선 무늬, 가운데 15~80%는 비움.
- 윷가락: 위에서 본 세로 윷가락 1개(폭:높이 약 1:4.4), 투명 배경. 배 = 밝은 원목 + 가는 가로 홈 3개, 빽도 = 배 + 가운데 X, 등 = 캐러멜색 원목 + X 3개.

생성 후 처리: 윷가락은 알파 40 기준으로 잘라 높이 460으로 줄이고, 배경은 JPEG(품질 86)로 저장했다. `test/presentation/app_assets_test.dart`가 경로와 디코딩을 검사한다.
