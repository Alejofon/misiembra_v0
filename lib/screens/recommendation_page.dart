import 'package:flutter/material.dart';

class RecommendationPage extends StatelessWidget {
  final String titulo;
  final String contenido;

  const RecommendationPage({
    super.key,
    required this.titulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            contenido,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
