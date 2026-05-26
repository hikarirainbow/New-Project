extends CanvasLayer

@onready var control_node = $Control
@onready var panel_node = $Control/Panel
@onready var map_button = $Control/Panel/MarginContainer/VBoxContainer/TabHeader/MapButton
@onready var items_button = $Control/Panel/MarginContainer/VBoxContainer/TabHeader/ItemsButton
@onready var map_page = $Control/Panel/MarginContainer/VBoxContainer/ContentContainer/MapPage
@onready var items_page = $Control/Panel/MarginContainer/VBoxContainer/ContentContainer/ItemsPage

# Dynamically created nodes for Skill Tree
var skills_button: Button = null
var skills_page: Control = null
var sp_label: Label = null
var desc_label: Label = null
var blackout_overlay: ColorRect = null

var is_open = false
var active_tab = 0 # 0 = Map, 1 = Items, 2 = Skills

var player_ref: Player = null
var skill_buttons: Dictionary = {}

const SKILL_DESCS = {
	"A": "[A] CƯỜNG LỰC:\n+50% Sát thương đòn đánh cận chiến.",
	"B": "[B] THẢO PHẠT:\nĐòn chém nhanh hơn (0.1s) & Reset combo lẹ hơn.",
	"C": "[C] BẠO KÍCH:\n20% cơ hội đòn chém gây gấp đôi sát thương.",
	"D": "[D] TẬT PHONG:\nLướt nhanh hơn và xa hơn 40%.",
	"E": "[E] HUYỄN ẢNH:\nCó thể lướt thêm một lần nữa trước khi tiếp đất.",
	"F": "[F] KHÔNG BỘ:\nCho phép nhảy hai bước liên tục (Nhảy đúp).",
	"G": "[G] MA BẢN:\nTha hóa tối đa cộng thêm tới 2.5x sát thương chém.",
	"H": "[H] HỒN LINH:\nTăng 50% tiến độ mút phím thoát QTE quái bắt giữ.",
	"I": "[I] PHẢN PHẠT:\nPhản 30% sát thương nhận vào cho các quái vật ở gần.",
	"J": "[J] TĨNH TÂM:\nTăng gấp đôi tốc độ hồi phục Sanity thụ động ngoài QTE.",
	"K": "[K] QUANG HUY:\nTăng 50% bán kính ánh sáng soi quanh người chơi.",
	"L": "[L] PHÒNG HỘ:\nGiảm 30% sát thương tinh thần và bớt sát thương nhận."
}

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	control_node.visible = false
	
	# Fetch player reference
	await get_tree().process_frame
	player_ref = get_tree().get_first_node_in_group("player") as Player
	
	# Connect existing tab buttons
	map_button.pressed.connect(func(): switch_tab(0))
	items_button.pressed.connect(func(): switch_tab(1))
	
	# Build the Skills page dynamically
	_build_skills_ui()
	
	_setup_styles()
	switch_tab(0)

