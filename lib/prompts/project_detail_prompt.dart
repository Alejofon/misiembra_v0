class ProjectDetailPrompt {
  static String build({
    required String cultivo,
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
DATOS DEL ANÁLISIS DE TERRENO Y MERCADO (fuente MiSiembra API):
$datosAnalisis
'''
        : '';

    return '''
Eres un ingeniero agrónomo experto en Colombia. Genera un plan de cultivo **REALISTA Y FLEXIBLE**, teniendo en cuenta que el agricultor puede sembrar solo una fracción del terreno si el presupuesto es limitado.

$contextoAnalisis
DATOS DEL AGRICULTOR:
- CULTIVO: $cultivo
- UBICACIÓN: $departamento - $municipio
- PRESUPUESTO: $presupuesto COP
- ÁREA DISPONIBLE (MÁXIMA): $area $unidad
- TIPO DE TERRENO: ${tipoTerreno ?? "No especificado"}

**DEFINICIÓN CLAVE DE VIABILIDAD (LEE CON ATENCIÓN):**
- El área reportada es el **terreno disponible**, NO la superficie que el agricultor está obligado a cultivar. Con presupuesto limitado, puedes sembrar solo una parte.
- La viabilidad se juzga según la **mejor combinación posible de cultivo dentro de las restricciones reales**:
  * Si el presupuesto solo alcanza para 100 m² de un cultivo, pero el agricultor tiene 1 ha, el proyecto es viable **si esos 100 m² generan una ganancia razonable** (por ejemplo, un cultivo intensivo de alta rentabilidad).
  * Si el área es muy pequeña (ej. 10 m²) pero el presupuesto es alto, no se pueden hacer milagros: cultivos arbóreos o que necesitan mucho espacio no son viables.
- **NUNCA declares un proyecto como “No viable” simplemente porque el área total es grande y el presupuesto pequeño, siempre que exista un plan posible (aunque sea a micro escala) que sea rentable.** Solo declara “No viable” si:
  - El clima/suelo es incompatible.
  - Incluso la escala mínima del cultivo (una cama de siembra, un pequeño lote) no puede generar un retorno positivo con el presupuesto disponible, por costos fijos o precios muy bajos.
  - El cultivo simplemente no crece en esas condiciones.

**INSTRUCCIONES PARA EL PLAN:**

1. **Rentabilidad**:
   - Estima cuánta área es realmente cultivable con el presupuesto (descontando costos de preparación, insumos y mano de obra).
   - Calcula la producción esperada y los ingresos potenciales según el precio de mercado (si está disponible en los datos).
   - La **ganancia estimada anual** debe reflejar ese escenario realista.
   - Si los datos de precios del DANE muestran un buen margen, incluso con poco volumen el proyecto puede ser viable.
   - El nivel de rentabilidad puede ser "Baja", "Media" o "Alta". Usa "Baja" para proyectos pequeños pero con retorno positivo.

2. **Tiempos y manejo**:
   - Recomienda la mejor época de siembra, calendario de riego y fertilización ajustados al cultivo y la escala.

3. **Semillas**:
   - Especifica cantidad de semillas/plántulas necesarias para la superficie realmente cultivada (no para todo el terreno).
   - Si hay proveedores reales disponibles, menciónalos; si no, lista vacía.

4. **Plagas**:
   - Indica plagas comunes, síntomas y control.

5. **Mercado**:
   - Usa los precios del DANE si están disponibles; si no, indica "NO_DISPONIBLE".  
   - Menciona canales de venta reales (mercados locales, intermediarios, etc.).

6. **Beneficios y pasos de siembra**:
   - Detalla beneficios (nutricionales, económicos, ambientales) y los pasos técnicos para este cultivo a la escala determinada.

**FORMATO DE SALIDA (OBLIGATORIO JSON VÁLIDO, SIN TEXTO ADICIONAL):**

{
  "rentabilidad": {
    "nivel": "Alta | Media | Baja | No viable",
    "descripcion": "Explicación clara de la viabilidad según el presupuesto, área real cultivada y precios. Si el proyecto es pequeño pero factible, indícalo.",
    "retorno_inversion_meses": número o null,
    "ganancia_estimada_por_cosecha": "texto descriptivo o cifra en COP"
  },
  "dificultad": {
    "nivel": "Alta | Media | Baja",
    "descripcion": "Descripción técnica"
  },
  "tiempos": {
    "siembra_mejor_epoca": "meses reales",
    "cosecha_meses": número,
    "calendario_riego": "detalle real",
    "calendario_fertilizacion": "detalle real"
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
    "precio_actual_kg": "precio o NO_DISPONIBLE",
    "canales_venta": ["canales reales"],
    "compradores": [],
    "tendencias": "basado en contexto colombiano"
  },
  "beneficios": ["beneficios reales"],
  "pasos_siembra": ["pasos técnicos reales"]
}
''';
  }
}