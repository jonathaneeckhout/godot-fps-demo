extends Node3D

@export var map_scene: PackedScene = null

func _ready() -> void:
    assert(map_scene != null, "Please set a map scene")

func _on_main_menu_hosted() -> void:
    get_window().title = "GFD (Server)"

    %MainMenu.hide()

func _on_main_menu_joined() -> void:
    get_window().title = "GFD (Client)"

    %MainMenu.hide()
