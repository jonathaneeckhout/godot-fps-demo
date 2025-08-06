class_name PlayerSpawner
extends Node


@export var player_scene: PackedScene = null
@export var players_node: Node3D = null
@export var spawn_points: Node3D = null

var players: Dictionary[int, Player] = {}

func _ready():
    assert(player_scene != null, "Please select player scene")
    assert(players_node != null, "Please select players node")
    assert(spawn_points != null, "Please select spawn points")

    NetworkEvents.on_client_start.connect(_handle_connected)
    NetworkEvents.on_server_start.connect(_handle_host)
    NetworkEvents.on_peer_join.connect(_handle_new_peer)
    NetworkEvents.on_peer_leave.connect(_handle_leave)
    NetworkEvents.on_client_stop.connect(_handle_stop)
    NetworkEvents.on_server_stop.connect(_handle_stop)

func _handle_connected(id: int):
    # Spawn an avatar for us
    _spawn(id)

func _handle_host():
    # Spawn own avatar on host machine
    _spawn(1)

func _handle_new_peer(id: int):
    # Spawn an avatar for new player
    _spawn(id)

func _handle_leave(id: int):
    if not players.has(id):
        return

    var player: Player = players[id]
    player.queue_free()

    players.erase(id)

func _handle_stop():
    # Remove all avatars on game end
    for player: Player in players.values():
        player.queue_free()

    players.clear()

func _spawn(id: int):
    var player: Player = player_scene.instantiate()
    players[id] = player
    player.name += " #%d" % id
    player.peer_id = id

    player.position = get_next_spawn_point(id)

    # Player is always owned by server
    player.set_multiplayer_authority(1)

    print("Spawned player %s at %s" % [player.name, multiplayer.get_unique_id()])
    
    # player's input object is owned by player
    var player_input: PlayerInput = player.find_child("PlayerInput")
    assert(player_input != null, "Player's should have a player input component")

    player_input.set_multiplayer_authority(id)
    print("Set input(%s) ownership to %s" % [player_input.name, id])

    players_node.add_child(player)


func get_next_spawn_point(peer_id: int, spawn_idx: int = 0) -> Vector3:
    var spawn_points_children = spawn_points.get_children() as Array[Node3D]
    # The same data is used to calculate the index on all peers
    # As a result, spawn points are the same, even without sync
    var idx := peer_id * 37 + spawn_idx * 19
    idx = hash(idx)
    idx = idx % spawn_points_children.size()

    return spawn_points_children[idx].position
