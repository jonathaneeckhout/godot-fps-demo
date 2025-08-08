class_name Rifle
extends Weapon

func _on_fired(_hit: Dictionary) -> void:
    %Blast.show()
    %BlastTimer.start()

func _on_blast_timer_timeout() -> void:
    %Blast.hide()