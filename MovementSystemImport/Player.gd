extends CharacterBody2D

#region Player Variables

# Nodes
@onready var Sprite = $Sprite
@onready var Animator = $Sprite
@onready var Collider = $Collider
@onready var States = $StateMachine

@onready var CoyoteTimer = $Timers/CoyoteTime
@onready var JumpBufferTimer = $Timers/JumpBuffer
@onready var DashTimer: Timer = $Timers/DashTimer
@onready var DashBuffer: Timer = $Timers/DashBuffer

@onready var RCWallKickLeft = $Raycasts/WallJump/WallKickLeft
@onready var RCWallKickRight = $Raycasts/WallJump/WallKickRight
@onready var RCWallClimbRight = $Raycasts/WallClimb/WallClimbTopRight
@onready var RCWallClimbLeft = $Raycasts/WallClimb/WallClimbTopLeft
@onready var RCWallClimbLimitTopLeft = $Raycasts/WallClimb/WallClimbLimitTopLeft
@onready var RCWallClimbLimitTopRight = $Raycasts/WallClimb/WallClimbLimitTopRight
@onready var RCWallClimbLimitBottomLeft = $Raycasts/WallClimb/WallClimbLimitBottomLeft
@onready var RCWallClimbLimitBottomRight = $Raycasts/WallClimb/WallClimbLimitBottomRight

@onready var DashGhost: = $"Graphics Effects/Dash/DashGhost"

var abilities: Array[StringName]
var tempabilities: Array[StringName]

var reset_position: Vector2

# Physics Variables
const RunSpeed = 120
const GroundAcceleration = 40
const GroundDeceleration = 50
const AirAcceleration = 15
const AirDeceleration = 20

const GravityJump = 600
const GravityFall = 700
const MaxFallVelocity = 700
const JumpVelocity = -280
const VariableJumpMultiplier = 0.5
const MaxJumps = 1
const CoyoteTime = 0.1 # 6 Frames: FPS / (desired frames) = Time in seconds
const JumpBufferTime = 0.15  # 9 Frames: FPS / (desired frames) = Time in seconds

const WallKickAcceleration = 4
const WallKickDeceleration = 5
const WallJumpYSpeedPeak = 0 # Y-speed at which the wall jump will end and change to fall state
const WallJumpVelocity = -190
const WallJumpHSpeed = 120

const WallSlideSpeed = 40
const ClimbSpeed = 30
const MaxClimbStamina = 300 # Measured in ticks not seconds as it can decrease at various rates
const GrabStaminaCost = 1
const ClimbStaminaCost = 2

const MaxDashes = 1
const DashSpeed = 300
const DashAcceleration = 4
const DashTime = 0.15
const DashBufferTime = 0.075
const DashMomentumCarry = 0.5
const DashDelayEffect = 30

# Player variables
var moveSpeed = RunSpeed
var Acceleration = GroundAcceleration
var Deceleration = GroundDeceleration
var jumpSpeed = JumpVelocity
var moveDirectionX = 0
var jumps = 0
var wallDirection = Vector2.ZERO
var wallClimbDirection = Vector2.ZERO
var climbStamina = MaxClimbStamina

var dashes = 0
var dashDirection: Vector2
var facing = 1

var squishX = 1.0
var squishY = 1.0
var squishStep = 0.02

# Input Variables
var keyUp = false
var keyDown = false
var keyLeft = false
var keyRight = false
var keyLock = false
var keyJump = false
var keyJumpPressed = false
var keyDropDown = false
var keyClimb = false
var keyDash = false

# State Machine
var currentState = null
var previousState = null
var nextState = null

# New Stuff
var hurting = false
var invulnerable = false
var in_hurt_zone = false
var default_damage := 5
var current_hurtzone_damage := 5

#endregion

var dying = false
var rewinding = false
var saving_rewind = true
var rewind_values = {
	"position" : [],
	"animation" : [],
	"frame" : [],
	"MetSysposition" : [],
	"flip_h" : []
}
var frame_count := 0
var MetSysposition : Vector3i

#region Game Loop Functions

var blaster := false

