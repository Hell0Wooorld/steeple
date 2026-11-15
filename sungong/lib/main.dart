import 'package:flutter/material.dart';

import 'data/study_store.dart';
import 'logic/rewards.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = StudyStore();
  await store.load();
  runApp(SungongApp(store: store));
}

class SungongApp extends StatelessWidget {
  const SungongApp({super.key, required this.store, this.policy = const RewardPolicy()});

  final StudyStore store;
  final RewardPolicy policy;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '순공',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)),
        useMaterial3: true,
      ),
      home: HomeScreen(store: store, policy: policy),
    );
  }
}
