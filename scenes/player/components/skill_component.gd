class_name SkillComponent
extends Node2D

# Skill list and unlock status:
# Path 1: A -> B -> C (Combat)
# Path 2: D -> E -> F (Agility)
# Path 3: G -> H -> I (Corruption)
# Path 4: J -> K -> L (Sanity)

var skill_points: int = 5
var unlocked_skills: Dictionary = {
	"A": false, "B": false, "C": false,
	"D": false, "E": false, "F": false,
	"G": false, "H": false, "I": false,
	"J": false, "K": false, "L": false
}

const SKILL_PARENTS = {
	"B": "A", "C": "B",
	"E": "D", "F": "E",
	"H": "G", "I": "H",
	"K": "J", "L": "K"
}

func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skills.get(skill_id, false)

func can_unlock_skill(skill_id: String) -> bool:
	if is_skill_unlocked(skill_id):
		return false
		
	if skill_points < 1:
		return false
		
	# Check parent dependency
	if SKILL_PARENTS.has(skill_id):
		var parent = SKILL_PARENTS[skill_id]
		return is_skill_unlocked(parent)
		
	return true # Root skill (A, D, G, J) can be unlocked freely if SP >= 1

func unlock_skill(skill_id: String) -> bool:
	if can_unlock_skill(skill_id):
		unlocked_skills[skill_id] = true
		skill_points -= 1
		print("[SKILL] Unlocked: ", skill_id, " | Remaining SP: ", skill_points)
		return true
	return false
