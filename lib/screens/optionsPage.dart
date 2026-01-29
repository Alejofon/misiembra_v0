import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OptionsPage extends StatefulWidget {
  final String presupuesto;
  final String area;
  final String unidad;
  final String? tipoTerreno;

  const OptionsPage({
    super.key,
    required this.presupuesto,
    required this.area,
    required this.unidad,
    this.tipoTerreno,
  });

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  // ====== ESTADO ======
  bool cargando = true;
  List<String> opciones = [];
  String? error;

  // ====== CICLO DE VIDA ======
  @override
  void initState() {
    super.initState();
    generarOpciones();
  }

  // ====== LÓGICA ======
  Future<void> generarOpciones() async {
    try {
      final prompt = '''
Eres un asesor agrícola profesional en Colombia.

Con estos datos:
Presupuesto: ${widget.presupuesto}
Área disponible: ${widget.area} ${widget.unidad}
Tipo de terreno: ${widget.tipoTerreno ?? "No especificado"}

Dame SOLO 3 opciones viables de cultivos.
Devuélvelas en formato de lista corta.
Solo títulos, uno por línea.
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer TU_API_KEY_AQUI',
        },
        body: jsonEncode({
          "model": "gpt-4.1-mini",
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.5
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final contenido =
            data['choices'][0]['message']['content'] as String;

        final lista = contenido
            .split('\n')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.replaceAll(RegExp(r'^[0-9\-\.\)]\s*'), ''))
            .toList();

        setState(() {
          opciones = lista;
          cargando = false;
        });
      } else {
        throw Exception('Error en la API');
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'No se pudieron generar recomendaciones';
      });
    }
  }

  // ====== INTERFAZ ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones de siembra'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: cargando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : error != null
                ? Center(
                    child: Text(
                      error!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: opciones.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Aquí después navegas al detalle
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              opciones[index],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

