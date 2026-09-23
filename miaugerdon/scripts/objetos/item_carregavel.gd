@tool
extends Interagivel

# Canto do mapa onde um item do plano fica largado, esperando o Caju vir buscar.
#
# A caneta e o papel estão pela casa desde o começo da partida: o jogador os vê
# antes de saber para que servem, e o Mr. T só dá a ideia de usá-los. O plano é
# a exceção, porque só existe depois de escrito.
#
# O item some da cena quando o Caju pega e reaparece no mesmo lugar quando o
# Alfredo toma de volta. É por isso que o confisco não precisa guardar posição
# nenhuma: o item nunca sai daqui, quem muda é o estado da boca do gato.

var _indice := -1


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return

	for i in Config.OBJETIVOS.size():
		if Config.OBJETIVOS[i].get("carga", "") == id:
			_indice = i
			break

	Jogo.carga_alterada.connect(_ao_mudar_carga)
	Jogo.objetivo_alterado.connect(_ao_trocar_objetivo)
	_atualizar()


func _ao_mudar_carga(_carga: String) -> void:
	_atualizar()


func _ao_trocar_objetivo(_i: int, _titulo: String) -> void:
	_atualizar()


# fica no chão até ser entregue, menos enquanto está na boca do Caju
func _atualizar() -> void:
	# o pensamento de perto só faz sentido depois que o Mr. T deu a ideia: antes
	# disso a caneta é só uma caneta, e gastar a fala ali a perderia para sempre
	pensamento = Config.dados(id).get("pensamento_perto", "") if _e_a_vez_dele() else ""

	var mostrar := not Jogo.esta_concluido(_indice) and Jogo.carga != id
	if Config.dados(id).get("so_na_vez", false):
		mostrar = mostrar and _e_a_vez_dele()
	if mostrar == visible:
		return
	visible = mostrar
	if mostrar and _caju:
		Jogo.pensar_uma_vez(_chave_pensamento(), pensamento)


func _e_a_vez_dele() -> bool:
	return _indice >= 0 and Jogo.indice == _indice and not Jogo.esta_concluido(_indice)


func _esta_ativo() -> bool:
	return _e_a_vez_dele() and Jogo.carga == ""


func _ao_progredir(delta: float) -> void:
	var dados := Config.dados(id)
	var fator := Jogo.FATOR_OBSERVADO if Jogo.observado else 1.0
	Jogo.aumentar_suspeita(float(dados.get("suspeita", 2.0)) * fator * delta)
	if _caju and _caju.has_method("marcar_acao_secreta"):
		_caju.marcar_acao_secreta()


func _concluir() -> void:
	Jogo.pegar_carga(id)


func _motivo_indisponivel() -> String:
	if Jogo.carga != "":
		return "Uma coisa de cada vez: leve o que está na boca primeiro"
	if Jogo.objetivo_atual().is_empty():
		return "%s: ainda não" % rotulo
	return "Antes disso: %s" % Jogo.titulo_atual()


func _texto_prompt() -> String:
	if not _esta_ativo():
		return "%s — ainda não" % rotulo
	return "%s  [segure E]" % rotulo
