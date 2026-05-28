class_name InventoryComponent
extends Node

signal key_collected(key_name: String)

var keys: Array[String] = []

@onready var player: Player = get_parent() as Player

func collect_key(key_name: String) -> void:
	keys.append(key_name)
	key_collected.emit(key_name)
	player.key_collected.emit(key_name) # Emit parent signal for backward compatibility
	print("Key collected (InventoryComponent): ", key_name, " | Total keys: ", keys)
