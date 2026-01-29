// Importa Flutter Material para usar widgets de interfaz
import 'package:flutter/material.dart';

// Pantalla que muestra la recomendación detallada del cultivo
class RecommendationDetailPage extends StatelessWidget {
  const RecommendationDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos simulados (luego vendrán de la API)
    final String cultivo = "Maíz criollo";
    final String zona = "Zona templada - Altitud media (1.500 - 2.000 msnm)";
    final String presupuesto = "\$1.200.000 COP";
    final String tiempoCosecha = "4 a 5 meses";

    final List<String> pasos = [
      "Preparar el terreno eliminando maleza y nivelando el suelo.",
      "Realizar surcos con una separación de 80 cm entre filas.",
      "Sembrar las semillas a una profundidad de 4 a 6 cm.",
      "Regar ligeramente después de la siembra.",
      "Aplicar fertilizante orgánico a los 20 días.",
      "Monitorear plagas semanalmente."
    ];

    final List<String> riesgos = [
      "Exceso de lluvia puede causar pudrición de raíces.",
      "Presencia de gusano cogollero en etapas tempranas.",
      "Suelos muy compactos reducen el crecimiento."
    ];

    // Scaffold define la estructura general de la pantalla
    return Scaffold(
      // Barra superior
      appBar: AppBar(
        title: const Text("Recomendación agrícola"),
        centerTitle: true,
      ),

      // Cuerpo principal con scroll
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarjeta principal con el nombre del cultivo
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.agriculture,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cultivo,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Información general
              _buildInfoSection(
                icon: Icons.location_on,
                title: "Zona recomendada",
                content: zona,
              ),

              _buildInfoSection(
                icon: Icons.attach_money,
                title: "Presupuesto estimado",
                content: presupuesto,
              ),

              _buildInfoSection(
                icon: Icons.calendar_month,
                title: "Tiempo aproximado de cosecha",
                content: tiempoCosecha,
              ),

              const SizedBox(height: 20),

              // Pasos de siembra
              _buildListSection(
                icon: Icons.format_list_numbered,
                title: "Pasos para la siembra",
                items: pasos,
              ),

              const SizedBox(height: 20),

              // Riesgos y recomendaciones
              _buildListSection(
                icon: Icons.warning_amber,
                title: "Riesgos y recomendaciones",
                items: riesgos,
              ),

              const SizedBox(height: 30),

              // Botón para volver
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  "Volver a opciones",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget reutilizable para secciones de información simple
  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget reutilizable para listas con viñetas numeradas
  Widget _buildListSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista de ítems
            ...items.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final text = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$index. ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(text)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
