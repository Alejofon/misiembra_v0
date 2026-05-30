import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../prompts/project_detail_prompt.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class ProjectDetailPage extends StatefulWidget {
  final String cultivo;
  final String zona;
  final String presupuesto;
  final String area;
  final String unidad;
  final String departamento;
  final String municipio;
  final String? tipoTerreno;
  final Map<String, dynamic>? datosAnalisis;
  final Map<String, dynamic>? proveedoresInsumos;
  final double? lat;
  final double? lon;
  final Map<String, dynamic>? planGuardado;

  const ProjectDetailPage({
    super.key,
    required this.cultivo,
    required this.zona,
    required this.presupuesto,
    required this.area,
    required this.unidad,
    required this.departamento,
    required this.municipio,
    this.tipoTerreno,
    this.datosAnalisis,
    this.proveedoresInsumos,
    this.lon,
    this.lat,
    this.planGuardado,
  });

  @override
  State<ProjectDetailPage> createState() =>
      _ProjectDetailPageState();
}

class _ProjectDetailPageState
    extends State<ProjectDetailPage> {
  bool cargando = true;
  String? error;
  Map<String, dynamic>? datosProyecto;

  static const String apiKey =
      ApiConfig.openAiApiKey;

  @override
  void initState() {
    super.initState();
    if (widget.planGuardado != null) {
      datosProyecto = widget.planGuardado;
      cargando = false;
    } else {
      _generarPlanDetallado();
    }
  }

  String _formatearDatosAnalisis() {
    final buf = StringBuffer();

    if (widget.datosAnalisis == null) return '';

    final data = widget.datosAnalisis!;

    final clima = data['clima']?['data'];

    if (clima != null) {
      buf.writeln(
        'CLIMA: Temp ${clima['current']?['temperature']}°C, '
        'Hum ${clima['current']?['humidity']}%, '
        'Precip ${clima['daily']?['precipitation_sum']}mm',
      );
    }

    final suelo = data['suelo']?['data'];

    if (suelo != null) {
      buf.writeln(
        'SUELO: pH ${suelo['ph']}, '
        'Arcilla ${suelo['clay']}%, '
        'Arena ${suelo['sand']}%',
      );
    }

    final insumos = data['insumos']?['data'];

    if (insumos != null) {
      buf.writeln(
        'ÍNDICE INSUMOS: '
        'Total ${insumos['indice_total']}, '
        'Fertilizantes ${insumos['total_fertilizantes']}, '
        'Plaguicidas ${insumos['total_plaguicidas']}',
      );
    }

    return buf.toString();
  }

Future<void> _generarPlanDetallado() async {
    try {
      final datosAnalisisStr = _formatearDatosAnalisis();

      final prompt = ProjectDetailPrompt.build(
        cultivo: widget.cultivo,
        departamento: widget.departamento,
        municipio: widget.municipio,
        presupuesto: widget.presupuesto,
        area: widget.area,
        unidad: widget.unidad,
        tipoTerreno: widget.tipoTerreno,
        datosAnalisis: datosAnalisisStr.isNotEmpty ? datosAnalisisStr : null,
      );

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-4.1-mini",
          "messages": [
            {
              "role": "user",
              "content": prompt,
            }
          ],
          "temperature": 0.3,
          "max_tokens": 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contenido = data['choices'][0]['message']['content'].trim();

        contenido = contenido
            .replaceAll('```json', '')
            .replaceAll('```', '');

        final Map<String, dynamic> plan = jsonDecode(contenido);

        // =========================================================================
        // 🔥 AQUÍ ES DONDE VA EL GUARDADO EN EL HISTORIAL
        // =========================================================================
        try {
          final prefs = await SharedPreferences.getInstance();
          // Recuperamos el historial actual o creamos uno vacío si no existe
          final List<String> historialRaw = prefs.getStringList('historial') ?? [];
          
          // Creamos el nuevo registro estructurado con toda la metadata y el plan de la IA
          final Map<String, dynamic> nuevoRegistro = {
            'cultivo': widget.cultivo,
            'departamento': widget.departamento,
            'municipio': widget.municipio,
            'presupuesto': widget.presupuesto,
            'area': widget.area,
            'unidad': widget.unidad,
            'tipo_terreno': widget.tipoTerreno,
            'fecha': DateTime.now().toIso8601String(),
            'plan_ia': plan, // Guardamos el JSON que generó el modelo para usarlo offline
            'datos_analisis': widget.datosAnalisis,
            'proveedores_insumos': widget.proveedoresInsumos,
            'lat': widget.lat,
            'lon': widget.lon,
          };

          // Lo añadimos a la lista local persistente en formato String
          historialRaw.add(jsonEncode(nuevoRegistro));
          await prefs.setStringList('historial', historialRaw);
        } catch (e) {
          debugPrint('Error silencioso al guardar en el historial: $e');
          // No lanzamos excepción para que, si falla el guardado local, al menos le muestre el plan en pantalla al usuario
        }
        // =========================================================================

        setState(() {
          datosProyecto = plan;
          cargando = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'Error generando el plan: $e';
      });
    }
  }

  Map<String, dynamic> _safeMap(
    dynamic value,
  ) =>
      value is Map<String, dynamic>
          ? value
          : {};

  List<dynamic> _safeList(dynamic value) =>
      value is List<dynamic> ? value : [];

  String _safeString(
    dynamic value, [
    String defaultValue =
        'No disponible',
  ]) {
    if (value == null) return defaultValue;

    if (value is String) {
      return value.isEmpty
          ? defaultValue
          : value;
    }

    return value.toString();
  }

  Color _getColorRentabilidad(
      String nivel) {
    if (nivel == "Alta") {
      return Colors.green;
    }

    if (nivel == "Media") {
      return Colors.orange;
    }

    return Colors.red;
  }

  Color _getColorDificultad(
      String nivel) {
    if (nivel == "Baja") {
      return Colors.green;
    }

    if (nivel == "Media") {
      return Colors.orange;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("🌱 ${widget.cultivo}"),
        centerTitle: true,
        backgroundColor:
            Colors.green.shade700,
      ),
      body: cargando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 70,
                        ),
                        const SizedBox(
                            height: 20),
                        Text(
                          error!,
                          textAlign:
                              TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .all(16),
                        color: Colors
                            .green.shade50,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceAround,
                          children: [
                            _resumenCard(
                              Icons.trending_up,
                              "Rentabilidad",
                              _safeString(
                                _safeMap(
                                  datosProyecto![
                                      'rentabilidad'],
                                )['nivel'],
                              ),
                              _getColorRentabilidad(
                                _safeString(
                                  _safeMap(
                                    datosProyecto![
                                        'rentabilidad'],
                                  )['nivel'],
                                ),
                              ),
                            ),
                            _resumenCard(
                              Icons.speed,
                              "Dificultad",
                              _safeString(
                                _safeMap(
                                  datosProyecto![
                                      'dificultad'],
                                )['nivel'],
                              ),
                              _getColorDificultad(
                                _safeString(
                                  _safeMap(
                                    datosProyecto![
                                        'dificultad'],
                                  )['nivel'],
                                ),
                              ),
                            ),
                            _resumenCard(
                              Icons.schedule,
                              "Cosecha",
                              "${_safeMap(datosProyecto!['tiempos'])['cosecha_meses']} meses",
                              Colors.blue,
                            ),
                          ],
                        ),
                      ),

                      const TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(
                            icon: Icon(
                              Icons.attach_money,
                            ),
                            text:
                                "Rentabilidad",
                          ),
                          Tab(
                            icon:
                                Icon(Icons.timer),
                            text: "Tiempos",
                          ),
                          Tab(
                            icon: Icon(
                              Icons.bug_report,
                            ),
                            text: "Plagas",
                          ),
                          Tab(
                            icon: Icon(
                              Icons.store,
                            ),
                            text:
                                "Proveedores",
                          ),
                        ],
                      ),

                      Expanded(
                        child: TabBarView(
                          children: [
                            _RentabilidadTab(
                              data: _safeMap(
                                datosProyecto![
                                    'rentabilidad'],
                              ),
                              beneficios:
                                  _safeList(
                                datosProyecto![
                                    'beneficios'],
                              ),
                            ),

                            _TiemposTab(
                              data: _safeMap(
                                datosProyecto![
                                    'tiempos'],
                              ),
                            ),

                            _PlagasTab(
                              data: _safeList(
                                datosProyecto![
                                    'plagas'],
                              ),
                            ),

                            _ProveedoresTab(
                              proveedoresData:
                                  widget
                                      .proveedoresInsumos,
                              lat: widget.lat,
                              lon: widget.lon,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _resumenCard(
    IconData icono,
    String titulo,
    String valor,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icono,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 5),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RentabilidadTab
    extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> beneficios;

  const _RentabilidadTab({
    required this.data,
    required this.beneficios,
  });

  Widget _infoCard(
    String titulo,
    dynamic valor,
    IconData icono,
  ) {
    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Colors.green.shade100,
          child: Icon(
            icono,
            color: Colors.green,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 6),
          child: Text(
            valor?.toString() ??
                'No disponible',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Rentabilidad del proyecto',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        _infoCard(
          'Nivel de rentabilidad',
          data['nivel'],
          Icons.trending_up,
        ),

        _infoCard(
          'Descripción',
          data['descripcion'],
          Icons.description,
        ),

        _infoCard(
          'Retorno de inversión',
          '${data['retorno_inversion_meses']} meses',
          Icons.schedule,
        ),

        _infoCard(
          'Ganancia estimada',
          data['ganancia_estimada_por_cosecha'],
          Icons.attach_money,
        ),

        _infoCard(
          'Área cultivable estimada',
          data['area_realmente_cultivable'],
          Icons.crop_square,
        ),

        _infoCard(
          'Número estimado de plantas',
          data['numero_plantas_estimadas'],
          Icons.grass,
        ),

        _infoCard(
          'Distancia de siembra',
          data['distancia_siembra'],
          Icons.straighten,
        ),

        _infoCard(
          'Producción estimada',
          data['produccion_estimada'],
          Icons.inventory_2,
        ),

        _infoCard(
          'Área mínima rentable',
          data['area_minima_rentable'],
          Icons.analytics,
        ),

        _infoCard(
          'Presupuesto mínimo recomendado',
          data[
              'presupuesto_minimo_recomendado'],
          Icons.payments,
        ),

        const SizedBox(height: 25),

        const Text(
          'Beneficios del cultivo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        ...beneficios.map(
          (beneficio) => Card(
            child: ListTile(
              leading: const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              title:
                  Text(beneficio.toString()),
            ),
          ),
        ),
      ],
    );
  }
}

class _TiemposTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TiemposTab({
    required this.data,
  });

  Widget _card(
    String titulo,
    dynamic valor,
    IconData icono,
  ) {
    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Colors.blue.shade100,
          child: Icon(
            icono,
            color: Colors.blue,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 6),
          child: Text(
            valor?.toString() ??
                'No disponible',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Calendario agrícola',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        _card(
          'Mejor época de siembra',
          data['siembra_mejor_epoca'],
          Icons.calendar_month,
        ),

        _card(
          'Tiempo estimado de cosecha',
          '${data['cosecha_meses']} meses',
          Icons.schedule,
        ),

        _card(
          'Calendario de riego',
          data['calendario_riego'],
          Icons.water_drop,
        ),

        _card(
          'Fertilización',
          data['calendario_fertilizacion'],
          Icons.spa,
        ),
      ],
    );
  }
}

