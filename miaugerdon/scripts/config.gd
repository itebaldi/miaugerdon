class_name Config

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
		"retrato": "res://sprites/personagens/MrT.png",
		"falas": [
			"Ora, ora. Outro gato pequeno com problemas pequenos.",
			"Eu tenho o melhor quintal. O maior quintal. Todos os gatos comentam.",
			"Um cachorro? Na SUA casa? Isso é uma invasão. Uma invasão total.",
			"Você precisa de uma máquina. Uma máquina de controle mental. As melhores máquinas são de controle mental.",
			"Humanos, cachorros, o carteiro, todos vão obedecer. Vai ser tremendo.",
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
		"pensamento_perto": "O chão atrás da cama serve. Ele nunca me procura aqui.",
		"titulo": "Escreva o plano atrás da cama",
		"duracao": 7.0,
		"suspeita": 5.0,
		"itens": ["Plano de dominação mundial (rascunho)"],
		"pensamento_depois": "Escrito assim no papel, parece meio... exagerado?",
	},
	{
		"id": "computador",
		"rotulo": "Usar o computador",
		"pensamento_perto": "O computador do Alfredo. A senha dele é o nome do gato. É o meu nome.",
		"titulo": "Acesse o PurrgleMiaut no computador",
		# fica no canto da tela enquanto ele trabalha, como se fosse o monitor
		"tela": "res://sprites/empresas/PurrgleMiaut.png",
		"recado": {
			"imagem": "res://sprites/empresas/encomenda miauzon.png",
			"texto": "Após se reunir no Purrgle Miaut, Caju encomendou na Miauzon as peças 
			necessárias para a construção da máquina de controle mental. Graças ao plano 
			Primiau, a encomenda já chegou na garagem.",
		},
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


const FINAIS := [
	{
		"vitoria": false,
		"titulo": "Alfredo descobriu o plano",
		"imagem": "res://sprites/finais/FINAL_alfredo pegou.png",
		"texto": "Ele juntou as peças: o papel sumido, o computador ligado, o gato onde não devia.\nCaju passou a tarde trancado no quintal e o cachorro chegou sem ele poder fazer nada.",
	},
	{
		"vitoria": false,
		"titulo": "O cachorro chegou",
		"imagem": "res://sprites/finais/FINAL_gameover tempo.png",
		"texto": "A campainha tocou antes de Caju decidir o que sentia.\nO cachorro entrou correndo e o abraçou. Caju ficou ali, paralisado, ainda com o plano no bolso.",
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
		"texto": "Caju olhou a máquina por um tempo longo. Depois puxou o fio com a pata.\nFoi até a porta e sentou, com o rabo enrolado nas patas, esperando.\nQuando o cachorro entrou, ele não correu. Cheirou, bufou uma vez e deitou do lado.",
	},
]


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
		"pensamento_perto": "Se eu arranhar o sofá, o Alfredo vem brigar aqui e me esquece no resto da casa.",
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

static func dados(id: String) -> Dictionary:
	if ACOES.has(id):
		return ACOES[id]
	for etapa in OBJETIVOS:
		if etapa["id"] == id:
			return etapa
	return {}
