extends Control

# Abertura em quadrinho. A prancha inteira já está montada na cena: este script
# só esconde tudo, revela quadro a quadro e move a câmera.
#
# Para mexer na diagramação, abra cenas/ui/abertura.tscn e arraste os nós. A
# ordem de revelação é a ordem dos nós na árvore: quadros de cima para baixo,
# e dentro de cada quadro, os balões na ordem em que aparecem.

const CENA_JOGO := "res://cenas/mapa2.tscn"

const FOLGA := 40.0
const ZOOM_MAXIMO := 1.15
const DURACAO_CAMERA := 0.55
const DESLIZE := 26.0

@onready var _palco: Control = $Palco
@onready var _prancha: PranchaHQ = $Palco/Prancha
@onready var _dica: Label = $Dica

var _passos: Array = []
var _passo := -1
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	_preparar()
	get_viewport().size_changed.connect(_reenquadrar)
	_avancar()


# Esconde tudo e monta a lista de passos a partir da árvore. Cada quadro entra
# junto com o seu primeiro balão; os outros entram um a um.
func _preparar() -> void:
	for quadro in _prancha.quadros():
		quadro.modulate.a = 0.0
		var area := Rect2(quadro.position, quadro.size)
		var baloes := _baloes_de(quadro)

		if baloes.is_empty():
			_passos.append({"quadro": quadro, "balao": null, "rect": area, "tremor": quadro.tremor})
			continue

		for i in baloes.size():
			_passos.append({
				"quadro": quadro if i == 0 else null,
				"balao": baloes[i],
				"rect": area,
				"tremor": quadro.tremor and i == 0,
			})

	_passos.append({
		"quadro": null,
		"balao": null,
		"rect": Rect2(Vector2.ZERO, _prancha.size),
		"tremor": false,
	})


func _baloes_de(quadro: QuadroHQ) -> Array:
	var lista: Array = []
	for filho in quadro.get_children():
		var balao := filho as BalaoHQ
		if balao == null:
			continue
		balao.modulate.a = 0.0
		balao.pivot_offset = balao.size * 0.5
		balao.scale = Vector2(0.82, 0.82)
		lista.append(balao)
	return lista


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_terminar()
		return
	if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("interagir"):
		_avancar()


func _avancar() -> void:
	# um segundo toque atropela a animação em vez de enfileirar outro passo
	if _tween != null and _tween.is_running():
		_tween.custom_step(10.0)
		return

	_passo += 1
	if _passo >= _passos.size():
		_terminar()
		return

	_tocar_passo(_passos[_passo])


func _tocar_passo(passo: Dictionary) -> void:
	var ultimo := _passo == _passos.size() - 1
	_dica.text = "[Enter] começar          [Esc] pular" if ultimo else "[Enter] continuar          [Esc] pular"

	_tween = create_tween()
	_tween.set_parallel(true)

	var enquadramento := _calcular_enquadramento(passo["rect"])
	_tween.tween_property(_prancha, "position", enquadramento["posicao"], DURACAO_CAMERA) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_prancha, "scale", enquadramento["escala"], DURACAO_CAMERA) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var quadro: QuadroHQ = passo["quadro"]
	if quadro != null:
		var destino := quadro.position
		quadro.position = destino + Vector2(0, DESLIZE)
		_tween.tween_property(quadro, "modulate:a", 1.0, 0.45) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(quadro, "position", destino, 0.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var balao: BalaoHQ = passo["balao"]
	if balao != null:
		var atraso := 0.22 if quadro != null else 0.0
		_tween.tween_property(balao, "modulate:a", 1.0, 0.22).set_delay(atraso)
		_tween.tween_property(balao, "scale", Vector2.ONE, 0.34) \
			.set_delay(atraso).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if passo["tremor"]:
		_tween.chain().tween_callback(_tremer)


func _tremer() -> void:
	var sacode := create_tween()
	for i in 6:
		var deslocamento := Vector2(randf_range(-9.0, 9.0), randf_range(-7.0, 7.0))
		sacode.tween_property(_palco, "position", deslocamento, 0.045)
	sacode.tween_property(_palco, "position", Vector2.ZERO, 0.07)


func _calcular_enquadramento(area: Rect2) -> Dictionary:
	var tela := get_viewport_rect().size
	var escala: float = minf(
		(tela.x - FOLGA * 2.0) / area.size.x,
		(tela.y - FOLGA * 2.0) / area.size.y
	)
	escala = minf(escala, ZOOM_MAXIMO)
	var centro := area.position + area.size * 0.5
	return {
		"escala": Vector2(escala, escala),
		"posicao": tela * 0.5 - centro * escala,
	}


func _reenquadrar() -> void:
	if _passo < 0 or _passo >= _passos.size():
		return
	var enquadramento := _calcular_enquadramento(_passos[_passo]["rect"])
	_prancha.scale = enquadramento["escala"]
	_prancha.position = enquadramento["posicao"]


func _terminar() -> void:
	if _tween != null:
		_tween.kill()
	Jogo.intro_vista = true
	get_tree().change_scene_to_file(CENA_JOGO)
