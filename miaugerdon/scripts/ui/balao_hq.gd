@tool
extends Control
class_name BalaoHQ

# Balão de quadrinho desenhado em runtime. É @tool: o que você vê no editor é o
# que aparece no jogo, então dá para arrastar, redimensionar e trocar o texto
# direto na cena da abertura.
#
# Para mover: arraste no editor 2D, ou mexa em Layout > Transform.
# Para o rabicho: mova "Aponta Para" (coordenadas do quadro, não da tela).
# Vector2.ZERO em "Aponta Para" = balão sem rabicho.

enum Tipo { FALA, PENSAMENTO, PENSAMENTO_TENSO, NARRACAO, ETIQUETA }

const COR_TINTA := Color(0.106, 0.086, 0.071)
const COR_FALA := Color(0.976, 0.965, 0.929)
const COR_PENSAMENTO := Color(0.980, 0.973, 0.949)
const COR_TENSO := Color(1.0, 0.945, 0.929)
const COR_NARRACAO := Color(0.945, 0.886, 0.745)
const COR_ETIQUETA := Color(0.992, 0.969, 0.902)

const ESPESSURA := 4.0
const LOBULOS := 9
const LOBULOS_TENSO := 15
const RECORTE := 0.18
const RECORTE_TENSO := 0.24
const PASSOS := 120
const FOLGA_QUADRO := 6.0

@export var tipo := Tipo.FALA:
	set(valor):
		tipo = valor
		_aplicar_medidas()
		queue_redraw()

@export_multiline var texto := "":
	set(valor):
		texto = valor
		_escrever()

@export_range(10, 48, 1) var fonte := 21:
	set(valor):
		fonte = valor
		_escrever()

## Ponto do quadro para onde o rabicho aponta. Zero deixa o balão sem rabicho.
@export var aponta_para := Vector2.ZERO:
	set(valor):
		aponta_para = valor
		queue_redraw()

## Risco de caneta por cima de uma palavra (o "servo" do Alfredo). O [s] do
## BBCode não desenha nada nesta engine, então o traço é feito à mão.
@export var risco_inicio := Vector2.ZERO:
	set(valor):
		risco_inicio = valor
		queue_redraw()

@export var risco_largura := 0.0:
	set(valor):
		risco_largura = valor
		queue_redraw()

var _caixa_texto: CenterContainer
var _rotulo: RichTextLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# o rabicho é desenhado em relação à posição do balão, então mover o nó
	# precisa redesenhar — senão ele fica apontando para o lugar antigo
	set_notify_transform(true)
	if not resized.is_connected(_ao_redimensionar):
		resized.connect(_ao_redimensionar)
	_escrever()
	if not Engine.is_editor_hint():
		_crescer_se_precisar.call_deferred()


func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


func _ao_redimensionar() -> void:
	_aplicar_medidas()
	queue_redraw()


# --- texto ------------------------------------------------------------------

# O rótulo é criado em código e nunca recebe owner, então não é salvo na cena:
# o que fica no .tscn é só o balão com suas propriedades.
func _escrever() -> void:
	if not is_node_ready():
		return

	if _caixa_texto != null and is_instance_valid(_caixa_texto):
		_caixa_texto.queue_free()

	_caixa_texto = CenterContainer.new()
	_caixa_texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caixa_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caixa_texto, false, Node.INTERNAL_MODE_BACK)

	_rotulo = RichTextLabel.new()
	_rotulo.bbcode_enabled = true
	_rotulo.fit_content = true
	_rotulo.scroll_active = false
	_rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.add_theme_font_size_override("normal_font_size", fonte)
	_rotulo.add_theme_font_size_override("bold_font_size", fonte)
	_rotulo.add_theme_color_override("default_color", COR_TINTA)
	_rotulo.text = "[center]%s[/center]" % texto
	_caixa_texto.add_child(_rotulo)

	_aplicar_medidas()
	queue_redraw()


