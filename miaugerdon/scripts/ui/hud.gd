extends CanvasLayer


const COR_BAIXA := Color(0.45, 0.75, 0.4)
const COR_MEDIA := Color(0.92, 0.76, 0.3)
const COR_ALTA := Color(0.87, 0.32, 0.26)
# a cara do Alfredo ao lado da barra acompanha a faixa: tranquilo, desconfiado,
# pegou no flagra
const ROSTO_BAIXA := preload("res://sprites/ui/suspeita_1.png")
const ROSTO_MEDIA := preload("res://sprites/ui/suspeita_2.png")
const ROSTO_ALTA := preload("res://sprites/ui/suspeita_3.png")
const CAIXA_VAZIA := preload("res://sprites/ui/checkbox_vazio.png")
const CAIXA_MARCADA := preload("res://sprites/ui/checkbox_feito.png")
const FONTE_MAO := preload("res://fontes/PatrickHand-Regular.ttf")
const DURACAO_AVISO := 3.0
const COR_FALANTE := Color(0.2, 0.13, 0.08)
# os painéis são papel: o texto é tinta escura, e o destaque é tinta de cor
const COR_TINTA := Color(0.2, 0.13, 0.08)
const COR_TINTA_DESTAQUE := Color(0.55, 0.2, 0.06)
const COR_TINTA_VITORIA := Color(0.16, 0.4, 0.2)
const COR_TINTA_DERROTA := Color(0.62, 0.16, 0.08)
const COR_TINTA_APAGADA := Color(0.2, 0.13, 0.08, 0.45)
# com retrato, a fala começa depois da polaroid; sem, encosta na borda
const MARGEM_COM_RETRATO := 164.0
const MARGEM_SEM_RETRATO := 30.0
# A moldura da caixa vem no dobro da resolução e é desenhada em meia escala.
# As orelhas, o rabo e o novelo passam da caixa: estas são as sobras, em
# pixels da textura, entre a borda da imagem e o retângulo da moldura.
const MOLDURA_ESCALA := 0.5
const MOLDURA_SOBRA_INICIO := Vector2(20, 71)
const MOLDURA_SOBRA_FIM := Vector2(24, 34)

@onready var _barra_suspeita: TextureProgressBar = %BarraSuspeita
@onready var _rosto_suspeita: TextureRect = %RostoSuspeita
@onready var _cronometro: Label = %Cronometro
@onready var _objetivo: Label = %Objetivo
@onready var _caixa_progresso: VBoxContainer = %CaixaProgresso
@onready var _barra_progresso: TextureProgressBar = %BarraProgresso
@onready var _aviso: Label = %Aviso
@onready var _observado: Control = %Observado
@onready var _painel_inventario: PanelContainer = %PainelInventario
@onready var _lista_etapas: VBoxContainer = %ListaEtapas
@onready var _lista_itens: VBoxContainer = %ListaItens
@onready var _caixa_dialogo: Control = %CaixaDialogo
@onready var _polaroid: Control = %Polaroid
@onready var _nome_tira: Control = %NomeTira
@onready var _pata: TextureRect = %Pata
@onready var _retrato: TextureRect = %Retrato
@onready var _falante: Label = %Falante
@onready var _fala: Label = %Fala
@onready var _tela_computador: TextureRect = %TelaComputador
@onready var _painel_recado: PanelContainer = %PainelRecado
@onready var _recado_imagem: TextureRect = %RecadoImagem
@onready var _recado_texto: Label = %RecadoTexto
@onready var _painel_intro: PanelContainer = %PainelIntro
@onready var _texto_intro: Label = %TextoIntro
@onready var _pagina_intro: Label = %PaginaIntro
@onready var _painel_tutorial: PanelContainer = %PainelTutorial
@onready var _painel_escolha: PanelContainer = %PainelEscolha
@onready var _painel_fim: PanelContainer = %PainelFim
@onready var _fim_imagem: TextureRect = %FimImagem
@onready var _fim_titulo: Label = %FimTitulo
@onready var _fim_texto: Label = %FimTexto
@onready var _botao_tentar: Button = %BotaoTentar
@onready var _botao_menu: Button = %BotaoMenu

