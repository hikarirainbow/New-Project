# METRICS & SPECS

## Player
SPEED: 200.0
ACCEL: 1000.0
FRICTION: 1200.0 (Actor)
SIZE: Collision 32x64 | Sprite scale 0.25x0.5 (= 32x64px visual, 2 tiles tall on a 32x32px grid)
JUMP: -450.0 (~103px apex, hold to jump higher)
JUMP_STYLE: Smooth variable jump – on release velocity.y *= 0.1 if rising (min jump ~5px)
GRAVITY_UP: 980. GRAVITY_DOWN: 980*1.5=1470
HP: max=100, respawn_debuff=-20 (max HP 80)
DASH: 0.2s (0.18s iframe, 0.02s lerp), CD=0.8s (upgradable 0.4s). Direction locked, sprite faces dash direction, recovery lerps to 0 or same direction. Key=C
ATTACK: 0.1s, Hitbox 50x10 Area2D offset 20px front (detects Body2D). Blue rect indicator. Locked direction/input; stops horizontal movement on ground, continues vertical falling in air. Key=X

## Upgrade Item
TYPE: Dash CD Halver (Green Circle)
POS: (960, 592)
FUNC: player.upgrade_dash_cooldown() -> CD = 0.4s. queue_free()

## Defeated & QTE Flow
TRIGGER: Player HP <= 0 OR Enemy grab
STATE: GRABBED (locks input) -> QTE UI (Space/E spam)
SUCCESS: pushback, heal minor, resume play
FAILURE: DEFEATED state -> fade out (0.5s) -> relocate to spawn_point -> heal (+9999) -> apply debuff -> fade in (0.5s)

## Level Design (Sandbox)
GRID: 32x32 tile
MAP: 60 cols x 20 rows (1920x640 px)
FLOOR: row 19 (top edge y=608)
CEILING: row 0
WALLS: col 0 (left), col 59 (right)
PLATFORMS: random at rows 16, 13, 10, 7 (4-6 platforms each, width 2-4 tiles, 1 col gap min)
ENEMIES: GrabEnemy (640,592 → falls to floor)
ITEMS: DashUpgrade (960,592)
TILE_VISUAL: brown fill Color(0.45,0.26,0.08) + black border 1.5px

## Settings & Save
SAVE: user://input_config.json
BIND_DEFAULTS: move_left=A(65), move_right=D(68), jump=Space(32), dash=C(67), attack=X(88)
PAUSE: ESC toggles pause. Sets MOUSE_MODE_VISIBLE (pause) / MOUSE_MODE_CAPTURED (play)
MUTE: Toggles AudioServer bus 0
RESET: Restores defaults, overwrites JSON
STYLE: Buttons flat, hover shows StyleBoxFlat border_width_bottom=2px
