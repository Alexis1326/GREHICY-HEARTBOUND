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
2. Abrir `scenes/main/Main.tscn` y pulsar **F5**.

## Controles

| Acción              | Teclas                    |
| ------------------- | ------------------------- |
| Moverse             | W A S D o flechas         |
| Saltar              | Espacio                   |
| Ataque giratorio    | J o clic izquierdo        |
| Cámara              | Ratón (arrastrar)         |
| Capturar/soltar ratón | Esc                     |

## Estructura

```
scenes/   escenas por dominio: player, enemies, objects, levels, main, ui
scripts/  lógica por dominio:  player, enemies, objects, levels, systems, ui
assets/   texturas y (más adelante) modelos, animaciones y audio
data/     contenido editable: recuerdos, diálogos, mensaje final, niveles
tools/    sonda de pruebas automatizadas (probe)
```

## Fases

- ✅ **FASE 1** — Movimiento, salto y cámara en tercera persona.
- ✅ **FASE 2** — Ataque giratorio, enemigos, cajas, coleccionables, HUD, checkpoint y fin de nivel.
- 🚧 **FASE 3** — Menú principal, selector de niveles y guardado de progreso.

## Pruebas automáticas

El proyecto incluye una sonda que verifica las fases implementadas sin abrir el editor:

```bash
Godot --headless --path . res://tools/probe.tscn
```

Imprime líneas `PROBE ...` con el resultado de cada comprobación y termina con `PROBE_DONE`.
