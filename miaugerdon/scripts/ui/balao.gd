extends Node2D

## Balão de pensamento do Caju. Fica dentro da cena do gato, então acompanha ele sozinho —
## sem uma linha de código para "seguir o jogador".
##
## Não pausa o jogo: pensamento é comentário, não conversa. Some sozinho depois de
## DURACAO segundos, e se vierem dois seguidos o segundo espera a vez numa fila (senão o
## primeiro sumiria antes de ser lido).
##
## O texto é desenhado em espaço de mundo, não na HUD. Como a câmera está em zoom 1, cada
## pixel de fonte é um pixel de tela e o texto sai nítido. Se um dia a câmera ganhar zoom,
## isto precisa virar um Control na HUD posicionado sobre o gato.

const DURACAO := 4.5

@onready var _texto: Label = $Texto

var _fila: Array[String] = []
var _restante := 0.0


func _ready() -> void:
	_texto.text = ""
	visible = false
	Jogo.pensamento.connect(_ao_pensar)


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


func _process(delta: float) -> void:
	if _restante <= 0.0:
		return
	_restante -= delta
	if _restante <= 0.0:
		_mostrar_proximo()
