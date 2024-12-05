extends PlayerState


func EnterState():
	# Set the state label
	Name = "Run"

func ExitState():
	pass


func Update(delta: float):
	# Allow the player to jump
	Player.jumps = 0
	
	# Handle the movments
	Player.HorizontalMovement()
	Player.call_deferred("HandleJump")
	Player.HandleFalling()
	Player.HandleDash()
	HandleAnimations()
	HandleIdle()


func HandleAnimations():
	var anim = "Run"
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


func HandleIdle():
	if (Player.moveDirectionX == 0 || Player.keyLock):
		Player.ChangeState(States.Idle)
