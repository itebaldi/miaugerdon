extends CharacterBody2D

## O gato. Movimento, animação, e as duas habilidades de teclado: limpar-se (F) e miar (Q).

const SPEED := 100.0

# Tangente do ângulo da câmera (30°)
const TANGENTE_CAMERA := 0.57735026919

const RECARGA_MIADO := 8.0
const SUSPEITA_MIADO := 3.0
const DURACAO_BLOQUEIO := 1.5   ## segundos sem controle depois de ser pego

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var ultima_direcao := "baixo"

## Milissegundo até quando o Caju conta como "fazendo ação secreta".
## Quem está progredindo numa etapa chama marcar_acao_secreta() a cada quadro, e a marca
## expira sozinha. Isso é mais robusto que um bool ligado/desligado: se o jogador sair de
## perto no meio da ação, ninguém precisa se lembrar de desligar.
var _acao_secreta_ate := 0
var _bloqueio := 0.0
var _recarga_miado := 0.0


func _ready() -> void:
	# O Alfredo procura o Caju por este grupo. Sem isto a IA dele não encontra ninguém —
	# e falha em silêncio, sem erro no console. Ver Parte 13 do TUTORIAL.md.
	add_to_group("jogador")


func _physics_process(delta: float) -> void:
	if _recarga_miado > 0.0:
		_recarga_miado = maxf(0.0, _recarga_miado - delta)

	# Pego em flagrante: o Alfredo carregou o gato de volta e ele fica tonto um instante.
	if _bloqueio > 0.0:
		_bloqueio -= delta
		velocity = Vector2.ZERO
		animated_sprite_2d.play("parado_" + ultima_direcao)
		move_and_slide()
		return

	if Input.is_action_just_pressed("miar") and _recarga_miado <= 0.0:
		_miar()

	var direcao := Input.get_vector("esquerda", "direita", "cima", "baixo")

	# Rotaciona o vetor de input para os eixos visuais da câmera isométrica: apertar para a
	# direita tem que andar para a direita NA TELA, e na planta isométrica esse eixo é
	# diagonal. Ver Parte 5 do TUTORIAL.md para a conta.
	var direcao_iso := Vector2(direcao.x - direcao.y, (direcao.x + direcao.y) * TANGENTE_CAMERA)
	velocity = direcao_iso.normalized() * SPEED

	if direcao != Vector2.ZERO:
		# decide se a direção "dominante" é horizontal ou vertical
		if absf(direcao.x) > absf(direcao.y):
			ultima_direcao = "direita" if direcao.x > 0 else "esquerda"
		else:
			ultima_direcao = "baixo" if direcao.y > 0 else "cima"
		animated_sprite_2d.play("andando_" + ultima_direcao)
	else:
		animated_sprite_2d.play("parado_" + ultima_direcao)
		# Limpar-se só funciona com o gato imóvel: é a válvula sempre disponível, mas custa
		# tempo parado — e tempo é a outra forma de perder.
		if Input.is_action_pressed("disfarce"):
			Jogo.reduzir_suspeita(Jogo.LIMPAR_SE * delta)

	move_and_slide()


func _miar() -> void:
	_recarga_miado = RECARGA_MIADO
	Jogo.aumentar_suspeita(SUSPEITA_MIADO)
	Jogo.emitir_ruido(global_position)
	Jogo.pensar_uma_vez("miar", "Miau. Agora ele vem pra cá — e eu vou pra lá.")


# ── ação secreta: o que dá flagrante ────────────────────────────────────────

func marcar_acao_secreta() -> void:
	_acao_secreta_ate = Time.get_ticks_msec() + 200


func esta_em_acao_secreta() -> bool:
	return Time.get_ticks_msec() < _acao_secreta_ate


## Chamado pelo Alfredo ao pegar o Caju: leva o gato para longe e tira o controle um instante.
func levar_para(destino: Vector2) -> void:
	global_position = destino
	velocity = Vector2.ZERO
	_bloqueio = DURACAO_BLOQUEIO
	_acao_secreta_ate = 0
