extends Node

# Refaz as figuras do artigo (monografia/figures) a partir do jogo de verdade:
# cada uma é uma situação encenada no mapa, com a interface atual.
#
# Como rodar, na resolução dos prints (1,5x a base de 1152x648):
# Godot --path . --resolution 1728x972 ferramentas/figuras_artigo.tscn
#
# Os arquivos saem com os mesmos nomes usados em figures/*.tex, então o LaTeX
# pega as versões novas sem precisar mudar nada.

const PASTA := "../monografia/figures/"

var _mapa: Node2D


func _abrir() -> void:
	if _mapa:
		Input.action_release("interagir")
		_mapa.queue_free()
		await get_tree().process_frame
	get_tree().paused = false
	Jogo.dia = 1
	Jogo.intro_vista = true
	_mapa = load("res://cenas/mapa2.tscn").instantiate()
	add_child(_mapa)
	for i in 30:
		await get_tree().process_frame
	var hud := _mapa.get_node("HUD")
	hud._painel_tutorial.visible = false
	get_tree().paused = false


func _ate(etapa: String) -> void:
	for e in Jogo.OBJETIVOS:
		if e["id"] == etapa:
			break
		Jogo.concluir_objetivo(e["id"])
	get_tree().paused = false
	var hud := _mapa.get_node("HUD")
	hud._painel_recado.visible = false


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var caminho := ProjectSettings.globalize_path("res://").path_join(PASTA + nome + ".png").simplify_path()
	get_viewport().get_texture().get_image().save_png(caminho)
	print("figura salva em ", caminho)


func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 1. conversa com o Mr. T: a fala em que ele propõe a máquina
	await _abrir()
	var caju: Node2D = _mapa.get_node("Caju")
	var alf: Node2D = _mapa.get_node("Alfredo")
	caju.global_position = Vector2(1160, 520)
	Jogo.tempo_restante = 163.0
	Jogo.aumentar_suspeita(4.0)
	await _esperar(0.6)
	var falas: Array = Jogo.OBJETIVOS[0]["falas"]
	Jogo.conversar(falas)
	var hud := _mapa.get_node("HUD")
	hud._fala_atual = 16
	hud._mostrar_fala()
	await _esperar(0.3)
	await _foto("mr_t")

	# 2. no computador, com a tela do PurrgleMiaut e a ação pela metade
	await _abrir()
	caju = _mapa.get_node("Caju")
	alf = _mapa.get_node("Alfredo")
	_ate("computador")
	alf.global_position = Vector2(640, 300)
	alf.set_physics_process(false)
	caju.global_position = Vector2(895, 440)
	Jogo.tempo_restante = 78.0
	await _esperar(0.4)
	_mapa.get_node("Caju/Balao")._esquecer()
	Jogo.definir_observado(false)
	Jogo.aumentar_suspeita(14.0)
	Jogo.definir_progresso(0.55, Config.OBJETIVOS[Jogo.indice]["tela"])
	await _esperar(0.3)
	await _foto("purrgle_miaut")

	# 3. o recado da Miauzon
	await _abrir()
	caju = _mapa.get_node("Caju")
	_ate("computador")
	caju.global_position = Vector2(895, 440)
	Jogo.tempo_restante = 74.0
	Jogo.aumentar_suspeita(40.0)
	await _esperar(0.4)
	Jogo.concluir_objetivo("computador")
	await _esperar(0.3)
	await _foto("miauzon")

	# 4. escrevendo o plano com a suspeita no vermelho e o Alfredo olhando
	await _abrir()
	caju = _mapa.get_node("Caju")
	alf = _mapa.get_node("Alfredo")
	_ate("escrever_plano")
	caju.global_position = Vector2(738, 212)
	alf.global_position = Vector2(800, 300)
	alf.set_physics_process(false)
	Jogo.tempo_restante = 131.0
	Jogo.aumentar_suspeita(78.0)
	await _esperar(0.4)
	await _esperar(1.0)
	Jogo.definir_progresso(0.6)
	_mapa.get_node("Caju/Balao")._esquecer()
	Jogo.definir_observado(true)
	await _esperar(0.2)
	await _foto("barra_suspeita")

	get_tree().quit()