func _ready():
	# Initialize the state machine
	for state in States.get_children():
		state.States = States
		state.Player = self
	previousState = States.Fall
	currentState = States.Fall
	
	#Set some important variables
	CoyoteTimer.one_shot = true
	JumpBufferTimer.one_shot = true
	
	MetSys.room_changed.connect(_on_room_changed, CONNECT_DEFERRED)


func _draw():
	currentState.Draw()


func _physics_process(delta: float) -> void:
	if !rewinding:
		
		if !blaster && "blaster" in abilities:
			blaster = true
		
		# Get input states
		GetInputStates()
		
		if keyDropDown:
			set_collision_mask_value(4, false)
		
		if Input.is_action_just_pressed("Shoot"):
			ShootBlaster()
		
		# Update the current state
		currentState.Update(delta)
		HandleMaxFallVelocity()
		# Commit movement
		move_and_slide()
		
		# Update squish
		UpdateSquish()
		
		# Handle areas of damage
		if in_hurt_zone && !invulnerable:
			damage_player()
			
		if saving_rewind:
			if frame_count == 0:
				if rewind_values["position"].size() > 240:
					for key in rewind_values.keys():
						rewind_values[key].pop_front()
				
				rewind_values["position"].append(global_position)
				rewind_values["animation"].append($Sprite.animation)
				rewind_values["frame"].append($Sprite.frame)
				rewind_values["MetSysposition"].append(MetSys.last_player_position)
				rewind_values["flip_h"].append(Sprite.flip_h)
				MetSysposition = MetSys.last_player_position
			frame_count += 1
			if frame_count >= 2: frame_count = 0
		
		# Handle aiming direction
		HandleAim()
		
		# Handle State Changes
		HandleStateChange()
		
		if keyDropDown:
			await get_tree().create_timer(0.25).timeout
			set_collision_mask_value(4, true)
		
	else:
		if frame_count == 0:
			global_position = rewind_values["position"].pop_back()
			$Sprite.animation = rewind_values["animation"].pop_back()
			$Sprite.frame = rewind_values["frame"].pop_back()
			$Sprite.flip_h = rewind_values["flip_h"].pop_back()
			var temp = rewind_values["MetSysposition"].pop_back() 
			if temp != MetSysposition:
				MetSys.visit_cell(temp)
				MetSys.cell_changed.emit(temp)
			if rewind_values["position"].is_empty(): rewinding = false
		frame_count += 1
		if frame_count >= 2: frame_count = 0


#endregion

func trigger_rewind() -> void:
	frame_count = 0
	rewinding = true
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(0.5)
	tween.tween_property(Game.get_singleton().fdb_rect, "self_modulate:a", 1.0, 5.0)
	tween.tween_callback(trigger_restart)

func trigger_death() -> void:
	dying = true
	ChangeState(States.LockedDeath)
	velocity = Vector2.ZERO
	$Collider.set_deferred("disabled", true)
	await get_tree().create_timer(1.25).timeout
	trigger_rewind()
	
func trigger_restart() -> void:
	get_tree().reload_current_scene()

#region Player Functions


func HorizontalMovement(acceleration: float = Acceleration, deceleration: float = Deceleration):
	moveDirectionX = Input.get_axis("Left", "Right")
	if dying: moveDirectionX = 0
	var targetSpeed = moveDirectionX * moveSpeed
	if keyLock: targetSpeed = 0
	if (moveDirectionX != 0):
		velocity.x = move_toward(velocity.x, targetSpeed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, targetSpeed, deceleration)

func HorizontalAutoMovement() -> void:
	velocity.x = move_toward(velocity.x, 0.0, GroundDeceleration)

func HandleFalling():
	# See if we walked off a ledge
	if (!is_on_floor()):
		# Start the coyote timer
		CoyoteTimer.start(CoyoteTime)
		ChangeState(States.Fall)


func HandleMaxFallVelocity():
	if (velocity.y > MaxFallVelocity): velocity.y = MaxFallVelocity


func HandleJumpBuffer():
	if (keyJumpPressed):
		JumpBufferTimer.start(JumpBufferTime)


