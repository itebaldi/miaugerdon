extends CharacterBody2D

const SPEED := 120.0
const INTERVALO_RECALCULO := 0.2  # segundos entre recálculos do caminho

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var alvo: Node2D
@export var debug_navegacao := false

var ultima_direcao := "baixo"
var _tempo_desde_recalculo := 0.0


func _ready() -> void:
	# o mapa de navegação só existe a partir do 1º frame de física
	await get_tree().physics_frame

	if not alvo:
		alvo = get_tree().get_first_node_in_group("jogador")

	_atualizar_alvo()


func _atualizar_alvo() -> void:
	if not alvo:
		return

	nav_agent.target_position = alvo.global_position

	if debug_navegacao:
		print("alcançável: ", nav_agent.is_target_reachable(),
			  " | pontos: ", nav_agent.get_current_navigation_path().size())


func _physics_process(delta: float) -> void:
	# recalcula o caminho periodicamente, já que o alvo se move
	_tempo_desde_recalculo += delta
	if _tempo_desde_recalculo >= INTERVALO_RECALCULO:
		_tempo_desde_recalculo = 0.0
		_atualizar_alvo()

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		_tocar_animacao("parado", ultima_direcao)
		move_and_slide()
		return

	var proximo := nav_agent.get_next_path_position()
	var direcao := global_position.direction_to(proximo)

	velocity = direcao * SPEED

	if absf(direcao.x) > absf(direcao.y):
		ultima_direcao = "direita" if direcao.x > 0 else "esquerda"
	else:
		ultima_direcao = "baixo" if direcao.y > 0 else "cima"

	_tocar_animacao("andando", ultima_direcao)

	move_and_slide()


# usa a animação da direita espelhada quando a direção é esquerda
func _tocar_animacao(acao: String, dir: String) -> void:
	if dir == "esquerda":
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play(acao + "_direita")
	else:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(acao + "_" + dir)
