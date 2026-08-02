extends Node

# Estado da partida: tempo, suspeita e as condições de fim.
# É autoload, então existe em todas as cenas e não morre na troca de cena.
# Ninguém aqui conhece o Caju nem a interface: tudo sai por sinal.

signal suspeita_alterada(valor: float)
signal faixa_alterada(nova: Faixa)
signal tempo_alterado(segundos: float)
signal objetivo_alterado(indice: int, titulo: String)
signal progresso_alterado(fracao: float)
signal partida_terminada(motivo: Motivo)

const TEMPO_TOTAL := 300.0
const SUSPEITA_MAX := 100.0
const LIMITE_MEDIA := 35.0
const LIMITE_ALTA := 70.0

const DECAIMENTO_BAIXA := 1.0

const LIMPAR_SE := 4.0
const SUSPEITA_MIADO := 3.0

enum Faixa { BAIXA, MEDIA, ALTA }
enum Motivo { SUSPEITA, TEMPO, VITORIA }

const OBJETIVOS := [
	{"id": "mr_t", "titulo": "Fale com o Mr. T no quintal", "duracao": 2.0, "suspeita": 3.0},
	{"id": "papel_caneta", "titulo": "Pegue papel e caneta na estante", "duracao": 4.0, "suspeita": 5.0},
	{"id": "escrever_plano", "titulo": "Escreva o plano na mesa de centro", "duracao": 7.0, "suspeita": 5.0},
	{"id": "computador", "titulo": "Acesse o PurrrgleMiaut no computador", "duracao": 7.0, "suspeita": 5.0},
	{"id": "maquina", "titulo": "Monte a máquina na garagem", "duracao": 10.0, "suspeita": 5.0},
]

var em_partida := false
var suspeita := 0.0
var tempo_restante := TEMPO_TOTAL
var indice := 0

var _faixa := Faixa.BAIXA


func iniciar_partida() -> void:
	get_tree().paused = false
	suspeita = 0.0
	tempo_restante = TEMPO_TOTAL
	indice = 0
	_faixa = Faixa.BAIXA
	em_partida = true

	suspeita_alterada.emit(suspeita)
	faixa_alterada.emit(_faixa)
	tempo_alterado.emit(tempo_restante)
	progresso_alterado.emit(0.0)
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

	if faixa() == Faixa.BAIXA and suspeita > 0.0:
		reduzir_suspeita(DECAIMENTO_BAIXA * delta)


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

	indice += 1
	progresso_alterado.emit(0.0)

	if indice >= OBJETIVOS.size():
		_terminar(Motivo.VITORIA)
		return
	objetivo_alterado.emit(indice, OBJETIVOS[indice]["titulo"])


func definir_progresso(fracao: float) -> void:
	progresso_alterado.emit(clampf(fracao, 0.0, 1.0))


func _terminar(motivo: Motivo) -> void:

	if not em_partida:
		return
	em_partida = false
	partida_terminada.emit(motivo)
	get_tree().paused = true
