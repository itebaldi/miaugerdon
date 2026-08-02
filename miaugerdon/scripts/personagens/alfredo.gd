extends CharacterBody2D

const VELOCIDADE := 70.0
const ESPERA_MIN := 1.5
const ESPERA_MAX := 3.0

# um agente empurrado para fora da área caminhável não acha caminho nenhum, e passa a
# responder "cheguei" para qualquer destino: sem estas duas redes ele congela de vez
const TOLERANCIA_PISO := 18.0
const VELOCIDADE_RESGATE := 55.0
const LIMITE_TRAVADO := 6.0
const MOVIMENTO_MINIMO := 5.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var debug_navegacao := false

var ultima_direcao := "baixo"

var _espera := 0.0
var _rotas: Array[Node2D] = []
var _resgatando := false
var _tempo_travado := 0.0
var _pos_vigia := Vector2.ZERO


func _ready() -> void:
	# consulta feita antes de o mapa sincronizar responde (0,0) sem erro nenhum
	var passos := 0
	while passos < 30:
		await get_tree().physics_frame
		passos += 1
		if _navegacao_pronta():
			break

	var no_rotas := get_tree().get_first_node_in_group("rotas")
	if no_rotas:
		for filho in no_rotas.get_children():
			if filho is Node2D:
				_rotas.append(filho)

	if debug_navegacao:
		print("[alfredo] rotas=%d navegacao_pronta=%s" % [_rotas.size(), _navegacao_pronta()])

	_ir_para_rota()


func _physics_process(delta: float) -> void:
	if _resgatar_se_fora_do_piso():
		return
	_vigiar_travamento(delta)

	if _espera > 0.0:
		_espera -= delta
		_parar()
		if _espera <= 0.0:
			_ir_para_rota()
		return

	if nav_agent.is_navigation_finished():
		_espera = randf_range(ESPERA_MIN, ESPERA_MAX)
		_parar()
		return

	_andar(VELOCIDADE)


func _andar(vel: float) -> void:
	var direcao := global_position.direction_to(nav_agent.get_next_path_position())
	velocity = direcao * vel

	if absf(direcao.x) > absf(direcao.y):
		ultima_direcao = "direita" if direcao.x > 0 else "esquerda"
	else:
		ultima_direcao = "baixo" if direcao.y > 0 else "cima"

	_tocar_animacao("andando", ultima_direcao)
	move_and_slide()


func _parar() -> void:
	velocity = Vector2.ZERO
	_tocar_animacao("parado", ultima_direcao)
	move_and_slide()


func _ir_para_rota() -> void:
	if _rotas.is_empty():
		return
	nav_agent.target_position = _no_piso(_rotas[randi() % _rotas.size()].global_position)


# um Marker2D é posicionado a olho no editor; se cair dentro de uma parede o destino fica
# inalcançável e o agente responde "cheguei" na hora
func _no_piso(ponto: Vector2) -> Vector2:
	if not _navegacao_pronta():
		return ponto
	return NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), ponto)


func _navegacao_pronta() -> bool:
	var mapa: RID = nav_agent.get_navigation_map()
	return mapa.is_valid() and NavigationServer2D.map_get_iteration_id(mapa) >= 2


func _resgatar_se_fora_do_piso() -> bool:
	if not _navegacao_pronta():
		return false

	var piso := _no_piso(global_position)
	if global_position.distance_to(piso) <= TOLERANCIA_PISO:
		if _resgatando:
			_resgatando = false
			_espera = 0.0
			_ir_para_rota()
		return false

	_resgatando = true
	var direcao := global_position.direction_to(piso)
	velocity = direcao * VELOCIDADE_RESGATE
	if absf(direcao.x) > absf(direcao.y):
		ultima_direcao = "direita" if direcao.x > 0 else "esquerda"
	else:
		ultima_direcao = "baixo" if direcao.y > 0 else "cima"
	_tocar_animacao("andando", ultima_direcao)
	move_and_slide()
	return true


# a espera legítima mais longa é ESPERA_MAX, então 6 s parado é sinal de que travou
func _vigiar_travamento(delta: float) -> void:
	if not _navegacao_pronta():
		return

	if _pos_vigia.distance_to(global_position) > MOVIMENTO_MINIMO:
		_pos_vigia = global_position
		_tempo_travado = 0.0
		return

	_tempo_travado += delta
	if _tempo_travado < LIMITE_TRAVADO:
		return

	_tempo_travado = 0.0
	global_position = _no_piso(global_position)
	_pos_vigia = global_position
	_espera = 0.0
	_ir_para_rota()


# usa a animação da direita espelhada quando a direção é esquerda
func _tocar_animacao(acao: String, dir: String) -> void:
	if dir == "esquerda":
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play(acao + "_direita")
	else:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(acao + "_" + dir)
