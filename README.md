# Packet Runner 🦏⚡

**A small 2D arcade game where computer-network traffic becomes the game mechanic.**

Packet Runner is an open Godot project built as a practical software-development exercise: design a playable system, iterate through Git branches, document the work, and prepare it for multiple platforms.

The player controls a rhino moving through a network-inspired arena, collecting safe packets while avoiding malware.

## Status

**Prototype: `0.2-dev`**

The current build is playable and includes the core gameplay loop. Visual design, balancing, export targets and additional mechanics are still in development.

## Current gameplay

- Rhino player controlled with `WASD` or arrow keys
- Safe packets that increase the score
- Malware packets that damage the shield
- Score system
- Shield system
- Basic procedural packet generation
- Spanish interface

### Rules

| Event | Effect |
|---|---:|
| 🟢 Safe packet | `+10` points |
| 🔴 Malware | `-15` shield |

## Technology

- **Godot 4**
- **GDScript**
- Scene/component-based project structure
- Git branches and incremental development
- OpenGL compatibility renderer

The project currently targets a `1280 × 720` viewport and uses Godot's compatibility renderer to remain practical on modest hardware.

## Run locally

Requires **Godot 4.x**.

```bash
git clone https://github.com/rhynocerus/packet-runner.git
cd packet-runner
godot --path .
```

You can also import `project.godot` from the Godot project manager.

## Repository structure

```text
packet-runner/
├── project.godot
├── scenes/
│   ├── main.tscn
│   └── player/
└── scripts/
    ├── main.gd
    └── player/
```

The structure will evolve as gameplay systems are separated into reusable components.

## Development goals

- Improve the rhino character so its silhouette and movement read clearly
- Refine packet spawning and difficulty progression
- Improve feedback for score, shield and damage
- Add sound and visual polish
- Prepare reliable exports for desktop and web
- Explore Android and iOS exports after the core game is stable

## Why this project exists

Packet Runner is deliberately small enough to finish and rich enough to practice real development habits: version control, branches, incremental features, debugging, documentation, release planning and multiplatform constraints.

The networking theme also gives the project room to grow into a playful bridge between **software development and cybersecurity concepts**.

## Portfolio note

This is an active learning and portfolio project. The repository is intended to show the development process as well as the finished result, so intermediate milestones and documented limitations are part of the project history.