@onready var _estilo_caixa: StyleBox = %Corpo.get_theme_stylebox("panel")
@onready var _moldura_caixa: NinePatchRect = %MolduraCaixa

var _aviso_restante := 0.0
var _falas: Array = []
var _fala_atual := 0
var _pagina_da_intro := 0
var _tela_atual := ""


func _ready() -> void:
	Jogo.suspeita_alterada.connect(_ao_mudar_suspeita)
	Jogo.faixa_alterada.connect(_ao_mudar_faixa)
	Jogo.tempo_alterado.connect(_ao_mudar_tempo)
	Jogo.objetivo_alterado.connect(_ao_mudar_objetivo)
	Jogo.progresso_alterado.connect(_ao_mudar_progresso)
	Jogo.inventario_alterado.connect(_ao_mudar_inventario)
	Jogo.dialogo.connect(_ao_abrir_dialogo)
	# o projeto filtra tudo em nearest por causa da pixel art; os retratos são
	# ilustração grande reduzida e serrilham sem mipmap
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	Jogo.observado_alterado.connect(_ao_mudar_observado)
	Jogo.aviso.connect(_ao_avisar)
	Jogo.recado.connect(_ao_receber_recado)
	Jogo.escolha_final.connect(_ao_pedir_escolha)
	Jogo.partida_terminada.connect(_ao_terminar)

	_botao_tentar.pressed.connect(_reiniciar)
	_botao_menu.pressed.connect(_voltar_ao_menu)

	_caixa_dialogo.resized.connect(_ajustar_moldura_caixa)
	_ajustar_moldura_caixa()

	if Jogo.intro_vista:
		_mostrar_tutorial.call_deferred()
	else:
		_mostrar_intro.call_deferred()


# a caixa acompanha a largura da tela; a moldura estica junto, só no meio
func _ajustar_moldura_caixa() -> void:
	_moldura_caixa.scale = Vector2.ONE * MOLDURA_ESCALA
	_moldura_caixa.position = -MOLDURA_SOBRA_INICIO * MOLDURA_ESCALA
	_moldura_caixa.size = _caixa_dialogo.size / MOLDURA_ESCALA + MOLDURA_SOBRA_INICIO + MOLDURA_SOBRA_FIM


func _process(delta: float) -> void:
	if _aviso_restante > 0.0:
		_aviso_restante -= delta
		if _aviso_restante <= 0.0:
			_aviso.visible = false

	if _observado.visible:
		_observado.modulate.a = 0.55 + 0.45 * (sin(Time.get_ticks_msec() / 170.0) * 0.5 + 0.5)

	if _caixa_dialogo.visible:
		_pata.position.y = -absf(sin(Time.get_ticks_msec() / 260.0)) * 4.0


func _ao_mudar_observado(observado: bool) -> void:
	_observado.visible = observado


func _ao_avisar(texto: String) -> void:
	_aviso.text = texto
	_aviso.visible = true
	_aviso_restante = DURACAO_AVISO


func _mostrar_intro() -> void:
	Jogo.intro_vista = true
	_pagina_da_intro = 0
	_pintar_intro()
	_painel_intro.visible = true
	_pausar_para_ler()


func _pausar_para_ler() -> void:
	get_tree().paused = true
	Jogo.definir_observado(false)


func _pintar_intro() -> void:
	_texto_intro.text = Config.INTRO[_pagina_da_intro]
	_pagina_intro.text = "%d / %d" % [_pagina_da_intro + 1, Config.INTRO.size()]

	var chamada := _pagina_da_intro == Config.INTRO.size() - 1
	_texto_intro.add_theme_color_override("font_color", COR_TINTA_DESTAQUE if chamada else COR_TINTA)


func _avancar_intro() -> void:
	_pagina_da_intro += 1
	if _pagina_da_intro < Config.INTRO.size():
		_pintar_intro()
		return
	_painel_intro.visible = false
	_mostrar_tutorial()


