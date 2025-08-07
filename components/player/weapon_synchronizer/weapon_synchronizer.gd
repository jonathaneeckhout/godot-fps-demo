class_name WeaponSynchronizer
extends Node

signal fired(hit: Dictionary)

@export var muzzle: Node3D = null

@onready var fire_action: RewindableAction = %FireAction

var player: Player = null
var player_input: PlayerInput = null
var rollback_synchronizer: RollbackSynchronizer = null

var weapon: Weapon = null

var last_fire: int = -1
var firing: bool = false

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Player not found")

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "PlayerInput not found")

    rollback_synchronizer = player.get_node_or_null("RollbackSynchronizer")
    assert(rollback_synchronizer != null, "RollbackSynchronizer not found")

    assert(muzzle != null, "Muzzle not set")

    fire_action.mutate(self) # Mutate self, so firing code can run
    # fire_action.mutate(player) # Mutate player

    NetworkTime.after_tick_loop.connect(_after_loop)

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool) -> void:
    if rollback_synchronizer.is_predicting():
        return

    fire_action.set_active(player_input.fire and _can_fire())

    firing = player_input.fire

    match fire_action.get_status():
        RewindableAction.CONFIRMING, RewindableAction.ACTIVE:
            # Fire if action has just activated or is active
            _fire()
        RewindableAction.CANCELLING:
            # Whoops, turns out we couldn't have fired, undo
            _unfire()

func load_weapon(new_weapon: Weapon) -> void:
    unload_weapon()

    weapon = new_weapon
    weapon.muzzle = muzzle

func unload_weapon() -> void:
    if weapon == null:
        return

    weapon.muzzle = null
    weapon = null

func _after_loop() -> void:
    if fire_action.has_confirmed():
        if weapon:
            weapon.fire_confirmed()


func _can_fire() -> bool:
    # You can only fire a weapon
    if weapon == null:
        return false

    # Only fire if the player released the fire button
    if not weapon.automatic and firing:
        return false

    return NetworkTime.seconds_between(last_fire, NetworkRollback.tick) >= weapon.fire_cooldown

func _fire() -> void:
    if weapon == null:
        return
    
    last_fire = NetworkRollback.tick

    var hit: Dictionary = weapon.fire()
    if hit.is_empty():
        return

    fired.emit(hit)

    _on_hit(hit)

func _unfire():
    fire_action.erase_context()

func _on_hit(hit: Dictionary):
    var is_new_hit := false
    if not fire_action.has_context():
        fire_action.set_context(true)
        is_new_hit = true

    print(hit)
