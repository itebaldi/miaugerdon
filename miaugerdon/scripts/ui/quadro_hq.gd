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
# mesmo papel da prancha: é com ele que a máscara apaga a arte que sobra fora
# da moldura ondulada
const COR_PAPEL := Color(0.925, 0.898, 0.843)

const NUVEM_AMPLITUDE := 15.0
const NUVEM_LOBULO := 58.0
const NUVEM_PASSO := 5.0
const NUVEM_ALCANCE := 52.0

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

## Moldura ondulada, a convenção de quadrinho para cena imaginada, sonhada ou
## lembrada. A arte é mascarada na mesma forma, senão os cantos quadrados
## aparecem por fora da moldura.
@export var imaginacao := false:
	set(valor):
		imaginacao = valor
		queue_redraw()


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

	if imaginacao:
		var nuvem := _forma_nuvem()
		_mascarar_fora(nuvem)
		if moldura > 0:
			var fechada := nuvem.duplicate()
			fechada.append(nuvem[0])
			draw_polyline(fechada, COR_TINTA, float(moldura) * 0.85, true)
	elif moldura > 0:
		var meia := float(moldura) * 0.5
		var dentro := Rect2(Vector2(meia, meia), size - Vector2(moldura, moldura))
		draw_rect(dentro, COR_TINTA, false, float(moldura))


# Contorno ondulado. A fase do seno corre pelo perímetro inteiro, não por lado:
# assim os cantos também ganham bolha em vez de ficarem pinçados. O número de
# lóbulos é inteiro, então a onda fecha certinho onde começou.
func _forma_nuvem() -> PackedVector2Array:
	var recuo := Vector2(NUVEM_AMPLITUDE, NUVEM_AMPLITUDE)
	var interno := Rect2(recuo, size - recuo * 2.0)
	var cantos := [
		interno.position,
		Vector2(interno.end.x, interno.position.y),
		interno.end,
		Vector2(interno.position.x, interno.end.y),
	]

	var perimetro := (interno.size.x + interno.size.y) * 2.0
	var lobulos: int = maxi(int(round(perimetro / NUVEM_LOBULO)), 8)
	var passo_lobulo := perimetro / float(lobulos)
	var centro := size * 0.5

	var pontos := PackedVector2Array()
	var percorrido := 0.0
	for lado in 4:
		var a: Vector2 = cantos[lado]
		var b: Vector2 = cantos[(lado + 1) % 4]
		var comprimento := a.distance_to(b)
		var quantos: int = maxi(int(comprimento / NUVEM_PASSO), 8)
		for k in quantos:
			var t := float(k) / float(quantos)
			var ponto := a.lerp(b, t)
			var onda := absf(sin(PI * (percorrido + comprimento * t) / passo_lobulo))
			# empurra pela radial, e não pela normal do lado: no canto a normal
			# vira de uma vez e abriria um degrau
			pontos.append(ponto + (ponto - centro).normalized() * NUVEM_AMPLITUDE * onda)
		percorrido += comprimento
	return pontos


# Pinta de papel tudo que fica entre a onda e a borda do quadro. O recorte real
# vem do clip_contents do próprio quadro, então basta empurrar para fora.
func _mascarar_fora(forma: PackedVector2Array) -> void:
	var centro := size * 0.5
	for i in forma.size():
		var p: Vector2 = forma[i]
		var q: Vector2 = forma[(i + 1) % forma.size()]
		var dp := (p - centro).normalized() * NUVEM_ALCANCE
		var dq := (q - centro).normalized() * NUVEM_ALCANCE
		draw_colored_polygon(PackedVector2Array([p, q, q + dq, p + dp]), COR_PAPEL)
