extends SceneTree

# Prepara as peças da HUD vindas do Firefly (sprites/origem/ui) para o jogo
# (sprites/ui). Ele já entrega sem fundo; as peças geradas sobre verde chapado
# (as que precisam de miolo vazado) vêm com o verde, e aqui ele sai.
#
# A HUD é pintada, não pixel art: o HUD.Raiz filtra em linear com mipmaps, e
# aqui só se corta a margem e reduz para perto do tamanho de uso.
#
# Rodar:  Godot --headless --path . --script ferramentas/tratar_ui.gd

const ORIGEM := "res://sprites/origem/ui/"
const DESTINO := "res://sprites/ui/"

const VERDE := 1  # veio sobre verde: tirar o verde
const SEM_CORTE := 2  # manter o recorte dado, sem aparar a margem vazia

# origem, destino, recorte na imagem original (vazio = tudo), maior dimensão final, opções
const TAREFAS := [
	# a imagem traz três tiras; basta a de cima
	["fita_crepe.png", "fita_crepe.png", Rect2i(40, 110, 960, 240), 160, VERDE],
	["tira_papel.png", "tira_papel.png", Rect2i(), 520, 0],
	# o botão fatia a tira em 9 e desenha os cantos no tamanho da textura:
	# com a de 520 os cantos sozinhos já seriam mais altos que o botão
	["tira_papel.png", "botao_papel.png", Rect2i(), 240, 0],
	["moldura_retrato.png", "moldura_retrato.png", Rect2i(), 360, VERDE],
	["pata_continuar.png", "pata_continuar.png", Rect2i(), 96, 0],
	["suspeita_1.png", "suspeita_1.png", Rect2i(), 128, 0],
	["suspeita_2.png", "suspeita_2.png", Rect2i(), 128, 0],
	["suspeita_3.png", "suspeita_3.png", Rect2i(), 128, 0],
	["barra_suspeita.png", "barra_tubo.png", Rect2i(), 600, VERDE],
	["cronometro_caixa.png", "cronometro_caixa.png", Rect2i(), 128, 0],
	# fatiado em 9 com a largura de uso: só o meio da altura estica, e a fita
	# de cima e a dobra do canto ficam intactas
	["objetivo_postit.png", "objetivo_postit.png", Rect2i(), 260, 0],
	["observado_olho.png", "observado_olho.png", Rect2i(), 96, 0],
	# as duas caixas no mesmo recorte, senão a pata que vaza da marcada deixa
	# o quadrado dela menor que o da vazia
	["checkbox.png", "checkbox_vazio.png", Rect2i(70, 262, 480, 460), 48, SEM_CORTE],
	["checkbox.png", "checkbox_feito.png", Rect2i(990, 262, 480, 460), 48, SEM_CORTE],
	["folha_plano.png", "folha_plano.png", Rect2i(), 600, 0],
	["menu_fundo.png", "menu_fundo.png", Rect2i(), 1536, SEM_CORTE],
	# no dobro do tamanho de uso: o HUD desenha em meia escala para ficar nítida
	# em tela cheia (o NinePatchRect desenha os cantos no tamanho da textura)
	["dialogo_moldura.png", "dialogo_moldura.png", Rect2i(), 992, 0],
	["logo.png", "logo.png", Rect2i(), 1100, 0],
	# o fogo fica sobre preto e é somado ao que está atrás: não se recorta
	["logo_fogo.png", "logo_fogo.png", Rect2i(), 1100, SEM_CORTE],
]

# Onde o rosto do Caju muda na logo piscando, em pixels da imagem original. O
# preenchimento generativo refez a imagem inteira, mas fora do rosto só mexeu
# em contornos finos; trocar só o rosto evita a logo tremer a cada piscada.
const ROSTO_CENTRO := Vector2(795, 320)
const ROSTO_RAIO := Vector2(200, 130)

# a fita veio da mesma cor do pergaminho e sumia em cima dele; clareada e
# translúcida ela passa a ler como fita crepe
const FITA_CLARA := Color(0.97, 0.95, 0.9)


