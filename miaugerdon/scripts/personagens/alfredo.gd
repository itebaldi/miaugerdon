extends CharacterBody2D

## O humano. Faz a ronda pela casa, investiga barulho, e em suspeita alta caça o gato.
##
## POR QUE MÁQUINA DE ESTADOS (um enum) E NÃO VÁRIOS BOOL: com `perseguindo`,
## `investigando` e `bravo` como bool separados, nada impede que dois fiquem `true` ao mesmo
## tempo — e aí o Alfredo tenta ir para dois lugares no mesmo quadro. Com um enum ele está
## em exatamente um estado, sempre, e esse bug fica impossível.
##
## O outro princípio: esta IA não decide "o que fazer", decide "PARA ONDE IR". Andar, animar
## e colidir é consequência, e é o mesmo código nos quatro estados.

const VELOCIDADE_ROTINA := 70.0
## Perseguindo ele é mais rápido, mas ainda abaixo dos 100 do Caju: dá para escapar.
## (Estava 120 antes, e nessa velocidade o gato nunca escapava.)
const VELOCIDADE_CACA := 95.0
const INTERVALO_RECALCULO := 0.2   ## segundos entre recálculos do caminho até o gato
const RAIO_FLAGRANTE := 60.0

## Até onde ele repara no gato, se não tiver nada no caminho. ~1/4 da largura da tela: ele
## nota de um lado ao outro de um cômodo, mas não da cozinha até o quintal.
const ALCANCE_VISAO := 260.0
const ESPERA_ROTINA_MIN := 1.5
const ESPERA_ROTINA_MAX := 3.0
const ESPERA_INVESTIGANDO := 2.0
const ESPERA_BRAVO := 1.5

## Se ele estiver mais longe do que isto da área caminhável, considera-se fora da malha.
const TOLERANCIA_PISO := 18.0
const VELOCIDADE_RESGATE := 55.0

## Vigia de travamento. A espera legítima mais longa é ESPERA_ROTINA_MAX (3 s), então 6 s
## parado só acontece quando algo deu errado.
const LIMITE_TRAVADO := 6.0
const MOVIMENTO_MINIMO := 5.0

enum Estado {
	ROTINA,        ## anda de um ponto de rota a outro, parando para "fazer tarefas"
	INVESTIGANDO,  ## ouviu barulho e vai ver o que foi
	PERSEGUINDO,   ## suspeita alta: vai atrás do gato onde ele estiver
	BRAVO,         ## acabou de pegar o Caju, parado resmungando
}

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var alvo: Node2D
@export var debug_navegacao := false

var ultima_direcao := "baixo"

var _estado := Estado.ROTINA
var _espera := 0.0
var _tempo_desde_recalculo := 0.0
var _rotas: Array[Node2D] = []
var _ponto_inicial := Vector2.ZERO
var _resgatando := false
var _tempo_travado := 0.0
var _pos_vigia := Vector2.ZERO


func _ready() -> void:
	# Conectar ANTES do await: se um barulho acontecer no primeiro quadro, não se perde.
	Jogo.ruido.connect(_ao_ouvir_ruido)

	# O mapa de navegação não fica pronto na primeira frame de física: get_navigation_map()
	# pode devolver um RID nulo, e a primeira iteração do mapa ainda não contém a malha da
	# região (ela entra na iteração 2). Consulta contra mapa nulo responde (0,0) sem erro
	# nenhum — sem esta espera o primeiro destino era descartado em silêncio.
	var passos := 0
	while passos < 30:
		await get_tree().physics_frame
		passos += 1
		var mapa: RID = nav_agent.get_navigation_map()
		if mapa.is_valid() and NavigationServer2D.map_get_iteration_id(mapa) >= 2:
			break

	if not alvo:
		alvo = get_tree().get_first_node_in_group("jogador")

	var no_rotas := get_tree().get_first_node_in_group("rotas")
	if no_rotas:
		for filho in no_rotas.get_children():
			if filho is Node2D:
				_rotas.append(filho)

	var inicio := get_tree().get_first_node_in_group("ponto_inicial")
	_ponto_inicial = inicio.global_position if inicio else global_position

	if debug_navegacao:
		print("[alfredo] alvo=", alvo, " rotas=", _rotas.size(),
			  " mapa_nav_valido=", nav_agent.get_navigation_map().is_valid())

	_ir_para_rota()


