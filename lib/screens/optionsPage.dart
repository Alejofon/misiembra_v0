import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'project_detail_page.dart';

class OptionsPage extends StatefulWidget {
  final String presupuesto;
  final String area;
  final String unidad;
  final String? tipoTerreno;
  final String departamento;
  final String municipio;

  const OptionsPage({
    super.key,
    required this.presupuesto,
    required this.area,
    required this.unidad,
    this.tipoTerreno,
    required this.departamento,
    required this.municipio,
  });

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  bool cargando = true;
  List<String> opciones = [];
  String? error;

  @override
  void initState() {
    super.initState();
    generarOpciones();
  }

  Future<void> generarOpciones() async {
    try {
      const String apiKey =
          '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'; // <- Coloca tu API key aquí

      final prompt =
          '''
Eres un ingeniero agrónomo experto en Colombia especializado en planificación agrícola basada en condiciones reales.

DATOS DEL AGRICULTOR:
- Departamento: ${widget.departamento}
- Municipio: ${widget.municipio}
- Presupuesto: ${widget.presupuesto} COP
- Área disponible: ${widget.area} ${widget.unidad}
- Tipo de terreno: ${widget.tipoTerreno ?? "No especificado"}

OBJETIVO:
Generar EXACTAMENTE 5 cultivos que sean REALMENTE VIABLES para este agricultor.

REGLAS CRÍTICAS:

1. VIABILIDAD OBLIGATORIA:
Cada cultivo debe cumplir TODAS estas condiciones:
- Compatible con el clima de la región
- Factible con el presupuesto disponible
- Adecuado para el tamaño del área
- Comúnmente cultivado en Colombia

2. PROHIBIDO:
- Sugerir cultivos inviables económicamente
- Sugerir cultivos que requieran alta inversión si el presupuesto es bajo
- Repetir cultivos similares (ej: papa criolla y papa común cuentan como uno)
- Usar ejemplos genéricos sin validar contexto

3. PRESUPUESTO:
- Si el presupuesto es bajo → prioriza cultivos de ciclo corto y baja inversión
- Si el presupuesto es medio → cultivos intermedios
- Si el presupuesto es alto → puedes incluir cultivos más exigentes

4. ÁREA:
- Área pequeña → cultivos intensivos o de alto valor
- Área grande → cultivos extensivos

5. SI NO EXISTEN 5 OPCIONES TOTALMENTE VIABLES:
- Devuelve solo las opciones reales disponibles (mínimo 3)
- NUNCA rellenes con opciones dudosas

6. FORMATO DE RESPUESTA:
- SOLO nombres de cultivos
- UNO por línea
- SIN números
- SIN viñetas
- SIN texto adicional
- SIN explicaciones

7. CALIDAD:
- Prioriza cultivos reales del contexto colombiano
- Evita cultivos poco comunes en la región

RESPUESTA:
Devuelve únicamente la lista final.
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.3,
          "max_tokens": 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contenido = data['choices'][0]['message']['content'] as String;

        final lista = contenido
            .split('\n')
            .where((linea) => linea.trim().isNotEmpty)
            .map((linea) => linea.trim())
            .toList();

        setState(() {
          opciones = lista.take(5).toList();
          cargando = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'No se pudieron generar recomendaciones: ${e.toString()}';
      });
    }
  }

  void _guardarEnHistorial(String cultivoSeleccionado) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historialActual = prefs.getStringList('historial') ?? [];

    final String nuevaRecomendacion = jsonEncode({
      'fecha': DateTime.now().toIso8601String(),
      'cultivo': cultivoSeleccionado,
      'departamento': widget.departamento,
      'municipio': widget.municipio,
      'presupuesto': widget.presupuesto,
      'area': '${widget.area} ${widget.unidad}',
      'terreno': widget.tipoTerreno ?? 'No especificado',
    });

    historialActual.insert(0, nuevaRecomendacion);
    if (historialActual.length > 20) historialActual.removeLast();
    await prefs.setStringList('historial', historialActual);
  }

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
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(error!),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          cargando = true;
                          error = null;
                          generarOpciones();
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
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
                        _guardarEnHistorial(opciones[index]);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectDetailPage(
                              cultivo: opciones[index],
                              zona:
                                  '${widget.departamento} - ${widget.municipio}',
                              presupuesto: widget.presupuesto,
                              area: widget.area,
                              unidad: widget.unidad,
                              departamento: widget.departamento,
                              municipio: widget.municipio,
                              tipoTerreno: widget.tipoTerreno,
                            ),
                          ),
                        );
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
