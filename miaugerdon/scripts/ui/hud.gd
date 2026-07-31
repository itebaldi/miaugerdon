extends CanvasLayer

## Toda a interface: barra de suspeita, cronômetro, objetivo atual, barra de progresso,
## inventário, diálogo, escolha final e telas de fim.
##
## POR QUE CanvasLayer: um CanvasLayer não é afetado pela câmera. Se a HUD fosse um nó
## comum dentro do mundo, a câmera que segue o gato arrastaria a barra de suspeita para
## fora da tela.
##
## POR QUE process_mode = ALWAYS (3, definido na cena): quando o jogo pausa, tudo para de
## processar — inclusive esta HUD. E aí o botão "Tentar novamente" da tela de derrota não
## responderia ao clique, porque a tela de derrota SÓ aparece com o jogo pausado.
##
## A LIÇÃO DESTE ARQUIVO: procure por "Caju" ou "Alfredo" aqui. Não tem. A HUD só conhece
## os sinais do Jogo. É por isso que ela funciona sem o mapa carregado, e por isso que
## renomear um nó do jogo não a quebra.

const COR_BAIXA := Color(0.45, 0.75, 0.4)
const COR_MEDIA := Color(0.92, 0.76, 0.3)
const COR_ALTA := Color(0.87, 0.32, 0.26)
const DURACAO_AVISO := 3.0
const PULSO_ACIMA_DE := 85.0

@onready var _barra_suspeita: ProgressBar = %BarraSuspeita
@onready var _cronometro: Label = %Cronometro
@onready var _objetivo: Label = %Objetivo
@onready var _aviso: Label = %Aviso
@onready var _observado: Label = %Observado
@onready var _caixa_progresso: VBoxContainer = %CaixaProgresso
@onready var _barra_progresso: ProgressBar = %BarraProgresso

@onready var _painel_tutorial: PanelContainer = %PainelTutorial
@onready var _painel_inventario: PanelContainer = %PainelInventario
@onready var _caixa_dialogo: PanelContainer = %CaixaDialogo
@onready var _painel_escolha: PanelContainer = %PainelEscolha
@onready var _painel_fim: PanelContainer = %PainelFim

@onready var _lista_etapas: VBoxContainer = %ListaEtapas
@onready var _lista_itens: VBoxContainer = %ListaItens
@onready var _falante: Label = %Falante
@onready var _fala: Label = %Fala
@onready var _fim_titulo: Label = %FimTitulo
@onready var _fim_texto: Label = %FimTexto
@onready var _botao_tentar: Button = %BotaoTentar
@onready var _botao_menu: Button = %BotaoMenu

@onready var _estilo_suspeita: StyleBoxFlat = _barra_suspeita.get_theme_stylebox("fill")

var _falas: PackedStringArray = []
var _fala_atual := 0
var _aviso_restante := 0.0


func _ready() -> void:
	Jogo.suspeita_alterada.connect(_ao_mudar_suspeita)
	Jogo.faixa_alterada.connect(_ao_mudar_faixa)
	Jogo.tempo_alterado.connect(_ao_mudar_tempo)
	Jogo.objetivo_alterado.connect(_ao_mudar_objetivo)
	Jogo.progresso_alterado.connect(_ao_mudar_progresso)
	Jogo.inventario_alterado.connect(_ao_mudar_inventario)
	Jogo.observado_alterado.connect(_ao_mudar_observado)
	Jogo.aviso.connect(_ao_avisar)
	Jogo.dialogo.connect(_ao_abrir_dialogo)
	Jogo.escolha_final.connect(_ao_pedir_escolha)
	Jogo.partida_terminada.connect(_ao_terminar)

	_botao_tentar.pressed.connect(_reiniciar)
	_botao_menu.pressed.connect(_voltar_ao_menu)

	# call_deferred porque o _ready() do NÍVEL roda depois do _ready() dos filhos (nós), e
	# é ele que chama Jogo.iniciar_partida(), que despausa. Se pausássemos agora, ele
	# despausaria em seguida e o tutorial apareceria com o jogo rodando atrás.
	_mostrar_tutorial.call_deferred()


func _process(delta: float) -> void:
	if _aviso_restante > 0.0:
		_aviso_restante -= delta
		if _aviso_restante <= 0.0:
			_aviso.visible = false

	# O aviso de "ele está te vendo" pisca devagar, para puxar o olho sem virar poluição.
	if _observado.visible:
		_observado.modulate.a = 0.55 + 0.45 * (sin(Time.get_ticks_msec() / 170.0) * 0.5 + 0.5)

	# Acima de 85 a barra pulsa: é uma condição de derrota, tem que assustar.
	if Jogo.em_partida and Jogo.suspeita >= PULSO_ACIMA_DE:
		var t := sin(Time.get_ticks_msec() / 90.0) * 0.5 + 0.5
		_barra_suspeita.modulate = Color.WHITE.lerp(Color(1.7, 0.7, 0.7), t)
	else:
		_barra_suspeita.modulate = Color.WHITE