func _physics_process(delta: float) -> void:
	if alvo == null:
		alvo = get_tree().get_first_node_in_group("jogador")

	# ANTES de qualquer estado: se a física o empurrou para fora da área caminhável, nada
	# mais funciona (o agente não acha caminho de um ponto que não é chão), e ele fica
	# parado para sempre. Isto tem que ser resolvido primeiro.
	if _resgatar_se_fora_do_piso():
		return

	_vigiar_travamento(delta)
	Jogo.definir_observado(_esta_vendo_o_caju())
	_verificar_flagrante()
	_atualizar_estado()

	match _estado:
		Estado.ROTINA:
			_passo_rotina(delta)
		Estado.INVESTIGANDO:
			_passo_investigando(delta)
		Estado.PERSEGUINDO:
			_passo_perseguindo(delta)
		Estado.BRAVO:
			_passo_bravo(delta)


## A faixa de suspeita manda no estado: em ALTA ele para tudo e vai atrás do gato.
func _atualizar_estado() -> void:
	if _estado == Estado.BRAVO:
		return
	if Jogo.faixa() == Jogo.Faixa.ALTA:
		_estado = Estado.PERSEGUINDO
	elif _estado == Estado.PERSEGUINDO:
		_estado = Estado.ROTINA
		_espera = 0.0
		_ir_para_rota()


# ── os quatro estados ───────────────────────────────────────────────────────

func _passo_rotina(delta: float) -> void:
	if _espera > 0.0:
		_espera -= delta
		_parar()
		if _espera <= 0.0:
			_ir_para_rota()
		return

	if nav_agent.is_navigation_finished():
		_espera = randf_range(ESPERA_ROTINA_MIN, ESPERA_ROTINA_MAX)
		_parar()
		return

	_andar(VELOCIDADE_ROTINA)


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

	_andar(VELOCIDADE_ROTINA)


func _passo_perseguindo(delta: float) -> void:
	# O gato se move, então o caminho tem que ser recalculado de tempo em tempo.
	# A cada quadro seria desperdício: pathfinding não é grátis.
	_tempo_desde_recalculo += delta
	if _tempo_desde_recalculo >= INTERVALO_RECALCULO:
		_tempo_desde_recalculo = 0.0
		if alvo:
			nav_agent.target_position = alvo.global_position

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


# ── resgate: voltar para a área caminhável ──────────────────────────────────

## Um agente de navegação só sabe achar caminho ENTRE pontos que são chão. Se a física
## empurra o corpo para fora da malha — raspando numa parede, ou levando encontrão — o
## agente passa a responder "cheguei" para qualquer destino, e o Alfredo congela.
##
## Nenhum valor de agent_radius evita isso: o navmesh é gerado a partir dos móveis, mas um
## personagem pode ser empurrado por outro corpo em movimento. Então precisa de resgate.
##
## Devolve true se estava resgatando (e o resto do _physics_process deve ser pulado).
func _resgatar_se_fora_do_piso() -> bool:
	if not _navegacao_pronta():
		return false
	var mapa: RID = nav_agent.get_navigation_map()

	var piso := NavigationServer2D.map_get_closest_point(mapa, global_position)
	if global_position.distance_to(piso) <= TOLERANCIA_PISO:
		if _resgatando:
			# Voltou ao chão: o caminho antigo é lixo, escolhe destino novo.
			_resgatando = false
			_espera = 0.0
			_ir_para_rota()
		return false

	_resgatando = true
	# Vai em linha reta para o chão mais próximo, ignorando o caminho.
	var direcao := global_position.direction_to(piso)
	velocity = direcao * VELOCIDADE_RESGATE
	if absf(direcao.x) > absf(direcao.y):
		ultima_direcao = "direita" if direcao.x > 0 else "esquerda"
	else:
		ultima_direcao = "baixo" if direcao.y > 0 else "cima"
	_tocar_animacao("andando", ultima_direcao)
	move_and_slide()
	return true


## Rede de segurança final. O resgate acima cobre "está claramente fora da malha"; isto cobre
## todo o resto: fora por 2 px (que o resgate tolera mas o servidor de navegação não),
## entalado entre dois móveis, ou num laço de destinos que falham. Se ele não sai do lugar por
## LIMITE_TRAVADO segundos, encosta no chão e escolhe outro destino.
##
## Um empurrão de poucos pixels é invisível para o jogador — e infinitamente melhor que um
## Alfredo congelado no meio da cozinha.
func _vigiar_travamento(delta: float) -> void:
	if _estado == Estado.BRAVO or not _navegacao_pronta():
		_tempo_travado = 0.0
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
	if debug_navegacao:
		print("[alfredo] destravado em ", global_position)


# ── movimento (igual para todos os estados) ─────────────────────────────────

