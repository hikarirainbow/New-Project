extends Control

# ── NODE REFERENCES ─────────────────────────────────────────────────────────
var menu_container: VBoxContainer = null
var save_panel: Control = null
var settings_layer: CanvasLayer = null
var title_label: Label = null

# Slot UI stored references for navigation and refresh
var slot_buttons: Array[Button] = []
var delete_buttons: Array[Button] = []
var info_labels: Array[Label] = []
var back_button: Button = null

# ── CONSTANTS ───────────────────────────────────────────────────────────────
const PURPLE_DARK  = Color(0.12, 0.06, 0.22)
const PURPLE_MID   = Color(0.20, 0.10, 0.35)
const PURPLE_LIGHT = Color(0.35, 0.18, 0.55)
const ACCENT_CYAN  = Color(0.40, 0.85, 1.0)
const ACCENT_PINK  = Color(0.95, 0.45, 0.65)
const TEXT_DIM     = Color(0.55, 0.50, 0.65)
const TEXT_BRIGHT  = Color(0.92, 0.90, 0.97)
const SLOT_BG      = Color(0.14, 0.08, 0.26, 0.9)
const SLOT_BORDER  = Color(0.30, 0.18, 0.50)
const DELETE_RED   = Color(0.85, 0.25, 0.30)
const DELETE_RED_H = Color(1.0, 0.35, 0.40)

func _ready() -> void:
	# Ensure mouse is visible in menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_build_background()
	_build_menu()
	_build_save_panel()

# ── BACKGROUND ──────────────────────────────────────────────────────────────
func _build_background() -> void:
	var bg = ColorRect.new()
	bg.name = "BG"
	bg.color = PURPLE_DARK
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	bg.z_index = -10

# ── MAIN MENU BUTTONS ──────────────────────────────────────────────────────
func _build_menu() -> void:
	menu_container = VBoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.set_anchors_preset(PRESET_CENTER)
	menu_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	menu_container.custom_minimum_size = Vector2(200, 0)
	menu_container.add_theme_constant_override("separation", 8)
	add_child(menu_container)

	# Title
	title_label = Label.new()
	title_label.text = "NEW GAME PROJECT"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", TEXT_BRIGHT)
	title_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.2, 1.0))
	title_label.add_theme_constant_override("outline_size", 6)
	menu_container.add_child(title_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	menu_container.add_child(spacer)

	# Buttons
	var play_btn = _create_menu_button("Play")
	play_btn.pressed.connect(_on_play_pressed)
	menu_container.add_child(play_btn)

	var settings_btn = _create_menu_button("Settings")
	settings_btn.pressed.connect(_on_settings_pressed)
	menu_container.add_child(settings_btn)

	var quit_btn = _create_menu_button("Quit")
	quit_btn.pressed.connect(_on_quit_pressed)
	menu_container.add_child(quit_btn)
	
	# Auto-focus Play button
	await get_tree().process_frame
	play_btn.grab_focus()

func _create_menu_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 36)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", TEXT_DIM)
	btn.add_theme_color_override("font_hover_color", TEXT_BRIGHT)
	btn.add_theme_color_override("font_focus_color", TEXT_BRIGHT)
	btn.add_theme_color_override("font_pressed_color", ACCENT_CYAN)

	# Normal style (transparent)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", style_normal)

	# Hover style (subtle underline)
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0, 0, 0, 0)
	style_hover.border_width_bottom = 2
	style_hover.border_color = ACCENT_CYAN
	btn.add_theme_stylebox_override("hover", style_hover)

	# Focus style (same as hover for keyboard nav)
	var style_focus = StyleBoxFlat.new()
	style_focus.bg_color = Color(0, 0, 0, 0)
	style_focus.border_width_bottom = 2
	style_focus.border_color = ACCENT_CYAN
	btn.add_theme_stylebox_override("focus", style_focus)
	
	# Pressed style
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(ACCENT_CYAN.r, ACCENT_CYAN.g, ACCENT_CYAN.b, 0.1)
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = ACCENT_CYAN
	btn.add_theme_stylebox_override("pressed", style_pressed)

	return btn

