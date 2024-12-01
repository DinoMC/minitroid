extends PlayerState

func EnterState():
	# Set the state label
	Name = "Locked"
	Player.hurting = true
	Player.start_hurt_timer()
	Player.invulnerable = true
	Player.start_invul_timer()
	Player.Animator.play("Hurt")


func ExitState():
	pass


func Update(delta: float):	
	Player.HorizontalAutoMovement()
	Player.HandleGravity(delta, Player.GravityFall)
	if !Player.hurting:
		Player.ChangeState(States.Idle)
