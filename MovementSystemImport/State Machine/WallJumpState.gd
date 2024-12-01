class_name WallJump extends PlayerState

var lastWallDirection
var shouldEnableWallKick

func EnterState():
	# Set the label
	Name = "WallJump"
	Player.velocity.y = Player.WallJumpVelocity
	lastWallDirection = Player.wallDirection
	ShouldOnlyJumpButtonWallKick(false)


func ExitState():
	pass


func Update(delta: float):
	Player.GetWallDirection() # For ending state if we hit a wall
	Player.HandleGravity(delta, Player.GravityJump)
	HandleWallKickMovement()
	HandleWallJumpEnd()
	Player.HandleDash()
	HandleAnimations()
	print("JUMPS: " + str(Player.jumps))


func ShouldOnlyJumpButtonWallKick(shouldEnable: bool):
	shouldEnableWallKick = shouldEnable
	if (shouldEnable):
		if (Player.keyLeft or Player.keyRight):
			Player.velocity.x = Player.WallJumpHSpeed * Player.wallDirection.x * -1
		else:
			if (Player.jumps == Player.MaxJumps):
				Player.velocity.x = Player.WallJumpHSpeed * Player.wallDirection.x * -1
			else:
				Player.ChangeState(States.Fall)
	else:
		Player.velocity.x = Player.WallJumpHSpeed * Player.wallDirection.x * -1


func HandleWallKickMovement():
	if (!Player.keyLeft and !Player.keyRight):
		# No input means wall kick, so slow horizontal movement to 0 to just move away from
		# the wall a little
		Player.velocity.x = move_toward(Player.velocity.x, 0, Player.WallKickAcceleration)
	else:
		# Allow the player to move to the oppoisite directin of the wall at full speed
		if ((lastWallDirection == Vector2.LEFT) and Player.keyRight):
			Player.HorizontalMovement(Player.WallKickAcceleration, Player.WallKickDeceleration)
		elif ((lastWallDirection == Vector2.RIGHT) and Player.keyLeft):
			Player.HorizontalMovement(Player.WallKickAcceleration, Player.WallKickDeceleration)


func HandleWallJumpEnd():
	# End if at jump peak
	if (Player.velocity.y >= Player.WallJumpYSpeedPeak):
		Player.ChangeState(States.Fall)
	
	# Cancel if we hit a wall
	if ((Player.wallDirection != lastWallDirection) and (Player.wallDirection != Vector2.ZERO)):
		Player.ChangeState(States.Fall)


func HandleAnimations():
	if ((!Player.keyLeft and !Player.keyRight) and shouldEnableWallKick):
		Player.Animator.play("WallKick")
		Player.Sprite.flip_h = (Player.velocity.x > 0)
	else:
		Player.Animator.play("WallJump")
		Player.Sprite.flip_h = (Player.velocity.x < 0)
