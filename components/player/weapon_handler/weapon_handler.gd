class_name WeaponHandler
extends Node3D

## Where to put the weapon for the local player
@export var local_player_weapon_location: Node3D = null

## Where to put the weapon for other players
@export var other_player_weapon_location: Node3D = null

# Dependencies
var player: Player = null
var player_input: PlayerInput = null
var weapon_synchronizer: WeaponSynchronizer = null
var rollback_synchronizer: RollbackSynchronizer = null

# Synced States
var current_weapon: String = ""

# Local Variables
var primary_weapon: Weapon = null
var secondary_weapon: Weapon = null
var loaded_weapon: Weapon = null

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Can't get Player")

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "Missing PlayerInput")

    weapon_synchronizer = player.get_node_or_null("WeaponSynchronizer")
    assert(weapon_synchronizer != null, "Missing WeaponSynchronizer")

    rollback_synchronizer = player.get_node_or_null("RollbackSynchronizer")
    assert(rollback_synchronizer != null, "Missing RollbackSynchronizer")

    rollback_synchronizer.add_state(self, "current_weapon")

func add_weapon(new_weapon: Weapon) -> void:
    match new_weapon.type:
        Weapon.WEAPON_TYPES.PRIMARY:
            if primary_weapon != null:
                primary_weapon.queue_free()

            primary_weapon = new_weapon

            %LoadedWeapons.add_child(primary_weapon)

            swap_weapons(false)
        Weapon.WEAPON_TYPES.SECONDARY:
            if secondary_weapon != null:
                secondary_weapon.queue_free()

            secondary_weapon = new_weapon

            %LoadedWeapons.add_child(secondary_weapon)

            swap_weapons(true)

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool) -> void:
    if player_input.next_weapon:
        swap_weapons(true)

    if player_input.previous_weapon:
        swap_weapons(false)

func swap_weapons(up: bool) -> void:
    var new_weapon: Weapon = null
    if up:
        new_weapon = primary_weapon
    else:
        new_weapon = secondary_weapon
    
    if new_weapon != null:
        if current_weapon != new_weapon.name:
            weapon_synchronizer.load_weapon(new_weapon)

        current_weapon = new_weapon.name

func _process(_delta: float) -> void:
    load_weapon()
    
func load_weapon() -> void:
    if loaded_weapon != null and loaded_weapon.name != current_weapon:
        loaded_weapon.queue_free()
        loaded_weapon = null
    

    if loaded_weapon == null and current_weapon != "":
        loaded_weapon = %LoadedWeapons.get_node_or_null(current_weapon).duplicate()
        loaded_weapon.connect_to_weapon_synchronizer(weapon_synchronizer)
        if player.peer_id == multiplayer.get_unique_id():
            local_player_weapon_location.add_child(loaded_weapon)
        else:
            other_player_weapon_location.add_child(loaded_weapon)
