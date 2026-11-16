extends Node

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var button = find_child("Button")
	if button:
		button.grab_focus()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://bouce-back-main-node.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://intro_menu.tscn")
