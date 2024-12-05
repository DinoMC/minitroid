extends PlayerState

func EnterState():
	# Set the state label
	Name = "LockedDeath"
	Player.Animator.play("Death")

func ExitState():
	pass


func Update(delta: float):	
	pass
