extends Node

## Efeitos de interface, tocados pelo nome no canal de efeitos. Tocam mesmo com
## o jogo pausado, porque quase toda a interface aparece assim (diálogos,
## painéis, plano). Os que dependem só do Jogo (etapa concluída e o fim da
## partida) se ligam aqui mesmo, sem passar pela HUD.

const SONS := {
	&"fala": preload("res://sounds/ui/fala.ogg"),
	&"papel": preload("res://sounds/ui/papel.ogg"),
	&"etapa": preload("res://sounds/ui/etapa.ogg"),
	&"botao": preload("res://sounds/ui/botao.ogg"),
	&"vitoria": preload("res://sounds/ui/vitoria.ogg"),
	&"derrota": preload("res://sounds/ui/derrota.ogg"),
}
# em dB; o que não estiver aqui toca no padrão
const VOLUME := {
	&"vitoria": -4.0,
	&"derrota": -4.0,
}
const VOLUME_PADRAO := -8.0
# o bastante para uma fala, um papel e a etapa soarem juntos sem um cortar o outro
const TOCADORES := 4

var _tocadores: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in TOCADORES:
		var tocador := AudioStreamPlayer.new()
		tocador.bus = &"Efeitos"
		add_child(tocador)
		_tocadores.append(tocador)

	Jogo.etapa_concluida.connect(func(_id): tocar(&"etapa"))
	Jogo.partida_terminada.connect(_ao_terminar)


# fechar o jogo com um som tocando prende a reprodução (ver Musica)
func _exit_tree() -> void:
	for tocador in _tocadores:
		tocador.stop()
		tocador.stream = null


func tocar(nome: StringName) -> void:
	var tocador := _tocadores[0]
	for livre in _tocadores:
		if not livre.playing:
			tocador = livre
			break
	tocador.stream = SONS[nome]
	tocador.volume_db = VOLUME.get(nome, VOLUME_PADRAO)
	tocador.play()


func _ao_terminar(motivo: Jogo.Motivo) -> void:
	tocar(&"vitoria" if Jogo.FINAIS[motivo]["vitoria"] else &"derrota")
