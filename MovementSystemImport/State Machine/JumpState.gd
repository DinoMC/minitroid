class_name Jump extends PlayerState

func EnterState():
	# Set the state label
	Name = "Jump"
	Player.velocity.y = Player.jumpSpeed


func ExitState():
	pass


func Update(delta: float):	
	# Handle State physics
	Player.HandleGravity(delta)
	Player.HorizontalMovement()
	Player.HandleWallJump()
	Player.HandleWallGrab()
	Player.HandleDash()
	HandleJumpToFall()
	HandleAnimations()


func HandleAnimations():
	Player.Animator.play("Jump")
	Player.HandleFlipH()


func HandleJumpToFall():
	if (Player.velocity.y >= 0):
		Player.ChangeState(States.Fall)
	elif (!Player.keyJump): # See if the jump key is held, if not, slash the momentum
		Player.velocity.y *= Player.VariableJumpMultiplier
		Player.ChangeState(States.Fall)
