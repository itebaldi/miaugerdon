extends Node

## Teste de fumaça: exercita o loop do jogo sem ninguém apertar tecla.
##
##   godot --path <projeto> --headless ferramentas/teste_jogo.tscn
##
## Confere o que só apareceria jogando: o Alfredo anda mesmo, as faixas de suspeita mudam o
## comportamento dele, o barulho o atrai, o decaimento só age na faixa BAIXA, a cadeia de
## objetivos avança até a escolha final, e as duas derrotas disparam.
##
## POR QUE ISTO É UMA CENA e não `--script`: rodando com `--script`, os autoloads não estão
## registrados na hora de compilar o script, e `Jogo` dá "Identifier not found". Como cena, o
## projeto está inteiro de pé.

var _falhas := 0
var _cena: Node
var _alfredo: CharacterBody2D
var _caju: Node2D
var _hud: CanvasLayer


func _ready() -> void:
	await _abrir()

	# Espera ATÉ ele andar, em vez de medir uma janela fixa: ao começar a rotina ele pode
	# ficar até 3 s parado (a espera de "fazer tarefa"), e uma janela fixa daria falso
	# negativo dependendo do sorteio da rota.
	await _testar("Alfredo sai do lugar", func() -> bool:
		var antes: Vector2 = _alfredo.global_position
		var maior := 0.0
		for i in 420:                                  # ~7 segundos
			await get_tree().physics_frame
			maior = maxf(maior, antes.distance_to(_alfredo.global_position))
			if maior > 20.0:
				return true
		print("      (andou no maximo %.1f px)" % maior)
		return false)

	# REGRESSÃO: o Alfredo já congelou de vez no meio da casa (agente empurrado para fora do
	# navmesh). A espera legítima mais longa da rotina é 3 s, então qualquer parada acima de
	# 5 s é o bug voltando.
	await _testar("Alfredo nunca congela (20 s de ronda)", func() -> bool:
		var anterior: Vector2 = _alfredo.global_position
		var parado := 0.0
		var pior := 0.0
		for i in 1200:                                 # 20 s
			await get_tree().physics_frame
			var agora: Vector2 = _alfredo.global_position
			if anterior.distance_to(agora) > 0.5:
				anterior = agora
				parado = 0.0
			else:
				parado += get_physics_process_delta_time()
				pior = maxf(pior, parado)
		if pior > 5.0:
			print("      (ficou %.1f s parado de uma vez)" % pior)
			return false
		return true)

	# REGRESSÃO: o Caju e o Alfredo estão em camadas de física separadas para não se
	# empurrarem. Se a máscara dos interagíveis não acompanhar, eles param de ver o gato e
	# nenhuma interação funciona mais.
	await _testar("interagivel detecta o Caju", func() -> bool:
		var acao: Area2D = _cena.get_node("Acoes/Brincar")
		_caju.global_position = acao.global_position
		await _esperar(6)
		return acao._caju != null)

	# ── visão do Alfredo ────────────────────────────────────────────────────
	await _testar("ele ve o gato no mesmo comodo, perto", func() -> bool:
		_alfredo.global_position = Vector2(500, 440)      # sala de estar
		_caju.global_position = Vector2(540, 460)         # ao lado, sem nada no meio
		await _esperar(3)
		return _alfredo._esta_vendo_o_caju())

	await _testar("parede bloqueia a visao", func() -> bool:
		# Parede1 corre de (512,301) a (685,401): a 110 px, DENTRO do alcance, mas com
		# parede no caminho.
		_alfredo.global_position = Vector2(650, 430)      # sala
		_caju.global_position = Vector2(650, 300)         # quarto, do outro lado da parede
		await _esperar(3)
		return not _alfredo._esta_vendo_o_caju())

	await _testar("longe demais ele nao ve", func() -> bool:
		_alfredo.global_position = Vector2(500, 440)      # sala
		_caju.global_position = Vector2(1150, 470)        # quintal
		await _esperar(3)
		return not _alfredo._esta_vendo_o_caju())

	await _testar("ser observado multiplica a suspeita da etapa", func() -> bool:
		# escondido: paga a taxa normal
		Jogo.iniciar_partida()
		Jogo.definir_observado(false)
		var etapa: Dictionary = Jogo.OBJETIVOS[0]
		Jogo.aumentar_suspeita(etapa["suspeita"] * 1.0)
		var escondido := Jogo.suspeita

		# observado: paga FATOR_OBSERVADO vezes
		Jogo.iniciar_partida()
		Jogo.definir_observado(true)
		Jogo.aumentar_suspeita(etapa["suspeita"] * Jogo.FATOR_OBSERVADO)
		var visto := Jogo.suspeita

		Jogo.definir_observado(false)
		return is_equal_approx(visto, escondido * Jogo.FATOR_OBSERVADO) and visto > escondido)

	await _testar("acao de gato nao e afetada por ser visto", func() -> bool:
		# Comportamento de gato e inocente: o Alfredo pode olhar a vontade.
		Jogo.iniciar_partida()
		Jogo.aumentar_suspeita(50.0)
		Jogo.definir_observado(true)
		var antes := Jogo.suspeita
		var acao: Node = _cena.get_node("Acoes/Dormir")
		acao._concluir()
		var caiu := antes - Jogo.suspeita
		Jogo.definir_observado(false)
		return is_equal_approx(caiu, acao.reduz_suspeita))

	await _reiniciar()

	await _testar("suspeita sobe e muda de faixa", func() -> bool:
		Jogo.aumentar_suspeita(40.0)
		return Jogo.faixa() == Jogo.Faixa.MEDIA)

	await _testar("acao de gato baixa a suspeita", func() -> bool:
		var antes := Jogo.suspeita
		Jogo.reduzir_suspeita(18.0)
		return is_equal_approx(Jogo.suspeita, antes - 18.0))

	await _testar("barulho faz o Alfredo investigar", func() -> bool:
		Jogo.emitir_ruido(Vector2(300, 470))            # garagem, longe dele
		await _esperar(2)
		return _alfredo._estado == _alfredo.Estado.INVESTIGANDO)

	await _testar("faixa ALTA faz ele perseguir", func() -> bool:
		Jogo.aumentar_suspeita(50.0)                    # passa de 70
		await _esperar(2)
		return _alfredo._estado == _alfredo.Estado.PERSEGUINDO)

	await _testar("decaimento so acontece na faixa BAIXA", func() -> bool:
		var alta := Jogo.suspeita
		await _esperar(60)
		if Jogo.suspeita < alta:
			return false                                # nao devia cair em faixa ALTA
		Jogo.reduzir_suspeita(Jogo.suspeita - 10.0)     # desce para a faixa BAIXA
		var baixa := Jogo.suspeita
		await _esperar(60)
		return Jogo.suspeita < baixa)                   # aqui SIM tem que cair

	await _testar("cadeia de 5 objetivos chega na escolha final", func() -> bool:
		var pediu := [false]
		Jogo.escolha_final.connect(func() -> void: pediu[0] = true, CONNECT_ONE_SHOT)
		for etapa in Jogo.OBJETIVOS:
			Jogo.concluir_objetivo(etapa["id"])
		await _esperar(2)
		return pediu[0] and Jogo.itens.size() == 5)

	await _testar("escolher ATIVAR termina a partida", func() -> bool:
		var motivo := [-1]
		Jogo.partida_terminada.connect(func(m: int) -> void: motivo[0] = m, CONNECT_ONE_SHOT)
		Jogo.decidir(true)
		return motivo[0] == Jogo.Motivo.ATIVOU and not Jogo.em_partida)

	await _reiniciar()
	await _testar("suspeita em 100 termina por SUSPEITA", func() -> bool:
		var motivo := [-1]
		Jogo.partida_terminada.connect(func(m: int) -> void: motivo[0] = m, CONNECT_ONE_SHOT)
		Jogo.aumentar_suspeita(100.0)
		return motivo[0] == Jogo.Motivo.SUSPEITA and Jogo.suspeita == Jogo.SUSPEITA_MAX)

	await _reiniciar()
	await _testar("cronometro em zero termina por TEMPO", func() -> bool:
		var motivo := [-1]
		Jogo.partida_terminada.connect(func(m: int) -> void: motivo[0] = m, CONNECT_ONE_SHOT)
		Jogo.tempo_restante = 0.05
		await _esperar(10)
		return motivo[0] == Jogo.Motivo.TEMPO)

	await _testar("reiniciar zera tudo", func() -> bool:
		Jogo.iniciar_partida()
		return Jogo.suspeita == 0.0 and Jogo.indice == 0 \
			and Jogo.itens.is_empty() and Jogo.tempo_restante == Jogo.TEMPO_TOTAL \
			and not get_tree().paused)

	print("")
	print("=== %s ===" % ("TUDO OK" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	get_tree().quit(_falhas)


func _abrir() -> void:
	_cena = load("res://cenas/mapa2.tscn").instantiate()
	add_child(_cena)
	_alfredo = _cena.get_node("Alfredo")
	_caju = _cena.get_node("Caju")
	_hud = _cena.get_node("HUD")
	# O jogo abre pausado no tutorial; sem ninguém para apertar Enter, fechamos na mão.
	await _esperar(20)
	_hud._fechar_tutorial()
	await _esperar(15)      # deixa o mapa de navegação sincronizar


func _reiniciar() -> void:
	get_tree().paused = false
	Jogo.iniciar_partida()
	await _esperar(3)


func _esperar(quadros: int) -> void:
	for i in quadros:
		await get_tree().physics_frame


func _testar(nome: String, corpo: Callable) -> void:
	var ok: bool = await corpo.call()
	if not ok:
		_falhas += 1
	print("  %s  %s" % ["ok  " if ok else "FALHA", nome])
