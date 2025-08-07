class_name PlayerInput
extends Node

@export var mouse_sensitivity: float = 0.4

var direction: Vector2 = Vector2.ZERO
var look_angle: Vector2 = Vector2.ZERO
var jump: bool = false
var fire: bool = false
var next_weapon: bool = false
var previous_weapon: bool = false

var _override_mouse: bool = false
var _mouse_rotation: Vector2 = Vector2.ZERO
var _wheel_up: bool = false
var _wheel_down: bool = false

var player: Player = null
var rollback_synchronizer: RollbackSynchronizer = null

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Player not found")
    
    rollback_synchronizer = player.get_node_or_null("RollbackSynchronizer")
    assert(rollback_synchronizer != null, "RollbackSynchronizer is not found")

    rollback_synchronizer.add_input(self, "direction")
    rollback_synchronizer.add_input(self, "look_angle")
    rollback_synchronizer.add_input(self, "jump")
    rollback_synchronizer.add_input(self, "fire")
    rollback_synchronizer.add_input(self, "next_weapon")
    rollback_synchronizer.add_input(self, "previous_weapon")

    NetworkTime.before_tick_loop.connect(_gather)

    if !is_multiplayer_authority():
        # Don't process input for other players
        set_process_input(false)
        return

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _mouse_rotation.y = event.relative.x * mouse_sensitivity
        _mouse_rotation.x = - event.relative.y * mouse_sensitivity

    if event.is_action_pressed("escape"):
        _override_mouse = !_override_mouse

        if _override_mouse:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    if event is InputEventMouseButton:
        if event.is_pressed():
            if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                _wheel_up = true
            elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                _wheel_down = true

func _gather() -> void:
    direction = Input.get_vector("strafe_right", "strafe_left", "move_down", "move_up")

    if _override_mouse:
        look_angle = Vector2.ZERO
    else:
        look_angle = Vector2(-_mouse_rotation.y * NetworkTime.ticktime, -_mouse_rotation.x * NetworkTime.ticktime)

    _mouse_rotation = Vector2.ZERO

    jump = Input.is_action_pressed("jump")
    
    fire = Input.is_action_pressed("fire")

    next_weapon = _wheel_up
    previous_weapon = _wheel_down

    _wheel_up = false
    _wheel_down = false
