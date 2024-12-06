extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var hp = 1
var dying = false

func damage(amount:int) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	if dying: return
	dying = true
	$CollisionShape2D.set_deferred("disabled", true)
	$EggSprite2D.texture = null
	Game.get_singleton().play_alien_damaged_sound()
	$EggSprite2D/eggsplosionAnimatedSprite2D.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()
