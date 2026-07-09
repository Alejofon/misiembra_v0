# MiSiembra (Flutter) — Pruebas del frontend

Evidencia de las pruebas automatizadas de la aplicación móvil. Complementa las
pruebas del backend (`API_DANE_MICRO/pruebas_validacion/`).

- **Rama:** `main` (app real). La app de validación vive en `pruebas-validacion`.
- **Framework:** `flutter_test` (widget/unit tests).
- **Última ejecución:** 2026-07-09 · **Resultado: 6/6 pruebas superadas.**

## Cómo ejecutar
```bash
flutter test        # corre toda la carpeta test/
flutter analyze     # análisis estático
```

## Pruebas y qué verifica cada una

| Archivo | Prueba | Qué valida |
|---|---|---|
| `test/number_format_test.dart` | Formato de números | `formatNumberWithDots` agrupa miles con puntos (formato COP). |
| `test/plan_response_parser_test.dart` | Parseo de respuesta del plan | `parsePlanResponse` limpia code-fences y normaliza números con coma antes de decodificar el JSON del backend. |
| `test/geocoding_service_test.dart` | Geocodificación | Comportamiento del servicio de geocodificación inversa (lat/lon → depto/municipio). |
| `test/ui_feedback_test.dart` | Botón de recomendaciones | En `HomePage`, el botón "Consultar recomendaciones" tiene el estilo/estado correcto según si el formulario está completo. |
| `test/ui_feedback_test.dart` | Notificación superior | `showTopSnackBar` muestra el aviso en la **mitad superior** de la pantalla mediante un `Overlay` propio (ya **no** usa el `SnackBar` de Flutter, que quedaba abajo tapando los botones) y se auto-cierra. |
| `test/widget_test.dart` | Smoke test de arranque | La app (`MyApp` → `StartPage`) se construye y muestra la pantalla inicial sin lanzar excepciones. |

## Análisis estático (`flutter analyze`)
- **2 avisos `info`** (no errores): uso de `withOpacity` (deprecado en favor de
  `withValues`) en `home_page.dart` y `start_page.dart`. No afectan la
  funcionalidad; son de estilo/deprecación.

## Notas
- Dos pruebas estaban desactualizadas y se corrigieron en esta iteración: el
  smoke test por defecto ("Counter increments", del andamiaje de Flutter) y la
  prueba de la notificación (que verificaba el `SnackBar` anterior). Ambas se
  reescribieron para reflejar el comportamiento vigente.
- Las **capturas de pantalla** de la app (Figuras del documento) se toman con la
  app corriendo en emulador/dispositivo; no forman parte de esta suite
  automatizada.
