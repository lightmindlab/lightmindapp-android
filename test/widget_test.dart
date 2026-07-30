// 基础冒烟测试：验证启动器界面可正常构建。
// 加载过程中显示小鸡破壳动画图，此处仅验证应用可挂载不抛异常。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightmind_app/main.dart';

void main() {
  testWidgets('启动器可正常构建', (WidgetTester tester) async {
    await tester.pumpWidget(const LightMindApp());
    // 触发一帧，确保不抛异常
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