func _build_skills_ui():
	var tab_header = $Control/Panel/MarginContainer/VBoxContainer/TabHeader
	var content_container = $Control/Panel/MarginContainer/VBoxContainer/ContentContainer
	
	# 1. Create Skills tab button
	skills_button = Button.new()
	skills_button.text = "CÂY KỸ NĂNG"
	skills_button.flat = true
	tab_header.add_child(skills_button)
	skills_button.pressed.connect(func(): switch_tab(2))
	
	# 2. Create Skills Page node
	var skills_page_script = load("res://scenes/ui/skills_page.gd")
	skills_page = Control.new()
	skills_page.name = "SkillsPage"
	skills_page.visible = false
	skills_page.layout_mode = 1
	skills_page.anchors_preset = Control.PRESET_FULL_RECT
	skills_page.set_script(skills_page_script)
	skills_page.inventory = self
	content_container.add_child(skills_page)
	
	# 3. Create labels
	desc_label = Label.new()
	desc_label.text = "DẤN THÂN VÀO HÀNH TRÌNH UNLOCK KỸ NĂNG..."
	desc_label.position = Vector2(10, 5)
	desc_label.custom_minimum_size = Vector2(300, 20)
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	skills_page.add_child(desc_label)
	
	sp_label = Label.new()
	sp_label.text = "SP: 5"
	sp_label.position = Vector2(320, 5)
	sp_label.custom_minimum_size = Vector2(150, 20)
	sp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sp_label.add_theme_font_size_override("font_size", 10)
	sp_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	skills_page.add_child(sp_label)
	
	# 4. Instantiate 12 skill buttons A to L
	# Spacing configurations: 4 branches starting from bottom
	var cols = [
		["A", "B", "C"], # Col 0: Combat
		["D", "E", "F"], # Col 1: Agility
		["G", "H", "I"], # Col 2: Corruption
		["J", "K", "L"]  # Col 3: Sanity
	]
	
	for col_idx in range(4):
		var col_x = 35 + col_idx * 115
		var branch_skills = cols[col_idx]
		
		for tier_idx in range(3):
			var skill_id = branch_skills[tier_idx]
			var tier_y = 135 - tier_idx * 52 # Bottom-up placement
			
			var btn = Button.new()
			btn.text = skill_id
			btn.custom_minimum_size = Vector2(32, 32)
			btn.position = Vector2(col_x, tier_y)
			btn.focus_mode = Control.FOCUS_ALL
			
			# Setup style placeholders
			btn.add_theme_font_size_override("font_size", 11)
			
			# Connect actions
			btn.pressed.connect(func(): _on_skill_pressed(skill_id))
			btn.mouse_entered.connect(func(): _show_skill_desc(skill_id))
			btn.focus_entered.connect(func(): _show_skill_desc(skill_id))
			
			skills_page.add_child(btn)
			skill_buttons[skill_id] = btn
			
	# 5. Create Blackout Overlay (covering skills_page when player is away from checkpoint)
	blackout_overlay = ColorRect.new()
	blackout_overlay.name = "BlackoutOverlay"
	blackout_overlay.color = Color(0.02, 0.02, 0.03, 0.88)
	blackout_overlay.layout_mode = 1
	blackout_overlay.anchors_preset = Control.PRESET_FULL_RECT
	skills_page.add_child(blackout_overlay)
	
	var overlay_label = Label.new()
	overlay_label.text = "[ HỆ THỐNG KỸ NĂNG BỊ KHÓA ]\nHÃY TÌM VÀ NGHỈ NGƠI TẠI CHECKPOINT (PHÍM E)\nĐỂ CÓ THỂ UNLOCK KỸ NĂNG"
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.add_theme_font_size_override("font_size", 11)
	overlay_label.add_theme_color_override("font_color", Color(0.85, 0.35, 0.35))
	overlay_label.layout_mode = 1
	overlay_label.anchors_preset = Control.PRESET_FULL_RECT
	blackout_overlay.add_child(overlay_label)

func _input(event):
	if Input.is_action_just_pressed("jump") and is_open:
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_just_pressed("inventory"):
		var settings = get_tree().current_scene.get_node_or_null("SettingsMenu")
		if settings and settings.is_open:
			return
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
		
	if Input.is_action_just_pressed("ui_cancel") and is_open:
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
		
	if is_open:
		if Input.is_action_just_pressed("move_left"):
			switch_tab((active_tab - 1 + 3) % 3)
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("move_right"):
			switch_tab((active_tab + 1) % 3)
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("attack") and active_tab != 2:
			var active_btn = map_button if active_tab == 0 else items_button
			active_btn.pressed.emit()
			get_viewport().set_input_as_handled()