func _aplicar_medidas() -> void:
	pivot_offset = size * 0.5
	if _caixa_texto == null or not is_instance_valid(_caixa_texto):
		return
	var margem := _margem_interna()
	_caixa_texto.offset_left = margem.x
	_caixa_texto.offset_top = margem.y
	_caixa_texto.offset_right = -margem.x
	_caixa_texto.offset_bottom = -margem.y
	_rotulo.custom_minimum_size = Vector2(maxf(size.x - margem.x * 2.0, 20.0), 0)


# Rede de segurança só no jogo: se um texto novo não couber na altura desenhada,
# o balão cresce em vez de vazar. No editor não cresce, para você enxergar o
# transbordo e resolver arrastando.
func _crescer_se_precisar() -> void:
	await get_tree().process_frame
	if _rotulo == null or not is_instance_valid(_rotulo):
		return

	var necessario := _altura_para(_rotulo.get_content_height())
	if necessario <= size.y:
		return

	var meio := position.y + size.y * 0.5
	size.y = necessario
	position.y = meio - size.y * 0.5
	_encaixar_no_quadro()


func _altura_para(conteudo: float) -> float:
	match tipo:
		Tipo.PENSAMENTO, Tipo.PENSAMENTO_TENSO:
			return (conteudo + 12.0) / maxf(1.0 - 2.0 * _recorte(), 0.2)
		Tipo.ETIQUETA:
			return conteudo + 20.0
		_:
			return conteudo + 28.0


func _encaixar_no_quadro() -> void:
	var quadro := get_parent() as Control
	if quadro == null:
		return
	position.x = clampf(position.x, FOLGA_QUADRO, maxf(quadro.size.x - size.x - FOLGA_QUADRO, FOLGA_QUADRO))
	position.y = clampf(position.y, FOLGA_QUADRO, maxf(quadro.size.y - size.y - FOLGA_QUADRO, FOLGA_QUADRO))


# --- desenho ----------------------------------------------------------------

func _recorte() -> float:
	return RECORTE_TENSO if tipo == Tipo.PENSAMENTO_TENSO else RECORTE


func _margem_interna() -> Vector2:
	match tipo:
		Tipo.PENSAMENTO, Tipo.PENSAMENTO_TENSO:
			return size * _recorte() + Vector2(6, 6)
		Tipo.ETIQUETA:
			return Vector2(14, 10)
		_:
			return Vector2(18, 14)


func _cor_fundo() -> Color:
	match tipo:
		Tipo.PENSAMENTO:
			return COR_PENSAMENTO
		Tipo.PENSAMENTO_TENSO:
			return COR_TENSO
		Tipo.NARRACAO:
			return COR_NARRACAO
		Tipo.ETIQUETA:
			return COR_ETIQUETA
		_:
			return COR_FALA


func _draw() -> void:
	match tipo:
		Tipo.PENSAMENTO, Tipo.PENSAMENTO_TENSO:
			var forma := _forma_nuvem()
			draw_colored_polygon(forma, _cor_fundo())
			var fechada := forma.duplicate()
			fechada.append(forma[0])
			draw_polyline(fechada, COR_TINTA, ESPESSURA, true)
		_:
			draw_style_box(_caixa(), Rect2(Vector2.ZERO, size))

	if aponta_para != Vector2.ZERO:
		_desenhar_ligacao()
	if risco_largura > 0.0:
		_desenhar_risco()


func _caixa() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = _cor_fundo()
	estilo.border_color = COR_TINTA
	estilo.set_border_width_all(int(ESPESSURA))
	match tipo:
		Tipo.NARRACAO:
			estilo.set_corner_radius_all(3)
		Tipo.ETIQUETA:
			estilo.set_corner_radius_all(6)
		_:
			estilo.set_corner_radius_all(26)
	return estilo


