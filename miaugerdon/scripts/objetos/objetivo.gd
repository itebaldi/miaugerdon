extends Interagivel

## Uma etapa do plano de dominação mundial.
##
## Diferença dos outros interagíveis: isto é AÇÃO SECRETA. Enquanto o progresso sobe, a
## suspeita do Alfredo sobe também, e se ele chegar perto o Caju é pego em flagrante.
## Só está ativo quando é a vez desta etapa — as outras ficam inertes.

## Se preenchido, concluir abre um diálogo e a etapa só fecha quando ele terminar.
@export var falas: PackedStringArray = []
@export var nome_falante: String = ""

var _aguardando_dialogo := false


func _ready() -> void:
	super()
	# duracao e o custo em suspeita vivem no jogo.gd, junto do resto do balanceamento.
	# Aqui só copiamos, para não ter o mesmo número em dois lugares podendo divergir.
	for etapa in Jogo.OBJETIVOS:
		if etapa["id"] == id:
			duracao = etapa["duracao"]
			break


func _esta_ativo() -> bool:
	if _aguardando_dialogo:
		return false
	var atual := Jogo.objetivo_atual()
	return not atual.is_empty() and atual["id"] == id


func _ao_progredir(delta: float) -> void:
	var atual := Jogo.objetivo_atual()
	if not atual.is_empty():
		# Trabalhar com o Alfredo olhando custa FATOR_OBSERVADO vezes mais suspeita. É o que
		# transforma "onde ele está" em decisão, em vez de só "corra até o objeto".
		var fator := Jogo.FATOR_OBSERVADO if Jogo.observado else 1.0
		Jogo.aumentar_suspeita(atual["suspeita"] * fator * delta)
	if _caju and _caju.has_method("marcar_acao_secreta"):
		_caju.marcar_acao_secreta()


func _concluir() -> void:
	if falas.is_empty():
		Jogo.concluir_objetivo(id)
		return

	# Com falas, a etapa fica em espera: o diálogo pausa o jogo e só ao fechar a última
	# fala é que a etapa conta como concluída. CONNECT_ONE_SHOT desconecta sozinho depois
	# de disparar, então não acumula ligação a cada partida.
	_aguardando_dialogo = true
	Jogo.dialogo_terminado.connect(_no_fim_do_dialogo, CONNECT_ONE_SHOT)
	Jogo.conversar(nome_falante, falas)


func _no_fim_do_dialogo() -> void:
	_aguardando_dialogo = false
	Jogo.concluir_objetivo(id)


func _texto_prompt() -> String:
	if not _esta_ativo():
		return "%s — ainda não" % rotulo
	return "%s  [segure E]" % rotulo
