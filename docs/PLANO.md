# Miaugerdon — plano da versão jogável

> Este documento explica **por que o jogo é assim**. O SGDD diz *o que* o jogo é;
> aqui estão as decisões de recorte, as regras e os números.
> Para aprender *como o código funciona*, veja [TUTORIAL.md](TUTORIAL.md).

## De onde partimos

O projeto tinha cenário e movimento, e mais nada:

- **Funcionava:** Caju andando com WASD em projeção isométrica, câmera seguindo o gato,
  27 objetos com colisão, sprites finais posicionados.
- **Não existia:** HUD, cronômetro, barra de suspeita, objetivos, interação, diálogo,
  inventário, vitória, derrota, menu, áudio. Nenhum `Control`, `CanvasLayer` ou `Timer`
  no projeto inteiro.
- **Estava quebrado:** o Alfredo ficava **parado** no `mapa2.tscn`. Três coisas erradas
  ao mesmo tempo — sem `NavigationRegion2D` no mapa, o `alvo` não ligado na instância, e
  o grupo `jogador` que o código procurava nunca existiu. E **sem nenhum erro no console**.
- **Sem profundidade:** o gato desenhava sempre por cima de tudo, nunca passava atrás
  da cama ou do sofá.
- **Bagunça:** uma cena de rascunho, um mapa legado, dois sprites órfãos e um sprite de
  2837x1928 invisível sendo carregado em memória para nada.

## Recorte: o que entrou e o que ficou de fora

O SGDD descreve 10 etapas do plano, 13 tipos de interação e 19 sons. Isso é muito para
uma primeira versão jogável. O critério foi: **manter o loop inteiro, com menos conteúdo**.
Um jogo curto que funciona do começo ao fim ensina e diverte mais que meio jogo grande.

| Entrou | Ficou de fora |
|---|---|
| 5 etapas do plano | encomendar no Miauzon, acompanhar a entrega, receber o pacote, reunir peças (absorvidas em `computador` e `maquina`) |
| 6 ações de gato + 2 no teclado | vomitar bola de pelo, fingir inocência, pedir para abrir a porta |
| Suspeita, cronômetro, flagrante | — |
| Diálogo, pensamentos, inventário | — |
| Menu, tutorial curto, 4 finais | quadrinhos de abertura, ilustração da Estátua da Liberdade |
| — | **áudio** (o projeto não tem nenhum arquivo de som) |

## A história: o arco do Caju

O jogo começa com o Caju convicto e termina com ele em dúvida. Isso **não é cutscene** —
é construído durante o gameplay, um pensamento por etapa concluída.

**Início.** O Caju vai até o Mr. T no quintal (é a etapa 1). Mr. T é o gato do Trump:
discurso de ditador, superlativos, e é ele que planta a ideia da máquina de controle mental.

**Meio.** Cada etapa concluída dispara um balão de pensamento:

| depois de | pensamento |
|---|---|
| `mr_t` | "Ele fala bonito... mas por que eu saí de lá me sentindo pior?" |
| `papel_caneta` | "O Alfredo comprou essa caneta pra fazer a lista de compras. Ele anota ração de gato primeiro." |
| `escrever_plano` | "Escrito assim no papel, parece meio... exagerado?" |
| `computador` | "O Mr. T tem o maior quintal do bairro. E não tem mais ninguém nele." |
| chegar na `maquina` | "Será que seria tão ruim ter mais um animal em casa?" |

A virada é a quarta: o Caju percebe que o mentor dele está sozinho. Ninguém precisa dizer
isso em voz alta — é o jogador que junta as peças.

**Fim.** Com a máquina montada, o jogo oferece uma escolha. Os pensamentos foram a
persuasão; a decisão é do jogador.

### Mr. T

Paródia caricata de um gato ditador. É personagem de ficção — nenhuma fala é atribuída a
pessoa real:

> — Ora, ora. Outro gato pequeno com problemas pequenos.
> — Eu tenho o melhor quintal. O maior quintal. Todos os gatos comentam.
> — Um cachorro? Na SUA casa? Isso é uma invasão. Uma invasão total.
> — Você precisa de uma máquina. Uma máquina de controle mental. As melhores máquinas são de controle mental.
> — Humanos, cachorros, o carteiro — todos vão obedecer. Vai ser tremendo.
> — Faça, Caju. Ninguém nunca fez isso melhor do que você vai fazer.

Sem arte dedicada, ele usa `sprites/gato.png` escalado. A caracterização vem do diálogo.

## Os 4 finais

