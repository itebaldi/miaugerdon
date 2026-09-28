extends Node2D

# Além de começar a partida, o mapa encena o fim da montagem: quem sabe onde
# ficam a máquina e a câmera do Caju é ele. O Jogo só dá o sinal e segura o
# tempo (PAUSA_MAQUINA_PRONTA e PAUSA_MAQUINA_LIGANDO).

const MAQUINA_LIGADA := preload("res://sprites/objetos/maquina_4_ligada.png")
# em pixels da textura da máquina: a bola da antena, de onde saem as ondas, e
# o meio do console, onde a câmera para
const PONTA_ANTENA := Vector2(810, 232)
const MEIO_MAQUINA := Vector2(780, 560)

const ZOOM_PRONTA := Vector2(1.8, 1.8)
const ZOOM_LIGADA := Vector2(2.2, 2.2)
# liga e desliga cada vez mais rápido, como lâmpada fria pegando
const PISCADAS := [0.32, 0.22, 0.16, 0.11, 0.08, 0.06, 0.05]

@onready var _maquina: Interagivel = $Objetivos/Maquina
@onready var _caju: Node2D = $Caju
@onready var _camera: Camera2D = $Caju/Camera2D

var _tremor := 0.0


func _ready() -> void:
	# a noite acabou no colo do Alfredo, no sofá: é ali que o Caju acorda
	if Jogo.dia > 1:
		$Caju.global_position = $PontoManha.global_position
	Jogo.maquina_pronta.connect(_ao_ficar_pronta)
	Jogo.maquina_ligando.connect(_ao_ligar)
	Jogo.iniciar_partida()


func _process(delta: float) -> void:
	if _tremor <= 0.0:
		return
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _tremor
	_tremor = maxf(0.0, _tremor - delta * 6.0)
	if _tremor == 0.0:
		_camera.offset = Vector2.ZERO


# Silêncio, a câmera chega perto e a máquina assenta no chão com um tranco.
func _ao_ficar_pronta() -> void:
	Musica.parar()
	_tremor = 3.0

	var assentar := create_tween()
	assentar.tween_property(_maquina, "scale", Vector2(1.08, 0.92), 0.08)
	assentar.tween_property(_maquina, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var camera := create_tween().set_parallel()
	camera.tween_property(_camera, "position", _caju.to_local(_ponto_da_maquina(MEIO_MAQUINA)), 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera.tween_property(_camera, "zoom", ZOOM_PRONTA, 3.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await get_tree().create_timer(1.6).timeout
	Jogo.pensar("Está pronta.")


# Pisca entre desligada e ligada até pegar; depois treme e manda sinal.
func _ao_ligar() -> void:
	var desligada := _maquina.textura
	for intervalo in PISCADAS:
		_maquina.textura = MAQUINA_LIGADA
		await get_tree().create_timer(intervalo).timeout
		_maquina.textura = desligada
		await get_tree().create_timer(intervalo * 0.7).timeout
	_maquina.textura = MAQUINA_LIGADA

	var ondas := OndasDeSinal.new()
	ondas.position = _maquina.to_local(_ponto_da_maquina(PONTA_ANTENA))
	_maquina.add_child(ondas)
	_tremor = 4.0
	create_tween().tween_property(_camera, "zoom", ZOOM_LIGADA, 2.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# o zumbido não para: o tremor é renovado até o final aparecer
	while Jogo.em_partida:
		_tremor = maxf(_tremor, 1.5)
		await get_tree().process_frame


# ponto da textura da máquina levado para o mundo, respeitando escala e
# deslocamento do sprite de cada etapa
func _ponto_da_maquina(pixel: Vector2) -> Vector2:
	var sprite: Sprite2D = _maquina.get_node("Sprite2D")
	return sprite.to_global(pixel - sprite.texture.get_size() * 0.5 + sprite.offset)


# Anéis verdes saindo da antena, sempre três no ar, cada um mais apagado conforme
# se afasta.
class OndasDeSinal extends Node2D:
	const RAIO_MAXIMO := 110.0
	const VELOCIDADE := 0.8
	const COR := Color(0.55, 1.0, 0.45)

	var _tempo := 0.0

	func _ready() -> void:
		z_index = 20

	func _process(delta: float) -> void:
		_tempo += delta
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var fase := fmod(_tempo * VELOCIDADE + float(i) / 3.0, 1.0)
			var cor := COR
			cor.a = (1.0 - fase) * 0.85
			draw_arc(Vector2.ZERO, lerpf(4.0, RAIO_MAXIMO, fase), 0.0, TAU, 56, cor, lerpf(4.0, 1.0, fase), true)
