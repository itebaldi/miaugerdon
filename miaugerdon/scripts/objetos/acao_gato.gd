extends Interagivel

# Comportamento de gato: é o que faz a suspeita descer.

@export var reduz_suspeita := 12.0
@export var recarga := 12.0
@export var usos := -1
@export var cor_placeholder: Color = Color(0, 0, 0, 0)

@onready var _placeholder: Polygon2D = $Placeholder

var _usos_restantes := -1
var _recarga_restante := 0.0


func _ready() -> void:
	super()
	_usos_restantes = usos
	_placeholder.color = cor_placeholder
	_placeholder.visible = cor_placeholder.a > 0.0


func _process(delta: float) -> void:
	if _recarga_restante > 0.0:
		_recarga_restante = maxf(0.0, _recarga_restante - delta)
	super(delta)


func _esta_ativo() -> bool:
	return _recarga_restante <= 0.0 and _usos_restantes != 0


func _concluir() -> void:
	Jogo.reduzir_suspeita(reduz_suspeita)
	if _usos_restantes > 0:
		_usos_restantes -= 1
	_recarga_restante = recarga


func _texto_prompt() -> String:
	if _usos_restantes == 0:
		return "%s — acabou" % rotulo
	if _recarga_restante > 0.0:
		return "%s — recarregando %ds" % [rotulo, ceili(_recarga_restante)]
	if _usos_restantes > 0:
		return "%s  [E] · %d" % [rotulo, _usos_restantes]
	return "%s  [E]" % rotulo
