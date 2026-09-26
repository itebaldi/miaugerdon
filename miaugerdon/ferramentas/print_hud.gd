extends Node2D

# Tira print do menu e da HUD em cada estado (tutorial, jogo, plano, diálogo,
# escolha, fim) por cima do mapa de verdade, para conferir a arte sem jogar até
# lá. Roda com render:
# Godot --path . --resolution 1280x720 ferramentas/print_hud.tscn -- <pasta>
# Sem pasta, salva em user://prints_hud.

var _pasta := "user://prints_hud"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_pasta = args[0]
	DirAccess.make_dir_recursive_absolute(_pasta)

	# o menu é uma cena de Control: numa CanvasLayer ele ancora na tela, como
	# quando é a cena principal. O fogo da logo leva quase dois segundos para pegar
	var camada := CanvasLayer.new()
	add_child(camada)
	camada.add_child(load("res://cenas/ui/menu.tscn").instantiate())
	await get_tree().create_timer(2.2).timeout
	await _print("menu")
	camada.queue_free()

	# sem isso a HUD abre a intro antiga em vez do tutorial
	Jogo.intro_vista = true
	var mapa: Node2D = load("res://cenas/mapa2.tscn").instantiate()
	add_child(mapa)
	var hud := mapa.get_node("HUD")
	await _print("tutorial")

	hud.get_node("%PainelTutorial").visible = false
	get_tree().paused = false
	hud._ao_mudar_suspeita(45.0)
	hud._ao_mudar_faixa(Jogo.Faixa.MEDIA)
	hud._ao_mudar_observado(true)
	hud._ao_mudar_progresso(0.6, "")
	await _print("jogo")

	hud._ao_mudar_suspeita(88.0)
	hud._ao_mudar_faixa(Jogo.Faixa.ALTA)
	hud._ao_mudar_tempo(24.0)
	hud._ao_mudar_progresso(0.0, "")
	await _print("jogo_alta")

	Jogo.concluir_objetivo("mr_t")
	hud._alternar_inventario()
	await _print("plano")
	hud._alternar_inventario()

	Jogo.dialogo.emit([
		["Mr. T", "Ora, ora. O Caju. Faz tempo que não aparece no meu quintal. O melhor quintal do bairro, aliás."],
		["Caju", "Mr. T, o Alfredo vai adotar outro gato. Chega amanhã."],
	])
	await _print("dialogo_mrt")
	hud._avancar_dialogo()
	await _print("dialogo_caju")
	hud._avancar_dialogo()

	Jogo.escolha_final.emit()
	await _print("escolha")
	hud.get_node("%PainelEscolha").visible = false

	Jogo.partida_terminada.emit(Jogo.Motivo.TEMPO)
	await _print("fim")
	get_tree().quit()


func _print(nome: String) -> void:
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var caminho := _pasta.path_join(nome + ".png")
	get_viewport().get_texture().get_image().save_png(caminho)
	print("print: ", caminho)
