extends PlayerState

func EnterState():
	# Set the label
	Name = "Idle"


func ExitState():
	pass


func Update(delta: float):
	Player.HandleFalling()
	Player.HandleJump()
	Player.HorizontalMovement()
	if (Player.moveDirectionX != 0):
		Player.ChangeState(States.Run)
	Player.HandleDash()
	HandleAnimations()


func HandleAnimations():
	Player.Animator.play("Idle")
	Player.HandleFlipH()
