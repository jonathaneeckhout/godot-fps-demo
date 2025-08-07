class_name WeaponHandler
extends Node

static var _logger: _NetfoxLogger = _NetfoxLogger.for_netfox("RollbackSynchronizer")

## Where to put the weapon for the local player
@export var local_player_weapon_location: Node3D = null

## Where to put the weapon for other players
@export var other_player_weapon_location: Node3D = null

## The weapon which the player starts with
@export var starter_weapon: PackedScene = null

var player: Player = null
var player_input: PlayerInput = null
var weapon_synchronizer: WeaponSynchronizer = null

var primary_weapon: Weapon = null
var secondary_weapon: Weapon = null

var current_weapon: Weapon

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Can't get Player")

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "Missing PlayerInput")

    weapon_synchronizer = player.get_node_or_null("WeaponSynchronizer")
    assert(weapon_synchronizer != null, "Missing WeaponSynchronizer")

    assert(starter_weapon != null, "Please select a starter weapon")

    load_primary_weapon(starter_weapon)

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool) -> void:
    if player_input.next_weapon:
        _logger.debug("on {0} for {1}".format([multiplayer.get_unique_id(), player.peer_id]))
        swap_weapons(true)

    if player_input.previous_weapon:
        swap_weapons(false)

func swap_weapons(up: bool) -> void:
    if up:
        if current_weapon == primary_weapon:
            set_current_weapon(secondary_weapon)
    else:
        if current_weapon == secondary_weapon:
            set_current_weapon(primary_weapon)

func load_primary_weapon(weapon: PackedScene) -> void:
    if primary_weapon != null:
        primary_weapon.queue_free()

    primary_weapon = weapon.instantiate()

    primary_weapon.hide()

    if player.peer_id == multiplayer.get_unique_id():
        local_player_weapon_location.add_child(primary_weapon)
    else:
        other_player_weapon_location.add_child(primary_weapon)

    if current_weapon == null:
        set_current_weapon(primary_weapon)

func load_secondary_weapon(weapon: PackedScene) -> void:
    if secondary_weapon != null:
        secondary_weapon.queue_free()

    secondary_weapon = weapon.instantiate()
    secondary_weapon.hide()

    if player.peer_id == multiplayer.get_unique_id():
        local_player_weapon_location.add_child(secondary_weapon)
    else:
        other_player_weapon_location.add_child(secondary_weapon)

    if current_weapon == null:
        set_current_weapon(secondary_weapon)

func set_current_weapon(weapon: Weapon) -> void:
    if current_weapon != null:
        current_weapon.hide()

    current_weapon = weapon

    current_weapon.show()

    weapon_synchronizer.load_weapon(weapon)