func toggle_inventory():
	is_open = !is_open
	control_node.visible = is_open
	get_tree().paused = is_open
	
	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		panel_node.scale = Vector2(0.95, 0.95)
		panel_node.pivot_offset = panel_node.size * 0.5
		var tween = create_tween()
		tween.tween_property(panel_node, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		update_skill_tree_ui()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func switch_tab(tab_index: int):
	active_tab = tab_index
	map_page.visible = (tab_index == 0)
	items_page.visible = (tab_index == 1)
	skills_page.visible = (tab_index == 2)
	
	_update_tab_headers()
	update_skill_tree_ui()
	
	# Manage focus on opening Skill Tree
	if tab_index == 2 and not blackout_overlay.visible:
		if skill_buttons.has("A") and is_instance_valid(skill_buttons["A"]):
			skill_buttons["A"].grab_focus()

func _update_tab_headers():
	var style_active = StyleBoxFlat.new()
	style_active.bg_color = Color(0, 0, 0, 0)
	style_active.border_width_bottom = 2
	style_active.border_color = Color(1.0, 1.0, 1.0, 0.9)
	
	var style_inactive = StyleBoxFlat.new()
	style_inactive.bg_color = Color(0, 0, 0, 0)
	
	map_button.add_theme_stylebox_override("normal", style_active if active_tab == 0 else style_inactive)
	items_button.add_theme_stylebox_override("normal", style_active if active_tab == 1 else style_inactive)
	if skills_button:
		skills_button.add_theme_stylebox_override("normal", style_active if active_tab == 2 else style_inactive)
	
	map_button.add_theme_color_override("font_color", Color(1, 1, 1) if active_tab == 0 else Color(0.6, 0.6, 0.6))
	items_button.add_theme_color_override("font_color", Color(1, 1, 1) if active_tab == 1 else Color(0.6, 0.6, 0.6))
	if skills_button:
		skills_button.add_theme_color_override("font_color", Color(1, 1, 1) if active_tab == 2 else Color(0.6, 0.6, 0.6))

func _on_skill_pressed(skill_id: String) -> void:
	if not player_ref or not player_ref.has_node("SkillComponent"):
		return
	var skill_comp = player_ref.skill_component
	if skill_comp.unlock_skill(skill_id):
		update_skill_tree_ui()
		skills_page.queue_redraw()
		_show_skill_desc(skill_id)

func _show_skill_desc(skill_id: String) -> void:
	if desc_label and SKILL_DESCS.has(skill_id):
		desc_label.text = SKILL_DESCS[skill_id]

func update_skill_tree_ui() -> void:
	if not player_ref or not player_ref.has_node("SkillComponent"):
		return
	var skill_comp = player_ref.skill_component
	
	# Update SP counter
	if sp_label:
		sp_label.text = "ĐIỂM KỸ NĂNG (SP): " + str(skill_comp.skill_points)
		
	# Toggle overlay based on checkpoint rest status
	if blackout_overlay:
		blackout_overlay.visible = not player_ref.is_at_checkpoint
		
	# Redraw skill buttons matching their unlockability states
	for id in skill_buttons.keys():
		var btn = skill_buttons[id]
		if not is_instance_valid(btn):
			continue
			
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		
		if skill_comp.is_skill_unlocked(id):
			style.bg_color = Color(0.12, 0.44, 0.62, 0.85) # Unlocked blue
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.2, 0.8, 1.0, 1.0)
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		elif skill_comp.can_unlock_skill(id):
			style.bg_color = Color(0.48, 0.36, 0.12, 0.75) # Unlockable amber
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.9, 0.7, 0.2, 1.0)
			btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		else:
			style.bg_color = Color(0.12, 0.12, 0.14, 0.6) # Locked dark grey
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.25, 0.25, 0.28, 0.6)
			btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
			
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("focus", style)

func _setup_styles():
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = Color(0.04, 0.04, 0.05, 0.9)
	style_panel.border_width_left = 1
	style_panel.border_width_top = 1
	style_panel.border_width_right = 1
	style_panel.border_width_bottom = 1
	style_panel.border_color = Color(1.0, 1.0, 1.0, 0.8)
	style_panel.corner_radius_top_left = 6
	style_panel.corner_radius_top_right = 6
	style_panel.corner_radius_bottom_right = 6
	style_panel.corner_radius_bottom_left = 6
	panel_node.add_theme_stylebox_override("panel", style_panel)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0, 0, 0, 0)
	style_hover.border_width_bottom = 1
	style_hover.border_color = Color(1.0, 1.0, 1.0, 0.4)
	
	var style_focus = StyleBoxEmpty.new()
	
	for btn in [map_button, items_button]:
		btn.flat = true
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("focus", style_focus)
		btn.add_theme_font_size_override("font_size", 12)
		
	if skills_button:
		skills_button.flat = true
		skills_button.add_theme_stylebox_override("hover", style_hover)
		skills_button.add_theme_stylebox_override("focus", style_focus)
		skills_button.add_theme_font_size_override("font_size", 12)
