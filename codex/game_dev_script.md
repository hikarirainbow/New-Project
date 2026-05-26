# METRICS & SPECS

## AI Agent Guidelines (IMPORTANT)
- **Ask the User First**: Whenever a task seems complex, requires long workarounds, or has high ambiguity, stop and ask the user directly instead of searching through massive chat history logs or trying complex recovery processes. The user is here to help and clarify.
- **Do Not Waste Tokens**: Avoid repetitive commands, excessively long plans, or rebuilding logic from scratch when a simple question to the user can resolve the path immediately.

## Player
SPEED: 200.0
ACCEL: 1000.0
FRICTION: 1200.0 (Actor)
SIZE: Collision 32x64 | Sprite scale 0.25x0.5 (= 32x64px visual, 2 tiles tall on a 32x32px grid)
JUMP: -450.0 (~103px apex, hold to jump higher)
JUMP_STYLE: Smooth variable jump – on release velocity.y *= 0.1 if rising (min jump ~5px)
GRAVITY_UP: 980. GRAVITY_DOWN: 980*1.5=1470
HP: max=100, respawn_debuff=-20 (max HP 80). Taking damage triggers invincibility (0.5s) with a visual flashing effect (10Hz). Interrupted state: damage immediately cancels active attack or dash. Knockback: player is locked from moving and pushed away (300px/s horizontal force, -180px/s upward bounce, duration 0.3s). Configurable via Inspector exports.
DASH: 0.2s (0.18s iframe, 0.02s lerp), CD=0.8s (upgradable 0.4s). Direction locked, sprite faces dash direction, recovery lerps to 0 or same direction. Key=C
ATTACK: 0.15s duration per strike. 3-hit combo variation. Key=X. Combo reset delay=0.5s after the attack ends (reverts back to Hit 1). Locks direction/input (stops horizontal movement on ground, falls vertically in air). Hitbox shapes:
- Hit 1: 40x50px in front (blue indicator).
- Hit 2: 40x50px in front + 70x40px above head (green indicators).
- Hit 3: 50x30px in front (red indicator).
COMPONENTS (Component-based architecture to reduce player.gd complexity):
- AttackComponent (Node2D): Manages the 3-hit melee combo mechanics, dynamic shape scaling, and visual indicators.
- DashComponent (Node): Manages dash cooldowns, speed calculations, movement locks, and iframes.
- LightComponent (Node2D): Configures and instantiates the PointLight2D radial flashlight.


## Upgrade Item
TYPE: Dash CD Halver (Green Circle)
POS: (960, 592)
FUNC: player.upgrade_dash_cooldown() -> CD = 0.4s. queue_free()

## Defeated & QTE Flow
TRIGGER: Player HP <= 0 OR Enemy overlap
COLLISION: Player and Enemy do not collide physically (can pass through each other; collision_mask = 1). Contact damage and QTE triggers are resolved via bounding box distance checks (dx < 30px, dy < 44px).
STATE: GRABBED (locks input) -> QTE UI (Space/E spam)
SUCCESS: pushback, heal minor, resume play
FAILURE: DEFEATED state -> fade out (0.5s) -> relocate to spawn_point -> heal (+9999) -> apply debuff -> fade in (0.5s)

## Level Design (Sandbox)
DISPLAY: Viewport 640x360 (16:9 pixel-art canvas). Window override 1280x720 (2x scaling). Stretch Mode = "canvas_items", Stretch Aspect = "keep" with Default Texture Filter = "Nearest" (enables crisp pixels with smooth subpixel motion). Physics Interpolation = enabled (eliminates 60Hz physics/movement jitter for buttery smooth per-pixel translation on high refresh rate monitors). Global shortcuts: F11 or Alt+Enter toggles fullscreen via InputManager.
GRID: 32x32 tile
MAP: 60 cols x 20 rows (1920x640 px)
FLOOR: row 19 (top edge y=608)
CEILING: row 0
WALLS: col 0 (left), col 59 (right)
PLATFORMS: random at rows 16, 13, 10, 7 (4-6 platforms each, width 2-4 tiles, 1 col gap min)
ENEMIES: GrabEnemy (640,592 -> falls to floor)
ITEMS: DashUpgrade (960,592)
TILE_VISUAL: brown fill Color(0.45,0.26,0.08) + black border 1.5px
LIGHTING: CanvasModulate Color(8.0 / 255.0, 8.0 / 255.0, 8.0 / 255.0) dark overlay (brightness around 8/255). Player PointLight2D uses a 384x384 radial smoothstep texture (scale 2.5 -> 960px diameter) with smooth step fall-off. Shadows are enabled. Tiles are set to light_mask=2 and PointLight2D to range_item_cull_mask=1 to keep tiles completely unlit by the flashlight, while shadow_item_cull_mask=3 and occluder_light_mask=2 allow tiles to cast shadows.
OCCLUDERS: LightOccluder2D on MapTile with size 32x32px. occluder_light_mask = 2.
BACKGROUND: ColorRect Color(0.12, 0.08, 0.2) dark purple background canvas.
SPAWNER: Procedural spawner maintaining at least 5 alive GrabEnemies. Spawn positions are ground tiles with empty cells above, >300px distance threshold.

## Settings & Save
SAVE: user://input_config.json
BIND_DEFAULTS: move_left=A(65), move_right=D(68), jump=Space(32), dash=C(67), attack=X(88)
PAUSE: ESC toggles pause. Sets MOUSE_MODE_VISIBLE (pause) / MOUSE_MODE_CAPTURED (play)
MUTE: Toggles AudioServer bus 0
RESET: Restores defaults, overwrites JSON
STYLE: Buttons flat, hover shows StyleBoxFlat border_width_bottom=2px

## Room & Portal Transition System
PORTAL_VISUAL: 32x64px solid white rectangle (drawn dynamically in _draw()).
PORTAL_COLLISION: Area2D with CollisionShape2D matching 32x64px. Detects player on Layer 2.
PORTAL_LOCATIONS: Located at the bottom-left and bottom-right corners of the room (rows 17-18, columns 0 and 59). Wall tiles are omitted at these rows to create openings.
PERSISTENCE_TRICK (RoomManager Autoload):
- Intercepts player node on transition using `node_added` signals and deferred removal/adding.
- Removes player node from old scene before `change_scene_to_file` to prevent deletion.
- Swaps/removes newly instantiated player in the new scene with the persistent player instance.
- Re-establishes HUD signal connections cleanly without duplicate connection errors.
- Resets physics interpolation (`reset_physics_interpolation`) and camera smoothing (`reset_smoothing` with zoom 1.2 and level bounds set) to prevent visual streaking/warping upon teleport.

## Changelog

### 2026-05-25
- Adjusted PointLight2D to 384x384px smoothstep gradient with scale 2.5 (960px diameter).
- Configured MapTile with light_mask=2 and LightOccluder2D with occluder_light_mask=2 to block light and cast shadows without being illuminated by player flashlight (range_item_cull_mask=1, shadow_item_cull_mask=3).
- Implemented 3-hit combo attack variations (X key, 40x50, 40x50+70x40, 50x30 hitboxes) with visual indicators.
- Disabled player-enemy physical collisions; contact damage checked via bounding box overlaps.
- Removed GPU-based enemy shadow shroud shader (monsters now render normally under standard Godot lighting).
- Deferred CollisionShape updates on enemy death to resolve flushing queries error.
- Deferred key pickup Area2D creation on enemy death using call_deferred() to fix physics flushing query error.

### 2026-05-26
- Reduced ambient light (CanvasModulate) brightness in dark areas to 8/255 (nearly pitch-black overlay).
- Enabled 2D physics interpolation and configured canvas_items stretch mode with Nearest texture filtering to eliminate movement jitter and enable smooth subpixel movement.
- Created RoomManager autoload and RoomPortal to implement seamless room transitions without reloading/killing the player.
- Implemented a smooth quick screen fade-out and fade-in (0.15s each) during room transitions to cover the scene swap.
- Refactored player.gd using a Component-based architecture, extracting AttackComponent, DashComponent, and LightComponent to decrease code complexity.