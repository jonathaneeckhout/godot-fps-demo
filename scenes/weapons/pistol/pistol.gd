extends Node3D

@export var fire_cooldown: float = 0.25
@export var damage: int = 35

@export var sync_network: bool = true
@export var player: Player = null
@export var player_input: PlayerInput = null
@export var muzzle: Node3D = null

@export var rollback_synchronizer: RollbackSynchronizer = null

@onready var fire_action: RewindableAction = %FireAction

var last_fire: int = -1

func _ready():
    if not sync_network:
        return

    assert(player != null, "Player is not set")
    assert(player_input != null, "PlayerInput is not set")
    assert(rollback_synchronizer != null, "RollbackSynchronizer is not set")
    assert(muzzle != null, "Muzzle is not set")

    fire_action.mutate(self) # Mutate self, so firing code can run
    fire_action.mutate(player) # Mutate player

    NetworkTime.after_tick_loop.connect(_after_loop)

func _rollback_tick(_dt, tick: int, _if):
    if not sync_network:
        return

    if rollback_synchronizer.is_predicting():
        return

    fire_action.set_active(player_input.fire and _can_fire())
    match fire_action.get_status():
        RewindableAction.CONFIRMING, RewindableAction.ACTIVE:
            # Fire if action has just activated or is active
            _fire()
        RewindableAction.CANCELLING:
            # Whoops, turns out we couldn't have fired, undo
            _unfire()

func _after_loop():
    if fire_action.has_confirmed():
        print("player:{0} from: {1}: Pang".format([player.peer_id, multiplayer.get_unique_id()]))

func _can_fire() -> bool:
    return NetworkTime.seconds_between(last_fire, NetworkRollback.tick) >= fire_cooldown

func _fire():
    last_fire = NetworkRollback.tick

    # See what we've hit
    var hit := _raycast()
    if hit.is_empty():
        # No hit, nothing to do
        return

    _on_hit(hit)

func _unfire():
    fire_action.erase_context()

func _raycast() -> Dictionary:
    # Detect hit
    var space := get_world_3d().direct_space_state
    var origin_xform := muzzle.global_transform
    var query := PhysicsRayQueryParameters3D.create(
        origin_xform.origin,
        origin_xform.origin + origin_xform.basis.z * 1024.
    )

    return space.intersect_ray(query)

func _on_hit(result: Dictionary):
    var is_new_hit := false
    if not fire_action.has_context():
        fire_action.set_context(true)
        is_new_hit = true

    print(result.collider)

    # if result.collider.has_method("damage"):
    #     result.collider.damage(damage, is_new_hit)
    #     NetworkRollback.mutate(result.collider)
