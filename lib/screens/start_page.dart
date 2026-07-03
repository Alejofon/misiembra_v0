import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool obteniendoUbicacion = false;

  double? lat;
  double? lon;

  String? departamentoSeleccionado;
  String? municipioSeleccionado;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _usarUbicacionActual() async {
    setState(() => obteniendoUbicacion = true);

    try {
      final position = await LocationService.getCurrentPosition();

      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;

        setState(() {
          departamentoSeleccionado = 'No disponible';
          municipioSeleccionado = 'No disponible';
        });

        final geocoded = await GeocodingService.reverseGeocode(
          lat!,
          lon!,
        );

        if (geocoded != null) {
          setState(() {
            departamentoSeleccionado =
                geocoded['departamento'] ?? 'No disponible';

            municipioSeleccionado =
                geocoded['municipio'] ?? 'No disponible';
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ubicación obtenida correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ubicación obtenida, pero no se pudo determinar la región'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la ubicación'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: $e'),
          ),
        );
      }
    } finally {
      setState(() => obteniendoUbicacion = false);
    }
  }

  bool validarCampos() {
    return lat != null && lon != null;
  }

  Future<void> saveProfile() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'departamento',
      departamentoSeleccionado ?? 'No disponible',
    );

    await prefs.setString(
      'municipio',
      municipioSeleccionado ?? 'No disponible',
    );

    await prefs.setDouble('lat', lat!);
    await prefs.setDouble('lon', lon!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiSiembra'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.agriculture,
                  size: 100,
                  color: Colors.green,
                ),

                const SizedBox(height: 25),

                const Text(
                  'Bienvenido a MiSiembra',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'MiSiembra es una aplicación orientada a apoyar la planificación agrícola mediante recomendaciones inteligentes basadas en ubicación geográfica y análisis contextual del terreno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'La aplicación utiliza datos climáticos, información del suelo y análisis ambientales para generar recomendaciones agrícolas adaptadas a cada región.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                obteniendoUbicacion
                    ? const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(
                          Icons.location_on,
                        ),
                        label: const Text(
                          'Usar ubicación actual',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                        ),
                        onPressed:
                            _usarUbicacionActual,
                      ),

                const SizedBox(height: 25),

                if (lat != null && lon != null)
                  Card(
                    elevation: 2,
                    color: Colors.green.shade50,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 45,
                          ),

                          const SizedBox(height: 15),

                          const Text(
                            'Ubicación detectada correctamente',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            '$departamentoSeleccionado - $municipioSeleccionado',
                            textAlign:
                                TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () async {
                    if (!validarCampos()) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Primero debes obtener tu ubicación',
                          ),
                          backgroundColor:
                              Colors.red,
                        ),
                      );

                      return;
                    }

                    final navigator =
                        Navigator.of(context);

                    await saveProfile();

                    if (!mounted) return;

                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            const HomePage(),
                      ),
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}