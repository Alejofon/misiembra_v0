import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'project_detail_page.dart';
import '../utils/snackbar_utils.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> historial = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historialRaw = prefs.getStringList('historial');

    if (historialRaw != null) {
      setState(() {
        historial = historialRaw
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList()
            .reversed
            .toList();
        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> _limpiarHistorial() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar historial?'),
        content: const Text(
            'Esta acción eliminará de forma permanente todas las recomendaciones guardadas localmente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('historial');
    if (!mounted) return;
    setState(() {
      historial = [];
    });
    showTopSnackBar(
      context,
      'Historial borrado correctamente',
      backgroundColor: Colors.green.shade700,
    );
  }

  Color _getBadgeColor(String? nivel) {
    switch (nivel) {
      case 'Alta':
        return Colors.green.shade700;
      case 'Media':
        return Colors.orange.shade700;
      case 'Baja':
        return Colors.amber.shade700;
      case 'No viable':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Cultivos'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (historial.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _limpiarHistorial,
              tooltip: 'Borrar historial',
            ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : historial.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 70, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tienes análisis guardados',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Las recomendaciones que generes aparecerán aquí.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final rec = historial[index];

                    final planAnterior = rec['plan_ia'] != null
                        ? (rec['plan_ia'] is String
                            ? jsonDecode(rec['plan_ia'])
                            : rec['plan_ia']) as Map<String, dynamic>?
                        : null;

                    final String nivelRentabilidad =
                        planAnterior?['rentabilidad']?['nivel'] ?? 'Pendiente';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailPage(
                                cultivo: rec['cultivo'] ?? 'Cultivo',
                                zona:
                                    '${rec['departamento']} - ${rec['municipio']}',
                                presupuesto:
                                    rec['presupuesto']?.toString() ?? '0',
                                area: rec['area']?.toString() ?? '0',
                                unidad: rec['unidad'] ?? 'm²',
                                departamento: rec['departamento'] ?? '',
                                municipio: rec['municipio'] ?? '',
                                tipoTerreno: rec['tipo_terreno'],
                                datosAnalisis: rec['datos_analisis'],
                                proveedoresInsumos: rec['proveedores_insumos'],
                                lat: rec['lat'],
                                lon: rec['lon'],
                                planGuardado: planAnterior,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              Colors.green.shade100,
                                          child: const Icon(Icons.agriculture,
                                              color: Colors.green),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                rec['cultivo'] ??
                                                    'Cultivo Desconocido',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${rec['municipio']}, ${rec['departamento']}',
                                                style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getBadgeColor(nivelRentabilidad)
                                            .withAlpha((0.15 * 255).round()),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        nivelRentabilidad,
                                        style: TextStyle(
                                          color:
                                              _getBadgeColor(nivelRentabilidad),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 1),
                              // 🔥 SE CORRIGIERON LOS CONTENEDORES CON EXPANDED PARA EVITAR EL OVERFLOW MARCADO EN AMARILLO
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: _metaInfo(
                                          Icons.payments,
                                          'Presupuesto',
                                          '\$${rec['presupuesto']}')),
                                  Expanded(
                                      child: _metaInfo(
                                          Icons.landscape,
                                          'Superficie',
                                          '${rec['area']} ${rec['unidad'] ?? "m²"}')),
                                  Expanded(
                                      child: _metaInfo(
                                          Icons.calendar_today,
                                          'Evaluado el',
                                          _formatearFecha(rec['fecha']))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _metaInfo(IconData icono, String etiqueta, String valor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          etiqueta,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow
              .ellipsis, // Corta el texto largo con '...' de forma segura
        ),
      ],
    );
  }

  String _formatearFecha(String? isoFecha) {
    if (isoFecha == null) return 'No disponible';
    try {
      final fecha = DateTime.parse(isoFecha);
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (e) {
      return 'No disponible';
    }
  }
}
