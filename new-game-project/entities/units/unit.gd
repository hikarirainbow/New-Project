extends CharacterBody2D
class_name Unit

# --- CONFIGURATION ---
@export_category("Physics Stats")
@export var move_speed: float = 150.0 
@export var gravity_scale: float = 1.0
@export var friction: float = 2000.0
@export var jump_force: float = 300.0

# --- INTERNAL VARIABLES ---
var default_gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_path: PackedVector2Array = []
var current_target_point: Vector2

# --- NODES ---
@onready var internal_camera: Camera2D = $Camera2D if has_node("Camera2D") else null

func _ready() -> void:
	if internal_camera:
		internal_camera.enabled = false
		internal_camera.queue_free()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	
	if not current_path.is_empty():
		follow_path(delta)
	else:
		apply_friction(delta)
	
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += default_gravity * gravity_scale * delta

func apply_friction(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func set_path(path: PackedVector2Array) -> void:
	current_path = path
	if not current_path.is_empty():
		current_target_point = current_path[0]

func follow_path(delta: float) -> void:
	if current_path.is_empty(): return
	
	# Logic đơn giản: Đi tới điểm tiếp theo
	var target = current_path[0]
	var diff_x = target.x - global_position.x
	
	# Di chuyển ngang
	if abs(diff_x) > 5.0:
		velocity.x = move_toward(velocity.x, sign(diff_x) * move_speed, friction * delta)
	else:
		# Đã đến gần điểm X, kiểm tra Y
		# Nếu điểm tiếp theo cao hơn -> Nhảy
		if target.y < global_position.y - 10.0 and is_on_floor():
			velocity.y = -jump_force
			
		# Xóa điểm này, đi tiếp điểm sau
		if global_position.distance_to(target) < 20.0: # Bán kính chấp nhận
			current_path.remove_at(0)
			if current_path.is_empty():
				velocity.x = 0