func _init() -> void:
	for tarefa in TAREFAS:
		var nome: String = tarefa[1]
		var opcoes: int = tarefa[4]
		var img := Image.load_from_file(ProjectSettings.globalize_path(ORIGEM + tarefa[0]))
		img.convert(Image.FORMAT_RGBA8)
		var recorte: Rect2i = tarefa[2]
		if recorte.has_area():
			img = img.get_region(recorte)
		if opcoes & VERDE:
			_tirar_verde(img)
		if not opcoes & SEM_CORTE:
			img = img.get_region(_area_usada(img))
		if nome == "fita_crepe.png":
			_clarear(img, FITA_CLARA, 0.5, 0.82)
		img = _reduzir(img, tarefa[3])
		img.save_png(ProjectSettings.globalize_path(DESTINO + nome))
		print(DESTINO + nome, "  ", img.get_size())
		if nome == "moldura_retrato.png":
			print("  janela da foto: ", _janela(img, 0.5).get_used_rect())
		if nome == "barra_tubo.png":
			_salvar_liquido(img)

	_compor_piscada()
	_compor_trilha()

	# o painel de pergaminho é a ficha da HQ de abertura, reduzida
	var ficha := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/abertura/ficha1.png"))
	ficha.convert(Image.FORMAT_RGBA8)
	ficha = _reduzir(ficha.get_region(_area_usada(ficha)), 760)
	ficha.save_png(ProjectSettings.globalize_path(DESTINO + "painel_papel.png"))
	print(DESTINO + "painel_papel.png  ", ficha.get_size())
	quit()


# A logo com os olhos fechados: a logo aberta com o rosto da piscando por cima,
# esfumado nas bordas, cortada e reduzida igual à aberta para as duas trocarem
# no mesmo lugar.
func _compor_piscada() -> void:
	var aberta := Image.load_from_file(ProjectSettings.globalize_path(ORIGEM + "logo.png"))
	var fechada := Image.load_from_file(ProjectSettings.globalize_path(ORIGEM + "logo_piscando.png"))
	aberta.convert(Image.FORMAT_RGBA8)
	fechada.convert(Image.FORMAT_RGBA8)
	var area := _area_usada(aberta)
	for y in range(ROSTO_CENTRO.y - ROSTO_RAIO.y, ROSTO_CENTRO.y + ROSTO_RAIO.y):
		for x in range(ROSTO_CENTRO.x - ROSTO_RAIO.x, ROSTO_CENTRO.x + ROSTO_RAIO.x):
			var distancia := ((Vector2(x, y) - ROSTO_CENTRO) / ROSTO_RAIO).length()
			var peso := smoothstep(1.0, 0.7, distancia)
			if peso > 0.0:
				aberta.set_pixel(x, y, aberta.get_pixel(x, y).lerp(fechada.get_pixel(x, y), peso))
	aberta = _reduzir(aberta.get_region(area), 1100)
	aberta.save_png(ProjectSettings.globalize_path(DESTINO + "logo_piscando.png"))
	print(DESTINO + "logo_piscando.png  ", aberta.get_size())


# A barra de progresso da ação é um rastro de cinco patas andando para a
# direita, pé esquerdo e pé direito alternados. O jogo desenha o rastro apagado
# por baixo e o mesmo rastro colorido por cima, cortado pelo progresso.
func _compor_trilha() -> void:
	const PASSOS := 5
	const PASSO := 132
	const DESVIO := 26
	var pata := Image.load_from_file(ProjectSettings.globalize_path(ORIGEM + "pata_continuar.png"))
	pata.convert(Image.FORMAT_RGBA8)
	pata = pata.get_region(_area_usada(pata))
	pata.resize(96, roundi(96.0 * pata.get_height() / pata.get_width()), Image.INTERPOLATE_LANCZOS)
	pata.rotate_90(CLOCKWISE)

	var trilha := Image.create(PASSO * (PASSOS - 1) + pata.get_width() + 8, pata.get_height() + DESVIO * 2 + 8, false, Image.FORMAT_RGBA8)
	for i in PASSOS:
		var y := 4 + DESVIO * (2 if i % 2 == 0 else 0)
		trilha.blend_rect(pata, Rect2i(Vector2i.ZERO, pata.get_size()), Vector2i(4 + PASSO * i, y))
	trilha.save_png(ProjectSettings.globalize_path(DESTINO + "barra_patinhas.png"))
	print(DESTINO + "barra_patinhas.png  ", trilha.get_size())


