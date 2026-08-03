extends Node2D

# Balão de pensamento do Caju.

const DURACAO := 4.5

@onready var _texto: Label = $Texto

var _fila: Array[String] = []
var _restante := 0.0


func _ready() -> void:
	_texto.text = ""
	visible = false
	Jogo.pensamento.connect(_ao_pensar)


func _process(delta: float) -> void:
	if _restante <= 0.0:
		return
	_restante -= delta
	if _restante <= 0.0:
		_mostrar_proximo()


func _ao_pensar(texto: String) -> void:
	_fila.append(texto)
	if _restante <= 0.0:
		_mostrar_proximo()


func _mostrar_proximo() -> void:
	if _fila.is_empty():
		visible = false
		_restante = 0.0
		return
	_texto.text = _fila.pop_front()
	visible = true
	_restante = DURACAO
