class_name Config

# Todo o texto que o jogador lê, e os números de cada objeto da casa.
#
# Isto é um .gd de propósito. O editor do Godot reescreve os .tscn quando salva a cena, e
# já apagou as falas do Mr. T duas vezes; um script ele nunca toca. Não é autoload porque
# não guarda estado nenhum — só constante — e class_name dispensa registrar no projeto.
#
# Regra: aqui só entra o que dá para reescrever sem entender o código. As regras da
# partida (tempo, faixas de suspeita, flagrante) continuam no jogo.gd, e a arte de cada
# objeto (textura, escala, posição) continua na cena, que é onde dá para ver.


# uma página por vez, avançando com Enter. A última é o primeiro objetivo, e a HUD pinta
# ela de outra cor porque já não é história.
const INTRO := [
	"Caju sempre soube quem realmente mandava naquela casa. Alfredo podia preparar a comida, limpar a bagunça e pagar as contas, mas era apenas seu fiel servo humano.",
	"Tudo seguia perfeitamente até Alfredo anunciar uma notícia terrível. Ele havia adotado um cachorro, e o novo invasor chegaria em breve.",
	"Para Caju, aquilo não era uma simples mudança. Era uma ameaça ao seu território, à sua rotina e à ordem natural das coisas. Se Alfredo acreditava que poderia colocar outro animal em seu lugar, estava muito enganado.",
	"Tomado pela indignação, Caju decidiu que não bastava defender a casa. Era hora de executar seu plano mais ambicioso e dominar o mundo antes da chegada do cachorro.",
	"Mas nenhum grande plano começa sem informações. No quintal vive um gato que pode ajudá-lo, o misterioso e influente Mr. T.",
	"Primeiro objetivo. Vá até o quintal e fale com Mr. T.",
]


const OBJETIVOS := [
	{
		"id": "mr_t",
		"rotulo": "Falar com o Mr. T",
		"pensamento_perto": "Aquele é o Mr. T. Dizem que ele resolve as coisas.",
		"titulo": "Fale com o Mr. T no quintal",
		"duracao": 2.0,
		"suspeita": 3.0,
		"itens": [],
		"falante": "Mr. T",
		"falas": [
			"Ora, ora. Outro gato pequeno com problemas pequenos.",
			"Eu tenho o melhor quintal. O maior quintal. Todos os gatos comentam.",
			"Um cachorro? Na SUA casa? Isso é uma invasão. Uma invasão total.",
			"Você precisa de uma máquina. Uma máquina de controle mental. As melhores máquinas são de controle mental.",
			"Humanos, cachorros, o carteiro — todos vão obedecer. Vai ser tremendo.",
			"Faça, Caju. Ninguém nunca fez isso melhor do que você vai fazer.",
		],
		"pensamento_depois": "Ele fala bonito... mas por que eu saí de lá me sentindo pior?",
	},
	{
		"id": "papel_caneta",
		"rotulo": "Pegar papel e caneta",
		"pensamento_perto": "Papel e caneta na estante. Todo plano começa escrito.",
		"titulo": "Pegue papel e caneta na estante",
		"duracao": 4.0,
		"suspeita": 5.0,
		"itens": ["Papel", "Caneta"],
		"pensamento_depois": "O Alfredo comprou essa caneta pra fazer a lista de compras. Ele anota ração de gato primeiro.",
	},
	{
		"id": "escrever_plano",
		"rotulo": "Escrever o plano",
		"pensamento_perto": "A mesa de centro serve. O Alfredo nunca olha aqui.",
		"titulo": "Escreva o plano na mesa de centro",
		"duracao": 7.0,
		"suspeita": 5.0,
		"itens": ["Plano de dominação mundial (rascunho)"],
		"pensamento_depois": "Escrito assim no papel, parece meio... exagerado?",
	},
	{
		"id": "computador",
		"rotulo": "Usar o computador",
		"pensamento_perto": "O computador do Alfredo. A senha dele é o nome do gato. É o meu nome.",
		"titulo": "Acesse o PurrrgleMiaut no computador",
		"duracao": 7.0,
		"suspeita": 5.0,
		"itens": ["Pedido no Miauzon: peça #TR-4"],
		"pensamento_depois": "O Mr. T tem o maior quintal do bairro. E não tem mais ninguém nele.",
	},
	{
		"id": "maquina",
		"rotulo": "Montar a máquina",
		"pensamento_perto": "Será que seria tão ruim ter mais um animal em casa?",
		"titulo": "Monte a máquina na garagem",
		"duracao": 10.0,
		"suspeita": 5.0,
		"itens": ["Máquina de controle mental"],
		# sem o plano escrito e sem a peça encomendada não há nada na garagem
		# para montar: a máquina só aparece quando chega a vez dela
		"oculto": true,
		"pensamento_depois": "",
	},
]


