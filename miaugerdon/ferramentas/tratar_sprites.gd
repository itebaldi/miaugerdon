extends SceneTree

# Prepara os PNGs vindos do gerador de imagem para virarem props do mapa.
#
# O gerador entrega 1024x1024 com muita margem vazia. Jogar isso no Sprite2D e
# encolher com escala_arte não serve: o projeto filtra tudo em nearest por causa
# da pixel art, e reduzir 1024 para 32 em nearest serrilha. Então o corte e a
# redução acontecem aqui, uma vez, e o mapa recebe o sprite já no tamanho certo.
#
# Rodar:  Godot --headless --path . --script ferramentas/tratar_sprites.gd

const CONTORNO := Color(0.36, 0.31, 0.26, 1.0)

# origem, destino, maior dimensão final, contornar
const TAREFAS := [
	# a caneta já veio com contorno próprio e cor forte: só cortar e reduzir
	["res://sprites/origem/caneta_1024.png", "res://sprites/interativo/caneta.png", 64, false, 0.0],
	# papel e plano são claros sobre chão claro; sem contorno viram mancha
	["res://sprites/origem/papel_1024.png", "res://sprites/interativo/papel.png", 46, true, 0.0],
	["res://sprites/origem/plano_1024.png", "res://sprites/interativo/plano.png", 46, true, 0.70],
]


func _init() -> void:
	for tarefa in TAREFAS:
		var origem: String = tarefa[0]
		var destino: String = tarefa[1]
		var alvo: int = tarefa[2]
		var contornar: bool = tarefa[3]
		var realce: float = tarefa[4]

		var img := _cortar_e_reduzir(origem, alvo)
		if realce > 0.0:
			_realcar_tracos(img, realce)
		if contornar:
			img = _contornar(img)
		img.save_png(ProjectSettings.globalize_path(destino))
		print(destino, "  ", img.get_size())
	_compor_papel_e_caneta()
	_folha_em_branco()
	quit()


func _cortar_e_reduzir(caminho: String, alvo: int) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(caminho))
	var cortado := img.get_region(img.get_used_rect())
	var w := cortado.get_width()
	var h := cortado.get_height()
	var f: float = float(alvo) / float(maxi(w, h))
	cortado.resize(maxi(1, int(round(w * f))), maxi(1, int(round(h * f))), Image.INTERPOLATE_LANCZOS)
	return cortado


# contorno de 1px na silhueta, no mesmo tom da moldura dos móveis da casa
func _contornar(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var saida := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	saida.fill(Color(0, 0, 0, 0))

	const VIZINHOS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a <= 0.35:
				continue
			for passo in VIZINHOS:
				saida.set_pixel(x + 1 + passo.x, y + 1 + passo.y, CONTORNO)

	saida.blend_rect(img, Rect2i(Vector2i.ZERO, Vector2i(w, h)), Vector2i(1, 1))
	return saida


# escurece o que já é mais escuro que o papel: reduzido, o rabisco fino some
func _realcar_tracos(img: Image, forca: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.05:
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum >= 0.86:
				continue
			if c.r - maxf(c.g, c.b) > 0.12:
				# o círculo vermelho é a única cor forte da folha: preservar
				c.r = minf(1.0, c.r * 1.45)
				c.g *= 0.72
				c.b *= 0.72
			else:
				var k: float = lerpf(forca, 1.0, clampf(lum / 0.86, 0.0, 1.0) * 0.35)
				c.r *= k
				c.g *= k
				c.b *= k
			img.set_pixel(x, y, c)


# O ponto atrás da cama mostra o que já foi entregue. Com os dois itens lá, o
# sprite é a soma dos dois: composto aqui para não depender de mais um desenho.
func _compor_papel_e_caneta() -> void:
	var papel := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/interativo/papel.png"))
	var caneta := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/interativo/caneta.png"))
	var c := caneta.get_region(caneta.get_used_rect())
	c.resize(int(c.get_width() * 0.62), int(c.get_height() * 0.62), Image.INTERPOLATE_LANCZOS)

	var largura := papel.get_width() + int(c.get_width() * 0.55)
	var altura := maxi(papel.get_height(), c.get_height()) + 6
	var folha := Image.create(largura, altura, false, Image.FORMAT_RGBA8)
	folha.fill(Color(0, 0, 0, 0))
	folha.blend_rect(papel, Rect2i(Vector2i.ZERO, papel.get_size()), Vector2i(0, altura - papel.get_height()))
	folha.blend_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(largura - c.get_width(), 0))
	folha.save_png(ProjectSettings.globalize_path("res://sprites/interativo/papel_e_caneta.png"))
	print("res://sprites/interativo/papel_e_caneta.png  ", folha.get_size())


# A folha que o Caju leva na boca é uma só, não a pilha: carregar o bloco
# inteiro ficava estranho. Em vez de pedir outro desenho, apago o miolo do plano
# e fico com a mesma folha em branco — mesmo contorno, mesma perspectiva.
const CORPO_PAPEL := Color(0.961, 0.933, 0.863)
const RAIO_BORDA := 6


func _folha_em_branco() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/origem/plano_1024.png"))
	var cortado := img.get_region(img.get_used_rect())
	var w := cortado.get_width()
	var h := cortado.get_height()

	for y in h:
		for x in w:
			if cortado.get_pixel(x, y).a <= 0.35:
				continue
			if _perto_da_borda(cortado, x, y):
				continue
			cortado.set_pixel(x, y, CORPO_PAPEL)

	var f: float = 42.0 / float(maxi(w, h))
	cortado.resize(int(round(w * f)), int(round(h * f)), Image.INTERPOLATE_LANCZOS)
	# o traço original do plano é claro demais para uma folha lisa sobre chão claro
	cortado = _contornar(cortado)
	cortado.save_png(ProjectSettings.globalize_path("res://sprites/interativo/folha.png"))
	print("res://sprites/interativo/folha.png  ", cortado.get_size())


# o traço do contorno é o que encosta no vazio; o resto é rabisco e sai fora
func _perto_da_borda(img: Image, x: int, y: int) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	for dy in range(-RAIO_BORDA, RAIO_BORDA + 1):
		for dx in range(-RAIO_BORDA, RAIO_BORDA + 1):
			var px: int = x + dx
			var py: int = y + dy
			if px < 0 or py < 0 or px >= w or py >= h:
				return true
			if img.get_pixel(px, py).a <= 0.35:
				return true
	return false
