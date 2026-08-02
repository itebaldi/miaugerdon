extends CharacterBody2D

const SPEED := 100.0

# Tangente do ângulo da câmera (30°)
const TANGENTE_CAMERA := 0.57735026919

const RECARGA_MIADO := 8.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var ultima_direcao := "baixo"
var recarga_miado := 0.0


func _ready() -> void:
	add_to_group("jogador")


func _physics_process(delta: float) -> void:
	if recarga_miado > 0.0:
		recarga_miado = maxf(0.0, recarga_miado - delta)

	if Input.is_action_just_pressed("miar") and recarga_miado <= 0.0:
		recarga_miado = RECARGA_MIADO
		Jogo.aumentar_suspeita(Jogo.SUSPEITA_MIADO)

	var direcao := Input.get_vector("esquerda", "direita", "cima", "baixo")

	# rotaciona o vetor de input para os eixos visuais da câmera isométrica
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
		# limpar-se só funciona parado: baixar a suspeita custa tempo, e tempo é a outra
		# forma de perder
		if Input.is_action_pressed("disfarce"):
			Jogo.reduzir_suspeita(Jogo.LIMPAR_SE * delta)

	move_and_slide()
