class_name PlayerInput
extends Node

@export var mouse_sensitivity: float = 0.4

var direction: Vector2 = Vector2.ZERO
var look_angle: Vector2 = Vector2.ZERO
var jump: bool = false
var fire: bool = false

var _mouse_rotation: Vector2 = Vector2.ZERO

func _ready() -> void:
    NetworkTime.before_tick_loop.connect(_gather)

    if !is_multiplayer_authority():
        # Don't process input for other players
        set_process_input(false)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _mouse_rotation.y = event.relative.x * mouse_sensitivity
        _mouse_rotation.x = -event.relative.y * mouse_sensitivity

func _gather() -> void:
    direction = Input.get_vector("strafe_right", "strafe_left", "move_down", "move_up")
    
    look_angle = Vector2(-_mouse_rotation.y * NetworkTime.ticktime, -_mouse_rotation.x * NetworkTime.ticktime)
    _mouse_rotation = Vector2.ZERO

    jump = Input.is_action_pressed("jump")
    fire = Input.is_action_pressed("fire")
