extends Node

## Estado da partida: tempo, suspeita, objetivos, inventário e condições de fim.
##
## Este script é um AUTOLOAD (registrado em project.godot como "Jogo"), então existe em
## todas as cenas e não morre quando a cena troca. É o barramento central: ninguém no jogo
## conhece ninguém: todos falam com o Jogo, e o Jogo avisa o resto por SINAL.
##
## Os números de balanceamento estão todos aqui, num só bloco, de propósito — é o lugar de
## mexer para o jogo ficar mais fácil ou mais difícil. Ver docs/PLANO.md.


# ─────────────────────────────────────────────────────────────────────────────
# Sinais
# ─────────────────────────────────────────────────────────────────────────────

## Valor contínuo da barra (0 a 100). A HUD usa para desenhar a barra.
signal suspeita_alterada(valor: float)
## Evento: a suspeita MUDOU DE FAIXA. Separado do sinal acima porque é outra coisa —
## um é "o número mudou" (todo quadro), o outro é "o Alfredo mudou de comportamento"
## (raro, e digno de um aviso na tela).
signal faixa_alterada(nova_faixa: Faixa)
signal tempo_alterado(segundos: float)
signal objetivo_alterado(indice: int, titulo: String)
## Fração de 0 a 1 da barra de progresso da ação em curso.
signal progresso_alterado(fracao: float)
signal inventario_alterado()
## Alguém fez barulho nesta posição. O Alfredo escuta e vai investigar.
signal ruido(posicao: Vector2)
## Balão de pensamento acima do Caju.
signal pensamento(texto: String)
## Caixa de diálogo (pausa o jogo).
signal dialogo(nome: String, falas: PackedStringArray)
## A caixa de diálogo fechou. Quem abriu espera por este sinal para continuar.
signal dialogo_terminado()
## A máquina ficou pronta: hora de escolher.
signal escolha_final()
## O Alfredo passou a ver / deixou de ver o Caju. A HUD usa para avisar na tela.
signal observado_alterado(observado: bool)
## Texto curto e temporário na HUD.
signal aviso(texto: String)
signal partida_terminada(motivo: Motivo)


# ─────────────────────────────────────────────────────────────────────────────
# Balanceamento — é aqui que se mexe
# ─────────────────────────────────────────────────────────────────────────────

const TEMPO_TOTAL := 300.0        ## segundos até o cachorro chegar
const SUSPEITA_MAX := 100.0       ## chegar aqui é derrota
const DECAIMENTO_BAIXA := 1.0     ## por segundo, SÓ na faixa BAIXA (ver nota abaixo)
const LIMPAR_SE := 4.0            ## por segundo, tecla F, gato imóvel
const FLAGRANTE := 15.0           ## punição por ser pego em ação secreta

## Quanto a suspeita sobe mais rápido quando o Alfredo está OLHANDO o Caju no meio de uma
## etapa do plano. Sem isto, trabalhar na frente dele custa igual a trabalhar escondido, e
## posicionar-se deixa de ser decisão.
##
## Só vale para as etapas do plano. Ele pode ver o gato arranhando o sofá à vontade — é o
## ponto todo do disfarce.
const FATOR_OBSERVADO := 2.5

const LIMITE_MEDIA := 35.0        ## a partir daqui o Alfredo investiga barulho
const LIMITE_ALTA := 70.0         ## a partir daqui ele procura o Caju

# NOTA sobre DECAIMENTO_BAIXA: a suspeita só cai sozinha enquanto está na faixa BAIXA.
# Se caísse em qualquer nível, bastaria andar em círculos para zerar a barra e as ações de
# gato viravam enfeite. Com essa regra, depois que o Alfredo desconfia o jogador TEM que
# agir como gato para voltar ao normal.

enum Faixa { BAIXA, MEDIA, ALTA }
enum Motivo { SUSPEITA, TEMPO, ATIVOU, DESISTIU }


# ─────────────────────────────────────────────────────────────────────────────
# Conteúdo: as etapas do plano
# ─────────────────────────────────────────────────────────────────────────────

# "pensamento" é a frase do arco de dúvida, disparada AO CONCLUIR a etapa.
# A quinta frase do arco ("Será que seria tão ruim...") não está aqui: ela é o pensamento
# de proximidade da máquina, definido no mapa2.tscn, porque tem que aparecer ao CHEGAR
# na garagem, não depois de montar.
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
		"titulo": "Pegue papel e caneta na estante do escritório",
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
		"titulo": "Monte a máquina de controle mental na garagem",
		"duracao": 10.0,
		"suspeita": 5.0,
		"itens": ["Máquina de controle mental"],
		"pensamento": "",
	},
]

# Indexado pelo enum Motivo, na mesma ordem.
const FINAIS := [
	{   # SUSPEITA
		"vitoria": false,
		"titulo": "Alfredo descobriu o plano",
		"texto": "Ele juntou as peças: o papel sumido, o computador ligado, o gato onde não devia.\nCaju passou a tarde trancado no quintal — e o cachorro chegou sem ele poder fazer nada.",
	},
	{   # TEMPO
		"vitoria": false,
		"titulo": "O cachorro chegou",
		"texto": "A campainha tocou antes de Caju decidir o que sentia.\nO cachorro entrou correndo e o abraçou. Caju ficou ali, duro, ainda com o plano no bolso.",
	},
	{   # ATIVOU
		"vitoria": true,
		"titulo": "O mundo agora pertence aos gatos",
		"texto": "A máquina zumbiu. Alfredo parou no meio da sala e piscou devagar.\nLá fora, o carteiro parou. O cachorro, na van, parou.\nCaju subiu no sofá e olhou a rua como quem olha um império.",
	},
	{   # DESISTIU
		"vitoria": true,
		"titulo": "Caju mudou de ideia",
		"texto": "Caju olhou a máquina por um tempo longo. Depois puxou o fio com a pata.\nFoi até a porta e sentou, com o rabo enrolado nas patas, esperando.\nQuando o cachorro entrou, ele não correu. Cheirou, bufou uma vez — e deitou do lado.",
	},
]


