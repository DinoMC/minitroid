class_name JumpPeak extends PlayerState

func EnterState():
	# Set the state label
	Name = "JumpPeak"


func ExitState():
	pass


func Update(delta: float):	
	# Handle State physics
	Player.HorizontalMovement()
	Player.ChangeState(States.Fall)
	HandleAnimations()


func HandleAnimations():
	Player.Animator.play("Jump")
	Player.HandleFlipH()
