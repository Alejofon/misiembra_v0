import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_page.dart';
import 'options_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController presupuestoController = TextEditingController();
  final TextEditingController extensionController = TextEditingController();

  bool tieneRecomendaciones = false;
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
    if (presupuestoController.text.trim().isEmpty) return false;
    if (extensionController.text.trim().isEmpty) return false;
    if (unidadSeleccionada == null) return false;
    if (departamento == null || municipio == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiSiembra - Consulta'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Datos para la recomendación agrícola',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingresa la información básica para generar una recomendación '
                'adaptada a tu capacidad y tipo de terreno.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Mostrar datos del perfil cargados
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          Text('Perfil cargado: $departamento - $municipio'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text(
                  'Ver recomendaciones anteriores',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: presupuestoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Presupuesto disponible (COP)',
                  hintText: 'Ejemplo: 1500000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: extensionController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Extensión aproximada del terreno',
                  hintText: 'Ejemplo: 2',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (!validarCampos()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor completa presupuesto, extensión, unidad de medida y asegúrate de tener perfil cargado',
                        ),
                      ),
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
                        departamento: departamento!,
                        municipio: municipio!,
                        lat: lat,
                        lon: lon,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Generar recomendaciones',
                  style: TextStyle(fontSize: 16),
                ),
              ),
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
