# METRICS & SPECS

## Player
SPEED: 200.0
ACCEL: 1000.0
FRICTION: 1200.0 (Actor)
JUMP: -380.0
GRAVITY: 980 * 1.5
HP: max=100, respawn_debuff=-20 (max HP 80)
DASH: 0.2s duration (0.18s active & is_invincible=true, 0.02s recovery with velocity lerp). CD=0.8s (upgradable to 0.4s). Key=C
ATTACK: 0.1s duration. Hitbox 50x10 Area2D, offset 20px front (X center = +/-45px relative to Player). Blue rect indicator. Key=X

## Upgrade Item
TYPE: Dash CD Halver (Green Circle)
POS: (800, 464)
FUNC: player.upgrade_dash_cooldown() -> CD = 0.4s. queue_free()

## Defeated & QTE Flow
TRIGGER: Player HP <= 0 OR Enemy grab
STATE: GRABBED (locks input) -> QTE UI (Space/E spam)
SUCCESS: pushback, heal minor, resume play
FAILURE: DEFEATED state -> fade out (0.5s) -> relocate to spawn_point -> heal (+9999) -> apply debuff -> fade in (0.5s)

## Level Design
FLOOR: 1200x40 at Y=500
RED_BEAN (Static Enemy): POS (400, 464). Contact damage 15. Logs hit.
GRAB_PATROL (Patrol Enemy): raycast wall/cliff check, turns back. Contact damage, logs hit.

## Settings & Save
SAVE: user://input_config.json
BIND_DEFAULTS: move_left=A(65), move_right=D(68), jump=Space(32), dash=C(67), attack=X(88)
PAUSE: ESC toggles pause. Sets MOUSE_MODE_VISIBLE (pause) / MOUSE_MODE_CAPTURED (play)
MUTE: Toggles AudioServer bus 0
RESET: Restores defaults, overwrites JSON
STYLE: Buttons flat, hover shows StyleBoxFlat border_width_bottom=2px