```
máquina pronta + [E]   ->  vitória "dominação":  o mundo agora pertence aos gatos
máquina pronta + [F]   ->  vitória "coração":    Caju desliga a máquina e vai esperar na porta
suspeita >= 100        ->  derrota "suspeita":   Alfredo descobriu o plano
tempo <= 0             ->  derrota "tempo":      o cachorro chegou antes do Caju decidir
```

**A tensão que isso resolve.** No SGDD, o cachorro chegar *era* a derrota. Agora aceitar o
cachorro é o final bom. A diferença é a **escolha**: se o tempo acaba, o cachorro chega antes
de o Caju resolver o que sente — ele é pego de surpresa, ainda ressentido. No final "coração",
ele decide. Mesmo evento, significado oposto.

As duas derrotas **empurram para lados opostos**, e é aí que está o jogo: baixar a suspeita
custa tempo parado; correr contra o cronômetro obriga a encadear etapas, o que sobe a suspeita.
Ganhar é achar o ritmo entre as duas.

## Balanceamento

Com a suspeita virando derrota, os números **decidem se o jogo é ganhável**. Por isso estão
todos num só lugar, no `scripts/jogo.gd`:

```gdscript
TEMPO_TOTAL       = 300.0   # 5 min — principal botão de ajuste
SUSPEITA_MAX      = 100.0   # chegar aqui é derrota
DECAIMENTO_BAIXA  =   1.0   # /s, SÓ na faixa BAIXA (<35)
LIMPAR_SE         =   4.0   # /s, tecla F, gato imóvel
FLAGRANTE         =  15.0   # levar flagrante do Alfredo
FATOR_OBSERVADO   =   2.5   # multiplicador quando o Alfredo está TE VENDO
```

**Faixas de suspeita:**

| faixa | valor | o que o Alfredo faz |
|---|---|---|
| BAIXA | < 35 | rotina normal, ignora barulho |
| MÉDIA | 35 – 70 | investiga barulho |
| ALTA | ≥ 70 | procura o Caju ativamente |
| — | 100 | derrota |

### A regra que segura o jogo em pé

**O decaimento passivo só acontece na faixa BAIXA.** Isso não é detalhe: se a suspeita
caísse sozinha em qualquer nível, bastaria andar em círculos para zerar a barra, e as seis
ações de gato viravam enfeite. Com essa regra, depois que o Alfredo desconfia o jogador
**tem** que agir como gato para voltar ao normal. É o loop do SGDD virando regra de código.

### Ser visto: onde você faz importa

Sem isto, trabalhar no plano na frente do Alfredo custava exatamente o mesmo que trabalhar
escondido, e a única punição era binária: ele chegar a 60 px e te pegar. Ou seja, *onde* você
executava não era decisão nenhuma — só "corra até o objeto e segure E".

Agora, enquanto ele tem **linha de visão** para o Caju, uma etapa do plano custa
`FATOR_OBSERVADO` vezes mais suspeita. Três regras completam a mecânica:

**Ele vê por alcance + linha de visão, não por cone.** Um cone de visão (só vê para onde está
virado) seria mais realista, mas o Alfredo é um bonequinho de 32 px com quatro direções — o
jogador não consegue ler para onde ele olha, e punir por algo imperceptível é injusto. Parede e
móvel no caminho, ao contrário, o jogador vê na hora. **Efeito colateral bem-vindo: esconder-se
atrás do sofá funciona.**

**O aviso chega antes.** Um "Alfredo está te vendo" fica piscando no alto da tela sempre que ele
tem o gato à vista — não só depois de o jogador começar a etapa. A informação útil é "não comece
agora", e para isso ela precisa chegar antes de apertar `E`.

**Ações de gato ficam de fora.** Ele pode ver o Caju arranhando o sofá à vontade: é o ponto todo
do disfarce. Só as etapas do plano são afetadas.

E o flagrante agora **exige** linha de visão. Antes era só distância, então ele pegava o gato
através de uma parede — o jogador não tinha como prever.

### Custo dos objetivos

| etapa | onde | duração | suspeita/s | total |
|---|---|---|---|---|
| `mr_t` | quintal | 2 s | +3 | 6 |
| `papel_caneta` | estante, escritório | 4 s | +5 | 20 |
| `escrever_plano` | mesa de centro, sala | 7 s | +5 | 35 |
| `computador` | escrivaninha, escritório | 7 s | +5 | 35 |
| `maquina` | garagem | 10 s | +5 | **50** |
| | | **30 s** | | **146** |

Duas propriedades que essa tabela **precisa** ter:

