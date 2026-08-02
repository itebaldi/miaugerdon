extends Interagivel

@export var falas: PackedStringArray = []
@export var nome_falante: String = ""

var _aguardando_dialogo := false


func _ready() -> void:
	super()
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
		var fator := Jogo.FATOR_OBSERVADO if Jogo.observado else 1.0
		Jogo.aumentar_suspeita(atual["suspeita"] * fator * delta)
	if _caju and _caju.has_method("marcar_acao_secreta"):
		_caju.marcar_acao_secreta()


func _concluir() -> void:
	if falas.is_empty():
		Jogo.concluir_objetivo(id)
		return

	# ONE_SHOT desconecta sozinho, senão cada partida acumularia uma ligação
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
