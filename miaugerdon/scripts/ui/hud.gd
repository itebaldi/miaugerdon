extends CanvasLayer

# Um CanvasLayer não é afetado pela câmera: se a HUD fosse um nó comum do mundo, a câmera
# que segue o gato arrastaria a barra para fora da tela.
# O process_mode da cena é "Sempre", senão a tela de fim (que só aparece com o jogo
# pausado) não responderia a tecla nenhuma.

const COR_BAIXA := Color(0.45, 0.75, 0.4)
const COR_MEDIA := Color(0.92, 0.76, 0.3)
const COR_ALTA := Color(0.87, 0.32, 0.26)
const DURACAO_AVISO := 3.0

@onready var _barra_suspeita: ProgressBar = %BarraSuspeita
@onready var _cronometro: Label = %Cronometro
@onready var _objetivo: Label = %Objetivo
@onready var _caixa_progresso: VBoxContainer = %CaixaProgresso
@onready var _barra_progresso: ProgressBar = %BarraProgresso
@onready var _aviso: Label = %Aviso
@onready var _observado: Label = %Observado
@onready var _painel_inventario: PanelContainer = %PainelInventario
@onready var _lista_etapas: VBoxContainer = %ListaEtapas
@onready var _lista_itens: VBoxContainer = %ListaItens
@onready var _caixa_dialogo: PanelContainer = %CaixaDialogo
@onready var _falante: Label = %Falante
@onready var _fala: Label = %Fala
@onready var _painel_fim: PanelContainer = %PainelFim
@onready var _fim_texto: Label = %FimTexto

@onready var _estilo_suspeita: StyleBoxFlat = _barra_suspeita.get_theme_stylebox("fill")

var _aviso_restante := 0.0
var _falas: PackedStringArray = []
var _fala_atual := 0


func _ready() -> void:
	Jogo.suspeita_alterada.connect(_ao_mudar_suspeita)
	Jogo.faixa_alterada.connect(_ao_mudar_faixa)
	Jogo.tempo_alterado.connect(_ao_mudar_tempo)
	Jogo.objetivo_alterado.connect(_ao_mudar_objetivo)
	Jogo.progresso_alterado.connect(_ao_mudar_progresso)
	Jogo.inventario_alterado.connect(_ao_mudar_inventario)
	Jogo.dialogo.connect(_ao_abrir_dialogo)
	Jogo.observado_alterado.connect(_ao_mudar_observado)
	Jogo.aviso.connect(_ao_avisar)
	Jogo.partida_terminada.connect(_ao_terminar)


func _process(delta: float) -> void:
	if _aviso_restante > 0.0:
		_aviso_restante -= delta
		if _aviso_restante <= 0.0:
			_aviso.visible = false

	if _observado.visible:
		_observado.modulate.a = 0.55 + 0.45 * (sin(Time.get_ticks_msec() / 170.0) * 0.5 + 0.5)


# aparece sempre que ele tem o gato à vista, não só depois de o jogador começar uma etapa:
# a informação útil é "não comece agora"
func _ao_mudar_observado(observado: bool) -> void:
	_observado.visible = observado


func _ao_avisar(texto: String) -> void:
	_aviso.text = texto
	_aviso.visible = true
	_aviso_restante = DURACAO_AVISO


func _unhandled_input(evento: InputEvent) -> void:
	if _caixa_dialogo.visible:
		if evento.is_action_pressed("interagir") or evento.is_action_pressed("ui_accept"):
			_avancar_dialogo()
		return

	if _painel_fim.visible:
		if evento.is_action_pressed("ui_accept"):
			get_tree().paused = false
			get_tree().reload_current_scene()
		return

	if evento.is_action_pressed("inventario"):
		_alternar_inventario()


func _alternar_inventario() -> void:
	# sem isto, Tab na tela de derrota despausaria o jogo por baixo dela
	if not Jogo.em_partida:
		return
	var abrir := not _painel_inventario.visible
	_painel_inventario.visible = abrir
	get_tree().paused = abrir


func _ao_mudar_inventario() -> void:
	# remove_child antes do queue_free: o queue_free só apaga no fim do quadro, e até lá
	# as linhas velhas ainda contam
	for lista in [_lista_etapas, _lista_itens]:
		for filho in lista.get_children():
			lista.remove_child(filho)
			filho.queue_free()

	for i in Jogo.OBJETIVOS.size():
		var linha := Label.new()
		linha.add_theme_font_size_override("font_size", 14)
		var feito := Jogo.esta_concluido(i)
		linha.text = "%s  %s" % ["[x]" if feito else "[ ]", Jogo.OBJETIVOS[i]["titulo"]]
		if feito:
			linha.modulate = Color(0.6, 0.86, 0.6)
		elif i == Jogo.indice:
			linha.modulate = Color(1, 0.9, 0.55)
		else:
			linha.modulate = Color(0.58, 0.56, 0.52)
		_lista_etapas.add_child(linha)

	if Jogo.itens.is_empty():
		var vazio := Label.new()
		vazio.add_theme_font_size_override("font_size", 13)
		vazio.text = "(nada ainda)"
		vazio.modulate = Color(0.58, 0.56, 0.52)
		_lista_itens.add_child(vazio)
		return

	for item in Jogo.itens:
		var linha := Label.new()
		linha.add_theme_font_size_override("font_size", 13)
		linha.text = "·  " + item
		linha.modulate = Color(0.9, 0.88, 0.8)
		_lista_itens.add_child(linha)


func _ao_abrir_dialogo(nome: String, falas: PackedStringArray) -> void:
	_falas = falas
	_fala_atual = 0
	_falante.text = nome
	_fala.text = _falas[0]
	_caixa_dialogo.visible = true
	get_tree().paused = true


func _avancar_dialogo() -> void:
	_fala_atual += 1
	if _fala_atual < _falas.size():
		_fala.text = _falas[_fala_atual]
		return

	_caixa_dialogo.visible = false
	# despausar antes de avisar: concluir a etapa dispara coisas que não animam pausadas
	get_tree().paused = false
	Jogo.encerrar_dialogo()


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


func _ao_mudar_objetivo(_indice: int, titulo: String) -> void:
	_objetivo.text = "Objetivo: " + titulo


func _ao_mudar_progresso(fracao: float) -> void:
	_caixa_progresso.visible = fracao > 0.001
	_barra_progresso.value = fracao * 100.0


func _ao_terminar(motivo: Jogo.Motivo) -> void:
	_caixa_progresso.visible = false
	_aviso.visible = false
	_observado.visible = false
	_caixa_dialogo.visible = false
	_painel_inventario.visible = false
	match motivo:
		Jogo.Motivo.SUSPEITA:
			_fim_texto.text = "Alfredo descobriu o plano."
		Jogo.Motivo.TEMPO:
			_fim_texto.text = "O cachorro chegou."
		Jogo.Motivo.VITORIA:
			_fim_texto.text = "A máquina está pronta."
			_fim_texto.modulate = Color(0.72, 0.94, 0.7)
	_painel_fim.visible = true
