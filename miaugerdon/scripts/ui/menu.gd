extends Control

const CENA_ABERTURA := "res://cenas/ui/abertura.tscn"


func _ready() -> void:
	%BotaoJogar.pressed.connect(_jogar)
	%BotaoSair.pressed.connect(get_tree().quit)
	%BotaoJogar.grab_focus()


func _jogar() -> void:
	# a abertura é quem carrega o mapa depois, e marca a intro como vista
	get_tree().change_scene_to_file(CENA_ABERTURA)
