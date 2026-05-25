# METRICS & SPECS

## Player
SPEED: 200.0
ACCEL: 1000.0
FRICTION: 1200.0 (Actor)
SIZE: Collision 32x64 | Sprite scale 0.25x0.5 (= 32x64px visual, 2 tiles tall on a 32x32px grid)
JUMP: -450.0 (~103px apex, hold to jump higher)
JUMP_STYLE: Smooth variable jump – on release velocity.y *= 0.1 if rising (min jump ~5px)
GRAVITY_UP: 980. GRAVITY_DOWN: 980*1.5=1470
HP: max=100, respawn_debuff=-20 (max HP 80). Taking damage triggers invincibility (1.0s) with a visual flashing effect (10Hz). Interrupted state: damage immediately cancels active attack or dash. Knockback: player is locked from moving and pushed away (300px/s horizontal force, -180px/s upward bounce, duration 0.3s). Configurable via Inspector exports.
DASH: 0.2s (0.18s iframe, 0.02s lerp), CD=0.8s (upgradable 0.4s). Direction locked, sprite faces dash direction, recovery lerps to 0 or same direction. Key=C
ATTACK: 0.15s duration per strike. 3-hit combo variation. Key=X. Combo reset delay=0.5s after the attack ends (reverts back to Hit 1). Locks direction/input (stops horizontal movement on ground, falls vertically in air). Hitbox shapes:
- Hit 1: 20x50px in front (blue indicator).
- Hit 2: 20x50px in front + 50x20px above head (orange/red indicators).
- Hit 3: 40x20px in front (green indicator).

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
DISPLAY: Viewport 640x360 (16:9 pixel-art canvas). Window override 1280x720 (2x integer scaling). Stretch Mode = "viewport", Stretch Aspect = "keep" (keeps pixels sharp, adds letterbox/pillarbox for non-16:9 screens). Default Texture Filter = "Nearest" (for crisp pixels). Global shortcuts: F11 or Alt+Enter toggles fullscreen via InputManager.
GRID: 32x32 tile
MAP: 60 cols x 20 rows (1920x640 px)
FLOOR: row 19 (top edge y=608)
CEILING: row 0
WALLS: col 0 (left), col 59 (right)
PLATFORMS: random at rows 16, 13, 10, 7 (4-6 platforms each, width 2-4 tiles, 1 col gap min)
ENEMIES: GrabEnemy (640,592 → falls to floor)
ITEMS: DashUpgrade (960,592)
TILE_VISUAL: brown fill Color(0.45,0.26,0.08) + black border 1.5px
LIGHTING: CanvasModulate Color(0.32, 0.25, 0.42) moderate ambient purple. Player PointLight2D uses a dynamically generated 256x256 radial dithered texture (scaled to 3.0 -> 768px diameter) with smoothstep fall-off and random noise ([-1.5/255, 1.5/255]) to prevent banding. Shadow enabled (PCF5 filter, shadow color 100% black to prevent light from shining into blocks).
OCCLUDERS: MapTile has LightOccluder2D slightly larger than tile size (33x33px square polygon) to overlap adjacent tile occluders and block light leaks completely.
BACKGROUND: ColorRect Color(0.18, 0.12, 0.28) dark purple background canvas.
SPAWNER: Procedural spawner maintaining at least 5 alive GrabEnemies. Spawn positions are ground tiles with empty cells above, >300px away from player.

## Settings & Save
SAVE: user://input_config.json
BIND_DEFAULTS: move_left=A(65), move_right=D(68), jump=Space(32), dash=C(67), attack=X(88)
PAUSE: ESC toggles pause. Sets MOUSE_MODE_VISIBLE (pause) / MOUSE_MODE_CAPTURED (play)
MUTE: Toggles AudioServer bus 0
RESET: Restores defaults, overwrites JSON
STYLE: Buttons flat, hover shows StyleBoxFlat border_width_bottom=2px

## Changelog

