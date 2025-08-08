class_name HealthSynchronizer
extends Node

signal health_changed(hp: int, amount: int)

@export var max_health: int = 100

# Synced states
var health: int = 100

# Locall Variables
var player: Player = null
var rollback_synchronizer: RollbackSynchronizer = null
var last_synced_health: int = health

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Player not found")

    rollback_synchronizer = player.get_node_or_null("RollbackSynchronizer")
    assert(rollback_synchronizer != null, "RollbackSynchronizer not found")

    rollback_synchronizer.add_state(self, "health")

func _process(_delta: float) -> void:
    if last_synced_health != health:
        health_changed.emit(health, last_synced_health - health)
        last_synced_health = health

func _rollback_tick(_delta: float, _tick: int, _is_fresh: bool) -> void:
    # Modify health value
    pass

func hurt(amount: int) -> void:
    health = clamp(0, health - amount, max_health)

    print(health)

func heal(amount: int) -> void:
    health = clamp(0, health + amount, max_health)
