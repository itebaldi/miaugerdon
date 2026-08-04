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
signal dialogo(nome: String, falas: PackedStringArray, retrato: String)
signal dialogo_terminado()
signal aviso(texto: String)
signal recado(imagem: String, texto: String)
signal escolha_final()
signal partida_terminada(motivo: Motivo)

const TEMPO_TOTAL := 300.0
const SUSPEITA_MAX := 100.0
const LIMITE_MEDIA := 35.0
const LIMITE_ALTA := 70.0

const LIMPAR_SE := 4.0
const SUSPEITA_MIADO := 3.0
const FLAGRANTE := 15.0

const FATOR_OBSERVADO := 2.5

enum Faixa { BAIXA, MEDIA, ALTA }
enum Motivo { SUSPEITA, TEMPO, ATIVOU, DESISTIU }

const OBJETIVOS := Config.OBJETIVOS
const FINAIS := Config.FINAIS

var intro_vista := false

var em_partida := false
var observado := false
var suspeita := 0.0
var tempo_restante := TEMPO_TOTAL
var indice := 0
var concluidos: Array[bool] = []
var itens: Array[String] = []

var _faixa := Faixa.BAIXA
var _pensamentos_vistos := {}


func iniciar_partida() -> void:
	get_tree().paused = false
	suspeita = 0.0
	tempo_restante = TEMPO_TOTAL
	indice = 0
	concluidos.clear()
	concluidos.resize(OBJETIVOS.size())
	concluidos.fill(false)
	itens.clear()
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
	objetivo_alterado.emit(indice, OBJETIVOS[indice]["titulo"])


func _process(delta: float) -> void:
	if not em_partida:
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
	if not em_partida:
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
	for item in atual["itens"]:
		itens.append(item)
	inventario_alterado.emit()

	var frase: String = atual["pensamento_depois"]
	var bilhete: Dictionary = atual.get("recado", {})
	indice += 1
	progresso_alterado.emit(0.0, "")
	if not bilhete.is_empty():
		recado.emit(bilhete["imagem"], bilhete["texto"])

	if indice >= OBJETIVOS.size():

		escolha_final.emit()
		return
	objetivo_alterado.emit(indice, OBJETIVOS[indice]["titulo"])
	pensar(frase)


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


func pensar(texto: String) -> void:
	if texto != "":
		pensamento.emit(texto)


func pensar_uma_vez(chave: String, texto: String) -> void:
	if texto == "" or _pensamentos_vistos.has(chave):
		return
	_pensamentos_vistos[chave] = true
	pensamento.emit(texto)


func conversar(nome: String, falas: PackedStringArray, retrato := "") -> void:
	if not falas.is_empty():
		dialogo.emit(nome, falas, retrato)


func encerrar_dialogo() -> void:
	dialogo_terminado.emit()


func avisar(texto: String) -> void:
	aviso.emit(texto)


func definir_progresso(fracao: float, tela := "") -> void:
	progresso_alterado.emit(clampf(fracao, 0.0, 1.0), tela)


func decidir(ativou: bool) -> void:
	_terminar(Motivo.ATIVOU if ativou else Motivo.DESISTIU)


func _terminar(motivo: Motivo) -> void:

	if not em_partida:
		return
	em_partida = false
	partida_terminada.emit(motivo)
	get_tree().paused = true
