# Packet Runner 🦏⚡

**A cybersecurity arcade project that evolved from a playable 2D prototype into a 3D runner set in the Cyber-Savanna.**

Packet Runner is built with **Godot 4** and **GDScript** as a practical development and portfolio project. The repository intentionally preserves both generations of the game so the evolution of the idea, code, mechanics and production workflow remains visible.

<p align="center">
  <a href="https://rhynocerus.github.io/packet-runner/"><img alt="Play Packet Runner 2D" src="https://img.shields.io/badge/PLAY-2D%20LEGACY-00BCD4?style=for-the-badge&logo=godotengine&logoColor=white"></a>
  <a href="https://rhynocerus.github.io/packet-runner/3d-v081/"><img alt="Play Packet Runner 3D" src="https://img.shields.io/badge/PLAY-3D%20WEB%20BUILD-00C896?style=for-the-badge&logo=godotengine&logoColor=white"></a>
</p>

<p align="center">
  <a href="https://github.com/rhynocerus/packet-runner/tree/packet-runner-3d-v0.8.1"><img alt="3D v0.8.1" src="https://img.shields.io/badge/3D%20MILESTONE-v0.8.1-6C63FF?style=flat-square"></a>
  <img alt="Godot 4" src="https://img.shields.io/badge/Godot-4.x-478CBF?style=flat-square&logo=godotengine&logoColor=white">
  <img alt="GDScript" src="https://img.shields.io/badge/GDScript-active-5D87BF?style=flat-square">
</p>

> **Current development milestone:** `packet-runner-3d-v0.8.1`  
> **Next planned pass:** `v0.8.2` Universal Controls for touch, gamepad and VR-controller-friendly input.

## Two generations, one project

Packet Runner is **not split into separate repositories**. The 2D version is kept as the original playable generation, while the 3D version is the current evolution of the same concept.

| Generation | Status | What it represents | Play |
|---|---|---|---|
| **Packet Runner 2D** | Legacy / playable | Original network-arcade prototype and the foundation of the project | [Play 2D](https://rhynocerus.github.io/packet-runner/) |
| **Packet Runner 3D** | Active development | Cyber-Savanna runner, cinematic presentation, Rhino Oscar and expanded mechanics | [Play 3D](https://rhynocerus.github.io/packet-runner/3d-v081/) |

The web build can temporarily trail the newest development commit until the latest export is published to GitHub Pages. Tagged milestones remain reproducible from Git.

## The evolution 🧬

```text
2D network arcade
      ↓
playable systems + Git workflow
      ↓
3D vertical slice
      ↓
Cyber-Savanna world
      ↓
cinematic presentation
      ↓
Rhino Oscar 3D character
      ↓
wide-lane steering + jump mechanics
      ↓
mobile / gamepad / VR-friendly controls
```

Rather than hiding the early prototype, the repository treats it as part of the engineering story: **prototype, test, learn, refactor, expand**.

## Game concept

In Packet Runner, computer-network traffic becomes a living arcade ecosystem:

- **Safe packets** are healthy network traffic moving through the system.
- **Malware** signals infection and intrusion.
- **Shield / firewall** provides system resilience and protection.
- **Boosts** deliver temporary network acceleration.
- **The rhino** is the runner and guardian moving through the network landscape.

The 3D world develops this idea as the **Cyber-Savanna**, where technology and nature share the same visual language.

## Packet Runner 3D · Current generation

The current 3D milestone is **v0.8.1**.

### Highlights

- 🦏 **Rhino Oscar**, a custom 3D cyber-rhino character
- 🎬 Cinematic intro and branded presentation
- 🌍 Procedural Cyber-Savanna environment
- 🛣️ Wide three-lane runner layout
- 🔄 Character steering that reveals a strong 3/4 profile during lane changes
- ⬆️ Jump mechanic
- ☠️ Malware that can be avoided by jumping
- 🛡️ Shield / firewall system
- ⚡ Network boosts
- 📦 Safe-packet scoring
- 🎵 Level music and gameplay sound effects
- 🌅 Multi-level visual progression
- 🌐 Native and web-oriented development workflow

### Desktop controls

| Action | Control |
|---|---|
| Change lane | `←` / `→` |
| Move forward / backward | `W` / `S` or `↑` / `↓` |
| Jump | `Space` |
| Pause / back | `Esc` |

Touch and gamepad/VR-controller input are planned for the **v0.8.2 Universal Controls** pass.

## Packet Runner 2D · Legacy generation

The original 2D game remains playable and preserved as the foundation of the project.

It established the first core loop:

- rhino player movement
- safe packets and scoring
- malware damage
- shield management
- procedural spawning
- web export
- iterative Git-based development

The 2D version is intentionally retained so the transition from a compact prototype to the current 3D architecture can be examined directly in one repository.

## Version history

| Milestone | Generation | Main change |
|---|---|---|
| `0.2-dev` | 2D | Early playable network-arcade prototype |
| `packet-runner-3d-v0.6.2` | 3D | Playable 3D vertical-slice baseline |
| `v0.7.1` | 3D | Cinematic Director Pass |
| **`packet-runner-3d-v0.8.1`** | **3D** | **Rhino Oscar, wider lanes, 3/4 steering and jump mechanics** |

See **[CHANGELOG.md](CHANGELOG.md)** for the milestone notes.

## Repository structure

```text
packet-runner/
├── assets/                 # audio, branding, fonts, models and game assets
├── docs/                   # GitHub Pages 2D web build
│   └── 3d/                 # GitHub Pages 3D web build
├── scenes/
│   ├── 3d/                 # current 3D game, rhino and showcase scenes
│   ├── background/         # original 2D systems
│   ├── packet/
│   ├── player/
│   └── main.tscn           # original 2D main scene
├── scripts/
│   └── 3d/                 # 3D gameplay and Rhino Oscar controller
├── exports/                # selected export artifacts and production output
├── tools/                  # project utilities / export helpers
├── project.godot
├── export_presets.cfg
├── CHANGELOG.md
└── README.md
```

## Run locally

Requires **Godot 4.x**.

```bash
git clone https://github.com/rhynocerus/packet-runner.git
cd packet-runner
godot --path .
```

### Reproduce the current 3D milestone

```bash
git checkout packet-runner-3d-v0.8.1
godot --path . scenes/3d/game/packet_runner_3d.tscn
```

### Follow current 3D development

```bash
git switch feat/rhino-promo-pass
godot --path . scenes/3d/game/packet_runner_3d.tscn
```

## Development direction

Packet Runner is being developed with one guiding principle:

> **It should feel fast before it becomes visually heavy.**

Near-term work focuses on control feel and accessibility before adding heavier visual complexity:

- touch controls for mobile
- gamepad input and VR-controller-friendly mappings where supported
- web audio / autoplay behaviour
- stronger movement feedback
- continued gameplay balancing
- further visual and material polish
- reliable multiplatform exports

## Why this project exists

Packet Runner is a learning and portfolio project designed to demonstrate more than a final screenshot. It preserves the process itself:

- version control and feature branches
- iterative gameplay design
- debugging and regression testing
- 2D-to-3D architectural evolution
- asset and character pipelines
- native and web exports
- reproducible tagged milestones
- documentation of decisions and limitations

The cybersecurity theme gives the project a playful way to connect **software development, networking concepts, visual design and interactive systems**.

---

**Packet Runner · A Rhynus Project** 🦏
