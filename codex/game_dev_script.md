# METRICS & SPECS

## Player
SPEED: 200.0
ACCEL: 1000.0
FRICTION: 1200.0 (Actor)
SIZE: Collision 48x120 | Sprite scale 0.5x1.0 (= 64x128px visual, 2 tiles tall)
JUMP_MAX: -657.0  (apex 220px = 3.4 tiles, hold full duration)
JUMP_CUT: -501.0  (apex 128px = 2 tiles, release early)
JUMP_STYLE: Hollow Knight variable – on press give JUMP_MAX; if !held && velocity.y < JUMP_CUT, clamp to JUMP_CUT
GRAVITY_UP: 980. GRAVITY_DOWN: 980*1.5=1470
HP: max=100, respawn_debuff=-20 (max HP 80)
DASH: 0.2s (0.18s iframe, 0.02s lerp), CD=0.8s (upgradable 0.4s). Key=C
ATTACK: 0.1s, Hitbox 50x10 Area2D offset 20px front. Blue rect indicator. Key=X

## Upgrade Item
TYPE: Dash CD Halver (Green Circle)
POS: (800, 464)
FUNC: player.upgrade_dash_cooldown() -> CD = 0.4s. queue_free()

## Defeated & QTE Flow
TRIGGER: Player HP <= 0 OR Enemy grab
STATE: GRABBED (locks input) -> QTE UI (Space/E spam)
SUCCESS: pushback, heal minor, resume play
FAILURE: DEFEATED state -> fade out (0.5s) -> relocate to spawn_point -> heal (+9999) -> apply debuff -> fade in (0.5s)

## Level Design (Sandbox)
GRID: 64x64 tile
MAP: 20 cols x 13 rows (1280x832 px)
FLOOR: row 12 (top edge y=768)
CEILING: row 0
WALLS: col 0 (left), col 19 (right)
PLATFORMS: random at rows 9, 6, 3 (2-3 platforms each, width 2-4 tiles, 1 col gap min)
ENEMIES: StaticEnemy (384,752), GrabEnemy (640,700 → falls to floor)
ITEMS: DashUpgrade (960,752)
TILE_VISUAL: brown fill Color(0.45,0.26,0.08) + black border 1.5px

## Settings & Save
SAVE: user://input_config.json
BIND_DEFAULTS: move_left=A(65), move_right=D(68), jump=Space(32), dash=C(67), attack=X(88)
PAUSE: ESC toggles pause. Sets MOUSE_MODE_VISIBLE (pause) / MOUSE_MODE_CAPTURED (play)
MUTE: Toggles AudioServer bus 0
RESET: Restores defaults, overwrites JSON
STYLE: Buttons flat, hover shows StyleBoxFlat border_width_bottom=2px
