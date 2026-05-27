extends Node

const MAX_SLOTS: int = 4
const SAVE_PATH_FORMAT: String = "user://saves/save_slot_%d.json"

# Currently active slot (-1 = no slot selected, e.g. still in main menu)
var current_slot: int = -1

# Elapsed play time in seconds for the current session (accumulated across saves)
var play_time_sec: int = 0
var _time_accumulator: float = 0.0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_ensure_saves_dir()

func _ensure_saves_dir() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			var err = dir.make_dir("saves")
			if err == OK:
				print("[SAVE] Created 'saves' directory under user://")
			else:
				push_error("[SAVE] Failed to create 'saves' directory: ", err)
		
		# Migrate old files if they exist in the root user:// folder
		for i in range(MAX_SLOTS):
			var old_path = "user://save_slot_%d.json" % i
			var old_tmp = old_path + ".tmp"
			var new_path = "user://saves/save_slot_%d.json" % i
			
			# Migrate main save file
			if FileAccess.file_exists(old_path) and not FileAccess.file_exists(new_path):
				var err = dir.rename(old_path, new_path)
				if err == OK:
					print("[SAVE] Migrated old save file to: ", new_path)
				else:
					push_error("[SAVE] Failed to migrate old save file: ", old_path)
					
			# Clean up any leftover old tmp files
			if FileAccess.file_exists(old_tmp):
				DirAccess.remove_absolute(old_tmp)


func _process(delta: float) -> void:
	if current_slot >= 0 and not get_tree().paused:
		# Only accumulate if not in main menu
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.scene_file_path != "res://scenes/ui/main_menu.tscn":
			_time_accumulator += delta
			if _time_accumulator >= 1.0:
				var secs = int(_time_accumulator)
				play_time_sec += secs
				_time_accumulator -= float(secs)

func format_play_time(total_seconds: int) -> String:
	var hrs = total_seconds / 3600
	var mins = (total_seconds % 3600) / 60
	var secs = total_seconds % 60
	if hrs > 0:
		return "%02d:%02d:%02d" % [hrs, mins, secs]
	return "%02d:%02d" % [mins, secs]

