extends CanvasLayer

@onready var label: Label = $Label

# Biến cấu hình FPS
@export var target_fps: int = 60

func _ready() -> void:
	# Cài đặt giới hạn FPS cho Engine
	Engine.max_fps = target_fps
	# Đảm bảo VSync hoạt động theo ý muốn (Ở đây dùng mặc định của Project Settings)
	pass

func _process(delta: float) -> void:
	# Lấy thông số thời gian thực
	var fps = Engine.get_frames_per_second()
	var ups = Engine.physics_ticks_per_second # Mặc định là 60
	
	# Tính toán frame time (ms) để xem độ trễ
	var frame_time = delta * 1000.0
	
	# Cập nhật nhãn
	label.text = "FPS: %d\nUPS: %d\nFrame Time: %.2f ms" % [fps, ups, frame_time]
	
	# Logic màu sắc: Nếu FPS thấp quá thì chuyển màu đỏ
	if fps < target_fps * 0.8:
		label.modulate = Color.RED
	else:
		label.modulate = Color.GREEN
