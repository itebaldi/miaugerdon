@tool
extends Control
class_name PranchaHQ

# A folha em que os quadros são diagramados. Desenha o papel e a sombra de cada
# quadro filho, para a sombra ficar por baixo de tudo e acompanhar o quadro
# quando ele aparece na animação.

const COR_PAPEL := Color(0.925, 0.898, 0.843)
const COR_SOMBRA := Color(0.0, 0.0, 0.0, 0.32)
const DESLOCAMENTO := Vector2(7, 9)

# sombra da folha inteira sobre a mesa: camadas de alfa baixo crescendo para
# fora, que é o mais barato que dá um esfumado sem shader
const SOMBRA_FOLHA := Color(0.0, 0.0, 0.0, 0.055)
const SOMBRA_CAMADAS := 7
const SOMBRA_ALCANCE := 34.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta: float) -> void:
	# as sombras são desenhadas aqui, então precisam ser refeitas enquanto os
	# quadros aparecem; são sete retângulos, não custa nada
	queue_redraw()


func _draw() -> void:
	for i in SOMBRA_CAMADAS:
		var margem := SOMBRA_ALCANCE * (1.0 - float(i) / float(SOMBRA_CAMADAS))
		draw_rect(Rect2(Vector2(-margem, -margem + 8.0), size + Vector2(margem, margem) * 2.0), SOMBRA_FOLHA)
	draw_rect(Rect2(Vector2.ZERO, size), COR_PAPEL)

	for filho in get_children():
		var quadro := filho as QuadroHQ
		if quadro == null or not quadro.visible:
			continue
		# quadro de imaginação não tem canto reto, e uma sombra retangular
		# apareceria por fora da moldura ondulada
		if quadro.imaginacao:
			continue
		var opacidade := quadro.modulate.a
		if opacidade <= 0.01:
			continue
		var cor := COR_SOMBRA
		cor.a *= opacidade
		draw_rect(Rect2(quadro.position + DESLOCAMENTO, quadro.size), cor)


func quadros() -> Array[QuadroHQ]:
	var lista: Array[QuadroHQ] = []
	for filho in get_children():
		var quadro := filho as QuadroHQ
		if quadro != null:
			lista.append(quadro)
	return lista
