# HELLGATE

A Doom-inspired first-person survival shooter set on an infected freighter deck. Open `project.godot` in Godot 4.7 and press F5. The playable level is a 7 × 7 network of interconnected rooms (about 140 × 140 game units) assembled from Kenney's premade Modular Space Kit. The old hangar demo remains in the project as a source of props and for reference; the active main scene is `main_ship.tscn`.

The run has an opening briefing, pause/death/victory menus, ten connected combat stages, dynamic music, and infected enemies. Defeat every monster in a room, press F at its locked door, and walk through to start the next stage. Enemy health, damage, and wave size rise across the stages. Health and ammunition are awarded automatically between stages; there are no supply caches. The final stage opens into a 40 × 60 unit arena with cover and two elite enemies: the infected captain and warden. Guards enter throughout the boss fight. The entrance seals behind the player, and the exit unlocks after both elites and remaining guards die. The elite models and animations reuse the project's existing undead asset. Weapons use the original animated FPS arms and matching guns, with firing, reload, and switch motion. The structural pieces and props are external assets.

Controls: WASD move, Shift sprint, Space jump, mouse aim/fire, R reload, mouse wheel change weapon, F interact, Esc pause.

This is a playable prototype, not an AAA production. Some active props from the abandoned ship demo are **CC BY-NC 4.0**, so commercial distribution needs a separate licence or replacement assets. See `THIRD_PARTY_ASSETS.md` and `ABANDONED_SHIP_LICENSE.txt`. The FPS template's code licence is in `LICENSE`.

## Original template

