extends Interagivel

var reduz_suspeita := 12.0
var atrai_alfredo := false
var recarga := 12.0
var usos := -1

var _usos_restantes := -1
var _recarga_restante := 0.0


func _ready() -> void:
	var dados: Dictionary = Config.ACOES.get(id, {})
	reduz_suspeita = dados.get("reduz_suspeita", reduz_suspeita)
	atrai_alfredo = dados.get("atrai_alfredo", atrai_alfredo)
	recarga = dados.get("recarga", recarga)
	usos = dados.get("usos", usos)

	super()
	_usos_restantes = usos


func _process(delta: float) -> void:
	if _recarga_restante > 0.0:
		_recarga_restante = maxf(0.0, _recarga_restante - delta)
	super(delta)


func _esta_ativo() -> bool:
	return _recarga_restante <= 0.0 and _usos_restantes != 0


func _concluir() -> void:
	Jogo.reduzir_suspeita(reduz_suspeita)
	if atrai_alfredo:
		Jogo.emitir_ruido(global_position)
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
