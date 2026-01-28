import 'package:flutter/material.dart';
import 'recommendation_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de recomendaciones'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Botón de ejemplo (luego será dinámico)
          ElevatedButton(
            onPressed: () {
              // Navega a la pantalla de detalle
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecommendationPage(
                    titulo: 'Recomendación de prueba',
                    contenido:
                        'Aquí se mostrará el contenido completo de la recomendación generada por la IA.',
                  ),
                ),
              );
            },
            child: const Text('Recomendación - Ejemplo'),
          ),
        ],
      ),
    );
  }
}
