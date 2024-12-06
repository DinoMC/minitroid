extends PlayerState

const DashSquish = 0.66
var DistortionEffect = preload("res://MovementSystemImport/DashDistortion.tscn")

func EnterState():
	# Set the label
	Name = "Dash"
	OS.delay_msec(Player.DashDelayEffect)
	Player.dashDirection = Player.GetDashDirection()
	if Player.Sprite.flip_h:
		Player.DashGhost.texture.region.position.x = 32
	else:
		Player.DashGhost.texture.region.position.x = 0
	Player.DashGhost.restart()
	Player.velocity = Player.dashDirection.normalized() * Player.DashSpeed
	Player.DashTimer.start(Player.DashTime)
	Player.SetSquish(abs(Player.dashDirection.y * DashSquish), abs(Player.dashDirection.x * DashSquish))
	var _distortion = DistortionEffect.instantiate()
	_distortion.global_position = Player.global_position
	get_tree().root.get_node("Engine").get_node("Game").add_child(_distortion)
	Player.Animator.play("Dash")
	Player.HandleFlipH()


func ExitState():
	pass


func Update(delta: float):
	HandleDashEnd()
	HandleAnimations()


func HandleDashEnd():
	if (Player.DashTimer.time_left <= 0):
		Player.DashTimer.stop()
		Player.velocity *= Player.DashMomentumCarry
		Player.ChangeState(States.Fall)


func HandleAnimations():
	Player.Animator.play("Dash")
	Player.HandleFlipH()
