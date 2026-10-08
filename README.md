# GREHICY HEARTBOUND

Juego personal de plataformas 3D en tercera persona, hecho con **Godot 4.7** y **GDScript**.
Inspirado en la fórmula de Crash Bandicoot (correr, saltar, romper cajas, recoger), con
identidad, arte y textos propios: no se usan recursos de juegos existentes.

## Requisitos

- [Godot 4.7](https://godotengine.org/download) versión **estándar** (no la de .NET).
- Sin dependencias externas. El arte es procedural: mallas, colores y texturas se generan
  desde el propio proyecto.

## Cómo abrirlo

1. Godot → *Import* → seleccionar `project.godot`.
2. Pulsar **F5**: el juego arranca en el menú principal.

## Controles

| Acción              | Teclas                    |
| ------------------- | ------------------------- |
| Moverse             | W A S D o flechas         |
| Saltar              | Espacio                   |
| Ataque giratorio    | J o clic izquierdo        |
| Cámara              | Ratón (arrastrar)         |
| Pausa               | Esc                       |
| Capturar/soltar ratón | Esc (al pausar/despausar) |

## Estructura

```
scenes/   escenas por dominio: player, enemies, objects, levels, main, ui
scripts/  lógica por dominio:  player, enemies, objects, levels, systems, ui
assets/   texturas, audio y (más adelante) modelos y animaciones
data/     contenido editable: recuerdos, diálogos, mensaje final y catálogo de niveles
tools/    sonda de pruebas automatizadas (probe)
```

El catálogo de niveles vive en `data/levels.json`: añadir un mundo es editar ese
fichero, el selector de niveles se construye solo.

El audio también es propio: los efectos y las pistas son WAV generados desde el
proyecto (`assets/audio/`) y se reproducen desde el autoload `AudioManager`,
que reparte el sonido en dos buses: `Music` y `SFX`.

## Fases

- ✅ **FASE 1** — Movimiento, salto y cámara en tercera persona.
- ✅ **FASE 2** — Ataque giratorio, enemigos, cajas, coleccionables, HUD, checkpoint y fin de nivel.
- ✅ **FASE 3** — Menú principal, selector de niveles, pausa y guardado de progreso (`user://progress.cfg`).
- ✅ **FASE 4** — Audio: 11 efectos de sonido, música de menú y de nivel con fundido
  cruzado y bucle, buses `Music`/`SFX` y clics en todos los botones.

## Pruebas automáticas

El proyecto incluye una sonda que verifica las fases implementadas sin abrir el editor:

```bash
Godot --headless --path . res://tools/probe.tscn
```

Imprime líneas `PROBE ...` con el resultado de cada comprobación y termina con `PROBE_DONE`.
