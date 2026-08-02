extends Node

# Estado da partida: tempo, suspeita e as condições de fim.
# É autoload, então existe em todas as cenas e não morre na troca de cena.
# Ninguém aqui conhece o Caju nem a interface: tudo sai por sinal.

signal suspeita_alterada(valor: float)
signal faixa_alterada(nova: Faixa)
signal tempo_alterado(segundos: float)
signal partida_terminada(motivo: Motivo)

const TEMPO_TOTAL := 300.0
const SUSPEITA_MAX := 100.0
const LIMITE_MEDIA := 35.0
const LIMITE_ALTA := 70.0

# A suspeita só cai sozinha na faixa baixa. Se caísse em qualquer nível, bastava andar
# em círculos para zerar a barra.
const DECAIMENTO_BAIXA := 1.0

const LIMPAR_SE := 4.0
const SUSPEITA_MIADO := 3.0

enum Faixa { BAIXA, MEDIA, ALTA }
enum Motivo { SUSPEITA, TEMPO }

var em_partida := false
var suspeita := 0.0
var tempo_restante := TEMPO_TOTAL

var _faixa := Faixa.BAIXA


func iniciar_partida() -> void:
	get_tree().paused = false
	suspeita = 0.0
	tempo_restante = TEMPO_TOTAL
	_faixa = Faixa.BAIXA
	em_partida = true

	suspeita_alterada.emit(suspeita)
	faixa_alterada.emit(_faixa)
	tempo_alterado.emit(tempo_restante)


# Para de rodar quando o jogo pausa, e é isso que faz o cronômetro congelar junto.
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

	# a faixa é avisada só na troca; o valor contínuo já vai no sinal acima
	var nova := faixa()
	if nova != _faixa:
		_faixa = nova
		faixa_alterada.emit(nova)


func _terminar(motivo: Motivo) -> void:
	# guarda para as duas derrotas não dispararem no mesmo quadro
	if not em_partida:
		return
	em_partida = false
	partida_terminada.emit(motivo)
	get_tree().paused = true