# ─────────────────────────────────────────────────────────────────────────────
# Estado
# ─────────────────────────────────────────────────────────────────────────────

var em_partida := false
## O Alfredo está com linha de visão para o Caju agora? Quem responde é o alfredo.gd.
var observado := false
var suspeita := 0.0
var tempo_restante := TEMPO_TOTAL
var indice := 0                        ## qual etapa está em curso
var concluidos: Array[bool] = []       ## um ✓ por etapa, para o inventário
var itens: Array[String] = []          ## itens ganhos, para o inventário

var _faixa := Faixa.BAIXA
var _pensamentos_vistos := {}          ## chave -> true, para não repetir descoberta


# ─────────────────────────────────────────────────────────────────────────────
# Ciclo da partida
# ─────────────────────────────────────────────────────────────────────────────

## Chamado pelo _ready() do nível. Como o _ready() do pai roda DEPOIS do dos filhos,
## a HUD já está conectada aos sinais quando isto emite os valores iniciais.
func iniciar_partida() -> void:
	get_tree().paused = false          # a partida anterior terminou pausada
	suspeita = 0.0
	tempo_restante = TEMPO_TOTAL
	indice = 0
	concluidos.clear()
	concluidos.resize(OBJETIVOS.size())
	concluidos.fill(false)
	itens.clear()
	_faixa = Faixa.BAIXA
	_pensamentos_vistos.clear()
	observado = false
	em_partida = true

	observado_alterado.emit(false)

	suspeita_alterada.emit(suspeita)
	faixa_alterada.emit(_faixa)
	tempo_alterado.emit(tempo_restante)
	inventario_alterado.emit()
	progresso_alterado.emit(0.0)
	objetivo_alterado.emit(indice, OBJETIVOS[indice]["titulo"])


# O process_mode padrão faz este _process PARAR quando get_tree().paused é true.
# É de propósito: diálogo e inventário pausam o jogo, e ler não deve custar cronômetro.
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


func _terminar(motivo: Motivo) -> void:
	if not em_partida:
		return                          # guarda: nenhum fim dispara duas vezes
	em_partida = false
	partida_terminada.emit(motivo)
	get_tree().paused = true


## Chamado pelo painel de escolha final.
func decidir(ativou: bool) -> void:
	_terminar(Motivo.ATIVOU if ativou else Motivo.DESISTIU)


# ─────────────────────────────────────────────────────────────────────────────
# Suspeita
# ─────────────────────────────────────────────────────────────────────────────

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


# ─────────────────────────────────────────────────────────────────────────────
# Objetivos e inventário
# ─────────────────────────────────────────────────────────────────────────────

## Dicionário da etapa em curso, ou {} se todas acabaram.
func objetivo_atual() -> Dictionary:
	if indice < 0 or indice >= OBJETIVOS.size():
		return {}
	return OBJETIVOS[indice]


func esta_concluido(i: int) -> bool:
	return i >= 0 and i < concluidos.size() and concluidos[i]


func concluir_objetivo(id: String) -> void:
	if not em_partida:
		return
	var atual := objetivo_atual()
	if atual.is_empty() or atual["id"] != id:
		return                          # etapa fora de ordem: ignora

	concluidos[indice] = true
	for item in atual["itens"]:
		itens.append(item)
	inventario_alterado.emit()

	var frase: String = atual["pensamento"]
	indice += 1
	progresso_alterado.emit(0.0)

	if indice >= OBJETIVOS.size():
		escolha_final.emit()            # máquina pronta: o jogador decide
		return

	objetivo_alterado.emit(indice, OBJETIVOS[indice]["titulo"])
	if frase != "":
		pensar(frase)


# ─────────────────────────────────────────────────────────────────────────────
# Narrativa e barulho
# ─────────────────────────────────────────────────────────────────────────────

func emitir_ruido(posicao: Vector2) -> void:
	if em_partida:
		ruido.emit(posicao)


## Chamado pelo Alfredo a cada quadro. Só avisa a HUD na TROCA de estado, não a cada quadro.
func definir_observado(valor: bool) -> void:
	if observado == valor:
		return
	observado = valor
	observado_alterado.emit(valor)


func pensar(texto: String) -> void:
	if texto != "":
		pensamento.emit(texto)


## Pensamento de descoberta: aparece uma vez só na partida.
func pensar_uma_vez(chave: String, texto: String) -> void:
	if texto == "" or _pensamentos_vistos.has(chave):
		return
	_pensamentos_vistos[chave] = true
	pensamento.emit(texto)


func conversar(nome: String, falas: PackedStringArray) -> void:
	if falas.is_empty():
		return
	dialogo.emit(nome, falas)


## Chamado pela HUD quando o jogador fecha a última fala.
func encerrar_dialogo() -> void:
	dialogo_terminado.emit()


## Fração de 0 a 1 da barra de progresso. Os interagíveis chamam isto em vez de emitirem
## o sinal direto — emitir sinal de outro nó funciona, mas embaça de quem é a informação.
func definir_progresso(fracao: float) -> void:
	progresso_alterado.emit(clampf(fracao, 0.0, 1.0))


func avisar(texto: String) -> void:
	aviso.emit(texto)
