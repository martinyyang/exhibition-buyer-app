import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/core/utils/responsive.dart';

void main() {
  group('Responsive 工具类测试', () {
    testWidgets('isMobile 在宽度<600时返回true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(599, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.isMobile(context), isTrue);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('isMobile 在宽度>=600时返回false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(600, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.isMobile(context), isFalse);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('isTablet 在宽度600-1199时返回true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(900, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.isTablet(context), isTrue);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop 在宽度>=1200时返回true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(1200, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.isDesktop(context), isTrue);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns 移动端返回2', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(400, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.getGridColumns(context), 2);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns 平板返回3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(900, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.getGridColumns(context), 3);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns 桌面端返回4', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(1200, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.getGridColumns(context), 4);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('ResponsiveLayout 在移动端显示mobile widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: ResponsiveLayout(
              mobile: const Text('Mobile'),
              tablet: const Text('Tablet'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('ResponsiveLayout 在平板显示tablet widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(900, 800)),
            child: ResponsiveLayout(
              mobile: const Text('Mobile'),
              tablet: const Text('Tablet'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('ResponsiveLayout 在桌面端显示desktop widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveLayout(
              mobile: const Text('Mobile'),
              tablet: const Text('Tablet'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
    });

    testWidgets('ResponsiveLayout 无tablet时使用mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(900, 800)),
            child: ResponsiveLayout(
              mobile: const Text('Mobile'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('ResponsiveLayout 无desktop时使用tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveLayout(
              mobile: const Text('Mobile'),
              tablet: const Text('Tablet'),
            ),
          ),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
    });

    testWidgets('ResponsiveContainer 限制最大宽度', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1600, 800)),
            child: ResponsiveContainer(
              maxWidth: 1200,
              child: Container(
                color: Colors.blue,
                child: const Text('Content'),
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ResponsiveContainer),
          matching: find.byWidgetPredicate(
            (widget) => widget is Container && widget.constraints != null,
          ),
        ),
      );

      expect(container.constraints?.maxWidth, 1200);
    });

    testWidgets('getSidebarWidth 桌面端返回280', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(1200, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.getSidebarWidth(context), 280);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('getSidebarWidth 平板返回240', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(900, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.getSidebarWidth(context), 240);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('getSidebarWidth 移动端返回0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(400, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.getSidebarWidth(context), 0);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('shouldShowSidebar 移动端返回false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(400, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.shouldShowSidebar(context), isFalse);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('shouldShowSidebar 平板和桌面端返回true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: const MediaQueryData(size: Size(900, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.shouldShowSidebar(context), isTrue);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
    });
  });
}
