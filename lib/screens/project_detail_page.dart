import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailPage extends StatefulWidget {
  final String cultivo;
  final String zona;
  final String presupuesto;
  final String area;
  final String unidad;
  final String departamento;
  final String municipio;
  final String? tipoTerreno;

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
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  bool cargando = true;
  String? error;
  Map<String, dynamic>? datosProyecto;

  @override
  void initState() {
    super.initState();
    _generarPlanDetallado();
  }

  Future<void> _generarPlanDetallado() async {
    try {
      const String apiKey =
          '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'; // Reemplazar con tu key

      final prompt =
          '''Eres un ingeniero agrónomo experto en Colombia especializado en planificación agrícola basada en datos reales.

Tu tarea es generar un plan de cultivo REALISTA, VIABLE y COHERENTE con las condiciones dadas.

DATOS DE ENTRADA:
- CULTIVO: ${widget.cultivo}
- UBICACIÓN: ${widget.departamento} - ${widget.municipio}
- PRESUPUESTO: ${widget.presupuesto} COP
- ÁREA: ${widget.area} ${widget.unidad}
- TIPO DE TERRENO: ${widget.tipoTerreno ?? "No especificado"}

REGLAS CRÍTICAS (OBLIGATORIAS):

1. PROHIBIDO inventar datos específicos (proveedores, direcciones, precios exactos).
2. Si no tienes certeza real, devuelve "NO_DISPONIBLE".
3. TODOS los valores deben ser coherentes con:
   - Presupuesto
   - Área
   - Cultivo
   - Región de Colombia

4. VALIDACIÓN DE VIABILIDAD:
   - Si el cultivo NO es viable con el presupuesto o área:
     - Debes indicarlo claramente en "rentabilidad.descripcion"
     - Ajusta recomendaciones a algo REALISTA
     - NO fuerces rentabilidad positiva

5. NUNCA uses valores genéricos como:
   - "texto"
   - "ejemplo"
   - "N/A"
   - "aproximado" sin contexto

6. SOLO usa rangos realistas en Colombia:
   - Costos agrícolas aproximados
   - Tiempos reales de cultivo
   - Prácticas agrícolas comunes

7. PROVEEDORES:
   - SOLO incluir si estás seguro de su existencia
   - Si no → devolver lista vacía []

8. RESPUESTA:
   - SOLO JSON válido
   - SIN texto adicional
   - SIN explicaciones fuera del JSON

FORMATO DE SALIDA:

{
  "rentabilidad": {
    "nivel": "Alta | Media | Baja | No viable",
    "descripcion": "Explicación basada en presupuesto y área",
    "retorno_inversion_meses": numero o null,
    "ganancia_estimada_anual": numero o null
  },
  "dificultad": {
    "nivel": "Alta | Media | Baja",
    "descripcion": "Descripción técnica"
  },
  "tiempos": {
    "siembra_mejor_epoca": "meses reales",
    "cosecha_meses": numero,
    "calendario_riego": "detalle real",
    "calendario_fertilizacion": "detalle real"
  },
  "semillas": {
    "proveedores": [],
    "cantidad_necesaria": "dato real o estimado",
    "recomendacion_variedad": "variedades reales en Colombia"
  },
  "plagas": [
    {
      "nombre": "plaga real",
      "sintomas": "descripción real",
      "control": "manejo real",
      "epoca_riesgo": "meses"
    }
  ],
  "mercado": {
    "precio_actual_kg": numero o null,
    "canales_venta": ["canales reales"],
    "compradores": [],
    "tendencias": "basado en contexto colombiano"
  },
  "beneficios": ["beneficios reales"],
  "pasos_siembra": ["pasos técnicos reales"]
}''';

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
          "temperature": 0.5,
          "max_tokens": 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contenido = data['choices'][0]['message']['content'];

        // Limpiar posibles markdown o texto adicional
        contenido = contenido.trim();
        if (contenido.startsWith('```json')) {
          contenido = contenido.replaceAll('```json', '').replaceAll('```', '');
        }
        if (contenido.startsWith('```')) {
          contenido = contenido.replaceAll('```', '');
        }

        final Map<String, dynamic> plan = jsonDecode(contenido);

        setState(() {
          datosProyecto = plan;
          cargando = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'Error generando el plan: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📋 Plan: ${widget.cultivo}"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        cargando = true;
                        error = null;
                        _generarPlanDetallado();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  // Resumen rápido
                  Container(
                    color: Colors.green.shade50,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _resumenChip(
                          Icons.trending_up,
                          "Rentabilidad",
                          _safeString(_safeMap(datosProyecto!['rentabilidad'])['nivel'], 'N/A'),
                          _getColorRentabilidad(
                            _safeString(_safeMap(datosProyecto!['rentabilidad'])['nivel'], ''),
                          ),
                        ),
                        _resumenChip(
                          Icons.speed,
                          "Dificultad",
                          _safeString(_safeMap(datosProyecto!['dificultad'])['nivel'], 'N/A'),
                          _getColorDificultad(
                            _safeString(_safeMap(datosProyecto!['dificultad'])['nivel'], ''),
                          ),
                        ),
                        _resumenChip(
                          Icons.timeline,
                          "Cosecha",
                          _safeString(_safeMap(datosProyecto!['tiempos'])['cosecha_meses'], 'N/A'),
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(icon: Icon(Icons.attach_money), text: "Rentabilidad"),
                      Tab(icon: Icon(Icons.calendar_month), text: "Tiempos"),
                      Tab(icon: Icon(Icons.eco), text: "Semillas"),
                      Tab(icon: Icon(Icons.bug_report), text: "Plagas"),
                      Tab(icon: Icon(Icons.store), text: "Mercado"),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _RentabilidadTab(
                          data: _safeMap(datosProyecto!['rentabilidad']),
                          beneficios: _safeList(datosProyecto!['beneficios']),
                        ),
                        _TiemposTab(data: _safeMap(datosProyecto!['tiempos'])),
                        _SemillasTab(data: _safeMap(datosProyecto!['semillas'])),
                        _PlagasTab(data: _safeList(datosProyecto!['plagas'])),
                        _MercadoTab(data: _safeMap(datosProyecto!['mercado'])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _resumenChip(IconData icon, String label, String valor, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Color _getColorRentabilidad(String nivel) {
    if (nivel == "Alta") return Colors.green;
    if (nivel == "Media") return Colors.orange;
    return Colors.red;
  }

  Color _getColorDificultad(String nivel) {
    if (nivel == "Baja") return Colors.green;
    if (nivel == "Media") return Colors.orange;
    return Colors.red;
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    return value is Map<String, dynamic> ? value : {};
  }

  List<dynamic> _safeList(dynamic value) {
    return value is List<dynamic> ? value : [];
  }

  String _safeString(dynamic value, [String defaultValue = 'No disponible']) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString();
  }
}

// Pestaña de Rentabilidad
class _RentabilidadTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> beneficios;

  const _RentabilidadTab({required this.data, required this.beneficios});

  static String _safeString(dynamic value, [String defaultValue = 'No disponible']) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.trending_up, color: _getColor()),
              title: const Text(
                "Nivel de rentabilidad",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_safeString(data['nivel'])),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text(
                "Análisis",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_safeString(data['descripcion'])),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer, color: Colors.orange),
              title: const Text(
                "Retorno de inversión",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("${_safeString(data['retorno_inversion_meses'], 'N/A')} meses"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.monetization_on, color: Colors.green),
              title: const Text(
                "Ganancia estimada anual",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_safeString(data['ganancia_estimada_anual'])),
            ),
          ),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "✨ Beneficios del cultivo",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...beneficios.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_safeString(b, 'Beneficio no especificado'))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    final nivel = _safeString(data['nivel'], '');
    if (nivel == "Alta") return Colors.green;
    if (nivel == "Media") return Colors.orange;
    return Colors.red;
  }
}

// Pestaña de Tiempos
class _TiemposTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TiemposTab({required this.data});

  static String _safeString(dynamic value, [String defaultValue = 'No disponible']) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Mejor época"),
            subtitle: Text(_safeString(data['siembra_mejor_epoca'])),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text("Tiempo a cosecha"),
            subtitle: Text("${_safeString(data['cosecha_meses'], 'N/A')} meses"),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text("Calendario de riego"),
            subtitle: Text(_safeString(data['calendario_riego'])),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.eco),
            title: const Text("Calendario de fertilización"),
            subtitle: Text(_safeString(data['calendario_fertilizacion'])),
          ),
        ),
      ],
    );
  }
}

