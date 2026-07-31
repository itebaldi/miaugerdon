extends Interagivel

## Comportamento típico de gato: derrubar o copo, comer, arranhar o sofá, dormir, cavar,
## brincar. É a ÚNICA forma de fazer a barra de suspeita descer, então é o que mantém o
## jogador vivo.
##
## Diferença do objetivo: isto NÃO é ação secreta. O Alfredo pode ver à vontade, não dá
## flagrante — é o ponto todo do disfarce. E não sobe suspeita: desce.
##
## Algumas ações fazem barulho e ATRAEM o Alfredo mesmo baixando a suspeita (derrubar um
## copo é comportamento de gato, mas faz barulho). Essa tensão é a decisão do jogador, e
## por isso essas têm usos contados: senão viravam botão de resolver tudo.

@export var reduz_suspeita := 12.0
## Emite barulho na posição do objeto: o Alfredo vem investigar.
@export var atrai_alfredo := false
@export var recarga := 12.0
## Quantas vezes dá para usar na partida. -1 = ilimitado.
@export var usos := -1

var _usos_restantes := -1
var _recarga_restante := 0.0


func _ready() -> void:
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

	if _usos_restantes == 0:
		Jogo.avisar("%s: acabou" % rotulo)


func _texto_prompt() -> String:
	# Recarga e usos restantes aparecem AQUI, no objeto, e não num painel de ícones da
	# HUD: é onde o jogador está olhando quando a informação importa.
	if _usos_restantes == 0:
		return "%s — acabou" % rotulo
	if _recarga_restante > 0.0:
		return "%s — recarregando %ds" % [rotulo, ceili(_recarga_restante)]
	if _usos_restantes > 0:
		return "%s  [E] · %d" % [rotulo, _usos_restantes]
	return "%s  [E]" % rotulo