1. **Nenhuma etapa sozinha mata** partindo de 0 — a pior é a máquina, com 50.
   (Numa versão anterior desses números a máquina dava exatamente 100 e o jogo era
   inganhável. Vale conferir isso sempre que mexer.)
2. **A soma passa de 100** — então é obrigatório baixar a suspeita ao menos duas vezes
   no meio do caminho. O loop não é opcional.

**Essa soma pressupõe fazer tudo escondido.** Executando as cinco etapas com o Alfredo olhando
o tempo inteiro, o custo seria 146 × 2,5 = 365 — inganhável de propósito. Não é armadilha: o
aviso na tela avisa antes, e soltar o `E` é barato (ver abaixo). É o que transforma "onde e
quando" na decisão central do jogo, em vez de só "corra até o objeto".

O progresso de um objetivo **decai devagar** ao soltar o `E` (25% da velocidade de subida),
então dá para fazer em pedaços: trabalha um pouco, vai comer, volta e termina. Essa é a
estratégia central e precisa continuar viável — e é também o que torna justo o multiplicador de
ser visto: ao ver o aviso, pausar custa pouco.

`F` (limpar-se) é **fraco de propósito**: 4/s com o gato imóvel. Limpar 100 de suspeita
custaria 25 s parado, 8% do cronômetro. É a válvula sempre disponível, não o botão de
resolver.

Diálogos, inventário e escolha final **pausam o jogo**: não custam cronômetro nem sobem
suspeita. Narrativa não deve ser penalizada.

## Ações de gato

O SGDD divide em dois efeitos: umas reduzem a suspeita, outras afastam o Alfredo. Uma mesma
ação pode fazer as duas — derrubar um copo é comportamento típico de gato (baixa suspeita)
**e** faz barulho (chama o Alfredo). Essa tensão é a decisão do jogador.

| id | rótulo | onde | reduz | atrai Alfredo | usos | recarga |
|---|---|---|---|---|---|---|
| `copo` | Derrubar o copo | mesa de jantar | −12 | **sim** | 2 | 15 s |
| `comer` | Comer na tigela | cozinha | −15 | não | ∞ | 12 s |
| `arranhar_sofa` | Arranhar o sofá | sofá | −18 | **sim** | 3 | 15 s |
| `dormir` | Dormir na cama | cama | −25 | não | ∞ | 20 s |
| `cavar_terra` | Cavar a terra do vaso | quintal | −10 | **sim** | 2 | 15 s |
| `brincar` | Brincar no tapete | tapete | −12 | não | ∞ | 10 s |

Mais duas sem objeto, no teclado: **`F` limpar-se** (gato imóvel, −4/s, andar cancela) e
**`Q` miar** (+3 e barulho na posição atual, recarga 8 s — serve para chamar o Alfredo para
um canto e trabalhar em outro).

As três de recarga infinita (`comer`, `dormir`, `brincar`) somam −52 por ciclo e são o
sustento do jogador. As três que atraem o Alfredo têm **usos contados**, para não virarem
botão de resolver tudo.

**Arte:** quatro delas ficam sobre móveis que já existem (sofá, cama, vaso, tapete), então
não precisam de imagem nenhuma. Só o copo e a tigela são objetos novos, e entram como
losango genérico (`Polygon2D`) desenhado nos eixos isométricos da cena. Trocar por sprite
depois é só preencher o export `textura`.

**Recarga e usos restantes** aparecem no próprio objeto, não num painel da HUD —
o `Label` alterna entre `Arranhar o sofá [E] · 3`, `recarregando 7s` e `sem usos`.
É onde o jogador está olhando.

## Estrutura do repositório

```
miaugerdon/
├── README.md
├── docs/
│   ├── PLANO.md        este arquivo
│   └── TUTORIAL.md     como o código funciona, passo a passo
└── miaugerdon/         projeto Godot (res://)
    ├── project.godot
    ├── cenas/
    │   ├── mapa2.tscn                     nível principal
    │   ├── personagens/  caju, alfredo
    │   ├── objetos/      objetivo, acao_gato
    │   └── ui/           menu, hud, balao
    ├── scripts/
    │   ├── jogo.gd       autoload: todo o estado da partida
    │   ├── mapa2.gd      gera a navegação, inicia a partida
    │   ├── personagens/  caju, alfredo
    │   ├── objetos/      interagivel (base), objetivo, acao_gato
    │   └── ui/           menu, hud, balao
    └── sprites/
        ├── personagens/  caju, alfredo, gato (Mr. T)
        └── objetos/      FINAL_*.png
```

`cenas/` e `scripts/` espelham a mesma divisão, então o script de uma cena está sempre no
caminho equivalente. `docs/` fica **fora** de `res://` para o Godot não tentar importar.

