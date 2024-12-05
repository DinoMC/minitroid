extends PlayerState

func EnterState():
	# Set the label
	Name = "Idle"

func ExitState():
	pass


func Update(delta: float):
	Player.HandleFalling()
	Player.call_deferred("HandleJump")
	Player.HorizontalMovement()
	if (Player.moveDirectionX != 0 && !Player.keyLock):
		Player.ChangeState(States.Run)
	Player.HandleDash()
	HandleAnimations()


func HandleAnimations():
	var anim = "Idle"
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
