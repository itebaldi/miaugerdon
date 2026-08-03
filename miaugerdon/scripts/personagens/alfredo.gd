extends CharacterBody2D

const VELOCIDADE := 70.0

const VELOCIDADE_CACA := 95.0
const ESPERA_MIN := 1.5
const ESPERA_MAX := 3.0
const ESPERA_INVESTIGANDO := 2.0
const ESPERA_BRAVO := 1.5
const RAIO_FLAGRANTE := 60.0

const ALCANCE_VISAO := 260.0
const INTERVALO_RECALCULO := 0.2

const DISTANCIA_MINIMA_ROTA := 80.0

const TOLERANCIA_PISO := 18.0
const VELOCIDADE_RESGATE := 55.0
const LIMITE_TRAVADO := 1.2
const MOVIMENTO_MINIMO := 3.0

enum Estado { ROTINA, INVESTIGANDO, PERSEGUINDO, BRAVO }

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var alvo: Node2D
@export var debug_navegacao := false

var ultima_direcao := "baixo"

var _estado := Estado.ROTINA
var _espera := 0.0
var _tempo_desde_recalculo := 0.0
var _ponto_inicial := Vector2.ZERO
var _rotas: Array[Node2D] = []
var _resgatando := false
var _tempo_travado := 0.0
var _pos_vigia := Vector2.ZERO
var _travamentos_seguidos := 0


func _ready() -> void:
	Jogo.ruido.connect(_ao_ouvir_ruido)

	var passos := 0
	while passos < 30:
		await get_tree().physics_frame
		passos += 1
		if _navegacao_pronta():
			break

	if not alvo:
		alvo = get_tree().get_first_node_in_group("jogador")

	var inicio := get_tree().get_first_node_in_group("ponto_inicial")
	_ponto_inicial = inicio.global_position if inicio else global_position

	var no_rotas := get_tree().get_first_node_in_group("rotas")
	if no_rotas:
		for filho in no_rotas.get_children():
			if filho is Node2D:
				_rotas.append(filho)

	if debug_navegacao:
		print("[alfredo] rotas=%d navegacao_pronta=%s" % [_rotas.size(), _navegacao_pronta()])

	_ir_para_rota()


func _physics_process(delta: float) -> void:
	if alvo == null:
		alvo = get_tree().get_first_node_in_group("jogador")

	if _resgatar_se_fora_do_piso():
		return
	_vigiar_travamento(delta)
	Jogo.definir_observado(_esta_vendo_o_caju())
	_verificar_flagrante()
	_atualizar_estado()

	match _estado:
		Estado.ROTINA:
			_passo_espera_e_anda(delta, ESPERA_MIN, ESPERA_MAX, VELOCIDADE)
		Estado.INVESTIGANDO:
			_passo_investigando(delta)
		Estado.PERSEGUINDO:
			_passo_perseguindo(delta)
		Estado.BRAVO:
			_passo_bravo(delta)


func _atualizar_estado() -> void:
	if _estado == Estado.BRAVO:
		return
	if Jogo.faixa() == Jogo.Faixa.ALTA:
		_estado = Estado.PERSEGUINDO
	elif _estado == Estado.PERSEGUINDO:
		_estado = Estado.ROTINA
		_espera = 0.0
		_ir_para_rota()


func _passo_espera_e_anda(delta: float, min_espera: float, max_espera: float, vel: float) -> void:
	if _espera > 0.0:
		_espera -= delta
		_parar()
		if _espera <= 0.0:
			_ir_para_rota()
		return

	if nav_agent.is_navigation_finished():
		_espera = randf_range(min_espera, max_espera)
		_parar()
		return

	_andar(vel)


func _passo_investigando(delta: float) -> void:
	if _espera > 0.0:
		_espera -= delta
		_parar()
		if _espera <= 0.0:
			_estado = Estado.ROTINA
			_ir_para_rota()
		return

	if nav_agent.is_navigation_finished():
		_espera = ESPERA_INVESTIGANDO
		_parar()
		return

	_andar(VELOCIDADE)