func HandleGravity(delta, gravity: float = GravityJump):
	if !dying:
		velocity.y += gravity * delta


func HandleJump():
	# Handle jump
	if (is_on_floor()):
		if (jumps < MaxJumps):
			#if JumpBufferTimer.time_left > 0 : breakpoint
			if (keyJumpPressed or JumpBufferTimer.time_left > 0):
				jumps += 1
				JumpBufferTimer.stop()
				ChangeState(States.Jump)
	else:
		# Handle air jumps if MaxJumps > 1, first jump must be on the ground
		if ((jumps < MaxJumps) and (jumps > 0) and keyJumpPressed):
			jumps += 1
			ChangeState(States.Jump)
		
		# Handle coyote time jumps
		if (CoyoteTimer.time_left > 0):
			if ((keyJumpPressed) and (jumps < MaxJumps)):
				CoyoteTimer.stop()
				jumps += 1
				ChangeState(States.Jump)


func HandleLanding():
	if (is_on_floor()):
		jumps = 0
		dashes = 0
		climbStamina = MaxClimbStamina
		ChangeState(States.Idle)


func HandleWallJump():
	if !abilities.has("walljump"): return
	GetWallDirection()
	if ((keyJumpPressed or (JumpBufferTimer.time_left > 0)) and (wallDirection != Vector2.ZERO)):
		ChangeState(States.WallJump)


func HandleWallSlide():
	if !abilities.has("walljump"): return
	if (((wallDirection == Vector2.LEFT and keyLeft) and (RCWallClimbLeft.is_colliding() and RCWallKickLeft.is_colliding()))
		or ((wallDirection == Vector2.RIGHT and keyRight) and (RCWallClimbRight.is_colliding() and RCWallKickRight.is_colliding()))):
			if (!keyJump):
				ChangeState(States.WallSlide)


func HandleWallGrab():
	if !abilities.has("walljump"): return
	GetCanWallClimb()
	if (wallClimbDirection != Vector2.ZERO):
		if (keyClimb and (climbStamina > 0)):
			ChangeState(States.WallGrab)


func HandleWallRelease():
	if (!keyClimb or (climbStamina <= 0)):
		ChangeState(States.Fall)


func GetWallDirection():
	if (RCWallKickRight.is_colliding()):
		wallDirection = Vector2.RIGHT
	elif (RCWallKickLeft.is_colliding()):
		wallDirection = Vector2.LEFT
	else:
		wallDirection = Vector2.ZERO


func GetCanWallClimb():
	if (RCWallKickLeft.is_colliding() and RCWallClimbLeft.is_colliding()):
		wallClimbDirection = Vector2.LEFT
	elif (RCWallKickRight.is_colliding() and RCWallClimbRight.is_colliding()):
		wallClimbDirection = Vector2.RIGHT
	else:
		wallClimbDirection = Vector2.ZERO


func HandleDash():
	if !abilities.has("dash") : return
	if (dashes < MaxDashes):
		if (keyDash):
			if (DashTimer.time_left <= 0):
				DashTimer.start(DashBufferTime)
				await DashTimer.timeout
				dashes += 1
				ChangeState(States.Dash)


func GetDashDirection() -> Vector2:
	var _dir = Vector2.ZERO
	if (!keyLeft and !keyRight and !keyUp and !keyDown):
		_dir = Vector2(facing, 0)
	else:
		_dir = Vector2(Input.get_axis("Left", "Right"), Input.get_axis("Up", "Down"))
	return _dir


