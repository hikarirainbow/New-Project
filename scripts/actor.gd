class_name Actor
extends CharacterBody2D

# Các thuộc tính chung của sinh vật (Player & Kẻ địch di chuyển)
@export var max_health: int = 100
@onready var current_health: int = max_health

# Trọng lực mặc định của dự án
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Trạng thái bị đẩy lùi (Knockback)
var knockback_timer: float = 0.0

# Lực ma sát giảm tốc khi dừng/bị đẩy lùi
@export var friction: float = 1200.0

# Các tín hiệu chung
signal health_changed(new_health)
signal actor_died

# Hàm nhận sát thương dùng chung
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO):
	if current_health <= 0:
		return
		
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health)
	
	# Nếu có vị trí nguồn sát thương và sinh vật chưa chết, áp dụng giật lùi
	if source_position != Vector2.ZERO and current_health > 0:
		apply_knockback(source_position)
		
	if current_health <= 0:
		die()

# Hàm áp dụng lực đẩy lùi dùng chung
func apply_knockback(source_position: Vector2, force: float = 250.0):
	# Tính hướng đẩy ngược lại nguồn gây sát thương
	var direction = (global_position - source_position).normalized()
	if abs(direction.x) < 0.1:
		direction.x = 1.0 if randf() > 0.5 else -1.0
	velocity.x = direction.x * force
	velocity.y = -180.0 # Nảy nhẹ lên trời
	knockback_timer = 0.25 # Khóa phím/logic di chuyển trong 0.25 giây

# Hàm xử lý khi chết (sẽ được ghi đè ở class con)
func die():
	emit_signal("actor_died")