class _PlagasTab extends StatelessWidget {
  final List<dynamic> data;

  const _PlagasTab({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Plagas y enfermedades',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        ...data.map(
          (plaga) => Card(
            elevation: 2,
            margin:
                const EdgeInsets.only(
              bottom: 16,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bug_report,
                        color: Colors.red,
                      ),
                      const SizedBox(
                          width: 10),
                      Expanded(
                        child: Text(
                          plaga['nombre'] ??
                              'Plaga',
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 14),

                  Text(
                    'Síntomas',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(
                      height: 5),

                  Text(
                    plaga['sintomas'] ??
                        '',
                  ),

                  const SizedBox(
                      height: 12),

                  Text(
                    'Control',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(
                      height: 5),

                  Text(
                    plaga['control'] ??
                        '',
                  ),

                  const SizedBox(
                      height: 12),

                  Text(
                    'Época de riesgo',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(
                      height: 5),

                  Text(
                    plaga['epoca_riesgo'] ??
                        '',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProveedoresTab
    extends StatelessWidget {
  final Map<String, dynamic>?
      proveedoresData;

  final double? lat;
  final double? lon;

  const _ProveedoresTab({
    required this.proveedoresData,
    this.lat,
    this.lon,
  });

  @override
  Widget build(BuildContext context) {
    final bool hayCoordenadas =
        lat != null && lon != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Proveedores agrícolas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        if (hayCoordenadas)
          ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text(
              'Buscar insumos cercanos',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.blue,
              foregroundColor:
                  Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
            onPressed: () {
              final uri = Uri.parse(
                'https://www.google.com/maps/search/insumos+agropecuarios/@$lat,$lon,14z',
              );

              launchUrl(
                uri,
                mode: LaunchMode
                    .externalApplication,
              );
            },
          ),

        const SizedBox(height: 25),

        if (proveedoresData == null ||
            proveedoresData!['data'] ==
                null)
          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.info_outline),
              title: Text(
                'Información no disponible',
              ),
            ),
          )
        else if ((proveedoresData!['data']
                as List)
            .isEmpty)
          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.info_outline),
              title: Text(
                'No se encontraron proveedores cercanos',
              ),
            ),
          )
        else
          ...(proveedoresData!['data']
                  as List)
              .map(
            (prov) {
              final nombre =
                  prov['nombre'] ??
                      'Proveedor';

              final direccion =
                  prov['direccion'] ??
                      '';

              final mapsLink =
                  prov['maps_link'] ??
                      '';

              return Card(
                elevation: 2,
                margin:
                    const EdgeInsets.only(
                  bottom: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    backgroundColor:
                        Colors.green,
                    child: Icon(
                      Icons.store,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    nombre,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle:
                      direccion.isNotEmpty
                          ? Text(direccion)
                          : null,
                  trailing:
                      mapsLink.isNotEmpty
                          ? IconButton(
                              icon:
                                  const Icon(
                                Icons
                                    .directions,
                                color: Colors
                                    .blue,
                              ),
                              onPressed: () {
                                launchUrl(
                                  Uri.parse(
                                    mapsLink,
                                  ),
                                  mode: LaunchMode
                                      .externalApplication,
                                );
                              },
                            )
                          : null,
                ),
              );
            },
          ),
      ],
    );
  }
}