func _andar(vel: float) -> void:
	var proximo := nav_agent.get_next_path_position()
	var direcao := global_position.direction_to(proximo)

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
	var destino: Node2D = _rotas[randi() % _rotas.size()]
	nav_agent.target_position = _no_piso(destino.global_position)


## Empurra um ponto qualquer para o chão caminhável mais próximo.
##
## POR QUE ISTO EXISTE: um Marker2D é posicionado no editor, a olho. Se ele cair a 20 px
## dentro de uma parede — ou se alguém aumentar o agent_radius e a malha encolher — aquele
## destino se torna INALCANÇÁVEL, e o agente responde "cheguei" na hora, sem sair do lugar.
## Passando todo destino por aqui, ele é sempre alcançável por construção, e ninguém precisa
## ajustar marcador na mão quando a malha muda.
func _no_piso(ponto: Vector2) -> Vector2:
	if not _navegacao_pronta():
		return ponto
	return NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), ponto)


## O _physics_process comeca a rodar ANTES do _ready() terminar, porque o _ready() tem await
## e portanto e uma corrotina. Nesses primeiros quadros o mapa ainda nao sincronizou, e
## consultar agora imprime "map query failed" no console.
func _navegacao_pronta() -> bool:
	var mapa: RID = nav_agent.get_navigation_map()
	return mapa.is_valid() and NavigationServer2D.map_get_iteration_id(mapa) >= 2


# ── reações ─────────────────────────────────────────────────────────────────

func _ao_ouvir_ruido(posicao: Vector2) -> void:
	# Perseguindo o gato ou bravo, ele não se distrai com barulho.
	if _estado == Estado.BRAVO or _estado == Estado.PERSEGUINDO:
		return
	_estado = Estado.INVESTIGANDO
	_espera = 0.0
	nav_agent.target_position = _no_piso(posicao)


# ── visão ───────────────────────────────────────────────────────────────────

## Ele está com o gato à vista agora?
##
## POR QUE ALCANCE + LINHA DE VISÃO, E NÃO CONE DE VISÃO: um cone (só vê para onde está
## virado) é mais realista, mas o Alfredo é um bonequinho de 32 px com quatro direções — o
## jogador não consegue LER para onde ele está olhando. Punir por algo que não se percebe é
## injusto. Parede e móvel no caminho, por outro lado, o jogador vê na hora.
##
## O efeito colateral é bem-vindo: esconder-se atrás do sofá funciona.
func _esta_vendo_o_caju() -> bool:
	if alvo == null:
		return false
	if global_position.distance_to(alvo.global_position) > ALCANCE_VISAO:
		return false
	return _tem_linha_de_visao(alvo.global_position)


## Traça um raio até o ponto e vê se algo do MUNDO (camada 1) atravessa o caminho.
## O Caju e o Alfredo estão nas camadas 2 e 4, então não bloqueiam a si mesmos.
func _tem_linha_de_visao(ponto: Vector2) -> bool:
	var espaco := get_world_2d().direct_space_state
	var consulta := PhysicsRayQueryParameters2D.create(global_position, ponto)
	consulta.collision_mask = 1
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	return espaco.intersect_ray(consulta).is_empty()


## Pega o Caju no flagra SÓ se ele estiver numa etapa do plano. Fazendo coisa de gato
## (arranhar o sofá, comer, dormir) ele pode olhar à vontade — é o ponto do disfarce.
func _verificar_flagrante() -> void:
	if _estado == Estado.BRAVO or alvo == null:
		return
	if not alvo.has_method("esta_em_acao_secreta") or not alvo.esta_em_acao_secreta():
		return
	if global_position.distance_to(alvo.global_position) > RAIO_FLAGRANTE:
		return
	# Exige ver: antes ele pegava o gato ATRAVÉS de uma parede, o que era simplesmente
	# injusto — o jogador não tinha como prever.
	if not _tem_linha_de_visao(alvo.global_position):
		return
	_flagrar()


func _flagrar() -> void:
	_estado = Estado.BRAVO
	_espera = ESPERA_BRAVO

	# Zera o progresso de qualquer etapa em curso. O grupo evita o Alfredo ter que conhecer
	# os interagíveis um por um.
	get_tree().call_group("interagivel", "cancelar")

	Jogo.avisar("Alfredo te pegou! De volta pra sala.")
	Jogo.aumentar_suspeita(Jogo.FLAGRANTE)   # se estourar 100, a derrota acontece aqui

	if alvo.has_method("levar_para"):
		alvo.levar_para(_ponto_inicial)


# usa a animação da direita espelhada quando a direção é esquerda
func _tocar_animacao(acao: String, dir: String) -> void:
	if dir == "esquerda":
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play(acao + "_direita")
	else:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(acao + "_" + dir)
