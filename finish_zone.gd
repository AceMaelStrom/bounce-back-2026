extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body is Ball and not body.homing_on and not body.retracing:
		get_tree().call_deferred("change_scene_to_file", "res://level_complete.tscn")
