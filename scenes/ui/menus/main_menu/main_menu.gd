class_name MainMenu
extends Control

signal hosted
signal joined

func host():
    var host_info = _parse_input()
    if host_info.size() == 0:
        return ERR_CANT_RESOLVE

    var port = host_info.port

    # Start host
    print("Starting host on port %s" % port)
    
    var peer = ENetMultiplayerPeer.new()
    if peer.create_server(port) != OK:
        print("Failed to listen on port %s" % port)

    get_tree().get_multiplayer().multiplayer_peer = peer
    print("Listening on port %s" % port)
    
    # Wait for server to start
    await async_condition(
        func():
            return peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING
    )

    if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
        OS.alert("Failed to start server!")
        return

    get_tree().get_multiplayer().server_relay = true

    hosted.emit()


func _parse_input() -> Dictionary:
    # Validate inputs
    var address = %AddressLineEdit.text
    var port = %PortLineEdit.text
    
    if address == "":
        OS.alert("No host specified!")
        return {}
        
    if not port.is_valid_int():
        OS.alert("Invalid port!")
        return {}
    port = port.to_int()

    return {
        "address": address,
        "port": port
    }


func join():
    var host_info = _parse_input()
    if host_info.size() == 0:
        return ERR_CANT_RESOLVE
        
    var address = host_info.address
    var port = host_info.port

    # Connect
    print("Connecting to %s:%s" % [address, port])
    var peer = ENetMultiplayerPeer.new()
    var err = peer.create_client(address, port)
    if err != OK:
        OS.alert("Failed to create client, reason: %s" % error_string(err))
        return err

    get_tree().get_multiplayer().multiplayer_peer = peer
    
    # Wait for connection process to conclude
    await async_condition(
        func():
            return peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTING
    )

    if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
        OS.alert("Failed to connect to %s:%s" % [address, port])
        return

    joined.emit()


func async_condition(cond: Callable, timeout: float = 10.0) -> Error:
    timeout = Time.get_ticks_msec() + timeout * 1000
    while not cond.call():
        await get_tree().process_frame
        if Time.get_ticks_msec() > timeout:
            return ERR_TIMEOUT
    return OK


func _on_host_button_pressed() -> void:
    host()


func _on_join_button_pressed() -> void:
    join()