# ── SAVE SLOT PANEL ─────────────────────────────────────────────────────────
func _build_save_panel() -> void:
	save_panel = Control.new()
	save_panel.name = "SavePanel"
	save_panel.set_anchors_preset(PRESET_FULL_RECT)
	save_panel.visible = false
	add_child(save_panel)

	# Dim overlay background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	save_panel.add_child(overlay)

	# Central panel — one big window split into 4
	var panel = Panel.new()
	panel.name = "SlotWindow"
	panel.custom_minimum_size = Vector2(500, 260)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -250
	panel.offset_top = -145
	panel.offset_right = 250
	panel.offset_bottom = 145

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = SLOT_BG
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = SLOT_BORDER
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", panel_style)
	save_panel.add_child(panel)

	# Title label at top of panel
	var panel_title = Label.new()
	panel_title.text = "SAVE SLOTS"
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_title.add_theme_font_size_override("font_size", 16)
	panel_title.add_theme_color_override("font_color", ACCENT_CYAN)
	panel_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	panel_title.add_theme_constant_override("outline_size", 3)
	panel_title.set_anchors_preset(PRESET_TOP_WIDE)
	panel_title.offset_top = 8
	panel_title.offset_bottom = 28
	panel.add_child(panel_title)

	# Grid container for 4 slots (2x2 layout)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 44)
	panel.add_child(margin)

	var grid = GridContainer.new()
	grid.name = "SlotGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(grid)

	slot_buttons.clear()
	delete_buttons.clear()
	info_labels.clear()

	for i in range(SaveManager.MAX_SLOTS):
		var slot_container = _build_slot_cell(i)
		grid.add_child(slot_container)

	# Back button at bottom
	back_button = Button.new()
	back_button.text = "← Back"
	back_button.flat = true
	back_button.add_theme_font_size_override("font_size", 12)
	back_button.add_theme_color_override("font_color", TEXT_DIM)
	back_button.add_theme_color_override("font_hover_color", TEXT_BRIGHT)
	back_button.add_theme_color_override("font_focus_color", TEXT_BRIGHT)
	
	var back_style_n = StyleBoxFlat.new()
	back_style_n.bg_color = Color(0, 0, 0, 0)
	back_button.add_theme_stylebox_override("normal", back_style_n)
	var back_style_h = StyleBoxFlat.new()
	back_style_h.bg_color = Color(0, 0, 0, 0)
	back_style_h.border_width_bottom = 1
	back_style_h.border_color = TEXT_DIM
	back_button.add_theme_stylebox_override("hover", back_style_h)
	var back_style_f = back_style_h.duplicate()
	back_button.add_theme_stylebox_override("focus", back_style_f)
	
	back_button.set_anchors_preset(PRESET_BOTTOM_WIDE)
	back_button.offset_top = -32
	back_button.offset_bottom = -8
	back_button.offset_left = 14
	back_button.offset_right = -14
	back_button.pressed.connect(_on_back_pressed)
	panel.add_child(back_button)

func _build_slot_cell(slot_index: int) -> PanelContainer:
	var cell = PanelContainer.new()
	cell.name = "Slot_%d" % slot_index
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(220, 80)

	# Cell background style
	var cell_style = StyleBoxFlat.new()
	cell_style.bg_color = Color(PURPLE_MID.r, PURPLE_MID.g, PURPLE_MID.b, 0.6)
	cell_style.border_width_left = 1
	cell_style.border_width_top = 1
	cell_style.border_width_right = 1
	cell_style.border_width_bottom = 1
	cell_style.border_color = SLOT_BORDER
	cell_style.corner_radius_top_left = 4
	cell_style.corner_radius_top_right = 4
	cell_style.corner_radius_bottom_right = 4
	cell_style.corner_radius_bottom_left = 4
	cell.add_theme_stylebox_override("panel", cell_style)

	# Inner margin
	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 8)
	inner_margin.add_theme_constant_override("margin_top", 6)
	inner_margin.add_theme_constant_override("margin_right", 8)
	inner_margin.add_theme_constant_override("margin_bottom", 6)
	cell.add_child(inner_margin)

	# VBox for slot info + action row
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	inner_margin.add_child(vbox)

	# Slot label header
	var header = Label.new()
	header.text = "Slot %d" % (slot_index + 1)
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", ACCENT_CYAN)
	vbox.add_child(header)

	# Info label (empty/data preview)
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.add_theme_color_override("font_color", TEXT_DIM)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(info_label)
	info_labels.append(info_label)

	# Action row: Load/New button + Delete button
	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	action_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(action_row)

	# Main slot action button (Play / Continue)
	var slot_btn = Button.new()
	slot_btn.name = "SlotButton"
	slot_btn.flat = true
	slot_btn.custom_minimum_size = Vector2(80, 22)
	slot_btn.add_theme_font_size_override("font_size", 11)
	slot_btn.add_theme_color_override("font_color", TEXT_BRIGHT)
	slot_btn.add_theme_color_override("font_hover_color", ACCENT_CYAN)
	slot_btn.add_theme_color_override("font_focus_color", ACCENT_CYAN)
	
	var sbtn_n = StyleBoxFlat.new()
	sbtn_n.bg_color = Color(ACCENT_CYAN.r, ACCENT_CYAN.g, ACCENT_CYAN.b, 0.08)
	sbtn_n.corner_radius_top_left = 3
	sbtn_n.corner_radius_top_right = 3
	sbtn_n.corner_radius_bottom_right = 3
	sbtn_n.corner_radius_bottom_left = 3
	slot_btn.add_theme_stylebox_override("normal", sbtn_n)
	
	var sbtn_h = StyleBoxFlat.new()
	sbtn_h.bg_color = Color(ACCENT_CYAN.r, ACCENT_CYAN.g, ACCENT_CYAN.b, 0.2)
	sbtn_h.corner_radius_top_left = 3
	sbtn_h.corner_radius_top_right = 3
	sbtn_h.corner_radius_bottom_right = 3
	sbtn_h.corner_radius_bottom_left = 3
	slot_btn.add_theme_stylebox_override("hover", sbtn_h)
	var sbtn_f = sbtn_h.duplicate()
	slot_btn.add_theme_stylebox_override("focus", sbtn_f)
	
	var captured_index = slot_index
	slot_btn.pressed.connect(func(): _on_slot_pressed(captured_index))
	action_row.add_child(slot_btn)
	slot_buttons.append(slot_btn)

	# Delete button (only visible when slot has data)
	var del_btn = Button.new()
	del_btn.name = "DeleteButton"
	del_btn.text = "✕"
	del_btn.flat = true
	del_btn.custom_minimum_size = Vector2(22, 22)
	del_btn.add_theme_font_size_override("font_size", 11)
	del_btn.add_theme_color_override("font_color", DELETE_RED)
	del_btn.add_theme_color_override("font_hover_color", DELETE_RED_H)
	del_btn.add_theme_color_override("font_focus_color", DELETE_RED_H)

	var dbtn_n = StyleBoxFlat.new()
	dbtn_n.bg_color = Color(0, 0, 0, 0)
	del_btn.add_theme_stylebox_override("normal", dbtn_n)
	var dbtn_h = StyleBoxFlat.new()
	dbtn_h.bg_color = Color(DELETE_RED.r, DELETE_RED.g, DELETE_RED.b, 0.15)
	dbtn_h.corner_radius_top_left = 3
	dbtn_h.corner_radius_top_right = 3
	dbtn_h.corner_radius_bottom_right = 3
	dbtn_h.corner_radius_bottom_left = 3
	del_btn.add_theme_stylebox_override("hover", dbtn_h)
	var dbtn_f = dbtn_h.duplicate()
	del_btn.add_theme_stylebox_override("focus", dbtn_f)

	del_btn.pressed.connect(func(): _on_delete_pressed(captured_index))
	action_row.add_child(del_btn)
	delete_buttons.append(del_btn)

	return cell