### 2026-05-25
- **Dynamic 2D Lighting & Shadows Reversion and Dithering**:
  - Implemented dynamic dithered noise (`randf_range(-1.5/255.0, 1.5/255.0)`) on the player's radial light texture in GDScript to break up color banding rings without blurring the environment.
  - Reverted player PointLight2D to use a 256x256 texture size, scaled to `3.0` (768px diameter on screen) for smooth GPU-filtering.
  - Set `shadow_color` to `Color(0.0, 0.0, 0.0, 1.0)` to ensure light does not shine into blocks.
  - Resized `LightOccluder2D` to `33x33px` (1px overlap) to prevent light leaks and corner "star" artifacts.
  - Configured `CanvasModulate` to `Color(0.32, 0.25, 0.42)` and background to `Color(0.18, 0.12, 0.28)` to maintain a moderate, readable ambient brightness instead of pitch-black.
- **Player Attack Variations (3-Hit Combo System)**:
  - Implemented a 3-hit combo sequence for player melee attack.
  - Hit 1: 20x50px rectangle in front of player (Blue indicator).
  - Hit 2: Dual hitbox - 20x50px in front and 50x20px above player's head (Orange/Red indicators).
  - Hit 3: 40x20px rectangle in front of player for a long-reach thrust (Green indicator).
  - Added combo chaining with `combo_reset_timer` of `0.5s` starting immediately when the last attack ends.
  - Programmatically created a second collision shape under `AttackArea` in `_ready()` to handle the dual hitbox of Hit 2.
  - Modified `_draw()` to dynamically render the active hitboxes on screen using colors corresponding to each combo hit.
- **Custom Player Damage Knockback & Invincibility**:
  - Overrode `apply_knockback()` in `player.gd` to use player-specific physics parameters rather than base actor hardcodings.
  - Added `@export` parameters to `player.gd` to configure knockback force (`300px/s`), upward bounce (`-180px/s`), lock duration (`0.3s`), and invincibility time (`1.0s`) directly via Godot Inspector.
  - Implemented an interruption system: taking damage immediately cancels any active attack (calling `end_attack()`) or dash (reverting back to `State.MOVE`).
  - Added a visual flashing effect on `Sprite2D` (modulating alpha to 0.4 at 10Hz) during the invincibility period.
  - Ensured invincibility state resolves correctly when dashing starts/ends during active invincibility.
  - Reset invincibility variables and sprite opacity to normal in `respawn()`.
- **Pixel-Art Viewport Scaling & Global Fullscreen Toggle**:
  - Configured project window stretch mode to `"viewport"` with aspect ratio `"keep"`, using a native canvas resolution of `640x360` scaled into a `1280x720` window default to preserve pixel proportions.
  - Set default canvas texture filtering to `Nearest` in project settings to guarantee pixel-art graphics stay sharp and crisp when scaled or fullscreened.
  - Added global unhandled key listeners (`F11` and `Alt+Enter`) to `input_manager.gd` (autoload singleton) to toggle window fullscreen/windowed modes globally.
- **Disabled Player-Enemy Physical Collisions**:
  - Removed Layer 3 (Enemy) from the Player's collision mask (`collision_mask = 1`) and Layer 2 (Player) from the Enemy's collision mask (`collision_mask = 1`) in `player.tscn` and `grab_enemy.tscn`.
  - Replaced the physics-based contact damage detection in `grab_enemy.gd` with a custom bounding box overlap check (`dx < 30px` and `dy < 44px`). This ensures that the player and enemy can walk through each other without getting physically blocked, while still correctly applying contact damage and triggering QTE states.
- **Shadow Shrouding for Enemies (Real-Time Vision Masks)**:
  - Created a custom CanvasItem shader `res://scenes/enemies/enemy_shadow_shroud.gdshader`.
  - The shader intercepts vertex colors in `vertex()` and caches them in a `varying vec4` variable to handle both custom node modulating and custom vector drawings in `_draw()`.
  - In `fragment()`, the base ambient color is replaced with a customizable `unlit_color` (black) and `unlit_alpha` (default `0.0` for completely hidden, but configurable to `1.0` for a solid black silhouette).
  - In `light()`, the light's `ATTENUATION` (combining distance attenuation and shadows) is used to mathematically interpolate between the dark state and the original fully lit state, producing pixel-perfect clipping at shadow borders.
  - Implemented `@export` parameters `shadow_shroud_unlit_alpha` (0.0 to 1.0) and `shadow_shroud_unlit_color` in both `grab_enemy.gd` and `static_enemy.gd`. This gives the developer full inspector access to customize the darkness style (invisible vs silhouette).
