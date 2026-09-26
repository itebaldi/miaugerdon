extends Node

## A trilha do jogo. Toca uma faixa por vez e troca com fade cruzado, sem parar
## quando o jogo pausa (diálogos, painéis). Durante a partida a música é uma só
## e acelera com a tensão: a cor da barra de suspeita e o último minuto.
##
## Trocar de faixa conforme a tensão ficou brusco; acelerar a mesma música
## deixa a pressão subir sem quebrar a trilha.

const FAIXAS := {
	&"menu": preload("res://sounds/musica/menu.mp3"),
	&"jogo": preload("res://sounds/musica/jogo.wav"),
}
# em dB: é música de companhia, bem abaixo dos efeitos
const VOLUME := {
	&"menu": -18.0,
	&"jogo": -18.0,
}

enum Tensao { CALMA, TENSA, AGITADA, PANICO }
const VELOCIDADE := [1.0, 1.1, 1.22, 1.35]
# Acelerar um áudio também sobe o tom: a 1.35 o jazz fica de esquilo. O efeito
# de tom no canal da música desfaz a subida e sobra só a pressa. Se soar
# artificial, false deixa a música só acelerar, subindo junto o tom.
const MANTER_TOM := true

const ULTIMO_MINUTO := 60.0
# subir a tensão é na hora; baixar espera um pouco, senão a música fica indo e
# voltando quando a suspeita oscila perto do limite de uma faixa
const ESPERA_PARA_ACALMAR := 4.0
const RAMPA_SUBINDO := 1.2
const RAMPA_DESCENDO := 2.5
const FADE := 1.5

var _tocadores: Array[AudioStreamPlayer] = []
var _ativo := 0
var _atual := &""
var _tensao := Tensao.CALMA
var _tensao_da_suspeita := Tensao.CALMA
var _acalmando_ha := 0.0
var _fade: Tween
var _rampa: Tween
var _bus := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bus = AudioServer.get_bus_index(&"Musica")
	for i in 2:
		var tocador := AudioStreamPlayer.new()
		tocador.bus = &"Musica"
		add_child(tocador)
		_tocadores.append(tocador)

	Jogo.faixa_alterada.connect(_ao_mudar_faixa)
	Jogo.partida_terminada.connect(func(_motivo): parar())


# fechar o jogo com uma faixa tocando deixava a reprodução presa e o Godot
# acusava recurso em uso na saída. No --headless o áudio é de mentira e a
# liberação não roda, então lá o aviso continua; no jogo de verdade, não
func _exit_tree() -> void:
	for tocador in _tocadores:
		tocador.stop()
		tocador.stream = null


func tocar(nome: StringName) -> void:
	if nome == _atual:
		return
	var saindo := _tocadores[_ativo]
	_ativo = 1 - _ativo
	var entrando := _tocadores[_ativo]
	_atual = nome
	if _rampa and _rampa.is_valid():
		_rampa.kill()
	_definir_velocidade(1.0)

	entrando.stream = FAIXAS[nome]
	entrando.volume_linear = 0.0
	entrando.play()
	_cruzar(entrando, VOLUME[nome], saindo)


func parar() -> void:
	if _atual == &"":
		return
	_atual = &""
	_cruzar(null, 0.0, _tocadores[_ativo])


# só um fade por vez: numa troca no meio de outra, o novo assume os dois
# tocadores, e o antigo não fica puxando o volume para o outro lado
func _cruzar(entrando: AudioStreamPlayer, volume: float, saindo: AudioStreamPlayer) -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	_fade = create_tween().set_parallel()
	if entrando:
		_fade.tween_property(entrando, "volume_linear", db_to_linear(volume), FADE)
	if saindo.playing:
		_fade.tween_property(saindo, "volume_linear", 0.0, FADE)
		_fade.chain().tween_callback(func():
			if saindo != _tocadores[_ativo] or _atual == &"":
				saindo.stop())


func _ao_mudar_faixa(nova: Jogo.Faixa) -> void:
	match nova:
		Jogo.Faixa.BAIXA:
			_tensao_da_suspeita = Tensao.CALMA
		Jogo.Faixa.MEDIA:
			_tensao_da_suspeita = Tensao.TENSA
		Jogo.Faixa.ALTA:
			_tensao_da_suspeita = Tensao.AGITADA


func _process(delta: float) -> void:
	if not Jogo.em_partida:
		return

	# a partida começou (ou recomeçou): música do jogo, do início e sem pressa
	if _atual != &"jogo":
		_tensao = Tensao.CALMA
		_acalmando_ha = 0.0
		tocar(&"jogo")
		return

	var desejada := _tensao_da_suspeita
	if Jogo.tempo_restante <= ULTIMO_MINUTO:
		desejada = Tensao.PANICO

	if desejada > _tensao:
		_mudar_tensao(desejada, RAMPA_SUBINDO)
	elif desejada < _tensao:
		_acalmando_ha += delta
		if _acalmando_ha >= ESPERA_PARA_ACALMAR:
			_mudar_tensao(desejada, RAMPA_DESCENDO)
	else:
		_acalmando_ha = 0.0


func _mudar_tensao(nova: Tensao, rampa: float) -> void:
	_tensao = nova
	_acalmando_ha = 0.0
	if _rampa and _rampa.is_valid():
		_rampa.kill()
	var de := _tocadores[_ativo].pitch_scale
	_rampa = create_tween()
	_rampa.tween_method(_definir_velocidade, de, VELOCIDADE[nova], rampa)


func velocidade() -> float:
	return _tocadores[_ativo].pitch_scale


func _definir_velocidade(valor: float) -> void:
	for tocador in _tocadores:
		tocador.pitch_scale = valor
	# o efeito mexe no som mesmo em 1.0, então só liga quando há o que desfazer
	var compensar := MANTER_TOM and valor > 1.001
	AudioServer.set_bus_effect_enabled(_bus, 0, compensar)
	if compensar:
		var tom := AudioServer.get_bus_effect(_bus, 0) as AudioEffectPitchShift
		tom.pitch_scale = 1.0 / valor
