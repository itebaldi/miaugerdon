extends Interagivel


func _ready() -> void:
	super()
	for etapa in Jogo.OBJETIVOS:
		if etapa["id"] == id:
			duracao = etapa["duracao"]
			break


func _esta_ativo() -> bool:
	var atual := Jogo.objetivo_atual()
	return not atual.is_empty() and atual["id"] == id


func _ao_progredir(delta: float) -> void:
	var atual := Jogo.objetivo_atual()
	if not atual.is_empty():
		Jogo.aumentar_suspeita(atual["suspeita"] * delta)


func _concluir() -> void:
	Jogo.concluir_objetivo(id)


func _texto_prompt() -> String:
	if not _esta_ativo():
		return "%s — ainda não" % rotulo
	return "%s  [segure E]" % rotulo
