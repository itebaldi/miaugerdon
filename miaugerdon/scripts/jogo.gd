extends Node

signal suspeita_alterada(valor: float)
signal faixa_alterada(nova: Faixa)
signal tempo_alterado(segundos: float)
signal objetivo_alterado(indice: int, titulo: String)
signal progresso_alterado(fracao: float, tela: String)
signal ruido(posicao: Vector2)
signal observado_alterado(observado: bool)
signal inventario_alterado()
signal pensamento(texto: String)
signal carga_alterada(id: String)
signal dialogo(falas: Array)
signal dialogo_terminado()
signal aviso(texto: String)
signal recado(imagem: String, texto: String)
signal escolha_final()
signal partida_terminada(motivo: Motivo)
signal etapa_concluida(id: String)
# o primeiro dia acabou: o Alfredo vai buscar o Caju e diz estas falas
signal fim_do_dia(falas: Array)
# a conversa do fim do dia terminou: hora de escurecer e ir para a HQ da noite
signal noite()
# montada a última peça: a casa para um instante para a máquina aparecer
signal maquina_pronta()
# o jogador escolheu ativar: a máquina liga antes de o final aparecer
signal maquina_ligando()

const TEMPO_TOTAL := 180.0
# o segundo dia é só a montagem, com o Soneca a caminho: pouco tempo e nada mais
const TEMPO_DIA_2 := 120.0
# a máquina pronta fica em cena antes da escolha, e ligada antes do final
const PAUSA_MAQUINA_PRONTA := 5.0
const PAUSA_MAQUINA_LIGANDO := 4.0
const SUSPEITA_MAX := 100.0
const LIMITE_MEDIA := 35.0
const LIMITE_ALTA := 70.0

const LIMPAR_SE := 8.0
const SUSPEITA_MIADO := 3.0
const FLAGRANTE := 15.0
# o Alfredo tirar o item da boca custa menos que ser pego no flagra: a punição
# já é perder a viagem
const SUSPEITA_CONFISCO := 10.0

const FATOR_OBSERVADO := 2.5

enum Faixa { BAIXA, MEDIA, ALTA }
enum Motivo { SUSPEITA, TEMPO, ATIVOU, DESISTIU }

const OBJETIVOS := Config.OBJETIVOS
const FINAIS := Config.FINAIS

var intro_vista := false
# quem define é a HQ que abre o dia: a abertura começa o primeiro, a da noite
# leva ao segundo. "Tentar de novo" recarrega o mapa e cai no mesmo dia.
var dia := 1
# cena sem jogador: o fim do primeiro dia e a máquina pronta. Relógio e
# suspeita param, o Caju fica sem controle e o Alfredo só faz o que o roteiro
# manda
var em_roteiro := false

var em_partida := false
var observado := false
var suspeita := 0.0
var tempo_restante := TEMPO_TOTAL
var indice := 0
var concluidos: Array[bool] = []
var itens: Array[String] = []
# id do item que o Caju está levando na boca; "" quando está de boca livre
var carga := ""

var _faixa := Faixa.BAIXA
var _pensamentos_vistos := {}
var _falas_fim_do_dia: Array = []
# conta as partidas: uma espera que termina depois de um "tentar de novo" não
# pode disparar nada na partida nova
var _rodada := 0


# O segundo dia começa depois da etapa que fecha o primeiro, com tudo o que veio
# antes já feito e guardado no inventário.
func iniciar_partida() -> void:
	get_tree().paused = false
	suspeita = 0.0
	tempo_restante = TEMPO_TOTAL if dia == 1 else TEMPO_DIA_2
	indice = 0 if dia == 1 else _inicio_do_dia_2()
	concluidos.clear()
	concluidos.resize(OBJETIVOS.size())
	concluidos.fill(false)
	itens.clear()
	for i in indice:
		concluidos[i] = true
		itens.append_array(OBJETIVOS[i]["itens"])
	carga = ""
	em_roteiro = false
	_rodada += 1
	_falas_fim_do_dia = []
	_pensamentos_vistos.clear()
	_faixa = Faixa.BAIXA
	observado = false
	em_partida = true

	suspeita_alterada.emit(suspeita)
	faixa_alterada.emit(_faixa)
	observado_alterado.emit(false)
	tempo_alterado.emit(tempo_restante)
	progresso_alterado.emit(0.0, "")
	inventario_alterado.emit()
	carga_alterada.emit(carga)
	objetivo_alterado.emit(indice, _titulo(OBJETIVOS[indice]))


func _process(delta: float) -> void:
	if not em_partida or em_roteiro:
		return

	tempo_restante -= delta
	tempo_alterado.emit(tempo_restante)
	if tempo_restante <= 0.0:
		tempo_restante = 0.0
		_terminar(Motivo.TEMPO)
		return



func faixa() -> Faixa:
	if suspeita >= LIMITE_ALTA:
		return Faixa.ALTA
	if suspeita >= LIMITE_MEDIA:
		return Faixa.MEDIA
	return Faixa.BAIXA


func aumentar_suspeita(quantidade: float) -> void:
	if not em_partida or em_roteiro:
		return
	_definir_suspeita(suspeita + quantidade)
	if suspeita >= SUSPEITA_MAX:
		_terminar(Motivo.SUSPEITA)


func reduzir_suspeita(quantidade: float) -> void:
	if not em_partida:
		return
	_definir_suspeita(suspeita - quantidade)


func _definir_suspeita(valor: float) -> void:
	suspeita = clampf(valor, 0.0, SUSPEITA_MAX)
	suspeita_alterada.emit(suspeita)

	var nova := faixa()
	if nova != _faixa:
		_faixa = nova
		faixa_alterada.emit(nova)


