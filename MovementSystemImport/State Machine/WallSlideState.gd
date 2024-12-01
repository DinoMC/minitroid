extends PlayerState

const WallMagnetSpeed = 50

func EnterState():
	Name = "WallSlide"
	if (Player.wallDirection == Vector2.LEFT):
		Player.velocity.x = -WallMagnetSpeed
	elif(Player.wallDirection == Vector2.RIGHT):
		Player.velocity.x = WallMagnetSpeed


func ExitState():
	pass


func Draw():
	pass


func Update(delta):
	Player.GetWallDirection()
	Player.HandleLanding()
	Player.HandleWallJump()
	HandleWallSlideMovement()
	HandleAnimations()


func HandleWallSlideMovement():
	if (Player.wallClimbDirection == Vector2.ZERO):
		Player.ChangeState(States.Fall)
	
	if ((Player.wallClimbDirection == Vector2.LEFT and Player.keyLeft) or (Player.wallClimbDirection == Vector2.RIGHT and Player.keyRight)):
		if (!Player.keyJump):
			Player.velocity.y = Player.WallSlideSpeed
	else:
		Player.ChangeState(States.Fall)


func HandleAnimations():
	Player.Animator.play("WallSlide")
	Player.Sprite.flip_h = (Player.wallClimbDirection == Vector2.LEFT)