func _mostrar_tutorial() -> void:
	_painel_tutorial.visible = true
	_pausar_para_ler()


func _ao_pedir_escolha() -> void:
	_caixa_progresso.visible = false
	_painel_escolha.visible = true
	get_tree().paused = true


func _reiniciar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _voltar_ao_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://cenas/ui/menu.tscn")


func _unhandled_input(evento: InputEvent) -> void:
	if _painel_recado.visible:
		if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("interagir"):
			_painel_recado.visible = false
			get_tree().paused = false
		return

	if _painel_intro.visible:
		if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("interagir"):
			_avancar_intro()
		return

	if _painel_tutorial.visible:
		if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("interagir"):
			_painel_tutorial.visible = false
			get_tree().paused = false
		return

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

	if _painel_fim.visible:
		if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("interagir"):
			_reiniciar()
		return

	if evento.is_action_pressed("inventario"):
		_alternar_inventario()


func _alternar_inventario() -> void:
	if not Jogo.em_partida:
		return
	var abrir := not _painel_inventario.visible
	_painel_inventario.visible = abrir
	get_tree().paused = abrir


func _ao_mudar_inventario() -> void:
	for lista in [_lista_etapas, _lista_itens]:
		for filho in lista.get_children():
			lista.remove_child(filho)
			filho.queue_free()

	# a lista é a letra do Caju na folha: o que já foi leva a pata carimbada, o
	# da vez fica em tinta de destaque e o que ainda vem fica apagado
	for i in Jogo.OBJETIVOS.size():
		var feito := Jogo.esta_concluido(i)
		var cor := COR_TINTA_APAGADA
		if feito:
			cor = COR_TINTA
		elif i == Jogo.indice:
			cor = COR_TINTA_DESTAQUE

		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 8)
		var caixa := TextureRect.new()
		caixa.texture = CAIXA_MARCADA if feito else CAIXA_VAZIA
		caixa.custom_minimum_size = Vector2(22, 22)
		caixa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		caixa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		caixa.modulate.a = 1.0 if feito or i == Jogo.indice else 0.55
		linha.add_child(caixa)
		linha.add_child(_linha_escrita(Jogo.OBJETIVOS[i]["titulo"], cor))
		_lista_etapas.add_child(linha)

	if Jogo.itens.is_empty():
		_lista_itens.add_child(_linha_escrita("(nada ainda)", COR_TINTA_APAGADA))
		return

	for item in Jogo.itens:
		_lista_itens.add_child(_linha_escrita("·  " + item, COR_TINTA))


func _linha_escrita(texto: String, cor: Color) -> Label:
	var linha := Label.new()
	linha.text = texto
	linha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linha.add_theme_font_override("font", FONTE_MAO)
	linha.add_theme_font_size_override("font_size", 19)
	linha.add_theme_color_override("font_color", cor)
	return linha


func _ao_abrir_dialogo(falas: Array) -> void:
	# o retrato já entra na primeira fala, mesmo que quem abra seja o Caju:
	# assim a caixa não muda de largura quando o outro começa a falar
	_retrato.texture = null
	for fala in falas:
		var retrato := _retrato_de(fala[0])
		if retrato:
			_retrato.texture = retrato
			break
	var tem_retrato := _retrato.texture != null
	_polaroid.visible = tem_retrato
	_estilo_caixa.content_margin_left = MARGEM_COM_RETRATO if tem_retrato else MARGEM_SEM_RETRATO
	_nome_tira.position.x = MARGEM_COM_RETRATO - 14.0 if tem_retrato else 18.0

	_falas = falas
	_fala_atual = 0
	_mostrar_fala()
	_caixa_dialogo.visible = true
	get_tree().paused = true


func _retrato_de(nome: String) -> Texture2D:
	var dados: Dictionary = Config.FALANTES.get(nome, {})
	var caminho: String = dados.get("retrato", "")
	if caminho == "":
		return null
	var textura: Texture2D = load(caminho)
	if not dados.has("recorte"):
		return textura
	var recorte := AtlasTexture.new()
	recorte.atlas = textura
	recorte.region = dados["recorte"]
	return recorte