func _passo_perseguindo(delta: float) -> void:
	_tempo_desde_recalculo += delta
	if _tempo_desde_recalculo >= INTERVALO_RECALCULO:
		_tempo_desde_recalculo = 0.0
		if alvo:
			nav_agent.target_position = _no_piso(alvo.global_position)

	if nav_agent.is_navigation_finished():
		_parar()
		return

	_andar(VELOCIDADE_CACA)


func _passo_bravo(delta: float) -> void:
	_espera -= delta
	_parar()
	if _espera <= 0.0:
		_estado = Estado.ROTINA
		_ir_para_rota()


func _ao_ouvir_ruido(posicao: Vector2) -> void:
	if _estado == Estado.BRAVO or _estado == Estado.PERSEGUINDO:
		return
	_estado = Estado.INVESTIGANDO
	_espera = 0.0
	nav_agent.target_position = _no_piso(posicao)


func _esta_vendo_o_caju() -> bool:
	if alvo == null:
		return false
	if global_position.distance_to(alvo.global_position) > ALCANCE_VISAO:
		return false
	return _tem_linha_de_visao(alvo.global_position)


func _tem_linha_de_visao(ponto: Vector2) -> bool:
	var consulta := PhysicsRayQueryParameters2D.create(global_position, ponto)
	consulta.collision_mask = 1
	consulta.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func _verificar_flagrante() -> void:
	if _estado == Estado.BRAVO or alvo == null:
		return
	if not alvo.has_method("esta_em_acao_secreta") or not alvo.esta_em_acao_secreta():
		return
	if global_position.distance_to(alvo.global_position) > RAIO_FLAGRANTE:
		return
	if not _tem_linha_de_visao(alvo.global_position):
		return

	_estado = Estado.BRAVO
	_espera = ESPERA_BRAVO
	get_tree().call_group("interagivel", "cancelar")
	Jogo.avisar("Alfredo te pegou! De volta pra sala.")
	Jogo.aumentar_suspeita(Jogo.FLAGRANTE)
	if alvo.has_method("levar_para"):
		alvo.levar_para(_ponto_inicial)


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

	var piso := _no_piso(global_position)
	if global_position.distance_to(piso) > 0.5:
		global_position = piso


	var longe: Array[Node2D] = []
	for rota in _rotas:
		if piso.distance_to(rota.global_position) > DISTANCIA_MINIMA_ROTA:
			longe.append(rota)
	if longe.is_empty():
		longe = _rotas
	nav_agent.target_position = _no_piso(longe[randi() % longe.size()].global_position)



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
	_estado = Estado.ROTINA
	var direcao := global_position.direction_to(piso)
	velocity = direcao * VELOCIDADE_RESGATE
	if absf(direcao.x) > absf(direcao.y):
		ultima_direcao = "direita" if direcao.x > 0 else "esquerda"
	else:
		ultima_direcao = "baixo" if direcao.y > 0 else "cima"
	_tocar_animacao("andando", ultima_direcao)
	move_and_slide()
	return true


func _vigiar_travamento(delta: float) -> void:
	if not _navegacao_pronta() or _estado == Estado.BRAVO or _espera > 0.0:
		_tempo_travado = 0.0
		_pos_vigia = global_position
		return

	if _pos_vigia.distance_to(global_position) > MOVIMENTO_MINIMO:
		_pos_vigia = global_position
		_tempo_travado = 0.0
		_travamentos_seguidos = 0
		return

	_tempo_travado += delta
	if _tempo_travado < LIMITE_TRAVADO:
		return

	_tempo_travado = 0.0
	_travamentos_seguidos += 1
	if _travamentos_seguidos >= 3 and not _rotas.is_empty():
		global_position = _no_piso(_rotas[randi() % _rotas.size()].global_position)
		_travamentos_seguidos = 0
	else:
		global_position = _no_piso(global_position)
	_pos_vigia = global_position
	_espera = 0.0
	_ir_para_rota()


func _tocar_animacao(acao: String, dir: String) -> void:
	if dir == "esquerda":
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play(acao + "_direita")
	else:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(acao + "_" + dir)