# na mesma ordem do enum Jogo.Motivo: SUSPEITA, TEMPO, ATIVOU, DESISTIU
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
		"imagem": "res://sprites/finais/FINAL_estatua liberdade.png",
		"texto": "A máquina zumbiu. Alfredo parou no meio da sala e piscou devagar.\nLá fora, o carteiro parou. O cachorro, na van, parou.\nCaju subiu no sofá e olhou a rua como quem olha um império.",
	},
	{
		"vitoria": true,
		"titulo": "Caju mudou de ideia",
		"imagem": "res://sprites/finais/FINAL_com cachorro.png",
		"texto": "Caju olhou a máquina por um tempo longo. Depois puxou o fio com a pata.\nFoi até a porta e sentou, com o rabo enrolado nas patas, esperando.\nQuando o cachorro entrou, ele não correu. Cheirou, bufou uma vez — e deitou do lado.",
	},
]

# Cada chave é o "id" do nó dentro de Acoes/ no mapa2.tscn.
#   duracao        segundos segurando E
#   reduz_suspeita quanto tira da barra ao concluir
#   recarga        segundos até poder repetir
#   usos           -1 é ilimitado
#   atrai_alfredo  faz barulho: ele vem investigar. É o que separa a ação segura da arriscada.
const ACOES := {
	"copo": {
		"rotulo": "Derrubar o copo",
		"pensamento_perto": "Um copo na beirada da mesa. É quase um convite.",
		"duracao": 1.5,
		"reduz_suspeita": 12.0,
		"recarga": 15.0,
		"usos": 2,
		"atrai_alfredo": true,
	},
	"comer": {
		"rotulo": "Comer na tigela",
		"pensamento_perto": "Comida. Comer é a coisa mais normal que um gato faz.",
		"duracao": 1.5,
		"reduz_suspeita": 15.0,
		"recarga": 12.0,
		"usos": -1,
		"atrai_alfredo": false,
	},
	"arranhar_sofa": {
		"rotulo": "Arranhar o sofá",
		"pensamento_perto": "Se eu arranhar o sofá, o Alfredo vem brigar aqui — e me esquece no resto da casa.",
		"duracao": 1.5,
		"reduz_suspeita": 18.0,
		"recarga": 15.0,
		"usos": 3,
		"atrai_alfredo": true,
	},
	"dormir": {
		"rotulo": "Dormir na cama",
		"pensamento_perto": "A cama dele. Dormir aqui é praticamente meu trabalho.",
		"duracao": 1.5,
		"reduz_suspeita": 25.0,
		"recarga": 20.0,
		"usos": -1,
		"atrai_alfredo": false,
	},
	"cavar_terra": {
		"rotulo": "Cavar a terra",
		"pensamento_perto": "Terra fofa. Dá vontade de cavar só de olhar.",
		"duracao": 1.5,
		"reduz_suspeita": 10.0,
		"recarga": 15.0,
		"usos": 2,
		"atrai_alfredo": true,
	},
	"brincar": {
		"rotulo": "Brincar no tapete",
		"pensamento_perto": "O tapete. Bom para fingir que sou um gato bobo.",
		"duracao": 1.5,
		"reduz_suspeita": 12.0,
		"recarga": 10.0,
		"usos": -1,
		"atrai_alfredo": false,
	},
}

# os nós de Objetivos/ e de Acoes/ dividem o mesmo script base, e ele não sabe de qual
# lado veio: procura nos dois
static func dados(id: String) -> Dictionary:
	if ACOES.has(id):
		return ACOES[id]
	for etapa in OBJETIVOS:
		if etapa["id"] == id:
			return etapa
	return {}
