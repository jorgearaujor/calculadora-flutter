import 'package:flutter/material.dart';
import 'calculadora_page.dart';

void main() {
  runApp(const MyApp());
}

// Widget raiz (Stateless), pois ele não muda: a tela dentro dele é que muda
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ), // ThemeData
      // Definimos a tela inicial como a CalculadoraPage
      home: const CalculadoraPage(),
    ); // MaterialApp
  }
}
