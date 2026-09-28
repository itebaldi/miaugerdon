extends Node2D

# Percorre a virada do primeiro para o segundo dia sem jogador: o recado do
# Miauzon, o Alfredo buscando o Caju, e a montagem da máquina em três peças na
# manhã seguinte. Roda com
# Godot --headless --path . ferramentas/teste_fim_do_dia.tscn

var _erros := 0


func _conferir(condicao: bool, texto: String) -> void:
	if condicao:
		print("  ok    ", texto)
	else:
		print("  FALHA ", texto)
		_erros += 1


func _abrir_mapa() -> Node2D:
	var mapa: Node2D = load("res://cenas/mapa2.tscn").instantiate()
	add_child(mapa)
	mapa.get_node("HUD").queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	return mapa


func _ready() -> void:
	Jogo.pensamento.connect(func(t): print("        >>> pensou: ", t))
	Jogo.objetivo_alterado.connect(func(_i, t): print("        >>> objetivo: ", t))

	var falas_recebidas: Array = []
	var noite := [false]
	var escolha := [false]
	Jogo.dialogo.connect(func(f): falas_recebidas.append_array(f))
	Jogo.noite.connect(func(): noite[0] = true)
	Jogo.escolha_final.connect(func(): escolha[0] = true)

	Jogo.dia = 1
	var mapa := await _abrir_mapa()
	var alfredo := mapa.get_node("Alfredo")
	var caju := mapa.get_node("Caju")

	print("\n[1] primeiro dia até o computador")
	for id in ["mr_t", "levar_caneta", "levar_papel", "escrever_plano", "mostrar_plano"]:
		Jogo.concluir_objetivo(id)
	_conferir(Jogo.objetivo_atual()["id"] == "computador", "objetivo é o computador")
	var titulo_antes := Jogo.titulo_atual()
	Jogo.concluir_objetivo("computador")
	_conferir(not Jogo.em_partida, "o relógio parou")
	_conferir(Jogo.em_roteiro, "o jogo entrou em roteiro")
	_conferir(Jogo.objetivo_atual()["id"] == "maquina_base", "a próxima etapa já é a da manhã")
	_conferir(not mapa.get_node("Objetivos/Maquina").visible, "mas a máquina não aparece hoje")
	_conferir(alfredo._estado != alfredo.Estado.BUSCANDO, "com o recado aberto, o Alfredo espera")

	print("\n[2] recado lido: o Alfredo vem buscar")
	Jogo.recado_lido()
	_conferir(alfredo._estado == alfredo.Estado.BUSCANDO, "Alfredo está buscando")
	var tempo := Jogo.tempo_restante
	var espera := 0.0
	while falas_recebidas.is_empty() and espera < 14.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	_conferir(not falas_recebidas.is_empty(), "ele chegou e falou (%.1fs)" % espera)
	_conferir(falas_recebidas.size() > 0 and falas_recebidas[0][0] == "Alfredo", "quem fala é o Alfredo")
	var distancia: float = alfredo.global_position.distance_to(caju.global_position)
	_conferir(distancia <= 60.0, "parou perto do Caju (%.0f px)" % distancia)
	_conferir(Jogo.tempo_restante == tempo, "o relógio não andou durante a busca")
	Jogo.encerrar_dialogo()
	_conferir(noite[0], "fim da conversa chama a noite")
	_conferir(titulo_antes != "", "(título do computador era: %s)" % titulo_antes)

	print("\n[3] manhã seguinte")
	mapa.queue_free()
	await get_tree().process_frame
	Jogo.dia = 2
	mapa = await _abrir_mapa()
	caju = mapa.get_node("Caju")
	var maquina := mapa.get_node("Objetivos/Maquina")
	_conferir(Jogo.em_partida and not Jogo.em_roteiro, "partida rodando de novo")
	_conferir(absf(Jogo.tempo_restante - Jogo.TEMPO_DIA_2) < 0.5, "relógio cheio do dia 2 (%.2fs)" % Jogo.tempo_restante)
	_conferir(Jogo.objetivo_atual()["id"] == "maquina_base", "objetivo é a base da máquina")
	_conferir(Jogo.esta_concluido(Jogo.indice - 1), "o dia anterior conta como feito")
	_conferir("Pedido no Miauzon: peça #TR-4" in Jogo.itens, "o inventário lembra do pedido")
	var ate_o_sofa: float = caju.global_position.distance_to(mapa.get_node("PontoManha").global_position)
	_conferir(ate_o_sofa < 4.0, "Caju acorda no sofá (%.1f px)" % ate_o_sofa)
	_conferir(maquina.visible, "a máquina está na garagem")
	_conferir(maquina._esta_ativo(), "e pode ser montada")
	_conferir(not mapa.get_node("Itens/Plano").visible, "o plano entregue ontem não volta")

	print("\n[4] três peças")
	_conferir(maquina.rotulo == "Montar a base", "primeira peça: base")
	maquina._concluir()
	_conferir(maquina.rotulo == "Ligar os fios", "segunda peça: fios")
	maquina._concluir()
	_conferir(maquina.rotulo == "Encaixar a antena", "terceira peça: antena")
	_conferir(not escolha[0], "ainda sem escolha")
	maquina._concluir()
	_conferir(not escolha[0], "a escolha espera a máquina aparecer")
	_conferir(Jogo.em_roteiro, "o jogo entra em cena")
	_conferir(maquina.textura.resource_path.ends_with("maquina_3_pronta.png"), "o ponto mostra a máquina pronta")
	var relogio := Jogo.tempo_restante
	await get_tree().create_timer(Jogo.PAUSA_MAQUINA_PRONTA + 0.3).timeout
	_conferir(escolha[0], "depois da pausa vem a escolha")
	_conferir(Jogo.tempo_restante == relogio, "o relógio não andou na pausa")
	_conferir("Máquina de controle mental" in Jogo.itens, "a máquina entrou no inventário")

	print("\n[5] ativar")
	var final := [-1]
	Jogo.partida_terminada.connect(func(m): final[0] = m)
	get_tree().paused = false
	Jogo.decidir(true)
	await get_tree().create_timer(0.5).timeout
	_conferir(final[0] == -1, "o final espera a máquina ligar")
	await get_tree().create_timer(Jogo.PAUSA_MAQUINA_LIGANDO).timeout
	_conferir(final[0] == Jogo.Motivo.ATIVOU, "depois dela ligar, o final de ativar")
	_conferir(maquina.textura.resource_path.ends_with("maquina_4_ligada.png"), "a máquina terminou ligada")

	print("\n=== %s ===" % ("TUDO OK" if _erros == 0 else "%d FALHAS" % _erros))
	get_tree().quit()
