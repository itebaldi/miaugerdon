class_name Interagivel
extends Area2D

const DECAIMENTO_PROGRESSO := 0.25

@export var id: String = ""
@export var rotulo: String = ""
@export var duracao: float = 3.0

@onready var _label: Label = $Label

var _caju: Node2D = null
var _progresso := 0.0


func _ready() -> void:
	_label.visible = false
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func _process(delta: float) -> void:
	var perto := _caju != null
	_label.visible = perto
	if perto:
		_label.text = _texto_prompt()

	if perto and _esta_ativo() and Input.is_action_pressed("interagir"):
		_progresso = minf(1.0, _progresso + delta / maxf(duracao, 0.01))
		_ao_progredir(delta)
		Jogo.definir_progresso(_progresso)
		if _progresso >= 1.0:
			_progresso = 0.0
			Jogo.definir_progresso(0.0)
			_concluir()
	elif _progresso > 0.0:

		_progresso = maxf(0.0, _progresso - delta * DECAIMENTO_PROGRESSO / maxf(duracao, 0.01))
		if perto:
			Jogo.definir_progresso(_progresso)


func _ao_entrar(corpo: Node2D) -> void:
	if corpo.is_in_group("jogador"):
		_caju = corpo


func _ao_sair(corpo: Node2D) -> void:
	if corpo == _caju:
		_caju = null
		Jogo.definir_progresso(0.0)


func _esta_ativo() -> bool:
	return true


func _ao_progredir(_delta: float) -> void:
	pass


func _concluir() -> void:
	pass


func _texto_prompt() -> String:
	return "%s  [E]" % rotulo
