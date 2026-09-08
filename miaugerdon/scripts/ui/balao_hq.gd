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

# A etiqueta é desenhada como folha de papel envelhecido: três camadas de
# polígono com a borda irregular, da mais queimada para a mais clara, e umas
# manchas por cima.
const PAPEL_QUEIMADO := Color(0.47, 0.31, 0.13)
const PAPEL_CLARO := Color(0.93, 0.84, 0.62)
const PAPEL_MANCHA := Color(0.52, 0.35, 0.15, 0.05)
const PAPEL_TINTA := Color(0.21, 0.13, 0.06)
const PAPEL_PASSO := 9.0
const PAPEL_RASGO := 8.0
const PAPEL_CAMADAS := 6
const PAPEL_BORDA := 16.0
const PAPEL_SOMBRA := Vector2(6, 7)

const ESPESSURA := 4.0
const RAIO_FALA := 26.0
# meia-largura da boca do rabicho, em pixels. Como ângulo fixo, um balão largo
# abria a boca no lado inteiro; em pixels a boca fica igual em qualquer balão.
const BOCA_RABICHO := 17.0
const RECUO_RABICHO := 12.0
const LOBULOS := 9
const LOBULOS_TENSO := 15
const RECORTE := 0.18
const RECORTE_TENSO := 0.24
const PASSOS := 120
const FOLGA_QUADRO := 6.0

@export var tipo := Tipo.FALA:
	set(valor):
		tipo = valor
		_escrever()

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

@export var risco_cor := Color(0.78, 0.13, 0.11):
	set(valor):
		risco_cor = valor
		queue_redraw()

## Muda o recorte das bordas rasgadas da etiqueta, para duas fichas na mesma
## página não saírem idênticas.
@export var semente := 0:
	set(valor):
		semente = valor
		queue_redraw()

## Se preenchida, substitui o papel desenhado por uma imagem (uma textura de
## pergaminho gerada fora, por exemplo). Só vale para a etiqueta.
@export var textura: Texture2D:
	set(valor):
		textura = valor
		queue_redraw()

## Tinge a textura. Serve para baixar a saturação de um pergaminho que chega
## mais berrante que a arte em volta.
@export var textura_cor := Color(1, 1, 1):
	set(valor):
		textura_cor = valor
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
	_rotulo.add_theme_color_override("default_color", PAPEL_TINTA if tipo == Tipo.ETIQUETA else COR_TINTA)
	# etiqueta é ficha de personagem: nome centralizado no próprio texto e os
	# marcadores alinhados à esquerda, como uma lista. O resto vai centralizado.
	_rotulo.text = texto if tipo == Tipo.ETIQUETA else "[center]%s[/center]" % texto
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
			return Vector2(34, 28)
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
		Tipo.ETIQUETA:
			_desenhar_papel()
		_:
			draw_style_box(_caixa(), Rect2(Vector2.ZERO, size))

	# o rabicho vem depois do corpo de propósito: o preenchimento dele apaga o
	# trecho de borda entre os dois pontos de saída, e é isso que faz o balão
	# "abrir" no rabicho em vez de ficar um triângulo encostado
	if tipo == Tipo.FALA and aponta_para != Vector2.ZERO:
		_desenhar_rabicho()
	elif aponta_para != Vector2.ZERO:
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
			estilo.set_corner_radius_all(int(RAIO_FALA))
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
	# o alvo vem em coordenadas do quadro; a inversa da transformação já cuida
	# de posição, pivô, rotação e escala do balão
	var alvo := get_transform().affine_inverse() * aponta_para
	var direcao := alvo - centro
	if direcao.length() < 1.0:
		return
	direcao = direcao.normalized()

	match tipo:
		Tipo.PENSAMENTO, Tipo.PENSAMENTO_TENSO:
			_desenhar_bolhas(_borda_elipse(centro, direcao), alvo)
		Tipo.ETIQUETA:
			_desenhar_ponteiro(_borda_retangulo(centro, direcao), alvo)
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


func _desenhar_rabicho() -> void:
	var centro := size * 0.5
	var alvo := get_transform().affine_inverse() * aponta_para
	var direcao := alvo - centro
	if direcao.length() < 1.0:
		return
	direcao = direcao.normalized()

	# os dois pontos de saída ficam sobre a borda arredondada de verdade, um de
	# cada lado da direção do alvo
	var base := _borda_forma(centro, direcao)
	var abertura: float = clampf(BOCA_RABICHO / maxf((base - centro).length(), 1.0), 0.05, 0.6)
	var a := _borda_forma(centro, direcao.rotated(abertura))
	var b := _borda_forma(centro, direcao.rotated(-abertura))
	var recuo := direcao * RECUO_RABICHO

	# o polígono entra um pouco para dentro do balão para cobrir a borda
	draw_colored_polygon(PackedVector2Array([a, alvo, b, b - recuo, a - recuo]), _cor_fundo())
	draw_line(a, alvo, COR_TINTA, ESPESSURA, true)
	draw_line(b, alvo, COR_TINTA, ESPESSURA, true)


