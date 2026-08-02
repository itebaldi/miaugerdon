extends Node2D


func _ready() -> void:
	# roda depois do _ready() dos filhos, então a HUD já está ligada nos sinais
	Jogo.iniciar_partida()