# Nuvem de pensamento: uma elipse com o raio modulado. Expoente baixo dá lóbulos
# gordos; expoente alto deixa só espigões, que é o balão do quadro do impacto.
func _forma_nuvem() -> PackedVector2Array:
	var centro := size * 0.5
	var raio := size * 0.5
	var tenso := tipo == Tipo.PENSAMENTO_TENSO
	var lobulos: int = LOBULOS_TENSO if tenso else LOBULOS
	var amplitude := 0.30 if tenso else 0.13
	var expoente := 3.0 if tenso else 0.55

	var pontos := PackedVector2Array()
	for i in PASSOS:
		var t := TAU * float(i) / float(PASSOS)
		var onda: float = pow(absf(sin(float(lobulos) * t * 0.5)), expoente)
		var fator: float = 1.0 - amplitude + amplitude * onda
		pontos.append(centro + Vector2(cos(t) * raio.x, sin(t) * raio.y) * fator)
	return pontos


func _desenhar_ligacao() -> void:
	var centro := size * 0.5
	var alvo := aponta_para - position
	var direcao := alvo - centro
	if direcao.length() < 1.0:
		return
	direcao = direcao.normalized()

	match tipo:
		Tipo.PENSAMENTO, Tipo.PENSAMENTO_TENSO:
			_desenhar_bolhas(_borda_elipse(centro, direcao), alvo)
		Tipo.ETIQUETA:
			_desenhar_ponteiro(_borda_retangulo(centro, direcao), alvo)
		Tipo.FALA:
			_desenhar_rabicho(centro, direcao, alvo)
		_:
			pass


func _borda_retangulo(centro: Vector2, direcao: Vector2) -> Vector2:
	var tx: float = (size.x * 0.5) / maxf(absf(direcao.x), 0.0001)
	var ty: float = (size.y * 0.5) / maxf(absf(direcao.y), 0.0001)
	return centro + direcao * (minf(tx, ty) - 2.0)


func _borda_elipse(centro: Vector2, direcao: Vector2) -> Vector2:
	var rx: float = maxf(size.x * 0.5, 1.0)
	var ry: float = maxf(size.y * 0.5, 1.0)
	var d: float = sqrt(pow(direcao.x / rx, 2.0) + pow(direcao.y / ry, 2.0))
	if d < 0.0001:
		return centro
	return centro + direcao * ((1.0 / d) * (1.0 - _recorte() * 0.5))


func _desenhar_rabicho(centro: Vector2, direcao: Vector2, alvo: Vector2) -> void:
	var base := _borda_retangulo(centro, direcao)
	var perpendicular := Vector2(-direcao.y, direcao.x)
	var largura: float = clampf((alvo - base).length() * 0.22, 12.0, 22.0)
	var a := base + perpendicular * largura
	var b := base - perpendicular * largura

	draw_colored_polygon(PackedVector2Array([a, b, alvo]), _cor_fundo())
	draw_line(a, alvo, COR_TINTA, ESPESSURA, true)
	draw_line(b, alvo, COR_TINTA, ESPESSURA, true)


func _desenhar_bolhas(inicio: Vector2, alvo: Vector2) -> void:
	for i in 3:
		var passo := (float(i) + 1.0) / 3.7
		var ponto := inicio.lerp(alvo, passo)
		var raio: float = lerpf(13.0, 5.0, float(i) / 2.0)
		draw_circle(ponto, raio, _cor_fundo())
		draw_arc(ponto, raio, 0.0, TAU, 22, COR_TINTA, ESPESSURA * 0.7, true)


func _desenhar_ponteiro(inicio: Vector2, alvo: Vector2) -> void:
	draw_line(inicio, alvo, COR_TINTA, ESPESSURA * 0.7, true)
	draw_circle(alvo, 7.0, COR_TINTA)


func _desenhar_risco() -> void:
	var fim := risco_inicio + Vector2(risco_largura, 0)
	var meio := risco_inicio.lerp(fim, 0.5) + Vector2(0, -2.0)
	draw_line(risco_inicio, meio, COR_TINTA, 3.0, true)
	draw_line(meio, fim + Vector2(0, 0.5), COR_TINTA, 3.0, true)
