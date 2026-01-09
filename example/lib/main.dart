import 'package:flutter/material.dart';

import 'bloc_tab.dart';
import 'vanilla_tab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panel Layout Example',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Layout Examples'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vanilla (Pure)'),
              Tab(text: 'BLoC Integration'),
            ],
          ),
        ),
        body: const TabBarView(children: [VanillaTab(), BlocTab()]),
      ),
    );
  }
}
