// Importa el paquete principal de Flutter para usar widgets de interfaz gráfica
import 'package:flutter/material.dart';

// Permite convertir texto JSON en estructuras Dart (listas, mapas, etc.)
import 'dart:convert';

// Permite leer archivos desde la carpeta assets del proyecto
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

// Clase principal del widget con estado
// Esta clase solo crea el estado, NO dibuja la interfaz
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  // Crea la instancia del estado asociado a este widget
  @override
  State<StartPage> createState() => _StartPageState();
}

// Clase que contiene el estado, la lógica y la interfaz gráfica
class _StartPageState extends State<StartPage> {
  // Lista completa del JSON cargado
  List<dynamic> departamentosData = [];

  // Lista de nombres de departamentos
  List<String> departamentos = [];

  // Lista de municipios filtrados según el departamento seleccionado
  List<String> municipios = [];

  // Valores seleccionados por el usuario
  String? departamentoSeleccionado;
  String? municipioSeleccionado;

  // Controlador para el campo de nombre del agricultor
  final TextEditingController nombreController = TextEditingController();

  // Este método se ejecuta automáticamente cuando se crea la pantalla
  @override
  void initState() {
    super.initState();
    cargarDepartamentos();
  }

  // Libera recursos cuando la pantalla se destruye
  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }

  // Lee el archivo JSON desde assets y lo convierte en estructura Dart
  Future<void> cargarDepartamentos() async {
    // Lee el archivo como texto desde la ruta indicada
    final String jsonString = await rootBundle.loadString(
      'assets/json/colombia.min.json',
    );

    // Convierte el texto JSON en una lista dinámica de Dart
    final List<dynamic> data = json.decode(jsonString);

    // Actualiza el estado de la pantalla
    setState(() {
      // Guarda la lista completa
      departamentosData = data;

      // Extrae solo los nombres de los departamentos
      departamentos = data
          .map<String>((dep) => dep['departamento'].toString())
          .toList();
    });
  }

  // Actualiza la lista de municipios según el departamento elegido
  void actualizarMunicipios(String departamento) {
    // Busca el departamento seleccionado dentro de la lista completa
    final dep = departamentosData.firstWhere(
      (d) => d['departamento'] == departamento,
    );

    // Actualiza el estado con la nueva lista de municipios
    setState(() {
      municipios = List<String>.from(dep['ciudades']);
      municipioSeleccionado = null; // Limpia selección anterior
    });
  }

  // Método que construye la interfaz gráfica de la pantalla
  @override
  Widget build(BuildContext context) {
    // Scaffold es la estructura base visual de la pantalla
    return Scaffold(
      // Barra superior de la aplicación
      appBar: AppBar(
        // Texto que aparece en la parte superior
        title: const Text('MiSiembra - Perfil del agricultor'),
        // Centra el título
        centerTitle: true,
      ),

      // Contenido principal de la pantalla
      body: Padding(
        // Espacio alrededor del contenido
        padding: const EdgeInsets.all(16.0),

        // Permite hacer scroll si la pantalla es pequeña
        child: SingleChildScrollView(
          // Organiza los widgets en columna (vertical)
          child: Column(
            // Estira los elementos al ancho disponible
            crossAxisAlignment: CrossAxisAlignment.stretch,

            // Lista de widgets visibles en pantalla
            children: [
              // Título principal
              const Text(
                'Bienvenido a MiSiembra',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              // Espacio vertical
              const SizedBox(height: 20),

              // Texto descriptivo
              const Text(
                'Por favor completa la información básica de tu finca para recibir recomendaciones agrícolas.',
                textAlign: TextAlign.center,
              ),

              // Espacio vertical
              const SizedBox(height: 30),

              // Campo de texto para el nombre del agricultor
              TextField(
                // Controlador para leer el valor escrito por el usuario
                controller: nombreController,
                inputFormatters: [
                  // Limita la longitud máxima a 50 caracteres
                  LengthLimitingTextInputFormatter(50),
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]"),
                  ),
                ],

                // Apariencia del campo
                decoration: const InputDecoration(
                  labelText: 'Nombre del agricultor',
                  border: OutlineInputBorder(),
                ),
              ),

              // Espacio vertical
              const SizedBox(height: 20),

              // Selector de Departamento
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),

                menuMaxHeight: 500,

                // Valor seleccionado actualmente
                initialValue: departamentoSeleccionado,

                // Lista de opciones del selector
                items: departamentos.map((String dep) {
                  return DropdownMenuItem<String>(value: dep, child: Text(dep));
                }).toList(),

                // Se ejecuta cuando el usuario cambia el valor
                onChanged: (value) {
                  setState(() {
                    departamentoSeleccionado = value;
                    municipios = []; // Limpia municipios anteriores
                  });

                  // Si hay un valor válido, filtra municipios
                  if (value != null) {
                    actualizarMunicipios(value);
                  }
                },
              ),

              // Espacio vertical
              const SizedBox(height: 20),

              // Selector de Municipio
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Municipio',
                  border: OutlineInputBorder(),
                ),

                menuMaxHeight: 500,

                // Valor seleccionado actualmente
                initialValue: municipioSeleccionado,

                // Lista de opciones del selector
                items: municipios.map((String mun) {
                  return DropdownMenuItem<String>(value: mun, child: Text(mun));
                }).toList(),

                // Se ejecuta cuando el usuario cambia el valor
                onChanged: (value) {
                  setState(() {
                    municipioSeleccionado = value;
                  });
                },
              ),

              // Espacio vertical
              const SizedBox(height: 30),

              // Botón principal
              ElevatedButton(
                // Acción al presionar el botón
                onPressed: () {
                  // Llama a la función de validación
                  bool camposValidos = validarCampos();

                  // Si algún campo no está bien, muestra un mensaje y no continúa
                  if (!camposValidos) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor completa todos los campos antes de continuar',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return; // Detiene la ejecución del botón aquí
                  }

                  // Si todo está bien, aquí luego llamarás a saveProfile()
                  saveProfile();
                  // Navega a la pantalla Home
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },

                // Texto del botón
                child: const Text(
                  'Guardar perfil',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Guarda el perfil del agricultor en almacenamiento local

  Future<void> saveProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre_agricultor', nombreController.text.trim());
    await prefs.setString('departamento', departamentoSeleccionado!);
    await prefs.setString('municipio', municipioSeleccionado!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Función que valida que todos los campos estén diligenciados
  bool validarCampos() {
    // Obtiene el texto del nombre y elimina espacios al inicio y al final
    final String nombre = nombreController.text.trim();

    // Si el nombre está vacío, la validación falla
    if (nombre.isEmpty) {
      return false;
    }

    // Si no se ha seleccionado un departamento, la validación falla
    if (departamentoSeleccionado == null) {
      return false;
    }

    // Si no se ha seleccionado un municipio, la validación falla
    if (municipioSeleccionado == null) {
      return false;
    }

    // Si pasó todas las validaciones, todo está correcto
    return true;
  }
}
