@tool
class_name Interagivel
extends Area2D

const DECAIMENTO_PROGRESSO := 0.25

@export var id: String = ""
@export var textura: Texture2D:
	set(valor):
		textura = valor
		_aplicar_arte()

@export var deslocamento_arte := Vector2.ZERO:
	set(valor):
		deslocamento_arte = valor
		_aplicar_arte()

@export var escala_arte := 1.0:
	set(valor):
		escala_arte = valor
		_aplicar_arte()

var rotulo := ""
var duracao := 3.0
var pensamento := ""
var tela := ""

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _label: Label = $Label

var _caju: Node2D = null
var _progresso := 0.0


func _enter_tree() -> void:
	_aplicar_arte()


func _ready() -> void:
	_aplicar_arte()
	if Engine.is_editor_hint():
		return

	var dados := Config.dados(id)
	rotulo = dados.get("rotulo", rotulo)
	pensamento = dados.get("pensamento_perto", pensamento)
	duracao = dados.get("duracao", duracao)
	tela = dados.get("tela", tela)

	add_to_group("interagivel")
	_label.position.y += minf(deslocamento_arte.y, 0.0)
	_label.visible = false
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


# roda tambem no editor, e os setters chamam de novo a cada ajuste no Inspector
func _aplicar_arte() -> void:
	var sp := get_node_or_null("Sprite2D") as Sprite2D
	if sp == null:
		return
	sp.texture = textura
	sp.offset = deslocamento_arte
	sp.scale = Vector2.ONE * escala_arte
	sp.visible = textura != null


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var perto := _caju != null
	_label.visible = perto
	if perto:
		_label.text = _texto_prompt()
		_label.modulate = _cor_prompt()

	if perto and not _esta_ativo() and Input.is_action_just_pressed("interagir"):
		Jogo.avisar(_motivo_indisponivel())

	if perto and _esta_ativo() and Input.is_action_pressed("interagir"):
		_progresso = minf(1.0, _progresso + delta / maxf(duracao, 0.01))
		_ao_progredir(delta)
		Jogo.definir_progresso(_progresso, tela)
		if _progresso >= 1.0:
			_progresso = 0.0
			Jogo.definir_progresso(0.0)
			_concluir()
	elif _progresso > 0.0:

		_progresso = maxf(0.0, _progresso - delta * DECAIMENTO_PROGRESSO / maxf(duracao, 0.01))
		if perto:
			Jogo.definir_progresso(_progresso, tela)


func _ao_entrar(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_caju = corpo

	if visible:
		Jogo.pensar_uma_vez("prox:" + id, pensamento)


func _ao_sair(corpo: Node2D) -> void:
	if corpo == _caju:
		_caju = null
		Jogo.definir_progresso(0.0)


func cancelar() -> void:
	if _progresso > 0.0:
		_progresso = 0.0
		Jogo.definir_progresso(0.0)


func _esta_ativo() -> bool:
	return true


func _ao_progredir(_delta: float) -> void:
	pass


func _concluir() -> void:
	pass


func _motivo_indisponivel() -> String:
	return "%s: agora não dá" % rotulo


func _texto_prompt() -> String:
	return "%s  [E]" % rotulo


func _cor_prompt() -> Color:
	return Color.WHITE
