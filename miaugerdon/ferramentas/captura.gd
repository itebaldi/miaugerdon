extends Node

## Tira fotos do jogo em situações escolhidas, para conferir profundidade e interface sem
## precisar jogar.
##
##   godot --path <projeto> --resolution 1152x648 ferramentas/captura.tscn
##
## Precisa rodar COM janela: em --headless não existe renderização e get_image() do viewport
## devolveria nada.

const PASTA := "user://capturas/"

var _cena: Node
var _caju: Node2D
var _camera: Camera2D
var _hud: CanvasLayer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA)
	print("salvando em ", ProjectSettings.globalize_path(PASTA))
	_cena = load("res://cenas/mapa2.tscn").instantiate()
	add_child(_cena)
	_caju = _cena.get_node("Caju")
	_camera = _caju.get_node("Camera2D")
	_hud = _cena.get_node("HUD")

	# O Alfredo atrapalha a leitura da foto: some com ele e trava a IA.
	var alfredo: Node = _cena.get_node("Alfredo")
	alfredo.set_physics_process(false)
	alfredo.visible = false

	await _quadros(20)
	_hud._fechar_tutorial()

	# ── profundidade ────────────────────────────────────────────────────────
	await _foto("01_frente_do_sofa", Vector2(600, 432), "gato NA FRENTE do sofa e do tapete")
	await _foto("02_atras_da_mesa", Vector2(573, 476), "gato ATRAS da mesa de jantar, cabeca aparecendo")
	await _foto("03_atras_da_estante", Vector2(1055, 310), "gato ATRAS da estante do escritorio")
	await _foto("04_frente_da_estante", Vector2(1030, 400), "gato NA FRENTE da estante")
	await _foto("05_mr_t", Vector2(1180, 500), "Mr. T do tamanho do Caju, prompt com acento")
	await _foto("05a_atras_da_parede", Vector2(600, 318), "gato no quarto: parede1 na frente dele")
	await _foto("05b_frente_da_parede", Vector2(600, 372), "gato na sala: parede1 atras dele")
	await _foto("05c_parede_quintal", Vector2(1000, 420), "gato no quintal: parede6 na frente dele")

	# ── interface ───────────────────────────────────────────────────────────
	_caju.global_position = Vector2(600, 432)
	_camera.reset_smoothing()

	# Aqui o Alfredo volta a existir: queremos ver a visão dele funcionando de verdade.
	alfredo.visible = true
	alfredo.set_physics_process(true)
	alfredo.global_position = Vector2(660, 430)   # ao lado do gato, sem nada no meio
	await _quadros(10)
	await _salvar("05d_alfredo_te_vendo")
	print("05d_alfredo_te_vendo  <- aviso 'Alfredo esta te vendo' no alto")
	alfredo.set_physics_process(false)
	alfredo.visible = false
	Jogo.definir_observado(false)

	Jogo.aumentar_suspeita(52.0)                 # faixa MEDIA, barra amarela
	await _foto_ui("06_suspeita_media")

	Jogo.aumentar_suspeita(35.0)                 # faixa ALTA, barra vermelha pulsando
	await _foto_ui("07_suspeita_alta")

	Jogo.conversar("Mr. T", PackedStringArray([
		"Um cachorro? Na SUA casa? Isso é uma invasão. Uma invasão total."]))
	await _foto_ui("08_dialogo")
	_hud._avancar_dialogo()

	Jogo.concluir_objetivo("mr_t")
	Jogo.concluir_objetivo("papel_caneta")
	_hud._alternar_inventario()
	await _foto_ui("09_inventario")
	_hud._alternar_inventario()

	for etapa in Jogo.OBJETIVOS:
		Jogo.concluir_objetivo(etapa["id"])
	await _foto_ui("10_escolha_final")

	Jogo.decidir(false)                          # o final "coração"
	await _foto_ui("11_final_desistiu")

	get_tree().quit(0)


func _foto(nome: String, onde: Vector2, esperado: String) -> void:
	_caju.global_position = onde
	# Sem isto a câmera vai devagar até o novo lugar e a foto sai fora de quadro.
	_camera.reset_smoothing()
	_camera.align()
	await _quadros(30)
	await _salvar(nome)
	print("%s  <- %s" % [nome, esperado])


func _foto_ui(nome: String) -> void:
	await _quadros(12)
	await _salvar(nome)
	print(nome)


func _salvar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(PASTA + nome + ".png")


func _quadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame
