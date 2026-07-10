# Capturas de pantalla — evidencia para el documento

Capturas generadas automáticamente con `integration_test` + `flutter drive`
sobre el simulador iOS (iPhone 16e), contra el backend en producción. Cada
imagen corresponde a una figura del documento de grado.

## Mapa figura → archivo

| Figura | Archivo | Pantalla | Cómo se generó |
|---|---|---|---|
| **Fig 1** | `fig01_formulario.png` | App de pruebas — formulario diligenciado | `integration_test/fig01_test_calculo_test.dart` (rama `pruebas-validacion`) |
| **Fig 1** | `fig01_resultado.png` | App de pruebas — resultado del cálculo (Zanahoria, "Alta", ganancia, precio DANE) | idem |
| **Fig 11** | `fig11_home_formulario.png` | HomePage con presupuesto y área diligenciados | `integration_test/fig_app_real_test.dart` (rama `main`) |
| **Fig 12** | `fig12_opciones.png` | Las 5 opciones de siembra de `/opciones-cultivo` | idem |
| **Fig 13/14** | `fig13_14_plan_rentabilidad.png` | Detalle del proyecto — pestaña Rentabilidad (cifras + descripción IA) | idem |
| **Fig 15** | `fig15_plan_tiempos.png` | Detalle — pestaña Tiempos | idem |
| **Fig 16** | `fig16_plan_plagas.png` | Detalle — pestaña Plagas | idem |
| **Fig 17** | `fig17_plan_proveedores.png` | Detalle — pestaña Proveedores | idem |
| **Fig 18** | `fig18_historial.png` | Historial de análisis | idem |

## Cómo regenerar
```bash
# App de pruebas (Fig 1) — en la rama pruebas-validacion:
flutter drive --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/fig01_test_calculo_test.dart -d <simulador>

# App real (Fig 11–18) — en la rama main:
flutter drive --driver=test_driver/screenshot_driver.dart \
  --target=integration_test/fig_app_real_test.dart -d <simulador>
```

## Figuras que faltan (requieren captura manual)

- **Fig 10** — StartPage con la ubicación detectada: depende del GPS real del
  dispositivo (permiso + geocodificación en vivo), difícil de automatizar de
  forma confiable en el simulador. Recomendado: tomarla a mano corriendo la app
  y pulsando "Usar ubicación actual".
- **Fig 19 / Fig 24** — formularios de los casos 1 y 2: son el mismo formulario
  de entrada (como Fig 11) diligenciado con los datos de cada caso
  (Turmequé $2.000.000/1 ha; Villavicencio $50.000.000/10 ha). Se pueden
  regenerar cambiando los valores en `fig_app_real_test.dart` o tomarlas a mano.
- **Fig 2–6** (evidencia de Scrum) y **Fig 20–21, 26–28**: salen de GitHub / de
  los JSON de `API_DANE_MICRO/pruebas_validacion/resultados/`, no de la app.
