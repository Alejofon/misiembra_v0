// Importa el paquete principal de Flutter para construir la interfaz
import 'package:flutter/material.dart';

// Importa herramientas para formatear la entrada de texto (solo números)
import 'package:flutter/services.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controlador para el campo de presupuesto
  final TextEditingController presupuestoController = TextEditingController();

  // Controlador para el campo de extensión del terreno
  final TextEditingController extensionController = TextEditingController();

  // Variable para simular si hay recomendaciones previas
  bool tieneRecomendaciones = true;


  // Lista de unidades de medida disponibles
  final List<String> unidadesMedida = [
    'Metros cuadrados',
    'Hectáreas',
    'Fanegadas',
    'Acres',
    'Kilómetros cuadrados',
  ];

  // Unidad seleccionada por el usuario
  String? unidadSeleccionada;

  // Tipo de terreno (opcional)
  final List<String> tiposTerreno = [
    'Plano',
    'Montañoso',
    'Ondulado',
    'Arenoso',
    'Arcilloso',
    'Mixto',
  ];

  // Tipo de terreno seleccionado
  String? tipoTerrenoSeleccionado;

  // Función para validar que los campos obligatorios estén completos
  bool validarCampos() {
    // Obtiene el texto del presupuesto sin espacios
    final String presupuesto = presupuestoController.text.trim();

    // Obtiene el texto de la extensión sin espacios
    final String extension = extensionController.text.trim();

    // Valida que el presupuesto no esté vacío
    if (presupuesto.isEmpty) {
      return false;
    }

    // Valida que la extensión no esté vacía
    if (extension.isEmpty) {
      return false;
    }

    // Valida que se haya seleccionado una unidad de medida
    if (unidadSeleccionada == null) {
      return false;
    }

    // Si pasa todas las validaciones
    return true;
  }

  // Función que en el futuro llamará a la API de OpenAI
  void generarRecomendacion() {
    // Primero valida los campos
    bool camposValidos = validarCampos();

    if (!camposValidos) {
      // Muestra mensaje si falta información
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor completa presupuesto, extensión y unidad de medida',
          ),
        ),
      );
      return;
    }

    // Aquí más adelante irá la llamada real a la API
    // Por ahora solo mostramos los datos capturados como prueba
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Consulta generada:\n'
          'Presupuesto: ${presupuestoController.text}\n'
          'Extensión: ${extensionController.text} $unidadSeleccionada\n'
          'Tipo de terreno: ${tipoTerrenoSeleccionado ?? "No especificado"}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior
      appBar: AppBar(
        title: const Text('MiSiembra - Consulta'),
        centerTitle: true,
      ),

      // Contenido principal con margen
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        // Permite scroll si la pantalla es pequeña
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título principal
              const Text(
                'Datos para la recomendación agrícola',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Texto explicativo
              const Text(
                'Ingresa la información básica para generar una recomendación '
                'adaptada a tu capacidad y tipo de terreno.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Botón para ver recomendaciones anteriores (solo si existen)
              if (tieneRecomendaciones)
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

              // Campo de presupuesto (solo números)
              TextField(
                controller: presupuestoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Presupuesto disponible',
                  hintText: 'Ejemplo: 1500000',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // Campo de extensión del terreno (solo números)
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

              // Selector de unidad de medida
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

              // Selector opcional de tipo de terreno
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

              // Botón para generar recomendación
              ElevatedButton(
                onPressed: generarRecomendacion,
                child: const Text(
                  'Generar recomendación',
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
    // Libera los controladores cuando la pantalla se destruye
    presupuestoController.dispose();
    extensionController.dispose();
    super.dispose();
  }
}
