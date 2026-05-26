class_name PlayerCorruptionComponent
extends Node2D

# Real-time change signal for HUD and visual effects
signal sanity_changed(current_sanity: float)

@export_group("Sanity Constants")
@export var max_sanity: float = 100.0
@export var sanity_loss_on_grab: float = 60.0
@export var sanity_loss_on_defeat: float = 60.0
@export var sanity_gain_on_escape: float = 10.0

@export_group("Passive Regeneration")
@export var base_regen_rate: float = 5.0
@export var upgraded_regen_rate: float = 10.0 # Skill J

@export_group("Skill Modifiers")
@export var skill_l_sanity_damage_reduction: float = 0.7 # Reflects 30% reduction (multiply by 0.7)
@export var base_attack_bonus_multiplier: float = 1.0
@export var skill_g_attack_bonus_multiplier: float = 1.5
@export var base_defense_penalty_multiplier: float = 0.5
@export var skill_l_defense_penalty_multiplier: float = 0.25
@export var base_qte_decay_multiplier: float = 2.0
@export var qte_decay_scaling_factor: float = 1.0

@onready var player: Player = get_parent()

# Core tracking variables (0.0 = fully corrupted, max_sanity = fully sanctified)
var sanity: float = 100.0
var corruption: float = 0.0

var _last_state: Player.State = Player.State.MOVE

func _ready() -> void:
	# Register component with parent player reference
	player.set("corruption_component", self)
	_last_state = player.current_state
	sanity = max_sanity
	corruption = 0.0
	sanity_changed.emit(sanity)

func _physics_process(delta: float) -> void:
	# 1. State transition monitoring (instantaneous single-frame checks)
	if player.current_state == Player.State.GRABBED and _last_state != Player.State.GRABBED:
		subtract_sanity(sanity_loss_on_grab)

	elif player.current_state == Player.State.MOVE and _last_state == Player.State.GRABBED:
		add_sanity(sanity_gain_on_escape)

	elif player.current_state == Player.State.DEFEATED and _last_state == Player.State.GRABBED:
		subtract_sanity(sanity_loss_on_defeat)

	# Update cached state
	_last_state = player.current_state

	# 2. Continuous time-based polling (framerate independent decay/recovery)
	if player.current_state == Player.State.MOVE:
		var regen_rate := base_regen_rate
		if player.skill_component and player.skill_component.is_skill_unlocked("J"):
			regen_rate = upgraded_regen_rate
		add_sanity(delta * regen_rate)

# Helper to safely decrease sanity
func subtract_sanity(amount: float) -> void:
	if amount <= 0.0 or player.current_state == Player.State.DEFEATED:
		return
	var actual_amount := amount
	if player.skill_component and player.skill_component.is_skill_unlocked("L"):
		actual_amount = amount * skill_l_sanity_damage_reduction
	sanity = max(0.0, sanity - actual_amount)
	corruption = max_sanity - sanity
	sanity_changed.emit(sanity)

# Helper to safely increase sanity
func add_sanity(amount: float) -> void:
	if amount <= 0.0 or player.current_state == Player.State.DEFEATED:
		return
	sanity = min(max_sanity, sanity + amount)
	corruption = max_sanity - sanity
	sanity_changed.emit(sanity)

# Shrines/items recovery helper
func purify(amount: float) -> void:
	add_sanity(amount)

# Public combat multipliers:
func get_attack_multiplier() -> float:
	var bonus := base_attack_bonus_multiplier
	if player.skill_component and player.skill_component.is_skill_unlocked("G"):
		bonus = skill_g_attack_bonus_multiplier
	return 1.0 + (corruption / max_sanity) * bonus

func get_defense_multiplier() -> float:
	var penalty := base_defense_penalty_multiplier
	if player.skill_component and player.skill_component.is_skill_unlocked("L"):
		penalty = skill_l_defense_penalty_multiplier
	return 1.0 + (corruption / max_sanity) * penalty

func get_qte_decay_multiplier() -> float:
	return base_qte_decay_multiplier + (corruption / max_sanity) * qte_decay_scaling_factor
