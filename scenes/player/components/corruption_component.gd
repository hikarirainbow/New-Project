class_name PlayerCorruptionComponent
extends Node2D

# Real-time change signal for HUD and visual effects
signal sanity_changed(current_sanity: float)

@onready var player: Player = get_parent()

# Core tracking variables (0.0 = fully corrupted, 100.0 = fully sanctified)
var sanity: float = 100.0
var corruption: float = 0.0

var _last_state: Player.State = Player.State.MOVE

func _ready() -> void:
	# Register component with parent player reference
	player.set("corruption_component", self)
	_last_state = player.current_state
	emit_signal("sanity_changed", sanity)

func _physics_process(delta: float) -> void:
	# 1. State transition monitoring (instantaneous single-frame checks)
	if player.current_state == Player.State.GRABBED and _last_state != Player.State.GRABBED:
		# Transition to Subjugated state: instantly lose -15.0 sanity
		subtract_sanity(15.0)

	elif player.current_state == Player.State.MOVE and _last_state == Player.State.GRABBED:
		# Successful QTE struggle escape: recover +10.0 sanity
		add_sanity(10.0)

	elif player.current_state == Player.State.DEFEATED and _last_state == Player.State.GRABBED:
		# Failed struggle / defeated by quai: lose -30.0 sanity
		subtract_sanity(30.0)

	# Update cached state
	_last_state = player.current_state

	# 2. Continuous time-based polling (framerate independent decay/recovery)
	if player.current_state == Player.State.DASH:
		# Dash cost: 5.0 sanity total over 0.2s duration -> 25.0 / sec
		subtract_sanity(delta * 25.0)

	elif player.attack_component and player.attack_component.is_attacking():
		# Melee attack costs: 2.0 / 3.0 / 5.0 total over 0.15s duration
		var cost_per_sec = 13.33
		match player.attack_component.current_combo_index:
			0: cost_per_sec = 13.33   # 2.0 / 0.15
			1: cost_per_sec = 20.0    # 3.0 / 0.15
			2: cost_per_sec = 33.33   # 5.0 / 0.15
		subtract_sanity(delta * cost_per_sec)

	elif player.current_state == Player.State.MOVE:
		# Passive recovery when idle/walking: +1.0 sanity / sec
		add_sanity(delta * 1.0)

# Helper to safely decrease sanity
func subtract_sanity(amount: float) -> void:
	if amount <= 0.0 or player.current_state == Player.State.DEFEATED:
		return
	sanity = max(0.0, sanity - amount)
	corruption = 100.0 - sanity
	emit_signal("sanity_changed", sanity)

# Helper to safely increase sanity
func add_sanity(amount: float) -> void:
	if amount <= 0.0 or player.current_state == Player.State.DEFEATED:
		return
	sanity = min(100.0, sanity + amount)
	corruption = 100.0 - sanity
	emit_signal("sanity_changed", sanity)

# Shrines/items recovery helper
func purify(amount: float) -> void:
	add_sanity(amount)

# Public combat multipliers:
# Sát thương gây ra (Attack multiplier): tăng tuyến tính lên tới 2.0x khi corruption chạm 100%
func get_attack_multiplier() -> float:
	return 1.0 + (corruption / 100.0) * 1.0

# Sát thương nhận vào (Defense multiplier): tăng tuyến tính lên tới 1.5x khi corruption chạm 100%
func get_defense_multiplier() -> float:
	return 1.0 + (corruption / 100.0) * 0.5

# Hệ số trừ thanh QTE trong trạng thái Subjugated
# 0% corruption -> 2x decay (default)
# 50% corruption -> 2.5x decay
# 100% corruption -> 3x decay
func get_qte_decay_multiplier() -> float:
	return 2.0 + (corruption / 100.0) * 1.0
