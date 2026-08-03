extends CharacterBody2D

const SPEED := 100.0

# Tangente do ângulo da câmera (30°)
const TANGENTE_CAMERA := 0.57735026919

const RECARGA_MIADO := 8.0
const DURACAO_BLOQUEIO := 1.5

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var ultima_direcao := "baixo"
var recarga_miado := 0.0


var _acao_secreta_ate := 0
var _bloqueio := 0.0


func _ready() -> void:
	add_to_group("jogador")


func _physics_process(delta: float) -> void:
	if recarga_miado > 0.0:
		recarga_miado = maxf(0.0, recarga_miado - delta)

	if _bloqueio > 0.0:
		_bloqueio -= delta
		velocity = Vector2.ZERO
		animated_sprite_2d.play("parado_" + ultima_direcao)
		move_and_slide()
		return

	if Input.is_action_just_pressed("miar") and recarga_miado <= 0.0:
		recarga_miado = RECARGA_MIADO
		Jogo.aumentar_suspeita(Jogo.SUSPEITA_MIADO)
		Jogo.emitir_ruido(global_position)

	var direcao := Input.get_vector("esquerda", "direita", "cima", "baixo")

	var direcao_iso := Vector2(direcao.x - direcao.y, (direcao.x + direcao.y) * TANGENTE_CAMERA)
	velocity = direcao_iso.normalized() * SPEED

	if direcao != Vector2.ZERO:
		if absf(direcao.x) > absf(direcao.y):
			ultima_direcao = "direita" if direcao.x > 0 else "esquerda"
		else:
			ultima_direcao = "baixo" if direcao.y > 0 else "cima"
		animated_sprite_2d.play("andando_" + ultima_direcao)
	else:
		animated_sprite_2d.play("parado_" + ultima_direcao)
		if Input.is_action_pressed("disfarce"):
			Jogo.reduzir_suspeita(Jogo.LIMPAR_SE * delta)

	move_and_slide()


func marcar_acao_secreta() -> void:
	_acao_secreta_ate = Time.get_ticks_msec() + 200


func esta_em_acao_secreta() -> bool:
	return Time.get_ticks_msec() < _acao_secreta_ate


func levar_para(destino: Vector2) -> void:
	global_position = destino
	velocity = Vector2.ZERO
	_bloqueio = DURACAO_BLOQUEIO
	_acao_secreta_ate = 0
