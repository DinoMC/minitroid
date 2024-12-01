extends CharacterBody2D

#region Player Variables

# Nodes
@onready var Sprite = $Sprite
@onready var Animator = $Animator
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
const JumpVelocity = -240
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
var keyJump = false
var keyJumpPressed = false
var keyClimb = false
var keyDash = false

# State Machine
var currentState = null
var previousState = null
var nextState = null

#endregion

#region Game Loop Functions

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


func _draw():
	currentState.Draw()


func _physics_process(delta: float) -> void:
	# Get input states
	GetInputStates()
	
	# Update the current state
	currentState.Update(delta)
	HandleMaxFallVelocity()
	# Commit movement
	move_and_slide()
	
	# Update squish
	UpdateSquish()
	
	# Handle State Changes
	HandleStateChange()


#endregion


#region Player Functions


func HorizontalMovement(acceleration: float = Acceleration, deceleration: float = Deceleration):
	moveDirectionX = Input.get_axis("Left", "Right")
	if (moveDirectionX != 0):
		velocity.x = move_toward(velocity.x, moveDirectionX * moveSpeed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, moveDirectionX * moveSpeed, deceleration)


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
	velocity.y += gravity * delta


func HandleJump():
	# Handle jump
	if (is_on_floor()):
		if (jumps < MaxJumps):
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
	GetWallDirection()
	if ((keyJumpPressed or (JumpBufferTimer.time_left > 0)) and (wallDirection != Vector2.ZERO)):
		ChangeState(States.WallJump)


func HandleWallSlide():
	if (((wallDirection == Vector2.LEFT and keyLeft) and (RCWallClimbLeft.is_colliding() and RCWallKickLeft.is_colliding()))
		or ((wallDirection == Vector2.RIGHT and keyRight) and (RCWallClimbRight.is_colliding() and RCWallKickRight.is_colliding()))):
			if (!keyJump):
				ChangeState(States.WallSlide)


func HandleWallGrab():
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
	keyUp = Input.is_action_pressed("Up")
	keyDown = Input.is_action_pressed("Down")
	keyLeft = Input.is_action_pressed("Left")
	keyRight = Input.is_action_pressed("Right")
	keyJump = Input.is_action_pressed("Jump")
	keyJumpPressed = Input.is_action_just_pressed("Jump")
	keyClimb = Input.is_action_pressed("Climb")
	keyDash = Input.is_action_just_pressed("Dash")
	
	if (keyLeft): facing = -1
	if (keyRight): facing = 1
	# Handle the sprite x-scale
	Sprite.flip_h = (facing < 0)


func ChangeState(targetState):
	if (targetState):
		nextState = targetState


func HandleStateChange():
	if (nextState != null):
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
