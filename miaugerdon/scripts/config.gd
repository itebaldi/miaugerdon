class_name Config

# Intro antiga em caixa de texto. Substituída pela prancha de quadrinho em
# cenas/ui/abertura.tscn, onde os textos agora moram nos próprios balões; só
# continua aqui porque o painel do HUD ainda sabe exibi-la.
const INTRO := [
	"Caju sempre soube quem realmente mandava naquela casa. Alfredo podia preparar a comida, limpar a bagunça e pagar as contas, mas era apenas seu fiel servo humano.",
	"Tudo seguia perfeitamente até Alfredo anunciar uma notícia terrível. Ele havia adotado um cachorro, e o novo invasor chegaria em breve.",
	"Para Caju, aquilo não era uma simples mudança. Era uma ameaça ao seu território, à sua rotina e à ordem natural das coisas. Se Alfredo acreditava que poderia colocar outro animal em seu lugar, estava muito enganado.",
	"Tomado pela indignação, Caju decidiu que não bastava defender a casa. Era hora de executar seu plano mais ambicioso e dominar o mundo antes da chegada do cachorro.",
	"Mas nenhum grande plano começa sem informações. No quintal vive um gato que pode ajudá-lo, o misterioso e influente Mr. T.",
	"Primeiro objetivo. Vá até o quintal e fale com Mr. T.",
]


# Retrato de quem fala na caixa de diálogo. Quem não tiver retrato fala com o
# do outro esmaecido ao lado. O recorte, em pixels da imagem, tira o corpo de
# baixo para o rosto caber maior na caixa.
const FALANTES := {
	"Mr. T": {
		"retrato": "res://sprites/personagens/retrato_mrt.png",
		"recorte": Rect2(0, 80, 1024, 1100),
		"cor": Color(1, 0.78, 0.35),
	},
	"Caju": {
		"retrato": "res://sprites/personagens/retrato_caju.png",
		"recorte": Rect2(0, 150, 1024, 1100),
		"cor": Color(0.62, 0.84, 1),
	},
	"Alfredo": {
		"retrato": "res://sprites/personagens/retrato_alfredo.png",
		"recorte": Rect2(0, 60, 1024, 1100),
		"cor": Color(0.55, 0.85, 0.75),
	},
}


# Cada fala é [quem fala, texto]. Uma etapa com "local" acontece no ponto do
# mapa de outra: é assim que Caju volta ao quintal para receber a próxima ordem.
const OBJETIVOS := [
	{
		"id": "mr_t",
		"rotulo": "Falar com o Mr. T",
		"pensamento_perto": "Aquele é o Mr. T. Ele sempre sabe das coisas antes de todo mundo.",
		"titulo": "Fale com o Mr. T no quintal",
		"duracao": 2.0,
		"suspeita": 3.0,
		"itens": [],
		"falas": [
			["Mr. T", "Ora, ora. O Caju. Faz tempo que não aparece no meu quintal. O melhor quintal do bairro, aliás."],
			["Caju", "Mr. T, o Alfredo vai adotar outro gato. Chega hoje à tarde."],
			["Mr. T", "Outro gato... Veio de onde?"],
			["Caju", "Do abrigo. O nome dele é Soneca."],
			["Mr. T", "Abrigo?! Eu não ia dizer nada, mas..."],
			["Caju", "Que foi?"],
			["Mr. T", "Nada contra, tenho até amigos que vieram de abrigo, mas você sabe como eles são..."],
			["Caju", "Como assim?"],
			["Mr. T", "Lá não tem tutor, não tem regra, não tem tigela própria. Eles aprendem a pegar o que é dos outros. É da natureza deles."],
			["Mr. T", "Primeiro é um cantinho do sofá. Depois a sua cama. Depois a sua tigela. Quando você vê, o Alfredo chama ELE de Caju."],
			["Caju", "...M-mas ele é gato, que nem a gente."],
			["Mr. T", "Mas não é gato de casa. Não é gato daqui. Tem diferença, Caju. Uma diferença tremenda."],
			["Mr. T", "Gato de abrigo mia a noite inteira, rasga tudo e traz pulga. Todo mundo sabe disso."],
			["Mr. T", "E o Alfredo vai dizer que o Soneca é um amor. Claro que vai. Humano acredita em qualquer foto bonitinha. Eu, não!! Confia em mim!"],
			["Mr. T", "Primeiro vem um. Depois vêm os amigos dele. Daqui a pouco a rua inteira é deles."],
			["Caju", "E agora?! O que eu faço?!"],
			["Mr. T", "Uma máquina! Você precisa de uma máquina! Uma máquina de controle mental! Máquinas de controle mental são as melhores! O Alfredo esquece essa ideia e a casa continua sendo só sua."],
			["Mr. T", "Vai, Caju. Pega papel e caneta, escreve o plano e volta aqui pra me mostrar."],
			["Mr. T", "Lembre-se: eu sou o único que fala a verdade pra você."],
		],
		"pensamento_depois": "Ele disse que não tinha nada contra... então por que tudo o que ele falou foi contra?",
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
		"id": "mostrar_plano",
		"local": "mr_t",
		"rotulo": "Mostrar o plano ao Mr. T",
		"pensamento_perto": "Ele vai saber o que fazer com isso.",
		"titulo": "Mostre o plano ao Mr. T no quintal",
		"duracao": 2.0,
		"suspeita": 3.0,
		"itens": [],
		"falas": [
			["Mr. T", "E aí? Trouxe o plano?"],
			["Caju", "Trouxe. Mas... escrito assim, parece meio exagerado."],
			["Mr. T", "Exagerado? Exagerado é deixar um estranho dormir na sua cama. Isso aqui é prevenção."],
			["Caju", "O Alfredo disse que ele ficou dois anos no abrigo e ninguém quis adotar..."],
			["Mr. T", "E você não se perguntou por quê? Dois anos, Caju. Dois anos! Alguma coisa ele fez."],
			["Caju", "Ele também disse que a gente vai se dar super bem."],
			["Mr. T", "O Alfredo já escolheu o lado dele. Você não devia se informar por ele."],
			["Mr. T", "O plano está bom. Mas falta o principal: as peças."],
			["Mr. T", "Usa o computador do Alfredo. Entra no PurrgleMiaut que eu te passo a lista, e encomenda tudo na Miauzon."],
			["Mr. T", "E ninguém pode saber. Nem o Alfredo. Principalmente o Alfredo."],
		],
		"pensamento_depois": "Dois anos esperando alguém... isso é culpa dele?",
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

static func local(etapa: Dictionary) -> String:
	return etapa.get("local", etapa["id"])


static func dados(id: String) -> Dictionary:
	if ACOES.has(id):
		return ACOES[id]
	for etapa in OBJETIVOS:
		if etapa["id"] == id:
			return etapa
	return {}
