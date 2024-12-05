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
