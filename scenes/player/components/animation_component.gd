class_name PlayerAnimationComponent
extends Node2D

# Animation name constants for safety and readability
const ANIM_IDLE       = "idle"
const ANIM_RUN        = "run"
const ANIM_JUMP_RISE  = "jump_rise"
const ANIM_JUMP_FALL  = "jump_fall"
const ANIM_LAND       = "land"
const ANIM_TURN       = "turn"
const ANIM_DASH       = "dash"
const ANIM_ATTACK_1   = "attack_1"
const ANIM_ATTACK_2   = "attack_2"
const ANIM_ATTACK_3   = "attack_3"
const ANIM_CLIMB_RISE = "climb_rise"
const ANIM_CLIMB_STEP = "climb_step"
const ANIM_GRABBED    = "grabbed"
const ANIM_HURT       = "hurt"
const ANIM_DEFEATED   = "defeated"

# Decoupled component references
@onready var player: Player = get_parent()
@onready var anim_player: AnimationPlayer = player.get_node_or_null("AnimationPlayer")

# Internal state tracking for transient transitions
var _current_anim: String = ""
var _was_on_floor: bool = true
var _last_facing_dir: int = 1 # 1 = right, -1 = left

# Timers for lock buffers to prevent transient animations from being instantly cut off
var _land_lock_timer: float = 0.0
var _turn_lock_timer: float = 0.0

const LAND_LOCK_DURATION = 0.12
const TURN_LOCK_DURATION = 0.10

func _ready() -> void:
	if not anim_player:
		push_warning("AnimationComponent: No AnimationPlayer found on parent. Running in headless/silent mode.")
	
	# Detect initial facing direction from Sprite2D's flip status
	if player.has_node("Sprite2D"):
		_last_facing_dir = -1 if player.get_node("Sprite2D").flip_h else 1
	_was_on_floor = player.is_on_floor()

func _physics_process(delta: float) -> void:
	# Tick lock timers down
	if _land_lock_timer > 0.0:
		_land_lock_timer -= delta
	if _turn_lock_timer > 0.0:
		_turn_lock_timer -= delta

	# 1. Evaluate the prioritized animation tree to find the target state
	var target_anim = _evaluate_animation_tree()

	# 2. Play the selected animation if it has changed
	_play_animation(target_anim)

	# 3. Update persistent flags at the end of the frame
	_was_on_floor = player.is_on_floor()
	if player.has_node("Sprite2D"):
		var current_facing = -1 if player.get_node("Sprite2D").flip_h else 1
		if current_facing != _last_facing_dir:
			_last_facing_dir = current_facing

# Evaluation tree with strict priority hierarchy (extensible/open structure)
func _evaluate_animation_tree() -> String:
	# Priority 1: Defeated State
	if player.current_state == Player.State.DEFEATED:
		return ANIM_DEFEATED

	# Priority 2: Hurt / Damage Knockback State
	if player.knockback_timer > 0.0:
		return ANIM_HURT

	# Priority 3: Grabbed (QTE) State
	if player.current_state == Player.State.GRABBED:
		return ANIM_GRABBED

	# Priority 4: Dash State
	if player.current_state == Player.State.DASH:
		return ANIM_DASH

	# Priority 5: Climb Ledge State (split into rise/step phases)
	if player.current_state == Player.State.CLIMB:
		if player.climb_component:
			var ratio = player.climb_component.climb_timer / ClimbComponent.CLIMB_DURATION
			return ANIM_CLIMB_RISE if ratio < 0.5 else ANIM_CLIMB_STEP
		return ANIM_CLIMB_RISE

	# Priority 6: Attack State (mapped to 3-hit combo sequence)
	if player.attack_component and player.attack_component.is_attacking():
		match player.attack_component.current_combo_index:
			0: return ANIM_ATTACK_1
			1: return ANIM_ATTACK_2
			2: return ANIM_ATTACK_3
		return ANIM_ATTACK_1

	# Priority 7: Free Movement (MOVE State)
	if player.current_state == Player.State.MOVE:
		var input_dir = Input.get_axis("move_left", "move_right")
		var is_on_floor = player.is_on_floor()

		# A. Grounded animations
		if is_on_floor:
			# Handle landing event (transition from airborne to ground)
			if not _was_on_floor:
				_land_lock_timer = LAND_LOCK_DURATION
				_turn_lock_timer = 0.0 # Clear turning lock on land
				return ANIM_LAND

			# Keep playing land lock animation if it hasn't expired yet
			if _land_lock_timer > 0.0:
				# If player starts running or jumps, interrupt landing early
				if input_dir != 0.0 or Input.is_action_just_pressed("jump"):
					_land_lock_timer = 0.0
				else:
					return ANIM_LAND

			# Handle turning event (sudden direction swap on ground)
			if input_dir != 0.0:
				var current_facing = -1 if input_dir < 0.0 else 1
				if current_facing != _last_facing_dir and abs(player.velocity.x) > 50.0:
					_turn_lock_timer = TURN_LOCK_DURATION
					return ANIM_TURN

			# Keep playing turn lock animation if it hasn't expired yet
			if _turn_lock_timer > 0.0:
				if input_dir == 0.0:
					_turn_lock_timer = 0.0
				else:
					return ANIM_TURN

			# Default ground states: Run vs Idle
			if input_dir != 0.0 or abs(player.velocity.x) > 10.0:
				return ANIM_RUN
			else:
				return ANIM_IDLE

		# B. Airborne animations
		else:
			# Interrupt landing locks if we suddenly become airborne again
			_land_lock_timer = 0.0
			_turn_lock_timer = 0.0

			if player.velocity.y < 0.0:
				return ANIM_JUMP_RISE
			else:
				return ANIM_JUMP_FALL

	# Safe fallback
	return ANIM_IDLE

# Safe animation playback wrapper
func _play_animation(anim_name: String) -> void:
	if _current_anim == anim_name:
		return

	_current_anim = anim_name

	if not anim_player:
		return

	# Only play if the animation exists in the AnimationPlayer to prevent errors/warnings
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	else:
		# Log missing animations silently without disrupting flow
		print_verbose("AnimationComponent: Animation player is missing track for: ", anim_name)
