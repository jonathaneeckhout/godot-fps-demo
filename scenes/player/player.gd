class_name Player
extends CharacterBody3D

@export var speed: float = 8.0
@export var jump_force: float = 5.0

@export var model: Node3D = null
@export var head: Node3D = null
@export var hands: Node3D = null

var peer_id: int = 0

var player_input: PlayerInput = null
var weapon_synchronizer: WeaponSynchronizer = null
var weapon_handler: WeaponHandler = null

func _ready() -> void:
    assert(model != null, "Model is not set")
    assert(head != null, "Head is not set")
    assert(hands != null, "Hands not set")

    player_input = get_node_or_null("PlayerInput")
    assert(player_input != null, "Player input missing")

    weapon_synchronizer = get_node_or_null("WeaponSynchronizer")
    assert(weapon_synchronizer != null, "WeaponSynchronizer missing")

    weapon_handler = get_node_or_null("WeaponHandler")
    assert(weapon_handler != null, "WeaponHandler missing")

    # #TODO: remove debug code
    weapon_handler.add_weapon(load("res://scenes/weapons/pistol/pistol.tscn").instantiate())
    weapon_handler.add_weapon(load("res://scenes/weapons/rifle/rifle.tscn").instantiate())

    if peer_id == multiplayer.get_unique_id():
        model.hide()
    else:
        hands.hide()
        %HUDCanvasLayer.hide()

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool) -> void:
    # Handle look left and right
    rotate_object_local(Vector3(0, 1, 0), player_input.look_angle.x)

    # Handle look up and down
    head.rotate_object_local(Vector3(1, 0, 0), player_input.look_angle.y)

    head.rotation.x = clamp(head.rotation.x, -1.57, 1.57)
    head.rotation.z = 0
    head.rotation.y = 0
    
    # Apply movement
    var input_dir: Vector2 = player_input.direction
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    if is_on_floor() and player_input.jump:
        velocity.y = jump_force
    else:
        velocity += get_gravity() * NetworkTime.ticktime

    # move_and_slide assumes physics delta
    # multiplying velocity by NetworkTime.physics_factor compensates for it
    velocity *= NetworkTime.physics_factor
    move_and_slide()
    velocity /= NetworkTime.physics_factor
