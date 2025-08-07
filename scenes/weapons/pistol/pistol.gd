class_name Pistol
extends Weapon


func _ready() -> void:
    fire_cooldown = 1.0
    damage = 30
    automatic = false

    fired.connect(_on_fired)

func _on_fired() -> void:
    %Blast.show()
    %BlastTimer.start()

func _on_blast_timer_timeout() -> void:
    %Blast.hide()