# ── SAVE ────────────────────────────────────────────────────────────────────
func save_game(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		push_warning("[SAVE] Invalid slot index: ", slot)
		return

	var player = _get_player()
	if not player:
		push_warning("[SAVE] No player found, cannot save.")
		return

	var data: Dictionary = {}
	data["slot_index"] = slot
	data["scene_path"] = get_tree().current_scene.scene_file_path
	data["spawn_point_x"] = player.spawn_point.x
	data["spawn_point_y"] = player.spawn_point.y

	# Skill component
	if player.skill_component:
		data["skill_points"] = player.skill_component.skill_points
		data["unlocked_skills"] = player.skill_component.unlocked_skills.duplicate()

	# Corruption / sanity
	if player.corruption_component:
		data["sanity"] = player.corruption_component.sanity
		data["max_sanity"] = player.corruption_component.max_sanity

	# Health
	data["current_health"] = player.current_health
	data["max_health"] = player.max_health
	data["is_debuffed"] = player.is_debuffed

	# Play time
	data["play_time_sec"] = play_time_sec

	# Keys & Dash upgrade
	data["keys"] = player.keys.duplicate() if "keys" in player else []
	if player.dash_component:
		data["dash_cooldown"] = player.dash_component.dash_cooldown

	# Timestamp
	var dt = Time.get_datetime_dict_from_system()
	data["timestamp"] = "%04d-%02d-%02d %02d:%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]

	# Write to file atomically using temp file
	var path = SAVE_PATH_FORMAT % slot
	var temp_path = path + ".tmp"
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		
		# Replace target file atomically
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		var err = DirAccess.rename_absolute(temp_path, path)
		if err == OK:
			print("[SAVE] Saved to slot ", slot, " at ", path)
		else:
			push_error("[SAVE] Failed to rename temp save file to: ", path)
	else:
		push_error("[SAVE] Failed to write temp save file: ", temp_path)

# ── LOAD ────────────────────────────────────────────────────────────────────
func load_game(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_SLOTS:
		return {}

	var path = SAVE_PATH_FORMAT % slot
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data

	push_error("[SAVE] Failed to parse save file: ", path)
	return {}

# ── QUERY ───────────────────────────────────────────────────────────────────
func has_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		return false
	return FileAccess.file_exists(SAVE_PATH_FORMAT % slot)

func get_slot_preview(slot: int) -> Dictionary:
	return load_game(slot)

# ── DELETE ──────────────────────────────────────────────────────────────────
func delete_save(slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	var path = SAVE_PATH_FORMAT % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SAVE] Deleted save slot ", slot)

# ── GAME FLOW ───────────────────────────────────────────────────────────────
func start_new_game(slot: int) -> void:
	current_slot = slot
	play_time_sec = 0

	# Create default save immediately so slot shows as occupied
	var data: Dictionary = {
		"slot_index": slot,
		"scene_path": "res://scenes/levels/sandbox_level.tscn",
		"spawn_point_x": 496.0,
		"spawn_point_y": 592.0,
		"skill_points": 5,
		"unlocked_skills": {
			"A": false, "B": false, "C": false,
			"D": false, "E": false, "F": false,
			"G": false, "H": false, "I": false,
			"J": false, "K": false, "L": false
		},
		"sanity": 100.0,
		"max_sanity": 100.0,
		"current_health": 100,
		"max_health": 100,
		"is_debuffed": false,
		"keys": [],
		"dash_cooldown": 0.8,
		"play_time_sec": 0,
		"timestamp": ""
	}
	var dt = Time.get_datetime_dict_from_system()
	data["timestamp"] = "%04d-%02d-%02d %02d:%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]

	var path = SAVE_PATH_FORMAT % slot
	var temp_path = path + ".tmp"
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		DirAccess.rename_absolute(temp_path, path)

	# Clear any persisted corpses from previous session
	var room_mgr = get_node_or_null("/root/RoomManager")
	if room_mgr:
		room_mgr.persisted_corpses.clear()

	get_tree().change_scene_to_file("res://scenes/levels/sandbox_level.tscn")
	print("[SAVE] Started new game on slot ", slot)

func continue_game(slot: int) -> void:
	var data = load_game(slot)
	if data.is_empty():
		push_warning("[SAVE] No data found for slot ", slot, ", starting new game instead.")
		start_new_game(slot)
		return

	current_slot = slot
	play_time_sec = data.get("play_time_sec", 0)

	# Clear any persisted corpses from previous session
	var room_mgr = get_node_or_null("/root/RoomManager")
	if room_mgr:
		room_mgr.persisted_corpses.clear()

	var scene_path = data.get("scene_path", "res://scenes/levels/sandbox_level.tscn")
	get_tree().change_scene_to_file(scene_path)
	print("[SAVE] Continuing game on slot ", slot)

# ── HELPERS ─────────────────────────────────────────────────────────────────
func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

# Called by sandbox_level._ready() to apply loaded save data to the player
func apply_save_to_player(player: Node) -> void:
	if current_slot < 0:
		return

	var data = load_game(current_slot)
	if data.is_empty():
		return

	# Spawn position
	var sx = data.get("spawn_point_x", player.spawn_point.x)
	var sy = data.get("spawn_point_y", player.spawn_point.y)
	player.spawn_point = Vector2(sx, sy)
	player.global_position = player.spawn_point

	# Skills
	if player.skill_component:
		player.skill_component.skill_points = data.get("skill_points", 5)
		var skills = data.get("unlocked_skills", {})
		for key in skills.keys():
			player.skill_component.unlocked_skills[key] = skills[key]

	# Sanity / Corruption
	if player.corruption_component:
		var max_sanity_val = data.get("max_sanity", 100.0)
		player.corruption_component.max_sanity = max_sanity_val
		
		var sanity_val = data.get("sanity", 100.0)
		player.corruption_component.sanity = sanity_val
		player.corruption_component.corruption = max_sanity_val - sanity_val
		player.corruption_component.sanity_changed.emit(sanity_val)

	# Health & debuff
	player.is_debuffed = data.get("is_debuffed", false)
	player.max_health = data.get("max_health", 100)
	player.current_health = data.get("current_health", 100)
	player.health_changed.emit(player.current_health)

	# Keys
	if "keys" in player:
		player.keys.clear()
		for k in data.get("keys", []):
			player.keys.append(str(k))
		player.key_collected.emit("")

	# Dash cooldown
	if player.dash_component:
		player.dash_component.dash_cooldown = data.get("dash_cooldown", 0.8)

	print("[SAVE] Applied save data from slot ", current_slot, " to player.")
