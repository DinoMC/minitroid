extends PlayerState

func EnterState():
	# Set the state label
	Name = "Locked"
	Player.jumps = 0
	Player.dashes = 0
	Player.hurting = true
	Player.start_hurt_timer()
	Player.invulnerable = true
	Player.start_invul_timer()
	Player.Animator.play("Hurt")
	var timer = Game.get_singleton().rewind_timer
	if timer != null && is_instance_valid(timer):
		var damage_amount = float(Player.current_hurtzone_damage)
		if timer.time_left > damage_amount:
			timer.start(timer.time_left - damage_amount)
		else:
			timer.start(0.25)
			pass


func ExitState():
	pass


func Update(delta: float):	
	Player.HorizontalAutoMovement()
	Player.HandleGravity(delta, Player.GravityFall)
	if !Player.hurting:
		Player.ChangeState(States.Idle)
