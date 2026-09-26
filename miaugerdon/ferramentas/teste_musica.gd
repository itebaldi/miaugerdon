extends Node2D

# Confere a trilha e os efeitos pela partida: a música do jogo acelera com a
# suspeita e no último minuto, volta a acalmar e se apaga no fim. Roda com
# Godot --path . --resolution 640x360 ferramentas/teste_musica.tscn
# (com --headless também passa, mas o áudio de mentira acusa recurso na saída)

var _erros := 0


func _conferir(condicao: bool, texto: String) -> void:
	if condicao:
		print("  ok    ", texto)
	else:
		print("  FALHA ", texto, "  (tocando: ", Musica._atual, " a ", Musica.velocidade(), "x)")
		_erros += 1


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, true, false, true).timeout


func _tocou(nome: StringName) -> bool:
	for tocador in Efeitos._tocadores:
		if tocador.playing and tocador.stream == Efeitos.SONS[nome]:
			return true
	return false


func _na_velocidade(tensao: Musica.Tensao) -> bool:
	return is_equal_approx(Musica.velocidade(), Musica.VELOCIDADE[tensao])


func _ready() -> void:
	Musica.tocar(&"menu")
	await _esperar(0.1)
	_conferir(Musica._atual == &"menu", "o menu toca a música do menu")

	Jogo.intro_vista = true
	var mapa: Node2D = load("res://cenas/mapa2.tscn").instantiate()
	add_child(mapa)
	mapa.get_node("HUD").queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	await _esperar(0.1)
	_conferir(Musica._atual == &"jogo" and _na_velocidade(Musica.Tensao.CALMA), "a partida começa na música do jogo, sem pressa")

	Jogo.concluir_objetivo("mr_t")
	await _esperar(0.05)
	_conferir(_tocou(&"etapa"), "etapa concluída: toca o som de etapa")

	Jogo.aumentar_suspeita(40.0)
	await _esperar(Musica.RAMPA_SUBINDO + 0.2)
	_conferir(Musica._atual == &"jogo" and _na_velocidade(Musica.Tensao.TENSA), "barra amarela: a mesma música, mais rápida")

	Jogo.aumentar_suspeita(35.0)
	await _esperar(Musica.RAMPA_SUBINDO + 0.2)
	_conferir(_na_velocidade(Musica.Tensao.AGITADA), "barra vermelha: mais rápida ainda")

	Jogo.reduzir_suspeita(70.0)
	await _esperar(2.0)
	_conferir(_na_velocidade(Musica.Tensao.AGITADA), "a suspeita baixou, mas a música ainda espera antes de acalmar")
	await _esperar(Musica.ESPERA_PARA_ACALMAR + Musica.RAMPA_DESCENDO)
	_conferir(_na_velocidade(Musica.Tensao.CALMA), "depois da espera, desacelera")

	Jogo.tempo_restante = 59.0
	await _esperar(Musica.RAMPA_SUBINDO + 0.2)
	_conferir(_na_velocidade(Musica.Tensao.PANICO), "último minuto: velocidade de pânico")

	Jogo.aumentar_suspeita(40.0)
	await _esperar(0.3)
	_conferir(_na_velocidade(Musica.Tensao.PANICO), "no último minuto a suspeita não tira o pânico")

	Jogo.decidir(false)
	await _esperar(0.05)
	_conferir(_tocou(&"vitoria"), "Caju mudou de ideia (vitória): toca a vinheta de vitória")
	await _esperar(0.1)
	_conferir(Musica._atual == &"", "fim da partida: a música se apaga")

	print("\n", "tudo certo" if _erros == 0 else "%d falha(s)" % _erros)
	get_tree().quit(_erros)
