import 'package:example/classic_ide_tab.dart';
import 'package:example/overlays_tab.dart';
import 'package:example/scoped_tab.dart';
import 'package:example/vertical_split_tab.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_panels/flutter_panels.dart';
import 'user_content_tab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panel Layout Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ExampleHome(),
    );
  }
}

// Global Configuration for the example app
final kAppPanelStyle = PanelStyle(
  headerPadding: 8.0,
  titleTextStyle: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    letterSpacing: 0.5,
  ),
  headerDecoration: BoxDecoration(
    color: Colors.grey[200],
    border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
  ),
  panelBoxDecoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.grey[300]!, width: 1),
  ),
);

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Layout Gallery'),
          bottom: TabBar(
            onTap: (index) {
              developer.log('[PERF] TabBar tapped index: $index');
            },
            isScrollable: true,
            tabs: const [
              Tab(text: 'Classic IDE', icon: Icon(Icons.grid_view)),
              Tab(text: 'Vertical Split', icon: Icon(Icons.splitscreen)),
              Tab(text: 'Overlays', icon: Icon(Icons.layers)),
              Tab(text: 'Scoped', icon: Icon(Icons.format_paint)),
              Tab(text: 'User Content', icon: Icon(Icons.code)),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            ClassicIdeTab(),
            VerticalSplitTab(),
            OverlaysTab(),
            ScopedTab(),
            UserContentTab(),
          ],
        ),
      ),
    );
  }
}
