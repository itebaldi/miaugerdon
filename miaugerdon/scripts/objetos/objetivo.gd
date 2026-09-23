@tool
extends Interagivel

var falas: Array = []

# etapas que acontecem neste ponto do mapa: o quintal do Mr. T recebe mais de
# uma visita, e cada visita é uma etapa com a própria conversa
var _indices: Array[int] = []
var _etapa := {}
var _aguardando_dialogo := false
var _oculto_ate_liberar := false
# o ponto atrás da cama vai mudando de cara conforme as peças chegam; os outros
# pontos do mapa têm sprite fixo, posto na cena
var _sprite_por_etapa := false


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return

	for i in Config.OBJETIVOS.size():
		var etapa: Dictionary = Config.OBJETIVOS[i]
		if Config.local(etapa) != id:
			continue
		_indices.append(i)
		if etapa.get("oculto", false):
			_oculto_ate_liberar = true
		if etapa.has("sprite_ponto"):
			_sprite_por_etapa = true

	_carregar_etapa()
	if _oculto_ate_liberar:
		visible = false
	Jogo.objetivo_alterado.connect(_ao_trocar_objetivo)


# a primeira etapa deste ponto que ainda não foi feita; feitas todas, a última
func _carregar_etapa() -> void:
	if _indices.is_empty():
		return
	var escolhida: int = _indices[-1]
	for i in _indices:
		if not Jogo.esta_concluido(i):
			escolhida = i
			break

	_etapa = Config.OBJETIVOS[escolhida]
	rotulo = _etapa.get("rotulo", rotulo)
	pensamento = _etapa.get("pensamento_perto", "")
	duracao = _etapa.get("duracao", duracao)
	tela = _etapa.get("tela", "")
	falas = _etapa.get("falas", [])
	if _sprite_por_etapa:
		_atualizar_sprite()


# mostra o que já foi entregue: nada, a caneta, a caneta com o papel
func _atualizar_sprite() -> void:
	var caminho: String = _etapa.get("sprite_ponto", "")
	textura = load(caminho) if caminho != "" else null


func _ao_trocar_objetivo(_indice: int, _titulo: String) -> void:
	_carregar_etapa()
	if _todas_feitas() and _etapa.get("some_ao_terminar", false):
		visible = false
		return
	if not _oculto_ate_liberar:
		return

	var liberado := _e_a_vez_dele()
	if liberado == visible:
		return
	visible = liberado

	if liberado and _caju:
		Jogo.pensar_uma_vez(_chave_pensamento(), pensamento)


func _chave_pensamento() -> String:
	return "prox:" + _etapa.get("id", id)


func _e_a_vez_dele() -> bool:
	var atual := Jogo.objetivo_atual()
	return not atual.is_empty() and Config.local(atual) == id


func _todas_feitas() -> bool:
	for i in _indices:
		if not Jogo.esta_concluido(i):
			return false
	return not _indices.is_empty()


func _esta_ativo() -> bool:
	if _aguardando_dialogo or not _e_a_vez_dele():
		return false
	# etapa de transporte: só vale se o item estiver na boca
	var exigido: String = _etapa.get("carga", "")
	return exigido == "" or Jogo.carga == exigido


func _ao_progredir(delta: float) -> void:
	var atual := Jogo.objetivo_atual()
	if not atual.is_empty():
		var fator := Jogo.FATOR_OBSERVADO if Jogo.observado else 1.0
		Jogo.aumentar_suspeita(atual["suspeita"] * fator * delta)
	if _caju and _caju.has_method("marcar_acao_secreta"):
		_caju.marcar_acao_secreta()


func _concluir() -> void:
	var id_etapa: String = _etapa["id"]
	if _etapa.has("carga"):
		Jogo.consumir_carga()
	if falas.is_empty():
		Jogo.concluir_objetivo(id_etapa)
		return

	_aguardando_dialogo = true
	Jogo.dialogo_terminado.connect(_no_fim_do_dialogo, CONNECT_ONE_SHOT)
	Jogo.conversar(falas)


func _no_fim_do_dialogo() -> void:
	_aguardando_dialogo = false
	Jogo.concluir_objetivo(_etapa["id"])


func _motivo_indisponivel() -> String:
	if _todas_feitas():
		return "%s: já está pronto" % rotulo
	var exigido: String = _etapa.get("carga", "")
	if _e_a_vez_dele() and exigido != "" and Jogo.carga != exigido:
		var dados: Dictionary = Config.CARREGAVEIS.get(exigido, {})
		return "Traga %s até aqui" % dados.get("nome", "o item")
	if Jogo.objetivo_atual().is_empty():
		return "%s: ainda não" % rotulo
	return "Antes disso: %s" % Jogo.titulo_atual()


func _texto_prompt() -> String:
	if _todas_feitas():
		return "%s — pronto" % rotulo
	if not _esta_ativo():
		return "%s — ainda não" % rotulo
	return "%s  [segure E]" % rotulo


func _cor_prompt() -> Color:
	# mesmo verde das etapas marcadas no inventario
	return Color(0.6, 0.86, 0.6) if _todas_feitas() else Color.WHITE
