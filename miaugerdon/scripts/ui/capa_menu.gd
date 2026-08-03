extends Control

## Anima a logo do menu: o gato pega fogo aos poucos, com brilho, leve
## tremor e brasas subindo. Baseado na animação feita no Claude Design.
## Este script fica no próprio nó da logo (dentro de um AspectRatioContainer),
## então "size" já é a área final da logo depois do ajuste de aspecto.

@export var intensidade_fogo: float = 1.0
@export var mostrar_brasas: bool = true
@export var respiracao_idle: bool = true

@onready var _fogo: TextureRect = %Fogo
@onready var _brilho: TextureRect = %Brilho
@onready var _brasas: CPUParticles2D = %Brasas

var _t0: float
var _rng := RandomNumberGenerator.new()
var _centro := Vector2.ZERO


func _ready() -> void:
	_t0 = Time.get_ticks_msec() / 1000.0
	_rng.randomize()

	pivot_offset = size / 2.0
	_centralizar()
	resized.connect(_ao_redimensionar)

	_brasas.texture = _criar_textura_ponto()
	_configurar_brasas()


func _ao_redimensionar() -> void:
	pivot_offset = size / 2.0
	_centralizar()
	_configurar_brasas()


func _centralizar() -> void:
	# o AspectRatioContainer não está centralizando o filho sozinho (fica
	# encostado no canto), então centralizamos manualmente dentro dele.
	var pai := get_parent_control()
	if pai:
		_centro = (pai.size - size) / 2.0


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 - _t0

	# rampa de ignição: o fogo demora um pouco a pegar, depois oscila (chama viva)
	var ignicao := clampf((t - 0.25) / 1.4, 0.0, 1.0)
	var f := 0.72 \
		+ 0.13 * sin(t * 7.3) \
		+ 0.08 * sin(t * 13.1 + 1.7) \
		+ 0.07 * sin(t * 21.7 + 0.4)
	var chama := clampf(f, 0.0, 1.0) * ignicao * intensidade_fogo

	_fogo.modulate.a = chama
	_brilho.modulate.a = chama * 0.85

	if _brasas.emitting != (mostrar_brasas and ignicao > 0.05):
		_brasas.emitting = mostrar_brasas and ignicao > 0.05

	var respiro := sin(t * 1.6) * 0.006 if respiracao_idle else 0.0
	var solavanco := (_rng.randf() - 0.5) * 1.4 if chama > 0.9 else 0.0
	position = _centro + Vector2(solavanco, solavanco * 0.6)
	scale = Vector2.ONE * (1.0 + respiro + chama * 0.008)


func _configurar_brasas() -> void:
	var tam := size
	_brasas.position = Vector2(tam.x * 0.5, tam.y * 0.78)
	_brasas.emission_rect_extents = Vector2(tam.x * 0.34, tam.y * 0.03)
	_brasas.initial_velocity_min = tam.y * 0.12
	_brasas.initial_velocity_max = tam.y * 0.28


func _criar_textura_ponto() -> ImageTexture:
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
