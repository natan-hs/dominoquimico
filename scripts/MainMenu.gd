extends Control

func _ready():
	pass

func _on_local_btn_pressed():
	get_tree().change_scene("res://cenas/JogoLocal.tscn")

func _on_emrede_btn_pressed():
	get_tree().change_scene("res://cenas/Lobby.tscn")

func _on_sair_btn_pressed():
	get_tree().quit()