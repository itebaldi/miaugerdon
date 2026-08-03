extends Interagivel

var falas: PackedStringArray = []
var nome_falante := ""

var _aguardando_dialogo := false
var _oculto_ate_liberar := false


func _ready() -> void:
	super()
	var etapa := Config.dados(id)
	falas = PackedStringArray(etapa.get("falas", []))
	nome_falante = etapa.get("falante", "")
	_oculto_ate_liberar = etapa.get("oculto", false)

	if _oculto_ate_liberar:
		visible = false
		Jogo.objetivo_alterado.connect(_ao_trocar_objetivo)


# some de novo ao reiniciar, porque iniciar_partida() também emite o sinal
func _ao_trocar_objetivo(_indice: int, _titulo: String) -> void:
	var liberado := _e_a_vez_dele()
	if liberado == visible:
		return
	visible = liberado
	# o Caju pode estar parado na garagem justo na hora em que a máquina aparece
	if liberado and _caju:
		Jogo.pensar_uma_vez("prox:" + id, pensamento)


func _e_a_vez_dele() -> bool:
	var atual := Jogo.objetivo_atual()
	return not atual.is_empty() and atual["id"] == id


func _esta_ativo() -> bool:
	return not _aguardando_dialogo and _e_a_vez_dele()


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
