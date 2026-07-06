import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'history_page.dart';
import 'options_page.dart';
import '../utils/number_format.dart';
import '../utils/snackbar_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController presupuestoController = TextEditingController();

  final TextEditingController extensionController = TextEditingController();

  String? departamento;
  String? municipio;

  double? lat;
  double? lon;

  final List<String> unidadesMedida = [
    'Metros cuadrados',
    'Hectáreas',
    'Fanegadas',
    'Acres',
    'Kilómetros cuadrados',
  ];

  String? unidadSeleccionada;

  final List<String> tiposTerreno = [
    'Plano',
    'Montañoso',
    'Ondulado',
    'Arenoso',
    'Arcilloso',
    'Mixto',
  ];

  String? tipoTerrenoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      departamento = prefs.getString('departamento');

      municipio = prefs.getString('municipio');

      lat = prefs.getDouble('lat');

      lon = prefs.getDouble('lon');
    });
  }

  bool validarCampos() {
    if (presupuestoController.text.trim().isEmpty) {
      return false;
    }

    if (extensionController.text.trim().isEmpty) {
      return false;
    }

    if (unidadSeleccionada == null) {
      return false;
    }

    if (lat == null || lon == null) {
      return false;
    }

    return true;
  }

  bool get _puedeConsultar => validarCampos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiSiembra - Consulta'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Planificación agrícola inteligente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MiSiembra analiza condiciones geográficas y variables del terreno para generar recomendaciones agrícolas contextualizadas y apoyar la toma de decisiones productivas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              Card(
                elevation: 2,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 35,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ubicación detectada',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$departamento - $municipio',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                child: const Text(
                  'Ver recomendaciones anteriores',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: presupuestoController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  final formatted = formatNumberWithDots(value);
                  if (formatted != presupuestoController.text) {
                    presupuestoController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Presupuesto disponible (COP)',
                  hintText: 'Ejemplo: 1.500.000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: extensionController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Extensión aproximada del terreno',
                  hintText: 'Ejemplo: 2',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Unidad de medida',
                  border: OutlineInputBorder(),
                ),
                initialValue: unidadSeleccionada,
                items: unidadesMedida.map((String unidad) {
                  return DropdownMenuItem<String>(
                    value: unidad,
                    child: Text(unidad),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    unidadSeleccionada = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de terreno (opcional)',
                  border: OutlineInputBorder(),
                ),
                initialValue: tipoTerrenoSeleccionado,
                items: tiposTerreno.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    tipoTerrenoSeleccionado = value;
                  });
                },
              ),
              const SizedBox(height: 35),
              ElevatedButton(
                onPressed: _puedeConsultar
                    ? () {
                        if (!validarCampos()) {
                          showTopSnackBar(
                            context,
                            'Completa todos los campos requeridos',
                            backgroundColor: Colors.red.shade700,
                          );

                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OptionsPage(
                              presupuesto: presupuestoController.text,
                              area: extensionController.text,
                              unidad: unidadSeleccionada!,
                              tipoTerreno: tipoTerrenoSeleccionado,
                              departamento: departamento ?? '',
                              municipio: municipio ?? '',
                              lat: lat,
                              lon: lon,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                  backgroundColor: _puedeConsultar
                      ? Colors.green.shade800
                      : Colors.green.shade300,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green.shade200,
                  disabledForegroundColor: Colors.white.withOpacity(0.9),
                  elevation: _puedeConsultar ? 3 : 1,
                ),
                child: const Text(
                  'Consultar recomendaciones',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    presupuestoController.dispose();
    extensionController.dispose();

    super.dispose();
  }
}
