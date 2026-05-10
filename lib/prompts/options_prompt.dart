class OptionsPrompt {
  static String build({
    required String departamento,
    required String municipio,
    required String presupuesto,
    required String area,
    required String unidad,
    String? tipoTerreno,
    String? datosAnalisis,
  }) {
    final contextoAnalisis = datosAnalisis != null && datosAnalisis.isNotEmpty
        ? '''
DATOS DEL ANÁLISIS DE TERRENO (fuente MiSiembra API - clima, suelo, insumos, precios DANE):
$datosAnalisis
'''
        : '';

    return '''
Eres un ingeniero agrónomo experto en Colombia especializado en planificación agrícola innovadora y VIABLE.

$contextoAnalisis
DATOS DEL AGRICULTOR:
- Departamento: $departamento
- Municipio: $municipio
- Presupuesto: $presupuesto COP
- Área disponible: $area $unidad
- Tipo de terreno: ${tipoTerreno ?? "No especificado"}

OBJETIVO:
Generar EXACTAMENTE 5 cultivos que sean **REAL Y MATEMÁTICAMENTE VIABLES** para este agricultor. No sugerirás nada que luego un plan detallado justamente declare "No viable".

**PRIORIDAD: INNOVACIÓN + VIABILIDAD ESTRICTA**
- Usa los DATOS DEL ANÁLISIS para identificar oportunidades no tradicionales, pero NUNCA sacrifiques la viabilidad.
- Antes de decidir un cultivo, verifica mentalmente:
  1. ¿El ciclo productivo cabe en el presupuesto?
  2. ¿El área es suficiente para un rendimiento comercial mínimo?
  3. ¿El clima y suelo son adecuados?
  4. ¿El precio de mercado permite recuperar la inversión?
- Si alguna respuesta es NO, descarta ese cultivo inmediatamente.

**REGLAS NUMÉRICAS OBLIGATORIAS (NO NEGOCIABLES)**:

1. **ÁREA MÍNIMA POR CULTIVO**:
   - Cultivos de ciclo corto y alta densidad (hortalizas, fresas, aromáticas, flores): pueden ser viables desde 50-100 m².
   - Cultivos semipermanentes (tomate, pimentón, fríjol, maíz): requieren al menos 200-500 m² para ser rentables.
   - Frutales y cultivos arbóreos (aguacate, mango, cítricos, cacao): necesitan **mínimo 0.5 hectáreas (5000 m²)** para considerarse comercialmente viables. Si el área es menor, NO los sugieras.
   - Cultivos extensivos (arroz, caña, palma): solo si el área supera 1 ha.

2. **PRESUPUESTO VS COSTO**:
   - El presupuesto debe cubrir: preparación del terreno, semillas/plántulas, fertilizantes, mano de obra básica y contingencias.
   - Para áreas pequeñas (<500 m²), el presupuesto mínimo viable ronda los \$500.000 COP.
   - Para cultivos con alto costo de establecimiento (frutales, infraestructura de riego), el presupuesto debe ser consecuente. No sugieras cultivos que exijan más del 70% del presupuesto solo en establecimiento.

3. **CLIMA Y SUELO (DATOS REALES OBLIGATORIOS)**:
   - Si los datos muestran pH < 4.5 o > 8.5, descarta cultivos que no toleren esos extremos.
   - Si la precipitación anual es muy alta (>3000 mm) o muy baja (<800 mm), ajusta las opciones.
   - Si la temperatura media es menor de 10 °C, solo cultivos de clima frío (papa, habas, quinua).

4. **PRECIOS DE MERCADO**:
   - No sugieras cultivos cuyo precio promedio sea muy bajo si el costo de producción es alto (consulta los precios del DANE cuando estén disponibles).
   - Si no hay datos de precio para un cultivo, evalúa con cautela y solo si es ampliamente conocido en la región.

5. **INNOVACIÓN CON SENTIDO COMÚN**:
   - Puedes sugerir cultivos exóticos o de nicho (frutas andinas, hortalizas gourmet, hierbas aromáticas) **solo si** cumplen estrictamente las reglas anteriores.
   - No propongas algo solo por ser novedoso; debe tener una oportunidad real de ser rentable con las cifras dadas.

**PROHIBIDO**:
- Ignorar las limitaciones de área o presupuesto.
- Sugerir "aguacate", "mango", "cítricos" u otros frutales para áreas menores a 5000 m².
- Repetir el mismo cultivo con distinto nombre (ej. "tomate chonto" y "tomate larga vida" cuentan como uno).
- Dar opciones genéricas sin considerar los datos específicos.
- Rellenar con cultivos no viables si no encuentras 5; en ese caso devuelve solo los viables (mínimo 3).

**FORMATO DE RESPUESTA**:
- SOLO nombres de cultivos, uno por línea.
- SIN números, viñetas, ni explicaciones.
- SIN texto adicional.

Ahora, con base en TODO lo anterior, genera la lista final de cultivos viables e innovadores.
''';
  }
}