A beginner-friendly, modular, free and open-source FPS (first-person shooter) template built by [bukkbeek](https://bukkbeek.github.io) for the Godot community.

Includes player movement, aim-down-sights (ADS), a complete hitscan weapon system, ammo, health, a test level, vehicles, and common FPS utilities you can strip or extend.

> **Work in progress:** This project is still under  development. You may encounter bugs, incomplete code.
> The README currently includes a brief tutorial for understanding the project structure. A more comprehensive tutorial is planned for a future update.


---
**Feature video:**
[![Watch the feature video](https://img.youtube.com/vi/HDL8GqJAMLs/maxresdefault.jpg)](https://www.youtube.com/watch?v=HDL8GqJAMLs)

---

## Project Links

- GitHub: https://github.com/bukkbeek/GodotFPS-Template
- itch.io: https://bukkbeek.itch.io/godot-fps-template

---

## Built With

- [Godot 4.6](https://godotengine.org/)
- 3D assets + FPS arms animations by [bukkbeek](https://bukkbeek.github.io)
- VFX from [EffectBlocks](https://bukkbeek.itch.io/effectblocks) by [bukkbeek](https://bukkbeek.github.io)
- SFX from [Pixabay](https://pixabay.com/)
- Undead animations from [Mesh2Motion](https://mesh2motion.org/) library
- Built with [Cursor](https://www.cursor.com/) 

---

## Feature list

This *feature list* is not completed but I will update and migrate all descriptions into following table as the project ongoing.

| ID | Category | Description | Status | Version |
| --- | --- | --- | --- | --- |
| 1.1 | Gameplay: player | Player movement and control systems at `res://player/player.tscn` | complete | 0.1 |
| 1.2 | Gameplay: input | Input handled at `res://common/managers/input_manager.gd` | complete | 0.1 |
| 1.3 | Gamplay: global autoload | `res://common/autoloads/global.gd` | Complete | 0.1 |
| 2.0 | Weapons: base | weapons inherited from `res://common/weapon/weapon_base.tscn` managed using `res://common/managers/weapons_manager.gd` | complete | 0.1 |
| 2.0.1 | Weapons: ammo refill | tracked using autoload: `res://common/autoloads/bullets.gd`, ammo loot can use: `res://common/utils/ammo_refil.gd` | Complete | 0.1 |
| 2.1 | Weapons: knife | `res://weapons/knife.tscn` (using hitscan) | complete | 0.1 |
| 2.2 | Weapons: Pistol | `res://weapons/pistol.tscn` | complete | 0.1 |
| 2.3 | Weapons: Assault rifle | `res://weapons/assualt_rifle.tscn` | complete | 0.1 |
| 2.4 | Weapons: Assault burst rifle | `res://weapons/assualt_burst.tscn` | complete | 0.1 |
| 2.5 | Weapons: LMG | `res://weapons/lmg.tscn` | complete | 0.1 |
| 2.6 | Weapons: SMG | FPS arms animations done/ needs implementation | in progress | - |
| 2.7 | Weapons: Shotgun | FPS arms animations done/ needs implementation | in progress | - |
| 2.8 | Weapons: Sniper | FPS arms animations done/ needs implementation | in progress | - |
| 2.9 | Weapons: Rifle | FPS arms animations done/ needs implementation | in progress | - |
| 2.10 | Weapons: Railgun | FPS arms animations done/ needs implementation | in progress | - |
| 2.11 | Weapons: Flamethrower | FPS arms animations done/ needs implementation | - |
| 2.12 | Weapons: Grenade launcher | FPS arms animations done/ needs implementation | in progress | - |
| 2.13 | Weapons: Hand grenade | FPS arms animations done/ needs implementation | in progress | - |
| 2.14 | Weapons: Smoke grenade | FPS arms animations done/ needs implementation | in progress | - |
| 2.15 | Weapons: Medi kit | FPS arms animations done/ needs implementation | in progress | - |
| 3.0 | Enemy: base | Enemies inherit  `res://common/enemy/enemy_base.tscn` - these are patrol-see-chase-attack type zombie enemies| Complete | 0.1 |
| 3.1 | Enemy: undead | `res://enemies/undead.tscn` | Complete | 0.1 |
| 4 | Interactives | World interactable gameplay items path: `res://world/interactive_items/`| Complete | 0.1 |
| 4.1 | Interactives: Ammo refill pickup | `res://common/utils/ammo_refil.tscn` | Complete | 0.1 |
| 4.2 | Interactives: auto door | `res://world/auto_door/door.tscn` | Complete | 0.1 |
| 4.3 | Interactives: Exploding barrel | `res://world/interactive_items/exploding_barrel.tscn` | Complete | 0.1 |
| 4.4 | Interactives: Vehicle | Drivable vehicle system (drive, steering, brake, enter/exit) |  `res://resources/vehicle/vehicle.gd` | Complete | 0.1 |
| 4.4.1 | Interactives: Vehicle: jeep | Vehicle camera + engine audio tuning | `res://resources/vehicle/jeep.tscn` note: needs tuning | complete | 0.1 |
| 5 | UI: HUD and feedback systems | `res://common/hud/` | Basic | 0.1 |
| 5.1 | UI: Gameplay HUD (health/weapon/ammo) | `res://common/hud/gameplay_hud.tscn`, `res://common/hud/hud.gd` | Basic | 0.1 |
| 5.2 | UI: Crosshair behaviors | `res://common/hud/crosshair.gd` | Basic | 0.1 |
| 5.3 | UI: Damage display feedback | `res://common/hud/damage_display.gd` | Basic | 0.1 |
| 6 | SFX| `res://resources/sfx/`, `res://player/sfx/` | Basic | 0.1 |
| 6.1 | SFX: Weapon sounds (fire/reload/switch/empty) | `res://resources/sfx/weapons/` | Basic | 0.1 |
| 6.2 | SFX: Movement and interaction sounds | `res://player/sfx/`, `res://resources/sfx/door_open.wav.import` | Basic | 0.1 |
| 6.3 | SFX: Enemy and other | `res://resources/undead/sfx/` | Basic | 0.1 |
| 7 | VFX |Visual effects systems and assets  `res://resources/vfx/`, `res://resources/undead/vfx/` | Complete | 0.1 |
| 7.1 | VFX  Muzzle flashes | `res://resources/vfx/muzzle_flash/vfx_muzzle_1.tscn` | Complete | 0.1 |
| 7.2 | VFX Bullet decals / bullet holes | `res://resources/vfx/bullet_decal.tscn` | Complete | 0.1 |
| 7.3 | VFX Explosion effects | `res://resources/vfx/explosions/vfx_standard_explosion.tscn` | Complete | 0.1 |
| 7.4 | VFX Enemy death VFX | `res://resources/undead/vfx/undead_death_vfx.tscn` | Complete | 0.1 |
| 8 | Utils: spawner | `res://common/spawner/spawner.tscn` | Complete | 0.1 |



---

## Controls

| Action | Default Binding |
| --- | --- |
| Move | W A S D |
| Look | Mouse |
| Fire | Left Mouse |
| Aim (ADS) | Right Mouse |
| Jump | Space |
| Sprint | Shift |
| Crouch | Ctrl |
| Reload | R |
| Previous / Next Weapon | Mouse Wheel Up / Down |
| Interact / Use | F |
| Exit / Menu | Esc |
| Vehicle Brake | Space *(when driving)* |

Remap everything under **Project → Project Settings → Input Map**.

---

## Project Layout

| Path | Role |
| --- | --- |
| `main.tscn` | Entry scene |
| `common/` | Shared scripts: autoloads, weapons base, managers, utilities |
| `player/` | Player scene + movement, health, camera |
| `weapons/` | Individual weapon scenes (pistol, rifles, knife, etc.) |
| `world/` | Levels and interactive props |
| `resources/` | Meshes, materials, vehicles, VFX, audio |

**Autoloads** (see **Project -> Project Settings -> Autoload**):

- `Global` — `common/autoloads/global.gd`: player reference, game state, UI signals (health, weapons, aim, etc.).
- `Bullets` — ammo pools / types used by weapons and refill stations.

---

## Customization Guide

### Player (`player/player.gd`)

| Variable | Purpose |
| --- | --- |
| `walk_speed` | Base move speed |
| `sprint_speed` | Sprint multiplier speed |
| `jump_velocity` | Jump strength |
| `sensitivity` | Mouse look sensitivity |

Health is defined in script (`MAX_HEALTH`, `current_health`); adjust there for different max HP or regen behavior.

### Weapons Manager (`WeaponsManager` on Player)

| Variable | Purpose |
| --- | --- |
| `follow_speed` | How fast the weapon rig follows the camera |
| `weapons_array` | Order and list of equipped weapon node paths |

### Per-Weapon (`common/weapon/weapon.gd`)

| Group / Variable | Purpose |
| --- | --- |
| **Weapon settings** | `is_melee_weapon`, `is_projectile`, `firing_distance` |
| **Bullets** | `bullet_type`, `damage`, `cooldown`, `burst_mode`, `consume`, `reload_required`, `mag_capacity`, `reload_time` |
| **Gameplay connections** | `focused_aim_fov`, `focused_aim_angle`, `standard_aim_angle` |
| **SFX / VFX** | Audio nodes, `firing_vfx`, `bullet_decal`, muzzle marker |

### Ammo Refill Pickup (`common/utils/ammo_refil.gd`)

| Variable | Purpose |
| --- | --- |
| `pistol_ammo`, `assault_ammo`, `lmg_ammo`, … | Reserve ammo granted per type when the player presses **Interact** |
| `outline_mesh` | Optional highlight mesh while designing |

### Vehicle (`resources/vehicle/vehicle.gd`)

| Group | Variables |
| --- | --- |
| **Engine** | `engine_force_value`, `max_rpm`, `brake_strength` |
| **Steering** | `steering_limit`, `steering_speed` |
| **Camera** | `camera_sensitivity`, `camera_pitch_min`, `camera_pitch_max` |
| **Audio** | `engine_audio`, `engine_min_pitch`, `engine_max_pitch`, `engine_max_speed` |
| **Visuals** | Door / outline meshes, `animation_player`, `get_in_animation` |

### Global Flags (`common/autoloads/global.gd`)

| Variable | Purpose |
| --- | --- |
| `debug_mode` | Toggle for debug behavior if you extend the autoload |
| `in_vehicle` | Driving state (used to block some interactions) |

---

## Extending the Template

- **New weapon:** Inherit from the base weapon in `weapons/`, configure `Weapon` script exports, add the instance under `WeaponsManager`, and append its `NodePath` to `weapons_array`.
- **New level:** Duplicate `world/test_level.tscn` or set **Main Scene** to your level; ensure the player and UI are spawned as in `main.tscn` if you rely on that flow.
- **Render layers:** Check **Project → Project Settings → Layer Names → 3D Render** (e.g. weapon layer vs world) when adding cameras or culling masks.

---


## Version Notes

| Version | Notes |
| --- | --- |
| `v0.1` | Initial release. |

---

## License

This project is under MIT license. You can fork, edit, use the repo as you want.
But you are prohibited to resell any asset originating from this project including 3D assets, VFX, SFX (credits: [Pixabay](https://pixabay.com/)) and animations (Credits: [Mesh2Motion](https://mesh2motion.org/))

---

## Credits

**Godot FPS Template** by [bukkbeek](https://bukkbeek.github.io)

| Contributor / Tool | Role |
| --- | --- |
| [bukkbeek](https://bukkbeek.github.io) | Project author, 3D assets, FPS arm animations, VFX |
| [EffectBlocks](https://bukkbeek.itch.io/effectblocks) | VFX library |
| [Pixabay](https://pixabay.com/) | Sound effects |
| [Mesh2Motion](https://mesh2motion.org/) | Undead character animations |

