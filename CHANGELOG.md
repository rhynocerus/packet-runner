# Changelog

Packet Runner keeps both its original 2D generation and its current 3D evolution in the same repository. This file records the major project milestones rather than every internal experiment.

## Unreleased · next

### Planned for 3D v0.8.2 · Universal Controls

- Touch controls for mobile play
- Dedicated on-screen jump control
- Gamepad mappings for lane movement and jump
- VR-controller-friendly input where the browser/runtime exposes controllers as gamepads
- Continued web audio / autoplay testing
- Further movement and feedback polish

## 3D v0.8.1 · 2026-09-12

**Tag:** `packet-runner-3d-v0.8.1`

The first milestone that combines the refined 3D Rhino Oscar character with the expanded runner mechanics.

### Added

- Rhino Oscar 3D GLB integrated into the game
- Dedicated `RhinoOscar3D` controller around the imported model
- Animated body, head, arms and legs using the imported node structure
- Wider road and larger lane spacing
- Strong 3/4 visual steering during lane changes
- Jump mechanic using `Space`
- Airborne character pose
- Malware evasion while jumping above the clearance threshold
- Higher gameplay pace and denser spawning from the V8 sprint pass
- Godot UID and import metadata required for a reproducible model import

### Validation

- Native Godot 4.7.2 run verified on the development system
- Clean-clone import test completed successfully
- Rhino Oscar model imported correctly from a fresh clone
- Milestone tagged and pushed to GitHub

## 3D v0.7.1 · Cinematic Director Pass

### Added / changed

- Cinematic intro sequence
- Rhynus branding presentation
- Improved title and menu motion
- Multi-level music setup
- Refined Cyber-Savanna presentation
- Continued native and web testing

This milestone established the more cinematic identity of the 3D generation before the final Rhino Oscar integration.

## 3D v0.6.2 · Vertical-slice baseline

**Tag:** `packet-runner-3d-v0.6.2`

### Included

- Playable 3D Cyber-Savanna prototype
- Rhino runner
- Three-lane movement
- Safe packets
- Malware hazards
- Shield / firewall gameplay
- HUD and status feedback
- Procedural environment elements
- Web-oriented export work

This milestone proved that the original 2D concept could survive the transition into a full 3D runner.

## 2D 0.2-dev · Legacy generation

The original playable Packet Runner prototype.

### Core systems

- 2D rhino player
- Keyboard movement
- Safe packets worth score
- Malware damage
- Shield system
- Procedural packet spawning
- Spanish interface
- Web export through GitHub Pages

The 2D generation is intentionally preserved instead of being replaced or moved to another repository. It documents where Packet Runner started and makes the project's 2D-to-3D evolution visible.

---

## Evolution summary

```text
2D prototype
    ↓
playable networking loop
    ↓
3D vertical slice
    ↓
Cyber-Savanna
    ↓
cinematic identity
    ↓
Rhino Oscar
    ↓
wide lanes + 3/4 steering + jump
    ↓
universal controls
```

**Packet Runner · A Rhynus Project** 🦏
