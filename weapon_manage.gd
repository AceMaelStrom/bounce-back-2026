extends Node3D

@onready var animation_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var hitbox: Area3D = $zweihander/hitbox

func _process(delta: float) -> void:
	play_anim()

func play_anim() -> void:
	if Input.is_action_pressed("swing"):
		animation_player.play("sword_load")
		
		
	if Input.is_action_just_released("swing"):
		animation_player.play("sword_swing")
