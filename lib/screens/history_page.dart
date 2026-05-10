import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recommendation_detail_page.dart';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('historial');
    if (!mounted) return;
    setState(() {
      historial = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial borrado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de recomendaciones'),
        centerTitle: true,
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
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay recomendaciones guardadas',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Genera una nueva recomendación para comenzar',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final rec = historial[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.agriculture, color: Colors.green),
                        title: Text(
                          rec['cultivo'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📍 ${rec['departamento']} - ${rec['municipio']}'),
                            Text('💰 ${rec['presupuesto']} COP | 📏 ${rec['area']}'),
                            Text('📅 ${_formatearFecha(rec['fecha'])}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecommendationDetailPage(
                                cultivo: rec['cultivo'],
                                zona: '${rec['departamento']} - ${rec['municipio']}',
                                presupuesto: rec['presupuesto'],
                                tiempoCosecha: 'Variable según el cultivo',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  String _formatearFecha(String isoFecha) {
    try {
      final fecha = DateTime.parse(isoFecha);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }
}