# Onde o raio saindo do centro cruza o retângulo arredondado. A distância até a
# forma cresce junto com t, então uma busca binária resolve sem marcha nem
# aproximação por canto.
func _borda_forma(centro: Vector2, direcao: Vector2) -> Vector2:
	var perto := 0.0
	var longe := size.length()
	for i in 24:
		var meio := (perto + longe) * 0.5
		if _fora_da_forma(centro + direcao * meio) <= 0.0:
			perto = meio
		else:
			longe = meio
	return centro + direcao * perto


func _fora_da_forma(ponto: Vector2) -> float:
	var interno := Rect2(
		Vector2(RAIO_FALA, RAIO_FALA),
		Vector2(maxf(size.x - RAIO_FALA * 2.0, 1.0), maxf(size.y - RAIO_FALA * 2.0, 1.0))
	)
	var perto := Vector2(
		clampf(ponto.x, interno.position.x, interno.end.x),
		clampf(ponto.y, interno.position.y, interno.end.y)
	)
	return ponto.distance_to(perto) - RAIO_FALA


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


# --- papel envelhecido ------------------------------------------------------

func _desenhar_papel() -> void:
	if textura != null:
		# a sombra reusa o alfa da própria textura, então sai no formato exato
		# da folha rasgada e descola a ficha da parede do quadro
		draw_texture_rect(textura, Rect2(PAPEL_SOMBRA, size), false, Color(0, 0, 0, 0.30))
		draw_texture_rect(textura, Rect2(Vector2.ZERO, size), false, textura_cor)
		return

	# camadas encaixadas da borda queimada até o miolo claro: um degradê feito de
	# polígonos, já que a borda rasgada não caberia num gradiente reto
	for c in PAPEL_CAMADAS:
		var t := float(c) / float(PAPEL_CAMADAS - 1)
		var recuo := lerpf(0.0, PAPEL_BORDA, t)
		var forca := lerpf(1.0, 0.40, t)
		draw_colored_polygon(_forma_papel(recuo, forca), PAPEL_QUEIMADO.lerp(PAPEL_CLARO, pow(t, 0.7)))
	_desenhar_manchas()


# Percorre o perímetro deslocando cada ponto para fora com um ruído fixo, o que
# dá a borda rasgada. Cada camada usa os mesmos índices, então as três ficam
# paralelas e formam a faixa queimada.
func _forma_papel(recuo: float, forca: float) -> PackedVector2Array:
	var canto := Vector2(recuo, recuo)
	var medida := Vector2(maxf(size.x - recuo * 2.0, 8.0), maxf(size.y - recuo * 2.0, 8.0))
	var area := Rect2(canto, medida)
	var cantos := [
		area.position,
		Vector2(area.end.x, area.position.y),
		area.end,
		Vector2(area.position.x, area.end.y),
	]
	var por_lado := [
		maxi(int(size.x / PAPEL_PASSO), 3),
		maxi(int(size.y / PAPEL_PASSO), 3),
		maxi(int(size.x / PAPEL_PASSO), 3),
		maxi(int(size.y / PAPEL_PASSO), 3),
	]

	var pontos := PackedVector2Array()
	var i := 0
	for lado in 4:
		var a: Vector2 = cantos[lado]
		var b: Vector2 = cantos[(lado + 1) % 4]
		var fora := (b - a).normalized().rotated(-PI * 0.5)
		var quantos: int = por_lado[lado]
		for k in quantos:
			pontos.append(a.lerp(b, float(k) / float(quantos)) + fora * _rasgo(i) * forca)
			i += 1
	return pontos


func _rasgo(indice: int) -> float:
	var s := float(semente) * 7.31
	var alto := sin(float(indice) * 12.9898 + s) * 43758.5453
	alto = alto - floorf(alto)
	var baixo := sin(float(indice) * 0.63 + s * 0.5)
	return (alto * 2.0 - 1.0) * PAPEL_RASGO * 0.75 + baixo * PAPEL_RASGO * 0.3


# Manchas em círculos concêntricos de alfa baixo: sem isso a borda do círculo
# aparece como um disco cinza chapado.
func _desenhar_manchas() -> void:
	for m in 5:
		var s := float(semente) * 3.7 + float(m) * 19.3
		var ponto := Vector2(
			lerpf(size.x * 0.20, size.x * 0.80, sin(s) * 0.5 + 0.5),
			lerpf(size.y * 0.28, size.y * 0.72, cos(s * 1.7) * 0.5 + 0.5)
		)
		var raio := lerpf(size.y * 0.14, size.y * 0.26, absf(sin(s * 2.3)))
		for camada in 4:
			draw_circle(ponto, raio * (0.4 + 0.2 * float(camada)), PAPEL_MANCHA)


func _desenhar_risco() -> void:
	draw_line(risco_inicio, risco_inicio + Vector2(risco_largura, 0), risco_cor, 3.0, true)