# quem não tem retrato fala com o do outro apagado na polaroid. Apagado e não
# transparente: metade da polaroid fica para fora da caixa, sobre o mapa
func _mostrar_fala() -> void:
	var nome: String = _falas[_fala_atual][0]
	var dados: Dictionary = Config.FALANTES.get(nome, {})
	_falante.text = nome
	_falante.add_theme_color_override("font_color", dados.get("cor", COR_FALANTE))
	_fala.text = _falas[_fala_atual][1]

	var retrato := _retrato_de(nome)
	if retrato:
		_retrato.texture = retrato
		_polaroid.visible = true
	_retrato.modulate = Color.WHITE if retrato else Color(0.62, 0.58, 0.52)


func _avancar_dialogo() -> void:
	_fala_atual += 1
	if _fala_atual < _falas.size():
		_mostrar_fala()
		return

	_caixa_dialogo.visible = false

	get_tree().paused = false
	Jogo.encerrar_dialogo()


func _ao_mudar_suspeita(valor: float) -> void:
	_barra_suspeita.value = valor


func _ao_mudar_faixa(nova: Jogo.Faixa) -> void:
	match nova:
		Jogo.Faixa.BAIXA:
			_barra_suspeita.tint_progress = COR_BAIXA
			_rosto_suspeita.texture = ROSTO_BAIXA
		Jogo.Faixa.MEDIA:
			_barra_suspeita.tint_progress = COR_MEDIA
			_rosto_suspeita.texture = ROSTO_MEDIA
		Jogo.Faixa.ALTA:
			_barra_suspeita.tint_progress = COR_ALTA
			_rosto_suspeita.texture = ROSTO_ALTA


func _ao_mudar_tempo(segundos: float) -> void:
	var total := int(ceilf(maxf(segundos, 0.0)))
	_cronometro.text = "%02d:%02d" % [total / 60, total % 60]
	_cronometro.add_theme_color_override("font_color", COR_TINTA_DERROTA if segundos <= 30.0 else COR_TINTA)


# o post-it já diz que é o objetivo
func _ao_mudar_objetivo(_indice: int, titulo: String) -> void:
	_objetivo.text = titulo


func _ao_receber_recado(imagem: String, texto: String) -> void:
	_recado_imagem.texture = load(imagem)
	_recado_texto.text = texto
	_painel_recado.visible = true
	get_tree().paused = true


# quem manda a imagem e o objeto em uso: olhar o objetivo da vez acendia a tela
# do computador enquanto o gato derrubava o copo
func _mostrar_tela(caminho: String) -> void:
	if caminho == _tela_atual:
		return
	_tela_atual = caminho
	_tela_computador.texture = load(caminho) if caminho != "" else null
	_tela_computador.visible = _tela_computador.texture != null


func _ao_mudar_progresso(fracao: float, tela: String) -> void:
	_caixa_progresso.visible = fracao > 0.001
	_barra_progresso.value = fracao * 100.0
	_mostrar_tela(tela)


func _ao_terminar(motivo: Jogo.Motivo) -> void:
	_caixa_progresso.visible = false
	_aviso.visible = false
	_observado.visible = false
	_caixa_dialogo.visible = false
	_painel_inventario.visible = false
	_painel_escolha.visible = false
	_painel_recado.visible = false
	_mostrar_tela("")

	var final: Dictionary = Jogo.FINAIS[motivo]
	_fim_titulo.text = final["titulo"]
	_fim_texto.text = final["texto"]
	_fim_titulo.add_theme_color_override("font_color", COR_TINTA_VITORIA if final["vitoria"] else COR_TINTA_DERROTA)

	var arte: String = final.get("imagem", "")
	var ilustracao: Texture2D = load(arte) if arte != "" else null
	_fim_imagem.texture = ilustracao
	_fim_imagem.visible = ilustracao != null

	var meia_altura := 240.0 if ilustracao != null else 150.0
	_painel_fim.offset_top = -meia_altura
	_painel_fim.offset_bottom = meia_altura

	_painel_fim.visible = true
