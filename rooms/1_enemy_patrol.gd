extends CharacterBody2D


@export var SPEED := 75.0

var state := 0
var state_position := "bottom"
@onready var target = $Positions/Bottom1
@export var hp = 1
@export var timer_length = 1.0
var dying = false


func _ready() -> void:
	$PatrolCDTimer.wait_time = timer_length

func _physics_process(delta: float) -> void:
	if state == 0:
		global_position = global_position.move_toward(target.global_position, SPEED * delta)
		if global_position == target.global_position:
			state = 1
			$PatrolCDTimer.start()

func _on_patrol_cd_timer_timeout() -> void:
	if state_position == "bottom":
		target = [$Positions/Top1, $Positions/Top2, $Positions/Top3].pick_random()
		state_position = "top"
	elif state_position == "top":
		target = [$Positions/Bottom1, $Positions/Bottom2, $Positions/Bottom3].pick_random()
		state_position = "bottom"
	state = 0

func _on_hurt_zone_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_hurt_zone = true


func _on_hurt_zone_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_hurt_zone = false

func damage(amount:int) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	if dying: return
	dying = true
	$CollisionShape2D.set_deferred("disabled", true)
	$HurtZone_Area2D/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()
