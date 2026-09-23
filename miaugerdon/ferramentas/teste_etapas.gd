extends Node2D

# Percorre a corrente de etapas do plano sem jogador: pega, confisca, entrega e
# escreve, conferindo o estado a cada passo. Roda com
# Godot --headless --path . ferramentas/teste_etapas.tscn

var _erros := 0


func _conferir(condicao: bool, texto: String) -> void:
	if condicao:
		print("  ok    ", texto)
	else:
		print("  FALHA ", texto)
		_erros += 1


func _ready() -> void:
	var mapa: Node2D = load("res://cenas/mapa2.tscn").instantiate()
	add_child(mapa)
	mapa.get_node("HUD").queue_free()
	Jogo.recado.connect(func(img, _t): print("        >>> recado: ", img))
	Jogo.aviso.connect(func(t): print("        >>> aviso: ", t))
	Jogo.pensamento.connect(func(t): print("        >>> pensou: ", t))
	Jogo.objetivo_alterado.connect(func(_i, t): print("        >>> objetivo: ", t))
	await get_tree().process_frame
	get_tree().paused = false

	var caneta := mapa.get_node("Itens/Caneta")
	var papel := mapa.get_node("Itens/Papel")
	var plano := mapa.get_node("Itens/Plano")
	var mesa := mapa.get_node("Objetivos/MesaDoPlano")
	var mr_t := mapa.get_node("Objetivos/MrT")

	print("\n[1] começo da partida: caneta e papel já estão pela casa")
	_conferir(Jogo.objetivo_atual()["id"] == "mr_t", "objetivo é mr_t")
	_conferir(caneta.visible, "caneta já está na cozinha")
	_conferir(papel.visible, "papel já está na estante")
	_conferir(not plano.visible, "plano ainda não existe")
	_conferir(not caneta._esta_ativo(), "mas a caneta não pode ser pega antes do Mr. T")
	_conferir(caneta.pensamento == "", "e ela não gasta o pensamento antes da hora")
	_conferir(caneta._motivo_indisponivel().contains("Mr. T"), "o aviso manda falar com o Mr. T")

	print("\n[2] depois de falar com o Mr. T")
	Jogo.concluir_objetivo("mr_t")
	_conferir(Jogo.objetivo_atual()["id"] == "levar_caneta", "objetivo é levar_caneta")
	_conferir(caneta._esta_ativo(), "agora a caneta pode ser pega")
	_conferir(caneta.pensamento != "", "e o pensamento dela acordou")
	_conferir(not papel._esta_ativo(), "o papel ainda espera a vez dele")
	_conferir(not mesa._esta_ativo(), "sem a caneta na boca a mesa não aceita")

	print("\n[3] Caju pega a caneta")
	caneta._concluir()
	_conferir(Jogo.carga == "caneta", "carga é a caneta")
	_conferir(not caneta.visible, "caneta saiu do chão")
	_conferir(mesa._esta_ativo(), "agora a mesa aceita")

	print("\n[4] Alfredo confisca no meio do caminho")
	Jogo.confiscar_carga()
	_conferir(Jogo.carga == "", "boca livre")
	_conferir(caneta.visible, "caneta voltou para o lugar de origem")
	_conferir(Jogo.objetivo_atual()["id"] == "levar_caneta", "etapa continua a mesma")

	print("\n[5] segunda tentativa, entrega")
	caneta._concluir()
	mesa._concluir()
	_conferir(Jogo.carga == "", "boca livre depois de largar")
	_conferir(Jogo.objetivo_atual()["id"] == "levar_papel", "objetivo é levar_papel")
	_conferir(not caneta.visible, "caneta entregue não volta para a cozinha")
	_conferir(papel.visible, "papel continua na estante")
	_conferir("Caneta" in Jogo.itens, "caneta entrou no inventário")
	_conferir(mesa.textura.resource_path.ends_with("caneta.png"), "mesa mostra a caneta")

	print("\n[6] leva o papel")
	papel._concluir()
	_conferir(not papel.visible, "papel saiu da estante")
	mesa._concluir()
	_conferir(Jogo.objetivo_atual()["id"] == "escrever_plano", "objetivo é escrever_plano")
	_conferir(mesa.textura.resource_path.ends_with("papel_e_caneta.png"), "mesa mostra papel e caneta")
	_conferir(not plano.visible, "plano ainda não existe")

	print("\n[7] escreve o plano")
	mesa._concluir()
	_conferir(Jogo.objetivo_atual()["id"] == "mostrar_plano", "a vez agora é do Mr. T")
	_conferir(not mesa.visible, "o ponto de escrita saiu de cena")
	_conferir(plano.visible, "o plano escrito apareceu no lugar")
	_conferir(Jogo.titulo_atual() == "Pegue o plano atrás da cama", "objetivo pede para pegar o plano")
	_conferir(not mr_t._esta_ativo(), "sem o plano na boca o Mr. T não recebe")

	print("\n[8] pega o plano e é pego no caminho")
	plano._concluir()
	_conferir(Jogo.carga == "plano", "carga é o plano")
	_conferir(not plano.visible, "plano saiu de trás da cama")
	_conferir(Jogo.titulo_atual() == "Leve o plano ao Mr. T no quintal", "objetivo pede para levar")
	_conferir(mr_t._esta_ativo(), "com o plano na boca o Mr. T recebe")
	Jogo.confiscar_carga()
	_conferir(plano.visible, "plano confiscado volta para trás da cama")

	print("\n[9] entrega ao Mr. T")
	plano._concluir()
	mr_t._concluir()
	_conferir(Jogo.carga == "", "boca livre ao entregar")
	_conferir(Jogo.objetivo_atual()["id"] == "mostrar_plano", "a conversa ainda está rolando")
	Jogo.encerrar_dialogo()
	_conferir(Jogo.objetivo_atual()["id"] == "computador", "depois da conversa, o computador")
	_conferir(not plano.visible, "plano entregue some do mapa")

	print("\n=== %s ===" % ("TUDO OK" if _erros == 0 else "%d FALHAS" % _erros))
	get_tree().quit()
