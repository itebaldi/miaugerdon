extends Control

## Anima a logo do menu: ela cai com um quique, o fogo acende atrás dela (a
## ondulação das chamas é do shader), as brasas sobem e, de tempos em tempos,
## o Caju pisca. Este script fica no próprio nó da logo (dentro de um
## AspectRatioContainer), então "size" já é a área final da logo.

const LOGO_ABERTA := preload("res://sprites/ui/logo.png")
const LOGO_PISCANDO := preload("res://sprites/ui/logo_piscando.png")
const DURACAO_QUEDA := 0.55
const ESCALA_INICIAL := 1.25
const DURACAO_IGNICAO := 1.2
const DURACAO_PISCADA := 0.14
# o subtítulo acompanha o tamanho da logo, que muda com a janela
const FONTE_SUBTITULO := 0.068

@export var intensidade_fogo: float = 1.0
@export var mostrar_brasas: bool = true
@export var respiracao_idle: bool = true

@onready var _base: TextureRect = %Base
@onready var _fogo: TextureRect = %Fogo
@onready var _brilho: TextureRect = %Brilho
@onready var _brasas: CPUParticles2D = %Brasas
@onready var _subtitulo: Label = %Subtitulo

var _t0: float
var _proxima_piscada := 2.5
var _centro := Vector2.ZERO


func _ready() -> void:
	_t0 = Time.get_ticks_msec() / 1000.0
	_fogo.material.set_shader_parameter("intensidade", intensidade_fogo)
	_brasas.texture = _criar_textura_ponto()
	_ao_redimensionar()
	resized.connect(_ao_redimensionar)


func _ao_redimensionar() -> void:
	pivot_offset = size / 2.0
	_centralizar()
	_configurar_brasas()
	_subtitulo.add_theme_font_size_override("font_size", maxi(12, roundi(size.y * FONTE_SUBTITULO)))


func _centralizar() -> void:
	# o AspectRatioContainer não está centralizando o filho sozinho (fica
	# encostado no canto), então centralizamos manualmente dentro dele.
	var pai := get_parent_control()
	if pai:
		_centro = (pai.size - size) / 2.0


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 - _t0

	# a logo entra grande e transparente e assenta passando um pouco do ponto
	var queda := clampf(t / DURACAO_QUEDA, 0.0, 1.0)
	modulate.a = clampf(t / 0.2, 0.0, 1.0)

	# o fogo só pega depois que a logo assentou, e aí fica vivo, oscilando
	var ignicao := clampf((t - DURACAO_QUEDA - 0.1) / DURACAO_IGNICAO, 0.0, 1.0)
	var f := 0.8 \
		+ 0.1 * sin(t * 7.3) \
		+ 0.06 * sin(t * 13.1 + 1.7) \
		+ 0.04 * sin(t * 21.7 + 0.4)
	var chama := clampf(f, 0.0, 1.0) * ignicao
	_fogo.modulate.a = chama
	_brilho.modulate.a = chama * 0.85

	var acesas := mostrar_brasas and ignicao > 0.05
	if _brasas.emitting != acesas:
		_brasas.emitting = acesas

	_piscar(t)

	var respiro := sin(t * 1.6) * 0.006 if respiracao_idle and queda >= 1.0 else 0.0
	position = _centro
	scale = Vector2.ONE * (lerpf(ESCALA_INICIAL, 1.0, _quique(queda)) + respiro)


# de vez em quando, e às vezes duas seguidas
func _piscar(t: float) -> void:
	var fechado := t >= _proxima_piscada and t < _proxima_piscada + DURACAO_PISCADA
	_base.texture = LOGO_PISCANDO if fechado else LOGO_ABERTA
	if t >= _proxima_piscada + DURACAO_PISCADA:
		_proxima_piscada = t + (0.22 if randf() < 0.25 else randf_range(2.5, 5.5))


# sai do 0 e chega no 1 passando um pouco dele antes de voltar
func _quique(x: float) -> float:
	const C1 := 1.70158
	const C3 := C1 + 1.0
	return 1.0 + C3 * pow(x - 1.0, 3.0) + C1 * pow(x - 1.0, 2.0)


# as brasas saem de trás das letras, onde as chamas nascem
func _configurar_brasas() -> void:
	var tam := size
	_brasas.position = Vector2(tam.x * 0.5, tam.y * 0.7)
	_brasas.emission_rect_extents = Vector2(tam.x * 0.45, tam.y * 0.04)
	_brasas.initial_velocity_min = tam.y * 0.14
	_brasas.initial_velocity_max = tam.y * 0.32


# brasa redonda e de borda macia: o ponto quadrado de antes combinava com a
# logo em pixel art, mas ao lado da pintada parecia pixel solto
func _criar_textura_ponto() -> ImageTexture:
	const LADO := 8
	var img := Image.create(LADO, LADO, false, Image.FORMAT_RGBA8)
	var centro := Vector2(LADO, LADO) / 2.0 - Vector2(0.5, 0.5)
	for y in LADO:
		for x in LADO:
			var distancia := Vector2(x, y).distance_to(centro) / (LADO / 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, smoothstep(1.0, 0.3, distancia)))
	return ImageTexture.create_from_image(img)
