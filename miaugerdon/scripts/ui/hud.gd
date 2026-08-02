extends CanvasLayer

# Um CanvasLayer não é afetado pela câmera: se a HUD fosse um nó comum do mundo, a câmera
# que segue o gato arrastaria a barra para fora da tela.
# O process_mode da cena é "Sempre", senão a tela de fim (que só aparece com o jogo
# pausado) não responderia a tecla nenhuma.

const COR_BAIXA := Color(0.45, 0.75, 0.4)
const COR_MEDIA := Color(0.92, 0.76, 0.3)
const COR_ALTA := Color(0.87, 0.32, 0.26)

@onready var _barra_suspeita: ProgressBar = %BarraSuspeita
@onready var _cronometro: Label = %Cronometro
@onready var _painel_fim: PanelContainer = %PainelFim
@onready var _fim_texto: Label = %FimTexto

@onready var _estilo_suspeita: StyleBoxFlat = _barra_suspeita.get_theme_stylebox("fill")


func _ready() -> void:
	Jogo.suspeita_alterada.connect(_ao_mudar_suspeita)
	Jogo.faixa_alterada.connect(_ao_mudar_faixa)
	Jogo.tempo_alterado.connect(_ao_mudar_tempo)
	Jogo.partida_terminada.connect(_ao_terminar)


func _unhandled_input(evento: InputEvent) -> void:
	if _painel_fim.visible and evento.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _ao_mudar_suspeita(valor: float) -> void:
	_barra_suspeita.value = valor


func _ao_mudar_faixa(nova: Jogo.Faixa) -> void:
	match nova:
		Jogo.Faixa.BAIXA:
			_estilo_suspeita.bg_color = COR_BAIXA
		Jogo.Faixa.MEDIA:
			_estilo_suspeita.bg_color = COR_MEDIA
		Jogo.Faixa.ALTA:
			_estilo_suspeita.bg_color = COR_ALTA


func _ao_mudar_tempo(segundos: float) -> void:
	var total := int(ceilf(maxf(segundos, 0.0)))
	_cronometro.text = "%02d:%02d" % [total / 60, total % 60]
	_cronometro.modulate = Color(1, 0.45, 0.4) if segundos <= 30.0 else Color.WHITE


func _ao_terminar(motivo: Jogo.Motivo) -> void:
	match motivo:
		Jogo.Motivo.SUSPEITA:
			_fim_texto.text = "Alfredo descobriu o plano."
		Jogo.Motivo.TEMPO:
			_fim_texto.text = "O cachorro chegou."
	_painel_fim.visible = true
