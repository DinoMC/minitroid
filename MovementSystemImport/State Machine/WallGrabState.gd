extends PlayerState

const WallMagnetSpeed = 50

func EnterState():
	Name = "WallGrab"
	Player.velocity = Vector2.ZERO
	
	# Ensure the player is completely against the wall
	if (Player.wallClimbDirection == Vector2.LEFT):
		Player.velocity.x = -WallMagnetSpeed
	elif (Player.wallClimbDirection == Vector2.RIGHT):
		Player.velocity.x = WallMagnetSpeed


func ExitState():
	pass


func Draw():
	pass


func Update(delta):
	Player.HandleWallRelease()
	HandleClimb()
	Player.climbStamina -= Player.GrabStaminaCost
	Player.HandleWallJump()
	HandleAnimations()


func HandleClimb():
	if (Player.keyUp or Player.keyDown):
		Player.ChangeState(States.WallClimb)


func HandleAnimations():
	Player.Animator.play("WallGrab")
	Player.Sprite.flip_h = (Player.wallClimbDirection == Vector2.LEFT)
