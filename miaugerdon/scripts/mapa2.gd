extends Node2D


func _ready() -> void:
	# a noite acabou no colo do Alfredo, no sofá: é ali que o Caju acorda
	if Jogo.dia > 1:
		$Caju.global_position = $PontoManha.global_position
	Jogo.iniciar_partida()