// Pestaña de Semillas (con llamada telefónica)
class _SemillasTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SemillasTab({required this.data});

  static String _safeString(dynamic value, [String defaultValue = 'No disponible']) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.production_quantity_limits,
              color: Colors.green,
            ),
            title: const Text(
              "Cantidad necesaria",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_safeString(data['cantidad_necesaria'])),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.recommend, color: Colors.orange),
            title: const Text(
              "Variedad recomendada",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_safeString(data['recomendacion_variedad'])),
          ),
        ),
        const Card(
          color: Colors.blue,
          child: ListTile(
            leading: Icon(Icons.store, color: Colors.white),
            title: Text(
              "Proveedores de semillas",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (data['proveedores'] != null && (data['proveedores'] as List).isNotEmpty)
          ...(data['proveedores'] as List).map(
            (proveedor) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                leading: const Icon(Icons.business, color: Colors.green),
                title: Text(
                _safeString(proveedor['nombre'], 'Proveedor desconocido'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_safeString(proveedor['ciudad'], 'Ciudad no especificada')),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: Colors.blue),
                onPressed: () =>
                    launchUrl(Uri.parse('tel:${proveedor['telefono'] ?? ''}')),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📞 Teléfono (texto visible)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            _safeString(proveedor['telefono'], 'No disponible'),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          if (proveedor['telefono_alternativo'] != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_android,
                                  size: 18,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _safeString(proveedor['telefono_alternativo']),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 📍 Dirección
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _safeString(proveedor['direccion'], 'Dirección no especificada'),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                      // 🏢 Sucursales (si existen)
                      if (proveedor['sucursales'] != null &&
                          (proveedor['sucursales'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.business_center,
                              size: 18,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Otras sucursales:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...(proveedor['sucursales'] as List).map(
                          (sucursal) => Padding(
                            padding: const EdgeInsets.only(left: 26, bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• ${_safeString(sucursal['ciudad'], 'Ciudad no especificada')}"),
                                if (sucursal['direccion'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "  ${_safeString(sucursal['direccion'])}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                if (sucursal['telefono'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "  📞 ${_safeString(sucursal['telefono'])}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // 🌐 Web (si existe)
                      if (proveedor['web'] != null &&
                          proveedor['web'].isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse(proveedor['web'])),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.language,
                                size: 18,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  proveedor['web'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Pestaña de Plagas
class _PlagasTab extends StatelessWidget {
  final List<dynamic> data;
  const _PlagasTab({required this.data});

  static String _safeString(dynamic value, [String defaultValue = 'No disponible']) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Manejo integrado de plagas",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...data.map(
          (plaga) => Card(
            child: ExpansionTile(
              leading: const Icon(Icons.bug_report, color: Colors.red),
              title: Text(
                _safeString(plaga['nombre'], 'Plaga desconocida'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("⚠️ Síntomas: ${_safeString(plaga['sintomas'])}"),
                      const SizedBox(height: 8),
                      Text("✅ Control: ${_safeString(plaga['control'])}"),
                      const SizedBox(height: 8),
                      Text("📅 Época de riesgo: ${_safeString(plaga['epoca_riesgo'])}"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Pestaña de Mercado
class _MercadoTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MercadoTab({required this.data});

  static String _safeString(dynamic value, [String defaultValue = 'No disponible']) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString();
  }

  static List<dynamic> _safeList(dynamic value) {
    return value is List<dynamic> ? value : [];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.green.shade50,
          child: ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.green),
            title: const Text(
              "Precio actual",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_safeString(data['precio_actual_kg'])),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storefront),
            title: const Text("Canales de venta"),
            subtitle: Text(_safeList(data['canales_venta']).join(" • ")),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.factory),
            title: const Text("Compradores potenciales"),
            subtitle: Text(_safeList(data['compradores']).join(" • ")),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.insights),
            title: const Text(
              "Tendencias de mercado",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_safeString(data['tendencias'])),
          ),
        ),
      ],
    );
  }
}
