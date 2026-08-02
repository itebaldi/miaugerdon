extends Control

const CENA_JOGO := "res://cenas/mapa2.tscn"


func _ready() -> void:
	%BotaoJogar.pressed.connect(_jogar)
	%BotaoSair.pressed.connect(get_tree().quit)
	%BotaoJogar.grab_focus()


func _jogar() -> void:
	get_tree().change_scene_to_file(CENA_JOGO)
