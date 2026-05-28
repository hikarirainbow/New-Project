class_name CameraComponent
extends Node

# Settings
@export var default_camera_zoom: Vector2 = Vector2(2.4, 2.4)
@export var camera_look_pan_distance: float = 200.0
@export var camera_look_pan_speed: float = 5.0

var camera_look_offset_y: float = 0.0
var camera_shake_timer: float = 0.0
var camera_shake_intensity: float = 0.0

@onready var player: Player = get_parent() as Player
@onready var camera: Camera2D = null

func _ready() -> void:
	# Locate Camera2D on player on next frame to ensure player node hierarchy is fully initialized
	await get_tree().process_frame
	if is_instance_valid(player):
		camera = player.get_node_or_null("Camera2D")
		if camera:
			camera.zoom = default_camera_zoom

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
		
	# Smoothly lerp camera zoom based on active H-scene
	var target_zoom = default_camera_zoom
	if player.is_h_scene_active():
		target_zoom = Vector2(5.0, 5.0)
	camera.zoom = camera.zoom.lerp(target_zoom, 5.0 * delta)
	
	# Panning look offset
	var target_offset_y = 0.0
	if player.current_state == Player.State.MOVE:
		if player.attack_component and not player.attack_component.is_attacking():
			if Input.is_action_pressed("look_up"):
				target_offset_y -= camera_look_pan_distance
			if Input.is_action_pressed("look_down"):
				target_offset_y += camera_look_pan_distance
				
	camera_look_offset_y = lerp(camera_look_offset_y, target_offset_y, camera_look_pan_speed * delta)
	
	# Apply eruption screen shake offset if active (3-phase envelope: 0.2s ramp-up, 0.4s peak, 0.2s decay)
	if camera_shake_timer > 0.0:
		camera_shake_timer -= delta
		var elapsed = 0.8 - camera_shake_timer
		var multiplier = 0.0
		if elapsed < 0.2:
			multiplier = elapsed / 0.2
		elif elapsed < 0.6:
			multiplier = 1.0
		elif elapsed < 0.8:
			multiplier = (0.8 - elapsed) / 0.2
		else:
			multiplier = 0.0
			
		var current_intensity = camera_shake_intensity * multiplier
		var shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		camera.offset = Vector2(shake_offset.x, camera_look_offset_y + shake_offset.y)
	else:
		camera.offset = Vector2(camera.offset.x, camera_look_offset_y)

func shake_camera(direction_x: float, intensity: float = 8.0, duration: float = 0.15) -> void:
	if camera:
		camera.offset.x = -direction_x * intensity
		var tween = player.create_tween().set_ignore_time_scale(true)
		tween.tween_property(camera, "offset:x", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func start_eruption_shake(intensity: float = 8.0, duration: float = 0.8) -> void:
	camera_shake_timer = duration
	camera_shake_intensity = intensity