func _unhandled_input(evento: InputEvent) -> void:
	# Ordem importa: o painel mais "modal" trata a tecla e para aí.
	if _painel_tutorial.visible:
		if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("interagir"):
			_fechar_tutorial()
		return

	if _painel_fim.visible:
		return                                   # os botões cuidam de si

	if _painel_escolha.visible:
		if evento.is_action_pressed("interagir"):
			Jogo.decidir(true)
		elif evento.is_action_pressed("disfarce"):
			Jogo.decidir(false)
		return

	if _caixa_dialogo.visible:
		if evento.is_action_pressed("interagir") or evento.is_action_pressed("ui_accept"):
			_avancar_dialogo()
		return

	if evento.is_action_pressed("inventario"):
		_alternar_inventario()


# ── barra, cronômetro, objetivo, progresso ──────────────────────────────────

func _ao_mudar_suspeita(valor: float) -> void:
	_barra_suspeita.value = valor


func _ao_mudar_faixa(nova: Jogo.Faixa) -> void:
	match nova:
		Jogo.Faixa.BAIXA:
			_estilo_suspeita.bg_color = COR_BAIXA
		Jogo.Faixa.MEDIA:
			_estilo_suspeita.bg_color = COR_MEDIA
			_ao_avisar("O Alfredo começou a estranhar os barulhos.")
		Jogo.Faixa.ALTA:
			_estilo_suspeita.bg_color = COR_ALTA
			_ao_avisar("Alfredo está te procurando!")


func _ao_mudar_tempo(segundos: float) -> void:
	var total := int(ceilf(maxf(segundos, 0.0)))
	_cronometro.text = "%02d:%02d" % [total / 60, total % 60]
	_cronometro.modulate = Color(1, 0.45, 0.4) if segundos <= 30.0 else Color.WHITE


func _ao_mudar_objetivo(_indice: int, titulo: String) -> void:
	_objetivo.text = "Objetivo: " + titulo


func _ao_mudar_progresso(fracao: float) -> void:
	_caixa_progresso.visible = fracao > 0.001
	_barra_progresso.value = fracao * 100.0


## O aviso é PERSISTENTE de propósito, e aparece sempre que ele tem o gato à vista — não só
## quando o jogador já começou uma etapa. A informação útil é "não comece agora", e para isso
## ela precisa chegar ANTES de apertar E.
func _ao_mudar_observado(observado: bool) -> void:
	_observado.visible = observado


func _ao_avisar(texto: String) -> void:
	_aviso.text = texto
	_aviso.visible = true
	_aviso_restante = DURACAO_AVISO


# ── inventário ──────────────────────────────────────────────────────────────

func _ao_mudar_inventario() -> void:
	for filho in _lista_etapas.get_children():
		filho.queue_free()
	for filho in _lista_itens.get_children():
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
	else:
		for item in Jogo.itens:
			var linha := Label.new()
			linha.add_theme_font_size_override("font_size", 13)
			linha.text = "·  " + item
			linha.modulate = Color(0.9, 0.88, 0.8)
			_lista_itens.add_child(linha)


func _alternar_inventario() -> void:
	if not Jogo.em_partida:
		return                                   # partida acabada: Tab não faz nada
	var abrir := not _painel_inventario.visible
	_painel_inventario.visible = abrir
	get_tree().paused = abrir


# ── tutorial ────────────────────────────────────────────────────────────────

func _mostrar_tutorial() -> void:
	_painel_tutorial.visible = true
	get_tree().paused = true


func _fechar_tutorial() -> void:
	_painel_tutorial.visible = false
	get_tree().paused = false


# ── diálogo ─────────────────────────────────────────────────────────────────

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
	# Despausar ANTES de avisar quem estava esperando: encerrar_dialogo() faz a etapa
	# concluir, o que dispara um balão de pensamento — e o balão não anima pausado.
	get_tree().paused = false
	Jogo.encerrar_dialogo()


# ── escolha final e telas de fim ────────────────────────────────────────────

func _ao_pedir_escolha() -> void:
	_caixa_progresso.visible = false
	_painel_escolha.visible = true
	get_tree().paused = true


func _ao_terminar(motivo: Jogo.Motivo) -> void:
	_painel_escolha.visible = false
	_painel_inventario.visible = false
	_caixa_dialogo.visible = false
	_caixa_progresso.visible = false
	_aviso.visible = false
	_observado.visible = false

	var final: Dictionary = Jogo.FINAIS[motivo]
	_fim_titulo.text = final["titulo"]
	_fim_texto.text = final["texto"]
	_fim_titulo.modulate = Color(0.72, 0.94, 0.7) if final["vitoria"] else Color(0.96, 0.6, 0.52)
	_painel_fim.visible = true


func _reiniciar() -> void:
	# reload_current_scene() recria o mapa, e o _ready() dele chama Jogo.iniciar_partida(),
	# que zera tempo, suspeita, inventário e despausa. O autoload sobrevive à troca de
	# cena, mas o estado dele é reiniciado de propósito ali.
	get_tree().paused = false
	get_tree().reload_current_scene()


func _voltar_ao_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://cenas/ui/menu.tscn")
