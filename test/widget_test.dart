// 基础冒烟测试：验证启动器界面可正常构建并显示加载提示。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightmind_app/main.dart';

void main() {
  testWidgets('启动器显示加载提示', (WidgetTester tester) async {
    await tester.pumpWidget(const LightMindApp());

    // 启动时应显示加载文案
    expect(find.text('正在打开 LightMind…'), findsOneWidget);
  });
}