func GetInputStates():
	if !dying:
		keyUp = Input.is_action_pressed("Up")
		keyDown = Input.is_action_pressed("Down")
		keyLeft = Input.is_action_pressed("Left")
		keyRight = Input.is_action_pressed("Right")
		keyLock = Input.is_action_pressed("Lock In Place")
		keyJump = Input.is_action_pressed("Jump") # && (!Input.is_action_pressed("Down") || !is_on_floor())
		keyJumpPressed = Input.is_action_just_pressed("Jump") # && (!Input.is_action_pressed("Down") || !is_on_floor())
		keyDropDown = Input.is_action_just_pressed("Jump") && (Input.is_action_pressed("Down") && is_on_floor())
		keyClimb = Input.is_action_pressed("Climb")
		keyDash = Input.is_action_just_pressed("Dash")
		
		if (keyLeft): facing = -1
		if (keyRight): facing = 1
		# Handle the sprite x-scale
		Sprite.flip_h = (facing < 0)
	else:
		keyUp = false
		keyDown = false
		keyLeft = false
		keyRight = false
		keyLock = false
		keyJump = false
		keyJumpPressed = false
		keyDropDown = false
		keyClimb = false
		keyDash = false


var test = 0
func ChangeState(targetState):
	if targetState == States.Idle && nextState == States.Jump: return
	if dying && targetState != States.LockedDeath: return
	if (targetState):
		nextState = targetState


func HandleStateChange():
	if hurting: return
	if (nextState != null):
		#print ("changing state to : " + nextState.Name)
		if (currentState != nextState):
			previousState = currentState
			currentState.ExitState()
			currentState = null
			currentState = nextState
			currentState.EnterState()
		nextState = null


func UpdateSquish():
	Sprite.scale.x = squishX
	Sprite.scale.y = squishY
	
	if (squishX != 1.0): squishX = move_toward(squishX, 1.0, squishStep)
	if (squishY != 1.0): squishY = move_toward(squishY, 1.0, squishStep)


func SetSquish(_squishX: float = 1.0, _squishY: float = 1.0, _step: float = squishStep):
	squishX = _squishX if (_squishX != 0) else 1.0
	squishY = _squishY if (_squishY != 0) else 1.0
	squishStep = _step if (_step != 0) else squishStep


func HandleFlipH():
	Sprite.flip_h = (facing < 1)


#endregion

func on_enter():
	# Position for kill system. Assigned when entering new room (see Game.gd).
	reset_position = position

func start_hurt_timer() -> void:
	$Timers/HurtStunTimer.start()

func start_invul_timer() -> void:
	$Timers/InvulTimer.start()

func _on_hurt_stun_timer_timeout() -> void:
	hurting = false

func _on_invul_timer_timeout() -> void:
	invulnerable = false

func try_damage_player() -> void:
	if !invulnerable:
		damage_player()

func damage_player() -> void:
	ChangeState(States.Locked)

var direction = ""
var degrees = 0

func HandleAim() -> void:
	var angle = Input.get_vector("Left", "Right", "Down", "Up", 0.3)
	if angle == Vector2.ZERO: 
		if $Sprite.flip_h: angle = Vector2.LEFT
		else: angle = Vector2.RIGHT
	degrees = rad_to_deg(angle.angle())
	degrees = round(degrees / 45) * 45
	direction = ""
	if degrees == 90: direction = "up"
	elif degrees == 45 || degrees == 135: direction = "upright"
	elif degrees == -45 || degrees == -135: direction = "downright"
	elif degrees == -90: direction = "down"

@onready var spawn_points = {
	"0": $ShootEmitters/Right,
	"45": $ShootEmitters/UpRight,
	"90": $ShootEmitters/Up,
	"-45": $ShootEmitters/DownRight,
	"-90": $ShootEmitters/Down,
	"135": $ShootEmitters/UpLeft,
	"-135": $ShootEmitters/DownLeft,
	"180": $ShootEmitters/Left,
	"-180": $ShootEmitters/Left
}

func ShootBlaster() -> void:
	if !blaster: return
	if $Timers/ShootCDTimer.time_left > 0: return
	$Timers/ShootCDTimer.start()
	var projectile = preload("res://scene_templates/projectile.tscn").instantiate()
	projectile.angle = degrees * -1.0
	var spawn_point = $ShootEmitters/Right
	var key = str(degrees)
	if spawn_points.has(key): 
		spawn_point = spawn_points[key]
	projectile.position = spawn_point.global_position
	Game.get_singleton().add_child(projectile)

func _on_room_changed(_target_room: String) -> void:
	invulnerable = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "invulnerable", false, 0.15)