# O verde se mistura com o que foi pintado na borda e no vidro do tubo, então
# não basta apagar o que é verde: quanto mais verde, mais transparente, e a cor
# que sobra perde o verde. Verde puro some; o vidro esverdeado vira vidro cinza.
func _tirar_verde(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var excesso := c.g - maxf(c.r, c.b)
			if c.a == 0.0 or excesso <= 0.0:
				continue
			c.a *= clampf(1.0 - excesso / 0.5, 0.0, 1.0)
			c.g = maxf(c.r, c.b)
			img.set_pixel(x, y, c)


func _area_usada(img: Image) -> Rect2i:
	var minimo := Vector2i(img.get_width(), img.get_height())
	var maximo := Vector2i(-1, -1)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.1:
				minimo = Vector2i(mini(minimo.x, x), mini(minimo.y, y))
				maximo = Vector2i(maxi(maximo.x, x), maxi(maximo.y, y))
	return Rect2i(minimo, maximo - minimo + Vector2i.ONE)


func _clarear(img: Image, cor: Color, peso: float, opacidade: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var a := c.a * opacidade
			c = c.lerp(cor, peso)
			c.a = a
			img.set_pixel(x, y, c)


func _reduzir(img: Image, maior: int) -> Image:
	var escala := float(maior) / maxi(img.get_width(), img.get_height())
	if escala < 1.0:
		img.resize(roundi(img.get_width() * escala), roundi(img.get_height() * escala), Image.INTERPOLATE_LANCZOS)
	return img


# O vão por dentro de uma peça vazada (a janela da polaroid, o miolo do tubo),
# achado a partir do centro, como máscara branca do tamanho da peça.
func _janela(img: Image, limite: float) -> Image:
	var mascara := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var centro := Vector2i(img.get_width() / 2, img.get_height() * 2 / 5)
	var area := Rect2i(Vector2i.ZERO, img.get_size())
	var visto := {centro: true}
	var pilha: Array[Vector2i] = [centro]
	while not pilha.is_empty():
		var p: Vector2i = pilha.pop_back()
		mascara.set_pixelv(p, Color.WHITE)
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q: Vector2i = p + d
			if visto.has(q) or not area.has_point(q):
				continue
			visto[q] = true
			if img.get_pixelv(q).a < limite:
				pilha.append(q)
	return mascara


# O líquido da barra de suspeita: o miolo do tubo em branco, que o jogo tinge
# conforme a faixa. Fica do tamanho do tubo para os dois esticarem juntos, e
# escurece para baixo para parecer líquido e não uma faixa chapada.
func _salvar_liquido(tubo: Image) -> void:
	# o vidro do tubo é semitransparente: o líquido passa por baixo dele
	var liquido := _janela(tubo, 0.95)
	var usado := liquido.get_used_rect()
	for y in liquido.get_height():
		var sombra := 1.0 - 0.3 * clampf(float(y - usado.position.y) / usado.size.y, 0.0, 1.0)
		for x in liquido.get_width():
			if liquido.get_pixel(x, y).a > 0.0:
				liquido.set_pixel(x, y, Color(sombra, sombra, sombra))
	liquido.save_png(ProjectSettings.globalize_path(DESTINO + "barra_liquido.png"))
	print(DESTINO + "barra_liquido.png  miolo ", usado, " de ", liquido.get_size())
