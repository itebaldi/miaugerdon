extends Control

## Tela inicial. É a cena principal do projeto (Projeto → Configurações → Cena Principal),
## então é o que abre com F5.

const CENA_JOGO := "res://cenas/mapa2.tscn"


func _ready() -> void:
	%BotaoJogar.pressed.connect(_jogar)
	%BotaoSair.pressed.connect(_sair)
	%BotaoJogar.grab_focus()


func _jogar() -> void:
	get_tree().change_scene_to_file(CENA_JOGO)


func _sair() -> void:
	get_tree().quit()
