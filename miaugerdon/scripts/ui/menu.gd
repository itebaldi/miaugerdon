extends Control

const CENA_ABERTURA := "res://cenas/ui/abertura.tscn"


func _ready() -> void:
	%BotaoJogar.pressed.connect(_jogar)
	%BotaoSair.pressed.connect(get_tree().quit)
	%BotaoJogar.grab_focus()
	# segue tocando pela HQ de abertura; a partida troca sozinha quando começa
	Musica.tocar(&"menu")


func _jogar() -> void:
	Efeitos.tocar(&"botao")
	# a abertura é quem carrega o mapa depois, e marca a intro como vista
	get_tree().change_scene_to_file(CENA_ABERTURA)
