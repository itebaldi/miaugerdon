@tool
extends Control
class_name QuadroHQ

# Um quadro da prancha. A arte entra por cobertura: escala até preencher o
# retângulo e escorrega pelo ponto de foco, então o corte tira parede vazia em
# vez de decepar um personagem.
#
# Para reenquadrar a arte dentro do quadro, mexa em "Foco": 0.5,0.5 é o centro;
# 0.5,0.85 puxa o corte para baixo (é o que o quadro do celular usa para não
# cortar as patas do Caju).

const COR_TINTA := Color(0.106, 0.086, 0.071)

@export var imagem: Texture2D:
	set(valor):
		imagem = valor
		queue_redraw()

@export var foco := Vector2(0.5, 0.5):
	set(valor):
		foco = Vector2(clampf(valor.x, 0.0, 1.0), clampf(valor.y, 0.0, 1.0))
		queue_redraw()

@export_range(0, 20, 1) var moldura := 6:
	set(valor):
		moldura = valor
		queue_redraw()

## Sacode a tela quando este quadro aparece. Usado no quadro do impacto.
@export var tremor := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _draw() -> void:
	if imagem != null:
		var original := Vector2(imagem.get_size())
		var escala: float = maxf(size.x / original.x, size.y / original.y)
		var recorte := size / escala
		var origem := (original - recorte) * foco
		draw_texture_rect_region(imagem, Rect2(Vector2.ZERO, size), Rect2(origem, recorte))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.78, 0.72))

	if moldura > 0:
		var meia := float(moldura) * 0.5
		var dentro := Rect2(Vector2(meia, meia), size - Vector2(moldura, moldura))
		draw_rect(dentro, COR_TINTA, false, float(moldura))
