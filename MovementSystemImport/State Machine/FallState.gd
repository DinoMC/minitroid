extends PlayerState

func EnterState():
	# Set the label
	Name = "Fall"

func ExitState():
	pass


func Update(delta: float):
	# Handle state physics
	Player.HandleGravity(delta, Player.GravityFall)
	Player.HorizontalMovement(Player.AirAcceleration, Player.AirDeceleration)
	Player.HandleLanding()
	Player.call_deferred("HandleJump")
	Player.call_deferred("HandleJumpBuffer")
	Player.HandleWallJump()
	Player.HandleWallSlide()
	Player.HandleWallGrab()
	Player.HandleDash()
	HandleAnimations()


func HandleAnimations():
	Player.Animator.play("Fall")
	Player.HandleFlipH()
