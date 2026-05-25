# ERR_LOG

ERR: Git command failed
CAUSE: Git not in PATH
FIX: Use "C:\Program Files\Git\cmd\git.exe"

ERR: Player respawns with 0 HP
CAUSE: apply_debuff() ran before HP restoration, setting min(0, max_health_debuffed)
FIX: Set current_health = max_health before applying debuff

ERR: GDScript "Only identifier, attribute access, and subscription access can be used as assignment target" in settingsmenu.gd
CAUSE: Path-style property assignment "node.theme_override_colors/color = val" invalid in GDScript
FIX: Use "node.add_theme_color_override('color', val)"

ERR: Undefined identifier "friction" in grab_enemy.gd
CAUSE: friction defined only in player.gd, but needed by enemy
FIX: Move friction to base Actor class: "@export var friction: float = 1200.0"
