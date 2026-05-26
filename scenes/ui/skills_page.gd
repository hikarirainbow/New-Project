extends Control

var inventory = null

func _draw() -> void:
	if not inventory or not is_instance_valid(inventory) or not inventory.player_ref:
		return
		
	var skill_comp = inventory.player_ref.get_node_or_null("SkillComponent")
	if not skill_comp:
		return
		
	# Define parent-child connections to draw
	var links = [
		["A", "B"], ["B", "C"],
		["D", "E"], ["E", "F"],
		["G", "H"], ["H", "I"],
		["J", "K"], ["K", "L"]
	]
	
	for link in links:
		var parent_id = link[0]
		var child_id = link[1]
		
		var parent_btn = inventory.skill_buttons.get(parent_id)
		var child_btn = inventory.skill_buttons.get(child_id)
		
		if parent_btn and child_btn:
			var p1 = parent_btn.position + parent_btn.size / 2.0
			var p2 = child_btn.position + child_btn.size / 2.0
			
			# Color coding for lines
			var color = Color(0.25, 0.25, 0.28, 0.8) # Gray for locked path
			
			if skill_comp.is_skill_unlocked(child_id):
				color = Color(0.2, 0.8, 1.0, 1.0) # Bright cyan for fully unlocked connection
			elif skill_comp.is_skill_unlocked(parent_id):
				color = Color(0.9, 0.6, 0.2, 0.9) # Orange/yellow for ready path
				
			draw_line(p1, p2, color, 2.5, true)
