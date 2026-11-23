import 'package:material_ui/material_ui.dart';

import '../theme/app_assets.dart';
import '../theme/app_palette.dart';

/// 종이 질감 + 파스텔 언덕 배경. 이미지가 없으면 단색 바탕.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppPalette.background,
        image: DecorationImage(
          image: AssetImage(AppAssets.background),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
