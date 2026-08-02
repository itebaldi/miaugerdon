extends Node

# Estado da partida: tempo, suspeita e as condições de fim.
# É autoload, então existe em todas as cenas e não morre na troca de cena.
# Ninguém aqui conhece o Caju nem a interface: tudo sai por sinal.

signal suspeita_alterada(valor: float)
signal faixa_alterada(nova: Faixa)
signal tempo_alterado(segundos: float)
signal objetivo_alterado(indice: int, titulo: String)
signal progresso_alterado(fracao: float)
signal ruido(posicao: Vector2)
signal observado_alterado(observado: bool)
signal inventario_alterado()
signal pensamento(texto: String)
signal dialogo(nome: String, falas: PackedStringArray)
signal dialogo_terminado()
signal aviso(texto: String)
signal escolha_final()
signal partida_terminada(motivo: Motivo)

const TEMPO_TOTAL := 300.0
const SUSPEITA_MAX := 100.0
const LIMITE_MEDIA := 35.0
const LIMITE_ALTA := 70.0

const DECAIMENTO_BAIXA := 1.0

const LIMPAR_SE := 4.0
const SUSPEITA_MIADO := 3.0
const FLAGRANTE := 15.0

# quanto a suspeita sobe mais rápido com o Alfredo olhando. Vale só para as etapas do
# plano: ele pode ver o gato arranhando o sofá à vontade, é o ponto do disfarce.
const FATOR_OBSERVADO := 2.5

enum Faixa { BAIXA, MEDIA, ALTA }
enum Motivo { SUSPEITA, TEMPO, ATIVOU, DESISTIU }

# indexado pelo enum Motivo, na mesma ordem
const FINAIS := [
	{
		"vitoria": false,
		"titulo": "Alfredo descobriu o plano",
		"texto": "Ele juntou as peças: o papel sumido, o computador ligado, o gato onde não devia.\nCaju passou a tarde trancado no quintal — e o cachorro chegou sem ele poder fazer nada.",
	},
	{
		"vitoria": false,
		"titulo": "O cachorro chegou",
		"texto": "A campainha tocou antes de Caju decidir o que sentia.\nO cachorro entrou correndo e o abraçou. Caju ficou ali, duro, ainda com o plano no bolso.",
	},
	{
		"vitoria": true,
		"titulo": "O mundo agora pertence aos gatos",
		"texto": "A máquina zumbiu. Alfredo parou no meio da sala e piscou devagar.\nLá fora, o carteiro parou. O cachorro, na van, parou.\nCaju subiu no sofá e olhou a rua como quem olha um império.",
	},
	{
		"vitoria": true,
		"titulo": "Caju mudou de ideia",
		"texto": "Caju olhou a máquina por um tempo longo. Depois puxou o fio com a pata.\nFoi até a porta e sentou, com o rabo enrolado nas patas, esperando.\nQuando o cachorro entrou, ele não correu. Cheirou, bufou uma vez — e deitou do lado.",
	},
]


const OBJETIVOS := [
	{
		"id": "mr_t",
		"titulo": "Fale com o Mr. T no quintal",
		"duracao": 2.0,
		"suspeita": 3.0,
		"itens": [],
		"pensamento": "Ele fala bonito... mas por que eu saí de lá me sentindo pior?",
	},
	{
		"id": "papel_caneta",
		"titulo": "Pegue papel e caneta na estante",
		"duracao": 4.0,
		"suspeita": 5.0,
		"itens": ["Papel", "Caneta"],
		"pensamento": "O Alfredo comprou essa caneta pra fazer a lista de compras. Ele anota ração de gato primeiro.",
	},
	{
		"id": "escrever_plano",
		"titulo": "Escreva o plano na mesa de centro",
		"duracao": 7.0,
		"suspeita": 5.0,
		"itens": ["Plano de dominação mundial (rascunho)"],
		"pensamento": "Escrito assim no papel, parece meio... exagerado?",
	},
	{
		"id": "computador",
		"titulo": "Acesse o PurrrgleMiaut no computador",
		"duracao": 7.0,
		"suspeita": 5.0,
		"itens": ["Pedido no Miauzon: peça #TR-4"],
		"pensamento": "O Mr. T tem o maior quintal do bairro. E não tem mais ninguém nele.",
	},
	{
		"id": "maquina",
		"titulo": "Monte a máquina na garagem",
		"duracao": 10.0,
		"suspeita": 5.0,
		"itens": ["Máquina de controle mental"],
		"pensamento": "",
	},
]

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
	progresso_alterado.emit(0.0)
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

	concluidos[indice] = true
	for item in atual["itens"]:
		itens.append(item)
	inventario_alterado.emit()

	var frase: String = atual["pensamento"]
	indice += 1
	progresso_alterado.emit(0.0)

	if indice >= OBJETIVOS.size():
		# a máquina está pronta, mas quem decide o que fazer com ela é o jogador
		escolha_final.emit()
		return
	objetivo_alterado.emit(indice, OBJETIVOS[indice]["titulo"])
	pensar(frase)


func emitir_ruido(posicao: Vector2) -> void:
	if em_partida:
		ruido.emit(posicao)


# o Alfredo escreve isto todo quadro; só avisa a HUD na troca
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


# pensamento de descoberta: sai uma vez só por partida
func pensar_uma_vez(chave: String, texto: String) -> void:
	if texto == "" or _pensamentos_vistos.has(chave):
		return
	_pensamentos_vistos[chave] = true
	pensamento.emit(texto)


func conversar(nome: String, falas: PackedStringArray) -> void:
	if not falas.is_empty():
		dialogo.emit(nome, falas)


# a HUD chama isto quando o jogador fecha a última fala
func encerrar_dialogo() -> void:
	dialogo_terminado.emit()


func avisar(texto: String) -> void:
	aviso.emit(texto)


func definir_progresso(fracao: float) -> void:
	progresso_alterado.emit(clampf(fracao, 0.0, 1.0))


func decidir(ativou: bool) -> void:
	_terminar(Motivo.ATIVOU if ativou else Motivo.DESISTIU)


func _terminar(motivo: Motivo) -> void:

	if not em_partida:
		return
	em_partida = false
	partida_terminada.emit(motivo)
	get_tree().paused = true
