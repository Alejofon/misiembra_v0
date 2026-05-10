import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

String normalizar(String texto) {
  // Pasa a mayúsculas, quita acentos y caracteres diacríticos
  final conAcentos = 'ÁÉÍÓÚÜÑ';
  final sinAcentos = 'AEIOUUN';
  String salida = texto.toUpperCase();
  for (int i = 0; i < conAcentos.length; i++) {
    salida = salida.replaceAll(conAcentos[i], sinAcentos[i]);
  }
  return salida.trim();
}

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

  // Variables para GPS
  bool obteniendoUbicacion = false;
  double? lat;
  double? lon;

  @override
  void initState() {
    super.initState();
    cargarDepartamentos();
  }

  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }

  Future<void> cargarDepartamentos() async {
    final String jsonString = await rootBundle.loadString(
      'assets/json/colombia.min.json',
    );
    final List<dynamic> data = json.decode(jsonString);
    setState(() {
      departamentosData = data;
      departamentos = data
          .map<String>((dep) => dep['departamento'].toString())
          .toList();
    });
  }

  void actualizarMunicipios(String departamento) {
    final dep = departamentosData.firstWhere(
      (d) => d['departamento'] == departamento,
      orElse: () => {'ciudades': []},
    );
    setState(() {
      municipios = List<String>.from(dep['ciudades'] ?? []);
      municipioSeleccionado = null; // Limpia selección anterior
    });
  }

  // Nuevo método para obtener ubicación actual
  Future<void> _usarUbicacionActual() async {
    setState(() => obteniendoUbicacion = true);
    try {
      debugPrint('🔍 Iniciando obtención de ubicación...');
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        debugPrint(
          '✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}',
        );
        lat = position.latitude;
        lon = position.longitude;
        final geocoded = await GeocodingService.reverseGeocode(lat!, lon!);
        // Dentro de _usarUbicacionActual, después de obtener geocoded:
        if (geocoded != null) {
          final deptRecibido = geocoded['departamento'] ?? '';
          final muniRecibido = geocoded['municipio'] ?? '';

          // Normalizar el departamento recibido para buscar en la lista
          final deptNormalizado = normalizar(deptRecibido);

          // Buscar el nombre exacto del JSON que coincida normalizado
          String? deptExacto;
          for (final d in departamentos) {
            if (normalizar(d) == deptNormalizado) {
              deptExacto = d;
              break;
            }
          }

          setState(() {
            if (deptExacto != null) {
              departamentoSeleccionado = deptExacto;
              actualizarMunicipios(deptExacto);

              // Ahora buscar el municipio normalizado dentro de la lista de municipios
              final muniNormalizado = normalizar(muniRecibido);
              String? muniExacto;
              for (final m in municipios) {
                if (normalizar(m) == muniNormalizado) {
                  muniExacto = m;
                  break;
                }
              }

              if (muniExacto != null) {
                municipioSeleccionado = muniExacto;
              } else {
                municipioSeleccionado = null; // El usuario deberá elegir otro
              }
            } else {
              // Departamento no encontrado en la lista, revertir
              departamentoSeleccionado = null;
              municipioSeleccionado = null;
            }
          });
          if (mounted && deptExacto == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No se pudo reconocer el departamento "$deptRecibido". Selecciona manualmente.',
                ),
              ),
            );
          }
        }
      } else {
        debugPrint('⚠️ No se pudo obtener la posición');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo obtener la ubicación')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error al obtener ubicación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    } finally {
      setState(() => obteniendoUbicacion = false);
    }
  }

  // Guarda el perfil en SharedPreferences
  Future<void> saveProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre_agricultor', nombreController.text.trim());
    await prefs.setString('departamento', departamentoSeleccionado!);
    await prefs.setString('municipio', municipioSeleccionado!);
    if (lat != null && lon != null) {
      await prefs.setDouble('lat', lat!);
      await prefs.setDouble('lon', lon!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  bool validarCampos() {
    final String nombre = nombreController.text.trim();
    if (nombre.isEmpty) return false;
    if (departamentoSeleccionado == null) return false;
    if (municipioSeleccionado == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiSiembra - Perfil del agricultor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bienvenido a MiSiembra',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Por favor completa la información básica de tu finca para recibir recomendaciones agrícolas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Campo de texto para el nombre del agricultor
              TextField(
                controller: nombreController,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(50),
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]"),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nombre del agricultor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Selector de Departamento
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),
                menuMaxHeight: 500,
                initialValue: departamentoSeleccionado,
                items: departamentos.map((String dep) {
                  return DropdownMenuItem<String>(value: dep, child: Text(dep));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    departamentoSeleccionado = value;
                    municipios = [];
                  });
                  if (value != null) {
                    actualizarMunicipios(value);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Selector de Municipio
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Municipio',
                  border: OutlineInputBorder(),
                ),
                menuMaxHeight: 500,
                initialValue: municipioSeleccionado,
                items: municipios.map((String mun) {
                  return DropdownMenuItem<String>(value: mun, child: Text(mun));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    municipioSeleccionado = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Botón de GPS
              Center(
                child: obteniendoUbicacion
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('Usar ubicación actual'),
                        onPressed: _usarUbicacionActual,
                      ),
              ),
              const SizedBox(height: 30),

              // Botón principal
              ElevatedButton(
                onPressed: () async {
                  // ← vuelve el callback async
                  if (!validarCampos()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor completa todos los campos antes de continuar',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  final navigator = Navigator.of(context);
                  await saveProfile(); // ← espera a que termine la escritura
                  if (!mounted) {
                    return; // seguridad por si el widget se destruye
                  }
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
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
}
