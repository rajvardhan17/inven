import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/auth/SplashScreen.dart';
import 'data/order_data.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => OrderData(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BizAdmin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}
