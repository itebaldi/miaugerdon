class_name Interagivel
extends Area2D

## Base comum de tudo com que o Caju interage segurando E.
##
## POR QUE Area2D: ele detecta quem entra e sai sem BLOQUEAR o gato (um StaticBody2D
## bloquearia). E o motor já mantém a lista de quem está dentro — medir distância até o
## Caju a cada quadro seria mais código, mais lento, e daria o mesmo resultado.
##
## POR QUE HERANÇA: chegar perto, mostrar o prompt, segurar E, encher a barra e perder
## progresso ao soltar é IGUAL para uma etapa do plano e para uma ação de gato. Só o que
## acontece no FIM é diferente. Então isso vive aqui, uma vez, e os filhos (objetivo.gd e
## acao_gato.gd) sobrescrevem os métodos marcados como "virtual" lá embaixo.

## Ao soltar o E o progresso cai a 25% da velocidade com que sobe — então dá para fazer
## uma etapa longa em pedaços: trabalha um pouco, vai se disfarçar, volta e termina.
const DECAIMENTO_PROGRESSO := 0.25

@export var id: String = ""
## Texto curto do prompt: "Arranhar o sofá".
@export var rotulo: String = ""
## Segundos segurando E para concluir.
@export var duracao: float = 3.0
## Balão de pensamento na PRIMEIRA vez que o Caju chega perto. É assim que o jogador
## descobre as mecânicas, no momento em que elas importam.
@export_multiline var pensamento: String = ""
## Opcional: imagem do objeto. Se ficar vazia, usa o losango de placeholder.
@export var textura: Texture2D
## Cor do losango de placeholder. Alfa 0 = não desenha nada (o caso de objetos que ficam
## sobre um móvel que já tem arte, como o sofá).
@export var cor_placeholder: Color = Color(0, 0, 0, 0)

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _placeholder: Polygon2D = $Placeholder
@onready var _label: Label = $Label

var _caju: Node2D = null
var _progresso := 0.0


func _ready() -> void:
	add_to_group("interagivel")         # o Alfredo usa o grupo para cancelar progresso

	if textura:
		_sprite.texture = textura
		_sprite.visible = true
		_placeholder.visible = false
	else:
		_sprite.visible = false
		_placeholder.visible = cor_placeholder.a > 0.0
		_placeholder.color = cor_placeholder

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
		# Continua decaindo mesmo se o Caju foi embora, mas só mexe na barra da tela
		# enquanto ele está perto — senão um objeto do outro lado da casa mexeria na
		# barra de outro.
		_progresso = maxf(0.0, _progresso - delta * DECAIMENTO_PROGRESSO / maxf(duracao, 0.01))
		if perto:
			Jogo.definir_progresso(_progresso)


func _ao_entrar(corpo: Node2D) -> void:
	# O Alfredo também é um corpo na mesma layer e entraria aqui: por isso o filtro
	# por grupo em vez de aceitar qualquer corpo.
	if not corpo.is_in_group("jogador"):
		return
	_caju = corpo
	Jogo.pensar_uma_vez("prox:" + id, pensamento)


func _ao_sair(corpo: Node2D) -> void:
	if corpo != _caju:
		return
	_caju = null
	Jogo.definir_progresso(0.0)         # esconde a barra; o progresso interno decai sozinho


## Zera o progresso na hora. O Alfredo chama isto em todos os interagíveis quando pega o
## Caju em flagrante.
func cancelar() -> void:
	if _progresso > 0.0:
		_progresso = 0.0
		Jogo.definir_progresso(0.0)


# ── métodos virtuais: os filhos sobrescrevem ────────────────────────────────

## Dá para interagir agora? (etapa da vez, fora de recarga, com usos...)
func _esta_ativo() -> bool:
	return true

## Chamado a cada quadro enquanto o progresso sobe.
func _ao_progredir(_delta: float) -> void:
	pass

## Chamado quando o progresso chega a 100%.
func _concluir() -> void:
	pass

## Texto do prompt na tela.
func _texto_prompt() -> String:
	return "%s  [E]" % rotulo
