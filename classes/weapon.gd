class_name Weapon
extends Node3D

static var _logger: _NetfoxLogger = _NetfoxLogger.for_netfox("RollbackSynchronizer")

enum WEAPON_TYPES {PRIMARY, SECONDARY}

signal fired()

## What type of weapon it is
@export var type: WEAPON_TYPES = WEAPON_TYPES.PRIMARY

## Time between 2 shots
@export var fire_cooldown: float = 1.0

## Damage done by a bullet
@export var damage: int = 10

## If automatic fire is enabled
@export var automatic: bool = false

@export var muzzle: Node3D = null


func fire() -> Dictionary:
    assert(muzzle != null, "Muzzle can't be null")

    return _detect_hit()

func fire_confirmed() -> void:
    pass

func _detect_hit() -> Dictionary:
    var space := get_world_3d().direct_space_state

    var origin_xform: Transform3D = muzzle.global_transform

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        origin_xform.origin,
        origin_xform.origin + origin_xform.basis.z * 1024.
    )

    return space.intersect_ray(query)

func connect_to_weapon_synchronizer(weapon_synchronizer: WeaponSynchronizer) -> void:
    weapon_synchronizer.fired.connect(_on_fired)

func _on_fired() -> void:
    pass
