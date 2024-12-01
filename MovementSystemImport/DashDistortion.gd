extends Control

@onready var Animator: AnimationPlayer = $Animator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Animator.play("Distort")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	await Animator.animation_finished
	Animator.stop()
	queue_free()