### O que foi apagado

Nada disso era referenciado por cena nenhuma (verificado por busca no projeto inteiro):

| Arquivo | Por que |
|---|---|
| `cenas/node_2d.tscn` | cena de rascunho |
| `sprites/4fa5e1bb...jpg`, `sprites/poltrona.png` | só a cena de rascunho usava |
| `sprites/poltrona2.png` | órfão |
| `sprites/objetos/FINAL_Alvenaria.png` | órfão, 2351x1385 sem uso |
| `sprites/objetos/FINAL_Total.png` | render composto de 2837x1928 com `visible = false` — carregado em memória para nada, já que o mapa é montado peça por peça |
| `cenas/mapa.tscn`, `sprites/tileset_interior.png` | mapa legado de tilemap |

Tudo continua no histórico do git (a partir do commit `485bff3`), então nada foi perdido
de verdade.

## Decisões técnicas e o porquê

Cada uma está explicada em detalhe no [TUTORIAL.md](TUTORIAL.md). Em resumo:

**Um autoload (`Jogo`) como barramento central.** Tempo, suspeita, objetivos, inventário e
narrativa vivem num só lugar, e todo mundo conversa por **sinal**. A HUD não tem nenhuma
referência ao Caju; o Alfredo não conhece a HUD. Reiniciar é `reload_current_scene()`, e o
`_ready()` do nível chama `Jogo.iniciar_partida()`, que zera tudo.

**A navegação é gerada por código, não desenhada.** Os 27 objetos já têm colisão; desenhar
um polígono de navegação à mão seria copiar essa informação, com risco de divergir. O
`NavigationRegion2D` recebe só o contorno externo do terreno (4 pontos) e o motor recorta os
obstáculos a partir dos colliders que já existem.

**Caju e Alfredo estão em camadas de física separadas** (`caju` e `alfredo`), ambos colidindo
só com o `mundo`. Eles atravessam um ao outro, e isso é de propósito: enquanto se empurravam,
o Alfredo era jogado para fora da área caminhável e **congelava de vez**, porque um agente de
navegação não sabe achar caminho a partir de um ponto que não é chão. Personagem de furtividade
que empurra o outro é fonte de bug sem trazer nada ao jogo.

**O Alfredo tem duas redes de segurança contra congelar:** se sair da malha, volta andando até
o chão mais próximo; e se não sair do lugar por 6 s (a espera legítima mais longa é 3 s), ele
encosta no chão e sorteia outro destino. Além disso, todo destino passa pelo chão mais próximo
antes de ser usado — assim um `Marker2D` posicionado a olho nunca se torna inalcançável.

**A profundidade exigiu mover a posição de cada móvel.** A posição real estava no `Sprite2D`
filho, com o corpo em (0,0) — nesse estado, ligar o Y-sort colocaria tudo atrás do chão. A
correção sobe a posição do filho para o corpo e compensa nos nós de colisão. Nada muda um
pixel; o corpo só passa a ter um Y para ordenar. Nesta arte isométrica o Y de tela **é** o
eixo de profundidade, então ordenar por Y é correto, não aproximação.

**Uma base compartilhada para os interagíveis.** `Interagivel` guarda o que é igual (chegar
perto, segurar `E`, barra de progresso, pensamento de descoberta); `objetivo` e `acao_gato`
só definem o que acontece no fim. Uma cópia da lógica, não duas.

## O que sabemos que está imperfeito

- **Sem áudio.** O SGDD lista 19 sons e o projeto não tem nenhum arquivo. A Parte 14 do
  tutorial ensina a adicionar.
- **Sem animações novas.** Ações de gato, disfarce e "Alfredo carregando Caju" reaproveitam
  as animações `parado_*` e `andando_*` que já existiam.
- **Mr. T e os finais são texto.** Sem arte dedicada.
- **A profundidade ordena pelo centro de cada móvel.** Para paredes compridas isso pode
  errar em casos limite; onde erra, é ajustado com `z_index` pontual em vez de uma solução
  geral.
- **O balanceamento é uma estimativa calculada, depois ajustada jogando.** Se o jogo estiver
  fácil ou impossível, a tabela deste documento é o lugar de mexer — e a Parte 12 do tutorial
  explica o que **não** mexer. O `FATOR_OBSERVADO` é o primeiro número a baixar se ser visto
  parecer punitivo demais.
- **O Alfredo não tem cone de visão.** Ele nota o gato em qualquer direção, dentro do alcance e
  com o caminho livre. Chegar por trás não ajuda — mas esconder-se atrás de um móvel, sim.
