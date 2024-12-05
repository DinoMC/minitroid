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
	var anim = "Jump"
	var extension = ""
	if !Player.abilities.has("blaster"): extension = "_down"
	elif Player.direction != "" : extension = "_"+Player.direction
	if !Player.Animator.animation.contains(anim):
		Player.Animator.play(anim + extension)
	elif anim + extension != Player.Animator.animation:
		var frame = Player.Animator.frame
		var progress = Player.Animator.frame_progress
		Player.Animator.animation = anim + extension
		Player.Animator.set_frame_and_progress(frame, progress)
	Player.HandleFlipH()


func HandleJumpToFall():
	if (Player.velocity.y >= 0):
		Player.ChangeState(States.Fall)
	elif (!Player.keyJump): # See if the jump key is held, if not, slash the momentum
		Player.velocity.y *= Player.VariableJumpMultiplier
		Player.ChangeState(States.Fall)
