class_name Rifle
extends Weapon

func _on_fired() -> void:
    %Blast.show()
    %BlastTimer.start()

func _on_blast_timer_timeout() -> void:
    %Blast.hide()