func objetivo_atual() -> Dictionary:
	if indice < 0 or indice >= OBJETIVOS.size():
		return {}
	return OBJETIVOS[indice]


func concluir_objetivo(id: String) -> void:
	if not em_partida:
		return
	var atual := objetivo_atual()
	if atual.is_empty() or atual["id"] != id:
		return

	concluidos[indice] = true
	etapa_concluida.emit(id)
	for item in atual["itens"]:
		itens.append(item)
	inventario_alterado.emit()

	var frase: String = atual["pensamento_depois"]
	var bilhete: Dictionary = atual.get("recado", {})
	indice += 1
	progresso_alterado.emit(0.0, "")
	if not bilhete.is_empty():
		recado.emit(bilhete["imagem"], bilhete["texto"])

	# a máquina ficou pronta: a escolha espera uns segundos para ela aparecer
	if indice >= OBJETIVOS.size():
		em_roteiro = true
		definir_observado(false)
		maquina_pronta.emit()
		_depois(PAUSA_MAQUINA_PRONTA, escolha_final.emit)
		return

	# a próxima etapa é de amanhã: não se anuncia, e o dia para aqui
	if atual.has("fim_do_dia"):
		em_partida = false
		em_roteiro = true
		definir_observado(false)
		pensar(frase)
		_falas_fim_do_dia = atual["fim_do_dia"]
		# com recado na tela, o Alfredo só aparece depois que ele for lido
		if bilhete.is_empty():
			recado_lido()
		return

	objetivo_alterado.emit(indice, _titulo(OBJETIVOS[indice]))
	pensar(frase)


func recado_lido() -> void:
	if _falas_fim_do_dia.is_empty():
		return
	var falas := _falas_fim_do_dia
	_falas_fim_do_dia = []
	fim_do_dia.emit(falas)


func encerrar_dia() -> void:
	noite.emit()


func _inicio_do_dia_2() -> int:
	for i in OBJETIVOS.size():
		if OBJETIVOS[i].has("fim_do_dia"):
			return i + 1
	return 0


func emitir_ruido(posicao: Vector2) -> void:
	if em_partida:
		ruido.emit(posicao)


func definir_observado(valor: bool) -> void:
	if observado == valor:
		return
	observado = valor
	observado_alterado.emit(valor)


func esta_concluido(i: int) -> bool:
	return i >= 0 and i < concluidos.size() and concluidos[i]


# A etapa de transporte troca de título conforme a boca do Caju: enquanto o item
# está no canto dele é "pegue", depois que ele pega vira "leve".
func _titulo(etapa: Dictionary) -> String:
	if etapa.has("carga") and carga != etapa["carga"]:
		return etapa.get("titulo_pegar", etapa["titulo"])
	return etapa["titulo"]


func pegar_carga(id: String) -> void:
	if not em_partida or carga != "":
		return
	carga = id
	carga_alterada.emit(carga)
	_reemitir_objetivo()


func largar_carga() -> void:
	if carga == "":
		return
	carga = ""
	carga_alterada.emit(carga)
	_reemitir_objetivo()


# a entrega limpa a boca sem reanunciar o objetivo: quem anuncia o próximo é o
# concluir_objetivo, logo na sequência
func consumir_carga() -> void:
	if carga == "":
		return
	carga = ""
	carga_alterada.emit(carga)


# O Alfredo não tira o item do jogo: devolve ao canto de onde saiu. O nó de
# origem reaparece sozinho, porque ele acompanha o sinal de carga.
func confiscar_carga() -> void:
	if carga == "":
		return
	var dados: Dictionary = Config.CARREGAVEIS.get(carga, {})
	var nome: String = dados.get("nome", "o item")
	largar_carga()
	aumentar_suspeita(SUSPEITA_CONFISCO)
	avisar("Alfredo tirou %s da sua boca e guardou de volta." % nome)
	pensar_uma_vez(
		"confisco",
		"Caramba... assim não dá. Preciso distrair o Alfredo antes de sair carregando as coisas."
	)


func titulo_atual() -> String:
	var atual := objetivo_atual()
	return "" if atual.is_empty() else _titulo(atual)


func _reemitir_objetivo() -> void:
	var atual := objetivo_atual()
	if not atual.is_empty():
		objetivo_alterado.emit(indice, _titulo(atual))



func pensar(texto: String) -> void:
	if texto != "":
		pensamento.emit(texto)


func pensar_uma_vez(chave: String, texto: String) -> void:
	if texto == "" or _pensamentos_vistos.has(chave):
		return
	_pensamentos_vistos[chave] = true
	pensamento.emit(texto)


func conversar(falas: Array) -> void:
	if not falas.is_empty():
		dialogo.emit(falas)


func encerrar_dialogo() -> void:
	dialogo_terminado.emit()


func avisar(texto: String) -> void:
	aviso.emit(texto)


func definir_progresso(fracao: float, tela := "") -> void:
	progresso_alterado.emit(clampf(fracao, 0.0, 1.0), tela)


func decidir(ativou: bool) -> void:
	if not ativou:
		_terminar(Motivo.DESISTIU)
		return
	# ativar não é um clique: a máquina liga em cena, e só então vem o final
	maquina_ligando.emit()
	_depois(PAUSA_MAQUINA_LIGANDO, _terminar.bind(Motivo.ATIVOU))


func _depois(segundos: float, acao: Callable) -> void:
	var rodada := _rodada
	await get_tree().create_timer(segundos).timeout
	if rodada == _rodada:
		acao.call()


func _terminar(motivo: Motivo) -> void:

	if not em_partida:
		return
	em_partida = false
	partida_terminada.emit(motivo)
	get_tree().paused = true