# ── REFRESH SLOT DISPLAY ────────────────────────────────────────────────────
func _refresh_slots() -> void:
	for i in range(SaveManager.MAX_SLOTS):
		if i >= info_labels.size() or i >= slot_buttons.size() or i >= delete_buttons.size():
			continue

		var info_label = info_labels[i]
		var slot_btn = slot_buttons[i]
		var del_btn = delete_buttons[i]

		if SaveManager.has_save(i):
			var data = SaveManager.get_slot_preview(i)
			var sp = data.get("skill_points", "?")
			var ts = data.get("timestamp", "---")
			var hp = data.get("current_health", "?")
			var max_hp = data.get("max_health", "?")
			var play_time = data.get("play_time_sec", 0)
			var time_str = SaveManager.format_play_time(play_time)
			info_label.text = "HP: %s/%s  |  SP: %s  |  Time: %s\n%s" % [str(hp), str(max_hp), str(sp), time_str, ts]
			slot_btn.text = "Continue ▶"
			del_btn.visible = true
		else:
			info_label.text = "--- Empty ---"
			slot_btn.text = "New Game"
			del_btn.visible = false


# ── CALLBACKS ───────────────────────────────────────────────────────────────
func _on_play_pressed() -> void:
	menu_container.visible = false
	save_panel.visible = true
	_refresh_slots()
	
	# Focus first slot button
	await get_tree().process_frame
	if not slot_buttons.is_empty():
		slot_buttons[0].grab_focus()

func _on_settings_pressed() -> void:
	if settings_layer:
		settings_layer.queue_free()
		settings_layer = null

	var settings_scene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scene:
		settings_layer = settings_scene.instantiate()
		add_child(settings_layer)
		# Force open
		if settings_layer.has_method("toggle_menu"):
			settings_layer.toggle_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	save_panel.visible = false
	menu_container.visible = true
	
	# Re-focus Play button
	await get_tree().process_frame
	var play_btn = menu_container.get_child(2) # Play is 3rd child (after title + spacer)
	if play_btn:
		play_btn.grab_focus()

func _on_slot_pressed(slot_index: int) -> void:
	if SaveManager.has_save(slot_index):
		SaveManager.continue_game(slot_index)
	else:
		SaveManager.start_new_game(slot_index)

func _on_delete_pressed(slot_index: int) -> void:
	SaveManager.delete_save(slot_index)
	_refresh_slots()

# ── INPUT HANDLING ──────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	# ESC / ui_cancel to go back from save panel
	if save_panel.visible and Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
