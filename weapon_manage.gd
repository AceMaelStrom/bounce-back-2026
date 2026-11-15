extends Node3D

@onready var animation_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var hitbox: Area3D = $zweihander/hitbox

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitarea_body_entered)

func _process(delta: float) -> void:
	play_anim()

func play_anim() -> void:
	if Input.is_action_pressed("swing"):
		animation_player.play("sword_load")
		
		
	if Input.is_action_just_released("swing"):
		animation_player.play("sword_swing")
		
func _on_hitarea_body_entered(body: Node3D) -> void:
	if body is Ball:
		print("hitarea entered by: ", body.name)
		$zweihander/parrysound.play(0.15)
	
