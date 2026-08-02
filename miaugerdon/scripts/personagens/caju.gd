extends CharacterBody2D

const SPEED := 100.0

# Tangente do ângulo da câmera (30°)
const TANGENTE_CAMERA := 0.57735026919

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var ultima_direcao := "baixo"

func _physics_process(_delta: float) -> void:
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
		
	y_sort_enabled = true

	move_and_slide()
