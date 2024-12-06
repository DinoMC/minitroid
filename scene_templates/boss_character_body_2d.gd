extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var hp := 8
var invulnerable = false
@export var bosshp_texturerect : TextureRect


func throw_barrel() -> void:
	$Throw_AudioStreamPlayer2D.play()
	var barrel = preload("res://scene_templates/boss_projectile_rigid_body_2d.tscn").instantiate()
	barrel.position = $Throw_Marker2D.global_position
	barrel.linear_velocity = Vector2(randi_range(-200, -275) * scale.x, -300)
	barrel.angular_velocity = randi_range(3, 12) * [-1, 1].pick_random()
	get_parent().add_child(barrel)

func play_intro() -> void:
	$AnimationPlayer.play("intro")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		$AnimationPlayer.play("loop")
	if anim_name == "die":
		Game.get_singleton().player.abilities.append("win_code") # TODO : check if win_code is already in abilities to prevent duplicates.
		Game.get_singleton()._on_rewind_timer_timeout()

func damage(amount) -> void:
	if invulnerable: return
	invulnerable = true
	$InvulTimer.start()
	$Damaged_AudioStreamPlayer2D.play()
	hp -= amount
	if hp < 0: hp = 0
	bosshp_texturerect.texture.region.position.x = 128 - 16 * hp
	if hp <= 0:
		Game.get_singleton().player.invulnerable = true
		$Explosion_AudioStreamPlayer2D.play()
		$AnimationPlayer.play("die")
	else:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.tween_property(self, "modulate:a", 1.0, 0.1)
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.tween_property(self, "modulate:a", 1.0, 0.1)
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		tween.tween_property(self, "modulate:a", 1.0, 0.1)



func _on_invul_timer_timeout() -> void:
	invulnerable = false
