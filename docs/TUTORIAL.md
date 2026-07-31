# Como o Miaugerdon foi construído

> **Para quem é este documento:** alguém que nunca abriu o Godot.
> Nenhum termo é usado antes de ser explicado.
>
> **Como usar:** dá para ler para entender o código que já está no repositório, ou seguir
> passo a passo e construir junto. Cada etapa termina com um **Teste agora** — uma prova
> visível de que funcionou. Se o teste não passar, não siga em frente: leia o
> **Se der errado** logo abaixo dele.
>
> As decisões de *jogo* (regras, números, história) estão no [PLANO.md](PLANO.md).
> Este documento é sobre o *código*.

## Formato

Cada etapa tem sempre as mesmas seis partes:

| | |
|---|---|
| **O que vamos fazer** | uma frase |
| **Por quê** | a escolha e a alternativa que foi rejeitada |
| **Como fazer** | clique a clique no editor do Godot |
| **O código** | completo e comentado, para copiar |
| **Teste agora** | o que apertar e o que deve acontecer |
| **Se der errado** | o erro provável e a causa |

O **Por quê** é o mais importante. Saber que escolhi `Area2D` *em vez de* medir distância a
cada quadro ensina mais do que só ver o `Area2D` pronto.

## Sumário

| Parte | Assunto |
|---|---|
| [0](#parte-0--antes-de-tocar-em-nada) | Antes de tocar em nada: nó, cena, árvore, a interface |
| [1](#parte-1--arrumar-a-casa) | Arrumar a casa: apagar o que não se usa, organizar pastas |
| [2](#parte-2--o-cérebro-do-jogo) | O cérebro do jogo: autoload e sinais |
| [3](#parte-3--teclas-novas) | Teclas novas: o Input Map |
| [4](#parte-4--a-hud) | A HUD: `CanvasLayer` e por que ela não conhece o Caju |
| [5](#parte-5--o-caju-ganha-habilidades) | O Caju ganha habilidades |
| [6](#parte-6--objetos-com-que-se-interage) | Objetos com que se interage: `Area2D` e herança |
| [7](#parte-7--fazer-o-alfredo-andar) | Fazer o Alfredo andar: diagnóstico e navegação |
| [8](#parte-8--a-ia-do-alfredo) | A IA do Alfredo: máquina de estados, visão, e não congelar |
| [9](#parte-9--narrativa) | Narrativa: diálogo, pensamentos, inventário, pausa |
| [10](#parte-10--menu-finais-e-reinício) | Menu, finais e reinício |
| [11](#parte-11--profundidade-y-sort) | Profundidade: Y-sort e `z_index` |
| [12](#parte-12--deixar-o-jogo-justo) | Deixar o jogo justo: balanceamento |
| [13](#parte-13--armadilhas-deste-projeto) | Armadilhas deste projeto |
| [14](#parte-14--como-continuar-sozinha) | Como continuar sozinha |

---

# Parte 0 — Antes de tocar em nada

## 0.1 Que programa é esse

**Godot** é uma *engine* de jogos: um programa que junta desenho na tela, física, som e
código num só lugar, para você não precisar escrever isso do zero.

A versão usada aqui é a **4.7.1**. O número importa: código de Godot 3 não funciona no
Godot 4. Se você achar um tutorial na internet que usa `KinematicBody2D`, é Godot 3 — no
Godot 4 esse nó se chama `CharacterBody2D`.

## 0.2 As três palavras que você precisa: nó, cena, árvore

Essa é a ideia central do Godot. Se você entender isso, o resto é detalhe.

**Nó** (*node*) é uma peça com uma função só. Um nó desenha uma imagem. Outro toca um som.
Outro detecta colisão. Um nó sozinho não faz muita coisa.

**Árvore** é como os nós se organizam: um nó pode ter nós **filhos** dentro dele. O filho
acompanha o pai — se o pai anda, o filho anda junto. O gato do jogo é assim:

```
Caju                    <- o corpo, que se move e colide
├── AnimatedSprite2D    <- o desenho animado do gato
├── CollisionShape2D    <- o formato invisível que bate nas paredes
└── Camera2D            <- a câmera, que segue o gato porque é filha dele
```

A câmera segue o gato **sem uma linha de código**: ela é filha, então vai onde o pai vai.
Isso é o que a árvore de nós faz por você.

**Cena** (*scene*) é uma árvore de nós salva num arquivo. E aqui está a parte que confunde
no começo: **uma cena não é uma "tela do jogo"**. Uma cena é qualquer pedaço reutilizável.

A analogia que funciona: uma cena é uma **caixa**, e caixas podem ser guardadas dentro de
outras caixas. `caju.tscn` é uma caixa com o gato inteiro dentro. `mapa2.tscn` é uma caixa
com a casa, e dentro dela tem a caixa do gato. Quando você coloca uma cena dentro de outra,
isso se chama **instanciar** — e você pode instanciar a mesma cena várias vezes. Neste jogo,
`acao_gato.tscn` é instanciada **seis vezes**, cada uma com valores diferentes. Um arquivo,
seis objetos no jogo.

É por isso que consertar a cena `acao_gato.tscn` conserta as seis de uma vez.

## 0.3 A interface

Abra o projeto: `Godot_v4.7.1-stable_win64.exe` → *Importar* → escolha
`miaugerdon/miaugerdon/project.godot`.

O editor pode estar em português ou em inglês, dependendo do seu Windows. Vou dar os dois
nomes.

| Painel | Onde | Para que serve |
|---|---|---|
| **Cena** (*Scene*) | canto superior esquerdo | a árvore de nós da cena aberta. É aqui que você adiciona e remove nós |
| **Sistema de Arquivos** (*FileSystem*) | canto inferior esquerdo | os arquivos do projeto. **Mova e renomeie arquivos SEMPRE por aqui**, nunca pelo Explorer — a Parte 1 explica por quê |
| **Viewport** | centro | onde você vê e arrasta as coisas. As abas em cima alternam entre `2D`, `3D`, `Script` |
| **Inspetor** (*Inspector*) | direita | todas as propriedades do nó selecionado. Clique num nó na Cena e o Inspetor mostra o que dá para mexer |
| **Nó** (*Node*) | direita, aba ao lado do Inspetor | os **sinais** e os **grupos** do nó selecionado. Vamos usar muito na Parte 2 |
| **Saída** (*Output*) | rodapé | onde aparecem os `print()` e as mensagens de erro. **Deixe sempre aberto** |

Se você só olhar um painel enquanto aprende, olhe a **Saída**. Erro no Godot quase nunca
trava o jogo — ele aparece ali e o jogo continua rodando errado.

## 0.4 Rodar o jogo

| Tecla | O que faz |
|---|---|
| `F5` | roda o **jogo** a partir da cena principal (a definida em Projeto → Configurações → Aplicação → Cena Principal) |
| `F6` | roda **só a cena aberta** |
| `F8` | fecha o jogo rodando |

`F6` é o seu melhor amigo neste tutorial. Dá para testar a HUD sem carregar a casa inteira.

## 0.5 Os arquivos do projeto

| Extensão | O que é | Pode apagar? |
|---|---|---|
| `.tscn` | uma **cena** (árvore de nós). É arquivo de texto, dá para abrir no editor de texto | não |
| `.gd` | um **script** em GDScript, a linguagem do Godot | não |
| `.png`, `.jpg` | imagens | só se nenhuma cena usar |
| `.import` | receita de como o Godot converteu a imagem. **Fica ao lado de cada imagem** | **nunca** — leia abaixo |
| `.uid` | o "número de identidade" de um script | **nunca** |
| `.godot/` | pasta de cache que o Godot gera sozinho. Está no `.gitignore` | pode, ele refaz |

**Por que nunca apagar o `.import` e o `.uid`.** Toda imagem e todo script têm um número de
identidade — um **uid**, que se parece com `uid://ck7avcfa5srao`. As cenas referenciam os
arquivos por esse número, **não pelo caminho da pasta**. Olhe uma linha de verdade do
`mapa2.tscn`:

```
[ext_resource type="Texture2D" uid="uid://srqhdpxgjg88" path="res://sprites/objetos/FINAL_cama.png" id="8_vl1wa"]
```

Tem os dois: o `uid` e o `path`. Quem manda é o `uid`. É por isso que **mover um arquivo não
quebra nada** — o número não mudou. E é por isso que apagar o `.import` **quebra tudo**: o
número morava lá dentro, o Godot gera um novo, e todas as cenas passam a apontar para um
número que não existe mais.

**`res://`** é a raiz do projeto. `res://cenas/mapa2.tscn` significa "a partir da pasta que
tem o `project.godot`". Sempre use `res://` no código, nunca `C:\Users\...`.

## 0.6 O que é um script

Um script é um arquivo de código **grudado num nó**, que dá comportamento a ele. Todo script
começa dizendo de que tipo de nó ele é:

```gdscript
extends CharacterBody2D
```

Isso diz: "eu sou o código de um nó do tipo `CharacterBody2D`". Se você grudar esse script
num nó de outro tipo, dá erro.

### As três funções que aparecem em todo script

Este é o conceito que mais confunde no começo. As três são chamadas **pelo Godot**, sozinhas
— você nunca chama elas.

```gdscript
func _ready() -> void:
	# Roda UMA vez, quando o nó nasce (entra na cena).
	# Use para: preparar coisas, conectar sinais, ler configuração.

func _process(delta: float) -> void:
	# Roda UMA VEZ POR QUADRO DESENHADO. Umas 60 vezes por segundo,
	# mas pode variar se o computador engasgar.
	# Use para: interface, contar tempo, animar coisa que não é física.

func _physics_process(delta: float) -> void:
	# Roda num ritmo FIXO, 60 vezes por segundo, sempre.
	# Use para: mover corpos, colisão, qualquer coisa de física.
```

**Como escolher entre as duas últimas:** se envolve mover algo que colide, é
`_physics_process`. Se é texto na tela ou cronômetro, é `_process`. Movimento em `_process`
fica trêmulo quando o jogo varia de velocidade.

**O que é `delta`.** É quantos segundos passaram desde a chamada anterior — algo como
`0.0166`. Serve para o jogo se comportar igual em computador rápido e lento. A regra:
**se você soma ou subtrai algo "por segundo", multiplique por `delta`**.

```gdscript
suspeita += 5.0            # ERRADO: 5 por QUADRO. Em PC rápido sobe o dobro.
suspeita += 5.0 * delta    # certo: 5 por SEGUNDO, em qualquer PC.
```

Esse erro aparece muito e é difícil de perceber, porque na sua máquina "parece funcionar".

### `@onready` e `@export`

Duas anotações que aparecem em quase todo script deste projeto.

```gdscript
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
```

`$AnimatedSprite2D` significa "meu nó filho chamado AnimatedSprite2D". O `@onready` diz
"pegue esse filho no momento em que eu nascer" — sem ele, o código tentaria pegar o filho
antes de ele existir e daria erro.

```gdscript
@export var duracao := 4.0
```

`@export` faz a variável **aparecer no Inspetor**. É assim que uma mesma cena pode ser
usada várias vezes com valores diferentes: `acao_gato.tscn` tem `@export var reduz_suspeita`,
e cada uma das seis instâncias no mapa põe um número diferente ali — sem duplicar código.

Regra prática: **se é um número que você vai querer ajustar sem abrir o código, use
`@export`.**

## 0.7 Duas palavras que vão voltar

Só para você reconhecer quando aparecerem. As duas têm capítulo próprio.

**Sinal** (*signal*) é um aviso que um nó solta quando algo acontece, sem saber quem está
ouvindo. Parte 2.

**Autoload** é um nó que existe em **todas** as cenas e não morre quando a cena troca.
Parte 2.

## Teste agora

Abra o projeto, abra `cenas/mapa2.tscn` e aperte `F6`. O gato deve aparecer e andar com
`W`, `A`, `S`, `D`. O homem (Alfredo) fica parado — isso é o bug que a Parte 7 conserta.

## Se der errado

| Sintoma | Causa |
|---|---|
| "Projeto criado com versão mais nova" | você abriu com Godot 3 ou 4.6. Precisa da 4.7 |
| A tela abre cinza e vazia | você apertou `F5` sem cena principal configurada. Aperte `F6` com o `mapa2.tscn` aberto |
| Imagens aparecem como quadrado branco | os `.import` foram apagados ou o cache `.godot/` corrompeu. Feche, apague a pasta `.godot/` e reabra — o Godot reimporta |

---

# Parte 1 — Arrumar a casa

Antes de escrever qualquer coisa nova, tirar o que está sobrando. Não é frescura: cada
arquivo órfão é um lugar onde você pode se perder procurando, e cada imagem no projeto é
memória gasta mesmo que ninguém a use.

## 1.1 Primeiro: uma rede de proteção

**O que vamos fazer:** um ramo (*branch*) separado no git, para poder desfazer tudo.

**Por quê:** vamos apagar arquivos e mover pastas. Com um branch, voltar atrás é um comando.
Sem ele, é reescrever à mão.

**Como fazer** — no terminal, na pasta do repositório:

```bash
git status                       # confira que não tem mudança pendente
git checkout -b versao-jogavel   # cria e entra no ramo novo
```

**Teste agora:** `git branch` deve mostrar `* versao-jogavel`.

**Se der errado:** se o `git status` mostrar arquivos modificados que você não reconhece,
provavelmente é só o Godot reescrevendo `.import` ao abrir o projeto. `git diff` mostrando
nada além de fim de linha é inofensivo.

## 1.2 Apagar o que ninguém usa

**O que vamos fazer:** remover 6 arquivos (mais os `.import` deles).

**Por quê:** o `FINAL_Total.png` é o caso que vale entender. Ele é um render da casa inteira,
2837x1928 pixels, e está no `mapa2.tscn` como um `Sprite2D` com `visible = false`. Invisível
— mas **o Godot carrega a imagem na memória de qualquer jeito**, porque a cena referencia o
arquivo. Ficar invisível economiza o desenho na tela, não a memória. E ele é redundante: a
casa é montada peça por peça pelos outros sprites.

**Antes de apagar qualquer coisa, confira que ninguém usa.** Este é o hábito que importa,
mais que a lista:

```bash
# procura o nome do arquivo em todas as cenas e scripts do projeto
grep -r "poltrona2" --include=*.tscn --include=*.gd miaugerdon/
```

Se não aparecer nada, nenhuma cena usa. Se aparecer, **não apague** — descubra quem usa
primeiro. (No Windows sem `grep`, use a busca do próprio Godot: `Ctrl+Shift+F` procura em
todos os arquivos do projeto.)

**Como fazer:**

```bash
cd miaugerdon
git rm cenas/node_2d.tscn
git rm "sprites/4fa5e1bb919c53b862f0115a5853ad6a.jpg" "sprites/4fa5e1bb919c53b862f0115a5853ad6a.jpg.import"
git rm sprites/poltrona.png sprites/poltrona.png.import
git rm sprites/poltrona2.png sprites/poltrona2.png.import
git rm "sprites/objetos/FINAL_Alvenaria.png" "sprites/objetos/FINAL_Alvenaria.png.import"
git rm "sprites/objetos/FINAL_Total.png" "sprites/objetos/FINAL_Total.png.import"
```

Repare que **cada imagem sai junto com o `.import` dela**. Deixar um `.import` órfão faz o
Godot reclamar de arquivo que não existe.

O `FINAL_Total.png` estava sendo usado pelo `mapa2.tscn`, então a cena também precisa perder
a referência: no editor, abra `cenas/mapa2.tscn`, selecione o nó `FinalTotal` na árvore e
aperte `Delete`.

**O que NÃO apagamos ainda:** `cenas/mapa.tscn` e `sprites/tileset_interior.png`. É o mapa
antigo, feito com tilemap, e é o único lugar do projeto onde a navegação do Alfredo
**funciona**. Vamos precisar dele como referência na Parte 7. Ele sai no fim.

**O que NÃO apagamos nunca:** `sprites/gato.png`. Parece órfão (só a cena de rascunho usava),
mas ele vai ser o Mr. T.

**Teste agora:** abra `cenas/mapa2.tscn` e aperte `F6`. A casa tem que aparecer exatamente
igual a antes — o `FinalTotal` era invisível, então não havia nada para desaparecer.

**Se der errado:**

| Sintoma | Causa |
|---|---|
| `Failed loading resource ...FINAL_Total.png` | você apagou o arquivo mas não o nó `FinalTotal` da cena |
| Um móvel virou quadrado branco | você apagou uma imagem que **estava** em uso. `git checkout -- <arquivo>` traz de volta |

## 1.3 Organizar em pastas

**O que vamos fazer:** criar subpastas em `cenas/` e `scripts/` e mover os arquivos.

**Por quê:** hoje `cenas/` tem 4 arquivos e dá para achar tudo. Quando o projeto terminar
vai ter 7 cenas e 9 scripts, misturando personagem, objeto e interface. A divisão escolhida
é a mesma nos dois lugares:

```
cenas/personagens/  ↔  scripts/personagens/
cenas/objetos/      ↔  scripts/objetos/
cenas/ui/           ↔  scripts/ui/
```

Espelhar é o ponto: sabendo onde está a cena, você sabe onde está o script, sem procurar.

**Como fazer — e aqui tem uma regra que evita muita dor:**

> **Mova arquivos pelo painel Sistema de Arquivos do Godot, arrastando. Nunca pelo
> Explorer do Windows.**

O Godot, ao mover, **reescreve as referências em todas as cenas** que usavam aquele arquivo.
O Explorer só move o arquivo e deixa as cenas apontando para o lugar errado.

No painel *Sistema de Arquivos*:

1. Clique com o botão direito na pasta `cenas/` → *Nova Pasta* → `personagens`. Repita para
   `objetos` e `ui`.
2. Faça o mesmo em `scripts/`.
3. Arraste `caju.tscn` e `alfredo.tscn` para `cenas/personagens/`.
4. Arraste `caju.gd` e `alfredo.gd` para `scripts/personagens/`.

Os arquivos `caju.gd.uid` e `alfredo.gd.uid` vão junto sozinhos — o Godot cuida deles.

**Se você preferir fazer pelo git** (foi o que eu fiz, porque é mais rápido em lote), aí
**você** precisa arrumar os caminhos:

```bash
cd miaugerdon
git mv cenas/caju.tscn cenas/alfredo.tscn cenas/personagens/
git mv scripts/caju.gd scripts/caju.gd.uid scripts/personagens/
git mv scripts/alfredo.gd scripts/alfredo.gd.uid scripts/personagens/
```

E depois corrigir as linhas `path="res://..."` nas cenas que referenciam esses arquivos
(`mapa2.tscn`, `mapa.tscn`, e as próprias cenas de personagem apontando para os scripts).

**E aqui tem uma pegadinha que eu levei na cara ao fazer isso.** Eu movi pelo git, corrigi
todos os `path=` nas cenas, rodei o projeto — e tomei isto:

```
ERROR: Cannot open file 'res://cenas/caju.tscn'.
ERROR: res://cenas/mapa2.tscn:433 - Parse Error: [ext_resource] referenced non-existent
       resource at: res://cenas/caju.tscn.
```

Estranho: `res://cenas/caju.tscn` não estava mais escrito em lugar nenhum. Eu tinha corrigido.

**O que estava acontecendo:** o Godot guarda a tabela de "qual `uid` mora em qual caminho"
num arquivo de cache, `.godot/uid_cache.bin`. Como quem resolve a referência é o `uid`, ele
consultou o cache, o cache respondeu com o caminho **antigo**, e o arquivo não estava lá.
O `path=` que eu tinha corrigido nem foi consultado — o `uid` resolveu primeiro, resolveu
errado, e a busca parou ali.

**O conserto** é apagar o cache e deixar o Godot reconstruir varrendo as pastas:

```bash
rm miaugerdon/.godot/uid_cache.bin
```

E então reimportar, o que reconstrói o cache:

```powershell
& $godot --path $proj --headless --import
```

Se você fizer isso na ordem inversa (apagar o cache e tentar rodar o jogo antes de
reimportar), aparece `Main scene's path could not be resolved from UID` — é o mesmo problema,
agora com a cena principal. Reimporte e passa.

**A lição:** o `uid` é o que faz mover arquivo ser seguro, mas ele depende de um cache que
o Godot só atualiza sozinho quando **ele** move o arquivo. Movendo por fora, o cache fica
mentindo. É exatamente por isso que a recomendação é mover pelo painel do Godot — lá isso
não acontece.

**Teste agora:**

```bash
& "C:\Users\isado\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe" --path "<caminho>\miaugerdon\miaugerdon" --headless --quit
```

Esse comando abre o projeto **sem janela** e fecha. Serve como conferência rápida: se algum
arquivo ficou perdido, o erro aparece no terminal. Nenhuma linha com `ERROR` significa que
todas as cenas carregaram.

E abra `cenas/mapa2.tscn`, aperte `F6`: o gato ainda tem que andar.

**Se der errado:**

| Sintoma | Causa |
|---|---|
| `Failed loading resource: res://cenas/caju.tscn` | você moveu pelo Explorer. Desfaça (`git checkout .`) e mova pelo Godot |
| O gato aparece mas não anda | o script se desgrudou da cena. Selecione o nó `Caju`, e no Inspetor, na propriedade *Script*, aponte para o novo caminho |

## 1.4 Fechar a etapa

```bash
git add -A
git commit -m "limpeza: remove arquivos sem uso e organiza cenas/scripts em subpastas"
```

Commit no fim de cada Parte. Se a Parte seguinte der errado, você volta para um ponto que
funcionava.

---

# Parte 2 — O cérebro do jogo

## 2.1 O problema: onde mora o cronômetro?

O jogo precisa guardar tempo restante, suspeita, qual etapa está em curso, o que já está no
inventário. Onde isso vive?

**Tentativa 1: dentro do Caju.** Parece natural — é o personagem principal. Mas então a HUD
precisa achar o Caju para desenhar a barra, o Alfredo precisa achar o Caju para saber a
suspeita, e o menu não tem Caju nenhum. Todo mundo passa a depender de um nó específico com
um nome específico.

**Tentativa 2: dentro do nível.** Melhor, mas o nível **morre** quando você troca de cena.
E ao apertar "Tentar novamente" o nível é recriado do zero.

**O que usamos: um autoload.** Um autoload é um nó que o Godot cria sozinho ao abrir o jogo e
que **existe em todas as cenas e não morre nas trocas**. É o lugar certo para o estado da
partida.

> **Não é bala de prata.** Autoload é estado global, e estado global é fácil de virar
> bagunça. A regra que eu segui: **um só**, e ele não conhece ninguém — só guarda números e
> avisa quem se interessar. Se você se pegar criando o terceiro autoload, provavelmente o
> problema é outro.

## 2.2 O que é um sinal

Este é o conceito que mais muda a qualidade do código, então vale a analogia certa.

**Chamada de função é telefone.** Você precisa saber para quem está ligando. Se a pessoa
mudar de número, sua ligação quebra.

**Sinal é rádio.** Quem emite não sabe quem está ouvindo. Pode não ter ninguém, pode ter
cinco. Quem quiser ouvir se sintoniza.

Concretamente, o `jogo.gd` declara:

```gdscript
signal suspeita_alterada(valor: float)
```

e quando a suspeita muda, faz:

```gdscript
suspeita_alterada.emit(suspeita)
```

O `jogo.gd` **não tem ideia** de que existe uma barra na tela. A HUD, do outro lado, se
sintoniza:

```gdscript
Jogo.suspeita_alterada.connect(_ao_mudar_suspeita)
```

O resultado prático: abra o [scripts/ui/hud.gd](../miaugerdon/scripts/ui/hud.gd) e procure
por "Caju" ou "Alfredo". **Não tem.** Por isso a HUD funciona sem o mapa carregado, e por
isso renomear um nó do jogo não a quebra.

## 2.3 Todos os sinais do jogo, e por que cada um existe

| Sinal | Quem emite | Quem escuta | Por que existe |
|---|---|---|---|
| `suspeita_alterada(valor)` | Jogo | HUD | desenhar a barra |
| `faixa_alterada(faixa)` | Jogo | HUD | mudar a cor e avisar na tela |
| `tempo_alterado(seg)` | Jogo | HUD | o cronômetro |
| `objetivo_alterado(i, titulo)` | Jogo | HUD | o texto do objetivo atual |
| `progresso_alterado(fracao)` | interagíveis (via `Jogo.definir_progresso`) | HUD | a barrinha de "segurando E" |
| `inventario_alterado()` | Jogo | HUD | redesenhar a lista do `Tab` |
| `ruido(posicao)` | Caju (miado) e ações de gato | Alfredo | fazer ele ir investigar |
| `pensamento(texto)` | Jogo | balão dentro do Caju | os pensamentos |
| `dialogo(nome, falas)` | Jogo | HUD | abrir a caixa de fala |
| `dialogo_terminado()` | HUD | o objetivo que abriu o diálogo | só concluir a etapa quando a conversa acabar |
| `escolha_final()` | Jogo | HUD | abrir o painel de decidir |
| `aviso(texto)` | vários | HUD | texto temporário |
| `partida_terminada(motivo)` | Jogo | HUD | mostrar o final certo |

### Por que `faixa_alterada` é separado de `suspeita_alterada`

Parece redundante: a faixa dá para calcular do valor. Mas são **coisas diferentes**:

- `suspeita_alterada` é um **valor contínuo**, emitido muitas vezes por segundo. É o que a
  barra desenha.
- `faixa_alterada` é um **evento raro**: "o Alfredo mudou de comportamento". É o que merece
  um aviso na tela e uma troca de cor.

Se fosse um sinal só, a HUD teria que ficar comparando "a faixa é diferente da de antes?" a
cada quadro. Colocar essa comparação no `jogo.gd`, onde o dado nasce, resolve uma vez:

```gdscript
func _definir_suspeita(valor: float) -> void:
	suspeita = clampf(valor, 0.0, SUSPEITA_MAX)
	suspeita_alterada.emit(suspeita)

	var nova := faixa()
	if nova != _faixa:          # só avisa na TROCA
		_faixa = nova
		faixa_alterada.emit(nova)
```

**A regra geral:** valor contínuo e evento de mudança são sinais diferentes. Quem mistura os
dois acaba com lógica de comparação espalhada por quem escuta.

### Quando NÃO usar sinal

Sinal não é sempre a resposta. Neste projeto aparecem os três casos:

| Situação | O que usamos | Por quê |
|---|---|---|
| A HUD quer saber da suspeita | **sinal** | são muitos interessados, e nenhum precisa conhecer o outro |
| Um objetivo quer somar suspeita | **chamada direta** (`Jogo.aumentar_suspeita`) | tem um destinatário só e conhecido. Sinal aqui seria cerimônia sem ganho |
| O Alfredo quer zerar o progresso de qualquer etapa em curso | **grupo** (`get_tree().call_group("interagivel", "cancelar")`) | são vários destinatários que ele não conhece, e ele quer AGIR neles, não avisar |

Grupo é o meio-termo: "chame este método em todo mundo que tem esta etiqueta".

## 2.4 O código

O arquivo é [scripts/jogo.gd](../miaugerdon/scripts/jogo.gd). O coração dele:

```gdscript
extends Node

const TEMPO_TOTAL := 300.0        # segundos até o cachorro chegar
const SUSPEITA_MAX := 100.0       # chegar aqui é derrota
const DECAIMENTO_BAIXA := 1.0     # por segundo, SÓ na faixa BAIXA
const LIMPAR_SE := 4.0            # por segundo, tecla F, gato imóvel
const FLAGRANTE := 15.0           # punição por ser pego

const LIMITE_MEDIA := 35.0
const LIMITE_ALTA := 70.0

enum Faixa { BAIXA, MEDIA, ALTA }
enum Motivo { SUSPEITA, TEMPO, ATIVOU, DESISTIU }

var em_partida := false
var suspeita := 0.0
var tempo_restante := TEMPO_TOTAL


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
```

Três coisas para notar:

**`if not em_partida: return`.** O autoload existe desde o menu, onde não há partida
nenhuma. Sem essa linha, o cronômetro começaria a correr na tela inicial.

**`* delta` no decaimento.** Como na Parte 0: é "1 por segundo", não "1 por quadro".

**Este `_process` PARA quando o jogo pausa.** Isso não é acidente: é o que faz ler um
diálogo não custar cronômetro. O Godot para de chamar `_process` em nós comuns quando
`get_tree().paused` é `true` — e o autoload é um nó comum. A HUD é a exceção, e a Parte 9
explica como.

### A guarda que evita o fim duplo

```gdscript
func _terminar(motivo: Motivo) -> void:
	if not em_partida:
		return                    # nenhum fim dispara duas vezes
	em_partida = false
	partida_terminada.emit(motivo)
	get_tree().paused = true
```

Por que isso importa: imagine que o cronômetro zera **no mesmo quadro** em que o Alfredo te
pega e a suspeita estoura 100. Sem a guarda, `partida_terminada` sairia duas vezes e a HUD
tentaria mostrar dois finais. Uma linha resolve.

**Isto é o tipo de bug que só aparece na demonstração.** Vale desconfiar de qualquer coisa
que só deveria acontecer uma vez.

## Teste agora

Ainda não há HUD, então o teste é pelo console. Adicione temporariamente no fim do
`_process` do `jogo.gd`:

```gdscript
	print("tempo: ", int(tempo_restante), "  suspeita: ", int(suspeita))
```

Registre o autoload (Parte 3 mostra onde) e rode. O console tem que mostrar o tempo caindo.
Depois apague o `print`.

## Se der errado

| Sintoma | Causa |
|---|---|
| `Identifier not found: Jogo` | o autoload não está registrado em Projeto → Configurações → Globais, ou o nome ali não é exatamente `Jogo` |
| O tempo não cai | `em_partida` continua `false` — quem chama `iniciar_partida()` é o `_ready()` do nível (Parte 10) |
| O tempo cai rápido demais | faltou `* delta` em algum lugar |

```bash
git commit -am "estado da partida no autoload Jogo"
```

---

# Parte 3 — Teclas novas

**O que vamos fazer:** ensinar ao jogo quatro teclas — `E`, `F`, `Q` e `Tab`.

**Por quê:** dá para ler a tecla direto no código (`Input.is_key_pressed(KEY_E)`), mas aí a
tecla fica escrita em vários arquivos. Trocar depois significa procurar todas. O **Input
Map** dá um nome à intenção: o código pergunta por `"interagir"`, e qual tecla é isso fica
num lugar só. É também o que permitiria oferecer troca de controles depois.

**Como fazer** — Projeto → Configurações do Projeto → aba *Mapa de Entrada*:

1. Em *Adicionar Nova Ação*, digite `interagir` e clique em *Adicionar*.
2. No `+` da linha nova, aperte a tecla `E`, confirme.
3. Repita: `disfarce` = `F`, `miar` = `Q`, `inventario` = `Tab`.

**O código** — o resultado aparece no `project.godot`. Assim:

```ini
interagir={
"deadzone": 0.2,
"events": [Object(InputEventKey, ... "physical_keycode":69, ... "unicode":101 ...)]
}
```

`physical_keycode` é o número da tecla **pela posição no teclado**, e não pela letra
impressa. É o certo para controle de jogo: em teclado AZERTY, o `physical_keycode` de `W`
continua sendo a tecla acima do `S`, que é onde o dedo espera estar.

Enquanto está aqui, aproveite: em *Aplicação → Executar → Cena Principal*, aponte para
`res://cenas/ui/menu.tscn` (a Parte 10 cria essa cena), e em *Exibição → Janela*, ponha
1152 x 648. E em *Globais*, adicione `res://scripts/jogo.gd` com o nome `Jogo` — é o autoload
da Parte 2.

## Teste agora

Num script qualquer que esteja na cena:

```gdscript
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interagir"):
		print("apertei E")
```

Rode e aperte `E`. Se aparecer no console, o Input Map está certo.

## Se der errado

| Sintoma | Causa |
|---|---|
| Nada acontece | o nome da ação tem que ser **idêntico** — `interagir` não é `Interagir` |
| `The InputMap action "interagir" doesn't exist` | a ação não foi salva; volte às Configurações |

---

# Parte 4 — A HUD

## 4.1 Por que `CanvasLayer`

**O que vamos fazer:** a barra de suspeita, o cronômetro, o objetivo e a barra de progresso.

**Por quê `CanvasLayer`:** a câmera do jogo segue o gato. Se a barra de suspeita fosse um nó
comum dentro do mundo, ela seria arrastada junto e sairia da tela em dois segundos. Um
`CanvasLayer` **não é afetado pela câmera** — ele desenha por cima, em coordenadas de tela.

Regra prática que vale para sempre:

> Se é **do mundo** (personagem, móvel, chão), é `Node2D`.
> Se é **da tela** (barra, botão, texto de interface), é `Control` dentro de um `CanvasLayer`.

O balão de pensamento do Caju é a exceção interessante, e a Parte 9 explica por quê.

## 4.2 A árvore de nós

**Como fazer:** Cena → *Nova Cena* → nó raiz `CanvasLayer`, salve como
`cenas/ui/hud.tscn`. Depois monte:

```
HUD                     CanvasLayer      process_mode = Sempre  (ver Parte 9)
└── Raiz                Control          âncoras = tela inteira, mouse_filter = Ignorar
    ├── CaixaSuspeita   VBoxContainer    canto superior esquerdo
    │   ├── RotuloSuspeita  Label        "SUSPEITA DO ALFREDO"
    │   └── BarraSuspeita   ProgressBar
    ├── Cronometro      Label            canto superior direito
    ├── Objetivo        Label
    ├── Dicas           Label            as teclas, em cinza
    ├── Aviso           Label            centro, some sozinho
    ├── CaixaProgresso  VBoxContainer    base da tela, só aparece durante a ação
    │   └── BarraProgresso  ProgressBar
    ├── PainelTutorial      PanelContainer   (Parte 9)
    ├── PainelInventario    PanelContainer   (Parte 9)
    ├── CaixaDialogo        PanelContainer   (Parte 9)
    ├── PainelEscolha       PanelContainer   (Parte 10)
    └── PainelFim           PanelContainer   (Parte 10)
```

Dois detalhes que economizam dor:

**`mouse_filter = Ignorar` no `Raiz`.** Um `Control` que ocupa a tela inteira intercepta
cliques por padrão — e aí os botões da tela de derrota, que estão *dentro* dele, nunca
recebem o clique. "Ignorar" faz ele deixar passar.

**Nome único.** Clique com o botão direito no `BarraSuspeita` → *Acessar como Nome Único*.
Aparece um `%` ao lado. Daí o script pega o nó com `%BarraSuspeita` em vez de escrever
`$Raiz/CaixaSuspeita/BarraSuspeita` — e não quebra se você mover o nó de lugar.

> **Cuidado:** nome único tem que ser único **na cena**. Eu tinha quatro nós chamados
> `Titulo` (um por painel); marquei o do painel de fim como único e renomeei para
> `FimTitulo`. Sem renomear, `%Titulo` seria ambíguo.

## 4.3 O código

[scripts/ui/hud.gd](../miaugerdon/scripts/ui/hud.gd). O `_ready()` é só sintonia:

```gdscript
func _ready() -> void:
	Jogo.suspeita_alterada.connect(_ao_mudar_suspeita)
	Jogo.faixa_alterada.connect(_ao_mudar_faixa)
	Jogo.tempo_alterado.connect(_ao_mudar_tempo)
	Jogo.objetivo_alterado.connect(_ao_mudar_objetivo)
	Jogo.progresso_alterado.connect(_ao_mudar_progresso)
	# ... e assim para os outros
```

E cada resposta é curta, porque a HUD **só desenha** — ela não decide nada:

```gdscript
func _ao_mudar_suspeita(valor: float) -> void:
	_barra_suspeita.value = valor


func _ao_mudar_tempo(segundos: float) -> void:
	var total := int(ceilf(maxf(segundos, 0.0)))
	_cronometro.text = "%02d:%02d" % [total / 60, total % 60]
	_cronometro.modulate = Color(1, 0.45, 0.4) if segundos <= 30.0 else Color.WHITE
```

### A cor da barra por faixa

A cor de preenchimento de uma `ProgressBar` mora num *StyleBox*. Para mudar em tempo de
execução, pegamos o estilo uma vez e mexemos nele:

```gdscript
@onready var _estilo_suspeita: StyleBoxFlat = _barra_suspeita.get_theme_stylebox("fill")

func _ao_mudar_faixa(nova: Jogo.Faixa) -> void:
	match nova:
		Jogo.Faixa.BAIXA:
			_estilo_suspeita.bg_color = COR_BAIXA
		Jogo.Faixa.MEDIA:
			_estilo_suspeita.bg_color = COR_MEDIA
			_ao_avisar("O Alfredo começou a estranhar os barulhos.")
		Jogo.Faixa.ALTA:
			_estilo_suspeita.bg_color = COR_ALTA
			_ao_avisar("Alfredo está te procurando!")
```

Repare que a HUD aproveita o mesmo sinal para **avisar por escrito**. Isso é design de jogo,
não enfeite: a suspeita é uma condição de derrota, e o jogador precisa sentir o perigo antes
de morrer. Por isso também a barra pulsa acima de 85:

```gdscript
	if Jogo.em_partida and Jogo.suspeita >= PULSO_ACIMA_DE:
		var t := sin(Time.get_ticks_msec() / 90.0) * 0.5 + 0.5
		_barra_suspeita.modulate = Color.WHITE.lerp(Color(1.7, 0.7, 0.7), t)
```

## Teste agora

Abra `hud.tscn` e aperte `F6`. A HUD aparece sozinha, sem o mapa, com o cronômetro parado em
`05:00`. **Isso é a prova de que ela não depende de nada do jogo** — é o ponto todo da
Parte 2.

## Se der errado

| Sintoma | Causa |
|---|---|
| `Node not found: %BarraSuspeita` | o nó não está marcado como *Acessar como Nome Único* |
| A barra não mexe | o `connect` não foi feito, ou o `Jogo` não está emitindo (`em_partida` falso) |
| Não dá para clicar nos botões | falta `mouse_filter = Ignorar` no `Control` raiz |

```bash
git commit -am "HUD ligada apenas nos sinais do Jogo"
```

---

# Parte 5 — O Caju ganha habilidades

## 5.1 Entendendo o movimento que já existia

O `caju.gd` original tinha uma linha que merece explicação, porque é a coisa menos óbvia do
projeto:

```gdscript
const TANGENTE_CAMERA := 0.57735026919   # tangente de 30°

var direcao := Input.get_vector("esquerda", "direita", "cima", "baixo")
var direcao_iso := Vector2(direcao.x - direcao.y, (direcao.x + direcao.y) * TANGENTE_CAMERA)
velocity = direcao_iso.normalized() * SPEED
```

**O problema que isso resolve.** A casa está desenhada em perspectiva isométrica: as paredes
não são horizontais nem verticais na tela, são diagonais. Se o `D` mandasse o gato para
`(+1, 0)`, ele andaria "para a direita na tela" — atravessando visualmente os cômodos na
diagonal, o que parece errado.

**Como a conta funciona.** Os dois eixos da casa, na tela, são
`(1, +tan30)` e `(1, -tan30)`. Então:

- `direcao.x` (o eixo `A`/`D`) empurra ao longo de `(1, +tan30)`
- `direcao.y` (o eixo `W`/`S`) empurra ao longo de `(-1, +tan30)`

Somando os dois: `x = dx - dy`, `y = (dx + dy) * tan30`. É exatamente a linha do código.
`tan30 ≈ 0.577` porque a arte foi desenhada com 30° de inclinação — se o desenho fosse a 45°,
esse número seria 1.

**Por que `.normalized()`:** sem ele, andar na diagonal seria mais rápido do que andar reto,
porque o vetor somado é mais comprido. `normalized()` deixa todo vetor com comprimento 1, e a
velocidade passa a ser sempre `SPEED`.

## 5.2 O `y_sort_enabled` no lugar errado

O código original tinha isto **dentro** do `_physics_process`:

```gdscript
	y_sort_enabled = true    # roda 60 vezes por segundo, sem efeito nenhum
```

Dois problemas:

1. **É desperdício.** Atribuir a mesma coisa 60 vezes por segundo não faz nada além de gastar
   tempo. Coisa que se configura uma vez vai no `_ready()`, ou melhor ainda, direto na cena
   pelo Inspetor.
2. **Não resolve o que parece resolver.** `y_sort_enabled` num nó ordena os **filhos dele**.
   Ligar no Caju ordena o sprite, a colisão e a câmera entre si — o que é irrelevante. Para o
   gato passar atrás do sofá, quem precisa do flag é o **pai** dos dois. É a Parte 11.

Removemos a linha. **A lição:** quando um código "não faz nada", vale entender por que ele
foi escrito antes de apagar — o autor estava tentando resolver um problema real (a
profundidade), só no nó errado.

## 5.3 As duas habilidades

**Limpar-se (`F`)** só funciona com o gato **imóvel**, e por isso mora dentro do `else` do
movimento:

```gdscript
	if direcao != Vector2.ZERO:
		# ... anda
	else:
		animated_sprite_2d.play("parado_" + ultima_direcao)
		if Input.is_action_pressed("disfarce"):
			Jogo.reduzir_suspeita(Jogo.LIMPAR_SE * delta)
```

Isso não é detalhe técnico, é a regra do jogo: limpar-se é a válvula sempre disponível, mas
**custa tempo parado** — e tempo é a outra forma de perder. Se funcionasse andando, seria de
graça.

**Miar (`Q`)** tem recarga, porque sem ela dava para chamar o Alfredo eternamente:

```gdscript
func _miar() -> void:
	_recarga_miado = RECARGA_MIADO           # 8 segundos
	Jogo.aumentar_suspeita(SUSPEITA_MIADO)   # 3
	Jogo.emitir_ruido(global_position)
	Jogo.pensar_uma_vez("miar", "Miau. Agora ele vem pra cá — e eu vou pra lá.")
```

`is_action_just_pressed` (e não `is_action_pressed`) porque miar é um toque, não algo que se
segura.

## 5.4 "Estou fazendo algo suspeito?" — o padrão do prazo

O Alfredo precisa saber se o Caju está no meio de uma etapa do plano. A solução óbvia é um
`bool`:

```gdscript
var interagindo := false     # quem liga precisa se lembrar de desligar
```

E aí vem o bug: o jogador sai andando no meio da ação, o objeto que ligou o `bool` não é mais
avisado, e o gato fica marcado como "suspeito" para sempre.

O que usamos é um **prazo que expira sozinho**:

```gdscript
var _acao_secreta_ate := 0

func marcar_acao_secreta() -> void:
	_acao_secreta_ate = Time.get_ticks_msec() + 200

func esta_em_acao_secreta() -> bool:
	return Time.get_ticks_msec() < _acao_secreta_ate
```

Quem está progredindo chama `marcar_acao_secreta()` a cada quadro. Se parar de chamar — por
qualquer motivo, inclusive um que eu não previ — a marca morre em 200 ms. **Ninguém precisa
se lembrar de desligar nada.**

Esse padrão vale para muita coisa: "está correndo?", "levou dano recentemente?", "está
invulnerável?". Sempre que você pensar "e se ninguém desligar isso?", pense em prazo.

## 5.5 Entrar no grupo `jogador`

```gdscript
func _ready() -> void:
	add_to_group("jogador")
```

Uma linha, e é ela que conserta metade do bug do Alfredo parado. O `alfredo.gd` sempre
procurou o Caju com `get_tree().get_first_node_in_group("jogador")` — mas **ninguém nunca
entrou nesse grupo**. Parte 7 conta a história inteira.

## Teste agora

Rode `mapa2.tscn` com `F6`, fique parado e segure `F`: a barra de suspeita tem que descer.
Comece a andar segurando `F`: tem que parar de descer. Aperte `Q`: a suspeita dá um pulinho.

## Se der errado

| Sintoma | Causa |
|---|---|
| A barra desce andando também | o `if Input.is_action_pressed("disfarce")` ficou fora do `else` |
| `Q` funciona repetidamente | está usando `is_action_pressed` em vez de `is_action_just_pressed`, ou a recarga não está sendo descontada |

```bash
git commit -am "Caju: limpar-se, miar e marca de acao secreta"
```

---

# Parte 6 — Objetos com que se interage

## 6.1 Por que `Area2D`

**O problema:** o jogo precisa saber quando o Caju está perto do sofá, da tigela, da estante.

**Tentativa 1: medir distância.** Cada objeto, a cada quadro, calcula
`global_position.distance_to(caju.global_position)`. Funciona, mas: cada objeto precisa achar
o Caju (acoplamento), e são 11 contas de raiz quadrada por quadro que o motor já sabe fazer
melhor. O motor de física mantém uma estrutura espacial para exatamente isso.

**Tentativa 2: `StaticBody2D`.** Detecta contato — e **bloqueia o gato**. Você não quer que o
gato bata numa parede invisível ao chegar perto da tigela.

**O que usamos: `Area2D`.** Detecta quem entra e sai, sem bloquear nada, e avisa por sinal
(`body_entered` / `body_exited`).

Duas configurações importantes na cena:

```
collision_layer = 0     # a área não precisa ser detectada por ninguém
collision_mask  = 1     # ela detecta o que está na camada 1 (os personagens)
```

E um filtro no código, porque o Alfredo **também** é um corpo na camada 1 e entraria no
`body_entered`:

```gdscript
func _ao_entrar(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_caju = corpo
```

## 6.2 Herança: uma lógica, dois comportamentos

Temos dois tipos de objeto interativo:

- **objetivo** — uma etapa do plano. Sobe suspeita, dá flagrante, só funciona na vez dela.
- **ação de gato** — comportamento normal. Desce suspeita, tem recarga e usos.

O que eles têm **em comum**: detectar o gato chegando, mostrar o prompt, encher a barra
enquanto o `E` está segurado, perder progresso ao soltar, disparar um pensamento na primeira
visita. Isso é a maior parte do código, e é idêntico.

O que é **diferente**: apenas o que acontece quando a barra enche.

Duas saídas possíveis:

| Abordagem | Como fica |
|---|---|
| Um script só, com `if tipo == OBJETIVO` espalhado | funciona, mas cada coisa nova exige mexer no meio do código dos dois, e um erro num afeta o outro |
| **Herança**: uma base com o comum, dois filhos com o diferente | escolhemos esta |

```gdscript
# scripts/objetos/interagivel.gd
class_name Interagivel
extends Area2D
```

`class_name` registra `Interagivel` como um tipo do projeto. Aí os filhos podem dizer:

```gdscript
# scripts/objetos/objetivo.gd
extends Interagivel
```

### Método virtual em GDScript

GDScript não tem `abstract` nem `virtual`. O padrão é: a base declara o método fazendo nada,
e o filho sobrescreve.

```gdscript
# na base
func _esta_ativo() -> bool:
	return true

func _concluir() -> void:
	pass
```

```gdscript
# em acao_gato.gd
func _esta_ativo() -> bool:
	return _recarga_restante <= 0.0 and _usos_restantes != 0

func _concluir() -> void:
	Jogo.reduzir_suspeita(reduz_suspeita)
	if atrai_alfredo:
		Jogo.emitir_ruido(global_position)
```

E quando o filho precisa **acrescentar** ao comportamento da base em vez de substituir, ele
chama `super()`:

```gdscript
# acao_gato.gd: descontar a recarga E depois fazer tudo o que a base faz
func _process(delta: float) -> void:
	if _recarga_restante > 0.0:
		_recarga_restante = maxf(0.0, _recarga_restante - delta)
	super(delta)
```

**Quando herança é a escolha certa:** quando as coisas são a mesma ideia com um final
diferente. Quando são ideias diferentes que só compartilham peças, o certo é composição
(guardar um nó auxiliar) — não herança.

## 6.3 A barra que decai devagar

```gdscript
const DECAIMENTO_PROGRESSO := 0.25    # 25% da velocidade com que sobe
```

Este número é regra de jogo disfarçada de constante. Ele existe para a estratégia central ser
possível: **fazer uma etapa longa em pedaços**. Trabalha 3 segundos, o Alfredo se aproxima,
você sai, vai comer, volta e termina. Se o progresso zerasse ao soltar o `E`, a etapa de 10
segundos exigiria 10 segundos ininterruptos com um Alfredo andando pela casa — provavelmente
impossível.

E há um detalhe fácil de errar. O progresso continua caindo mesmo depois do gato ir embora,
mas a **barra na tela** só é atualizada enquanto ele está perto:

```gdscript
	elif _progresso > 0.0:
		_progresso = maxf(0.0, _progresso - delta * DECAIMENTO_PROGRESSO / maxf(duracao, 0.01))
		if perto:
			Jogo.definir_progresso(_progresso)
```

Sem esse `if perto`, um objeto do outro lado da casa ficaria mexendo na barra do objeto onde o
jogador está.

## 6.4 Um número só num lugar

O `objetivo.gd` **não** guarda a própria duração. Ele copia do `jogo.gd` ao nascer:

```gdscript
func _ready() -> void:
	super()
	for etapa in Jogo.OBJETIVOS:
		if etapa["id"] == id:
			duracao = etapa["duracao"]
			break
```

Por quê: duração e custo em suspeita são **balanceamento**, e balanceamento vive todo junto
no `jogo.gd`. Se a duração estivesse também no Inspetor de cada instância, um dia os dois
valores divergiriam e ninguém saberia qual manda.

## Teste agora

Ande até a estante do escritório. O prompt tem que aparecer: `Pegar papel e caneta — ainda
não` (porque a primeira etapa é falar com o Mr. T). Vá até o sofá: aparece
`Arranhar o sofá [E] · 3`. Segure `E`: a barra na base da tela enche, a suspeita **não** sobe,
e ao completar ela desce 18. O prompt passa a `recarregando 15s`.

## Se der errado

| Sintoma | Causa |
|---|---|
| O prompt não aparece | o `CollisionShape2D` da área não tem forma, ou o Caju não está no grupo `jogador` |
| O prompt aparece quando o Alfredo passa | falta o filtro `is_in_group("jogador")` |
| O gato bate numa parede invisível | você usou `StaticBody2D` em vez de `Area2D` |
| A barra enche instantaneamente | `duracao` está 0; veja se o `id` bate com algum em `Jogo.OBJETIVOS` |

```bash
git commit -am "interagiveis: base comum, objetivos e acoes de gato"
```

---

# Parte 7 — Fazer o Alfredo andar

Esta Parte começa diferente das outras, porque o mais valioso aqui não é a solução — é o
**diagnóstico**. O Alfredo ficava parado no meio da casa e o console **não reclamava de
absolutamente nada**.

## 7.1 Investigando um bug silencioso

Erro que aparece no console é fácil: ele diz o arquivo e a linha. Bug silencioso é outra
coisa, e a técnica é sempre a mesma: **listar hipóteses e testar uma por uma, a mais barata
primeiro.**

O código dele era este:

```gdscript
func _ready() -> void:
	await get_tree().physics_frame

	if not alvo:
		alvo = get_tree().get_first_node_in_group("jogador")

	_atualizar_alvo()


func _atualizar_alvo() -> void:
	if not alvo:
		return              # <- sai de fininho, sem avisar nada
	nav_agent.target_position = alvo.global_position
```

**Hipótese 1: ele não sabe quem perseguir.** Teste barato: `print(alvo)` no `_ready`.
Resultado: `<null>`. Duas causas somadas —

- a instância do Alfredo no `mapa2.tscn` não tinha o `alvo` preenchido (no mapa antigo,
  `mapa.tscn`, tinha: `alvo = NodePath("../Caju")`);
- e o plano B, `get_first_node_in_group("jogador")`, também falhava, porque **nenhum nó do
  projeto entrava nesse grupo**. O grupo nunca existiu.

E o `if not alvo: return` engolia tudo em silêncio.

**Hipótese 2: ele sabe para onde ir, mas não tem por onde.** Teste: existe algum
`NavigationRegion2D` no `mapa2.tscn`? Não existe. O mapa antigo tinha navegação pintada nos
tiles; o mapa novo é feito de sprites e não tem nada.

**Hipótese 3: a velocidade está zerada.** Não: `SPEED = 120`.

Três hipóteses, e **as duas primeiras estavam certas ao mesmo tempo**. É comum: um bug que
"não faz sentido" é frequentemente dois bugs se sobrepondo.

**A lição que fica:** `if not x: return` é um jeito educado de esconder problema. Numa função
que não deveria ser chamada sem alvo, prefira reclamar:

```gdscript
	if not alvo:
		push_warning("[alfredo] sem alvo: a IA nao vai fazer nada")
		return
```

`push_warning` aparece no console e no depurador, e custa uma linha.

## 7.2 O que é navmesh e o que é agente

Duas coisas distintas, e confundir as duas trava muita gente:

**Navmesh** (malha de navegação) é o **mapa do que é chão**. É uma lista de polígonos que
dizem "aqui dá para andar". Não tem nada a ver com colisão: colisão impede atravessar,
navmesh serve para *planejar* um caminho antes de andar. Fica num `NavigationRegion2D`.

**Agente** é **quem usa o mapa**. O `NavigationAgent2D`, filho do Alfredo, recebe um destino
(`target_position`) e responde "para chegar lá, o próximo passo é ali"
(`get_next_path_position()`). Ele não move ninguém — quem move é o seu código.

## 7.3 Por que gerar o navmesh por código

O jeito normal é desenhar o polígono à mão no editor. Aqui não:

**A informação já existe.** Os 27 móveis já têm colisão desenhada — foi o trabalho feito
antes deste. Desenhar um polígono de navegação seria **copiar** essa informação à mão. E
cópia é o que diverge: no dia em que alguém arrastar o sofá 20 pixels, a colisão acompanha e
o navmesh não, e o Alfredo passa a andar através do sofá.

Então geramos: o motor recebe **um** contorno escrito à mão — os quatro cantos do terreno — e
recorta os obstáculos a partir dos colliders que já existem.

```gdscript
# ferramentas/gerar_navmesh.gd
const CONTORNO_TERRENO := [
	Vector2(14, 590),     # oeste  (entrada da garagem)
	Vector2(762, 158),    # norte  (fundo do quarto)
	Vector2(1416, 522),   # leste  (fundo do quintal)
	Vector2(658, 960),    # sul    (frente da casa)
]
const RAIO_AGENTE := 14.0

var poligono := NavigationPolygon.new()
poligono.agent_radius = RAIO_AGENTE
poligono.cell_size = 1.0
poligono.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
poligono.parsed_collision_mask = 1
poligono.add_outline(PackedVector2Array(CONTORNO_TERRENO))

var geometria := NavigationMeshSourceGeometryData2D.new()
NavigationServer2D.parse_source_geometry_data(poligono, geometria, cena)
NavigationServer2D.bake_from_source_geometry_data(poligono, geometria)
```

Linha por linha, o que cada coisa faz:

| Linha | O que faz |
|---|---|
| `add_outline(...)` | define a **área caminhável**. É a única geometria escrita à mão |
| `parsed_geometry_type = ..._STATIC_COLLIDERS` | só colisão de corpo **estático** conta como obstáculo. Assim o Caju e o Alfredo (`CharacterBody2D`) e os interagíveis (`Area2D`) ficam de fora — senão o Alfredo trataria a si mesmo como parede |
| `parsed_collision_mask = 1` | quais camadas de física considerar |
| `parse_source_geometry_data(..., cena)` | **varre a árvore** a partir de `cena` e junta os contornos dos obstáculos |
| `bake_from_source_geometry_data(...)` | recorta os obstáculos da área caminhável e produz os polígonos finais |
| `agent_radius = 14` | "engorda" cada obstáculo em 14 px, para o agente não raspar na parede |

O resultado é salvo como recurso, `cenas/navmesh_casa.tres`, e a `NavigationRegion2D` do
mapa aponta para ele. Assim o custo é zero quando o jogo abre, o resultado fica versionado no
git (dá para ver num diff quando a malha muda), e a região já entra na cena com a malha
pronta.

> **`agent_radius` é o número que mais importa aqui.** Alto demais, e as portas fecham: os
> obstáculos engordam até se encontrarem, e um cômodo fica inalcançável **sem nenhum erro**.
> Baixo demais, e o Alfredo raspa nos móveis — e raspar é como ele sai da malha e congela
> (Parte 8.8).
>
> **Ele tem que ser >= a meia-largura do corpo.** O corpo do Alfredo tem 28 px de largura,
> então a meia-largura é 14. Comecei com 8, e o caminho passava mais perto da parede do que o
> corpo cabia: ele encostava, escorregava, e saía do chão. Testei 10, 12 e 14 rodando o
> diagnóstico em cada um — os três mantêm todos os cômodos alcançáveis, então ficou 14.

Se você mexer numa parede ou num móvel, rode a ferramenta de novo:

```powershell
& $godot --path $proj --headless --script res://ferramentas/gerar_navmesh.gd
```

## 7.4 Conferindo sem jogar

Aqui vale mostrar a ferramenta, porque "olhar e achar que está bom" não pega cômodo
inalcançável. O `ferramentas/diagnostico.gd` pergunta três coisas ao motor:

```powershell
& $godot --path $proj --headless --script res://ferramentas/diagnostico.gd
```

```
--- navmesh ---
  poligonos: 133 | vertices: 229
--- rotas do Alfredo ---
  SalaEstar      ok  (desvio do piso:   0.0 px, pontos no caminho: 2)
  Cozinha        ok  (desvio do piso:   0.0 px, pontos no caminho: 7)
  Quintal        ok  (desvio do piso:  15.1 px, pontos no caminho: 15)
  ...
--- interagiveis (dentro de movel = ruim) ---
  MrT            ok    dentro_de=-                piso_mais_perto=  0.0 px
  ...
=== TUDO OK ===
```

O que ele usa:

- `NavigationServer2D.map_get_closest_point(mapa, ponto)` — "qual o chão mais próximo daqui?".
  Se a resposta está longe, esse ponto não é chão.
- `NavigationServer2D.map_get_path(mapa, origem, destino, true)` — "existe caminho?". Zero
  pontos = não existe.
- `PhysicsPointQueryParameters2D` + `intersect_point` — "tem algum corpo estático neste
  ponto?". É o que pega um objeto interativo enfiado dentro de um móvel.

E para ver com os olhos, o Godot desenha a área caminhável se você pedir:

```powershell
& $godot --path $proj --debug-navigation cenas/mapa2.tscn
```

## 7.5 A armadilha que me custou meia hora

Escrevi o diagnóstico, rodei, e **tudo falhou**: toda consulta respondia `(0, 0)` e o desvio
do piso dava 600, 900, 1200 px. Mas o navmesh tinha 133 polígonos e a caixa deles cobria a
casa inteira. A malha estava lá; as consultas não a viam.

Duas coisas ao mesmo tempo (de novo):

1. **`get_navigation_map()` devolve um RID nulo nas primeiras frames**, antes da região se
   registrar. E consulta contra mapa nulo responde `(0,0)` **sem erro nenhum**.
2. **A primeira iteração do mapa (id 1) ainda não contém a malha da região** — ela entra na
   iteração 2.

O conserto é esperar de verdade, e o mesmo cuidado está no `_ready()` do Alfredo:

```gdscript
	var passos := 0
	while passos < 30:
		await get_tree().physics_frame
		passos += 1
		var mapa: RID = nav_agent.get_navigation_map()
		if mapa.is_valid() and NavigationServer2D.map_get_iteration_id(mapa) >= 2:
			break
```

**A lição, que vale para qualquer servidor do Godot (física, navegação, áudio):** eles são
assíncronos. `await get_tree().physics_frame` uma vez raramente é o suficiente. Espere pela
**condição** que você precisa, não por um número de frames.

## Teste agora

Rode `mapa2.tscn`. O Alfredo tem que sair andando pela casa, contornando os móveis, parar uns
segundos e ir para outro cômodo.

## Se der errado

| Sintoma | Causa |
|---|---|
| Ele continua parado | rode o diagnóstico. Se o navmesh tem 0 polígonos, o contorno está errado ou o `agent_radius` é grande demais |
| Ele anda através dos móveis | a região não tem navmesh, ou você regerou depois de mexer nos móveis e esqueceu de salvar |
| Ele fica preso num canto | `agent_radius` grande demais fechou aquela passagem — baixe para 6, depois 4 |
| Um cômodo nunca é visitado | o diagnóstico mostra qual: `FALHA` na linha daquela rota |

```bash
git commit -am "navegacao gerada a partir dos colliders + ferramenta de diagnostico"
```

---

# Parte 8 — A IA do Alfredo

## 8.1 Máquina de estados, e por que não `bool`

O Alfredo faz quatro coisas: ronda a casa, investiga barulho, caça o gato, e fica bravo
depois de pegá-lo.

**Tentativa com `bool`:**

```gdscript
var perseguindo := false
var investigando := false
var bravo := false
```

O problema não é o tamanho, é que **nada impede duas serem `true` ao mesmo tempo**. E aí, no
mesmo quadro, o código manda ele para dois destinos. Você acaba escrevendo
`if perseguindo and not bravo and not investigando`, e cada estado novo dobra o número
dessas condições.

**Com `enum`, o estado inválido não existe:**

```gdscript
enum Estado { ROTINA, INVESTIGANDO, PERSEGUINDO, BRAVO }

func _physics_process(delta: float) -> void:
	_verificar_flagrante()
	_atualizar_estado()

	match _estado:
		Estado.ROTINA:       _passo_rotina(delta)
		Estado.INVESTIGANDO: _passo_investigando(delta)
		Estado.PERSEGUINDO:  _passo_perseguindo(delta)
		Estado.BRAVO:        _passo_bravo(delta)
```

Ele está em **exatamente um** estado, sempre. E dá para ler o comportamento inteiro olhando
quatro funções curtas.

## 8.2 O princípio: a IA escolhe destino, não movimento

Repare que os quatro `_passo_*` fazem a mesma coisa no fim: chamar `_andar()`. A diferença
entre eles é só **para onde** o `nav_agent.target_position` aponta.

```gdscript
func _andar(vel: float) -> void:
	var proximo := nav_agent.get_next_path_position()
	var direcao := global_position.direction_to(proximo)
	velocity = direcao * vel
	# ... escolhe a animação pela direção
	move_and_slide()
```

Andar, animar e colidir é um código só, escrito uma vez. Adicionar um quinto estado
("ir dormir às 22h") não mexe em nada disso — só num `target_position` novo.

## 8.3 Quem manda no estado é a suspeita

```gdscript
func _atualizar_estado() -> void:
	if _estado == Estado.BRAVO:
		return                              # bravo não é interrompido
	if Jogo.faixa() == Jogo.Faixa.ALTA:
		_estado = Estado.PERSEGUINDO
	elif _estado == Estado.PERSEGUINDO:
		_estado = Estado.ROTINA
		_ir_para_rota()
```

Isso amarra a IA no sistema de suspeita sem um único `if` espalhado: passou de 70, ele caça;
desceu, ele volta à ronda. E é a dica visual de que a derrota por suspeita está perto — o
jogador **vê** o Alfredo vindo atrás dele.

## 8.4 Rotas: `Marker2D` em vez de coordenadas no código

```gdscript
	var no_rotas := get_tree().get_first_node_in_group("rotas")
	if no_rotas:
		for filho in no_rotas.get_children():
			if filho is Node2D:
				_rotas.append(filho)
```

**Por que `Marker2D` e não uma lista de `Vector2` no script:** um marcador dá para
**arrastar no editor** e ver onde ele está no desenho da casa. Uma coordenada no código é um
par de números que você ajusta às cegas, roda, olha, ajusta de novo. Quem faz nível agradece.

E `_ir_para_rota()` sorteia:

```gdscript
func _ir_para_rota() -> void:
	if _rotas.is_empty():
		return
	var destino: Node2D = _rotas[randi() % _rotas.size()]
	nav_agent.target_position = destino.global_position
```

Sorteio simples é o suficiente para parecer "semialeatório" como o documento de design pede.
Se um dia ficar repetitivo, o próximo passo é não sortear o ponto onde ele já está.

## 8.5 O flagrante

```gdscript
func _verificar_flagrante() -> void:
	if _estado == Estado.BRAVO or alvo == null:
		return
	if not alvo.has_method("esta_em_acao_secreta") or not alvo.esta_em_acao_secreta():
		return
	if global_position.distance_to(alvo.global_position) > RAIO_FLAGRANTE:
		return
	if not _tem_linha_de_visao(alvo.global_position):   # ver a seção 8.6
		return
	_flagrar()
```

**Quatro saídas antecipadas, em ordem de custo crescente:** o estado (grátis), a pergunta ao
gato (grátis), a distância (uma raiz quadrada) e, por último, o raycast (o mais caro, porque
envolve o motor de física). Assim, na esmagadora maioria dos quadros a função sai na primeira
linha e o raio nunca é traçado.

Essa ordem não é estética: `_verificar_flagrante()` roda 60 vezes por segundo, e um raycast a
cada quadro para nada seria desperdício puro. **Quando você tem várias condições, teste a mais
barata primeiro.**

E a punição:

```gdscript
func _flagrar() -> void:
	_estado = Estado.BRAVO
	_espera = ESPERA_BRAVO

	get_tree().call_group("interagivel", "cancelar")

	Jogo.avisar("Alfredo te pegou! De volta pra sala.")
	Jogo.aumentar_suspeita(Jogo.FLAGRANTE)   # se estourar 100, a derrota acontece aqui

	if alvo.has_method("levar_para"):
		alvo.levar_para(_ponto_inicial)
```

O `call_group` é o ponto interessante: o Alfredo precisa zerar o progresso de qualquer etapa
em curso, mas **não conhece nenhum interagível**. O grupo resolve isso — "chame `cancelar()`
em todo mundo com essa etiqueta". Adicionar um objeto novo amanhã não exige tocar no
Alfredo.

E o `has_method(...)` antes de chamar: é o jeito de trabalhar com um nó que você conhece por
grupo, e não por tipo. Se um dia o alvo for outra coisa, o código não explode.

## 8.6 Visão: fazer "onde você está" importar

O flagrante da seção anterior é binário: a 60 px ele te pega, a 61 px não acontece nada. Isso
deixava um furo de design — trabalhar no plano **na frente** do Alfredo custava exatamente o
mesmo que trabalhar escondido. O jogador não tinha por que se posicionar.

A correção é um gradiente: enquanto ele **te vê**, a etapa custa `FATOR_OBSERVADO` (2,5) vezes
mais suspeita.

### Por que linha de visão e não cone de visão

Um cone — "ele só vê para onde está virado" — é o padrão em jogos de furtividade, e é mais
realista. Aqui seria **errado**:

O Alfredo é um sprite de 32 px com quatro direções de animação. O jogador **não consegue ler**
para onde ele está olhando. Punir com base em algo imperceptível transforma o jogo em sorte.

Já parede e móvel no caminho, o jogador vê na hora. Então a regra é: **alcance + caminho livre**.

E isso traz um efeito colateral que eu não tinha planejado e que é melhor que o plano:
**esconder-se atrás do sofá funciona**. Sai de graça, porque o sofá tem colisão.

> **A regra geral:** baseie a punição no que o jogador consegue perceber. Regra invisível não é
> dificuldade, é ruído.

### O raio de visão

```gdscript
const ALCANCE_VISAO := 260.0     # ~1/4 da largura da tela

func _esta_vendo_o_caju() -> bool:
	if alvo == null:
		return false
	if global_position.distance_to(alvo.global_position) > ALCANCE_VISAO:
		return false
	return _tem_linha_de_visao(alvo.global_position)


func _tem_linha_de_visao(ponto: Vector2) -> bool:
	var espaco := get_world_2d().direct_space_state
	var consulta := PhysicsRayQueryParameters2D.create(global_position, ponto)
	consulta.collision_mask = 1              # só o MUNDO bloqueia
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	return espaco.intersect_ray(consulta).is_empty()
```

Duas coisas para entender:

**O que é um raycast.** É perguntar ao motor de física: "traçando uma linha reta daqui até ali,
bate em alguma coisa?". `intersect_ray` devolve um dicionário vazio se o caminho está livre. É
barato — uma consulta por quadro para um personagem não pesa.

**Por que `collision_mask = 1` é o detalhe que faz funcionar.** Só o mundo (camada 1) bloqueia.
O Caju está na camada 2 e o Alfredo na 4, então nenhum dos dois bloqueia a própria visão. Se a
máscara fosse `0xFFFFFFFF`, o raio bateria no **próprio Caju** e a resposta seria sempre "não
vejo" — um bug silencioso e confuso. As camadas separadas da seção 8.8 ficam de graça aqui.

### Aplicando o multiplicador

No `objetivo.gd`, uma linha:

```gdscript
func _ao_progredir(delta: float) -> void:
	var atual := Jogo.objetivo_atual()
	if not atual.is_empty():
		var fator := Jogo.FATOR_OBSERVADO if Jogo.observado else 1.0
		Jogo.aumentar_suspeita(atual["suspeita"] * fator * delta)
```

E repare onde isso **não** está: no `acao_gato.gd`. Comportamento de gato é inocente — ele pode
olhar à vontade. Se o multiplicador valesse para tudo, o disfarce deixaria de ser disfarce.

### Publicando o estado: mais um sinal de evento

O Alfredo calcula, mas quem precisa saber é a HUD. Mesmo padrão do `faixa_alterada` da Parte 2:
o Alfredo escreve o valor todo quadro, e o `Jogo` só avisa na **troca**.

```gdscript
# alfredo.gd, no _physics_process
Jogo.definir_observado(_esta_vendo_o_caju())
```

```gdscript
# jogo.gd
func definir_observado(valor: bool) -> void:
	if observado == valor:
		return                    # nada mudou: não incomoda ninguém
	observado = valor
	observado_alterado.emit(valor)
```

Sem esse `if`, a HUD receberia 60 sinais por segundo para redesenhar a mesma coisa.

### O aviso tem que chegar ANTES

```gdscript
func _ao_mudar_observado(observado: bool) -> void:
	_observado.visible = observado
```

A decisão de design aqui: o aviso aparece sempre que ele tem o gato à vista, **não** só quando
o jogador já começou uma etapa. A informação útil é "não comece agora" — se ela chegar depois de
apertar `E`, o jogador já pagou.

E ele pisca devagar, para puxar o olho sem virar poluição visual:

```gdscript
	if _observado.visible:
		_observado.modulate.a = 0.55 + 0.45 * (sin(Time.get_ticks_msec() / 170.0) * 0.5 + 0.5)
```

### O flagrante também passou a exigir visão

```gdscript
	if global_position.distance_to(alvo.global_position) > RAIO_FLAGRANTE:
		return
	if not _tem_linha_de_visao(alvo.global_position):
		return
	_flagrar()
```

Antes era só distância — e nesta casa, com paredes finas, ele pegava o gato **através da
parede**. Era injusto no sentido preciso do termo: o jogador não tinha como prever.

### Testando uma regra geométrica

Esta mecânica é geometria, e geometria se testa com coordenadas concretas:

```gdscript
	await _testar("parede bloqueia a visao", func() -> bool:
		# Parede1 corre de (512,301) a (685,401): a 110 px, DENTRO do alcance, mas com
		# parede no caminho.
		_alfredo.global_position = Vector2(650, 430)      # sala
		_caju.global_position = Vector2(650, 300)         # quarto, do outro lado
		await _esperar(3)
		return not _alfredo._esta_vendo_o_caju())
```

O comentário com as coordenadas da parede é o que faz esse teste ser mantível: sem ele, quem
ler depois não sabe por que (650, 430) e (650, 300) provam algo.

Os cinco testes que cobrem a mecânica:

```
  ok    ele ve o gato no mesmo comodo, perto
  ok    parede bloqueia a visao
  ok    longe demais ele nao ve
  ok    ser observado multiplica a suspeita da etapa
  ok    acao de gato nao e afetada por ser visto
```

O último é o mais importante: ele protege a regra de **design** (o disfarce funciona) de alguém
"consertar" o multiplicador para valer em tudo.

## 8.7 Consertando o `scale` no corpo físico

A cena do Alfredo tinha `scale = Vector2(2, 2)` no `CharacterBody2D`.

**Por que isso é problema:** escalar um corpo de física escala junto a forma de colisão, e o
motor de física do Godot não gosta disso — a colisão fica imprecisa. Pior, o
`NavigationAgent2D` filho herda a escala, e o `radius` dele passa a valer o dobro do que
você digitou, sem avisar.

**Como escalar do jeito certo:** deixe o corpo em escala 1 e escale só o que é **visual**,
ajustando a forma de colisão nos números reais.

| Antes | Depois |
|---|---|
| `Alfredo` (corpo) `scale = (2, 2)` | *sem escala* |
| `AnimatedSprite2D` sem escala | `scale = (2, 2)` |
| `CollisionShape2D` em `(0, 13.25)`, forma `14 x 5.5` | em `(0, 26.5)`, forma `28 x 11` |

Os números dobrados dão exatamente o mesmo resultado na tela e na colisão, e agora o
`radius = 14` do agente significa 14 pixels de verdade — o mesmo valor da meia-largura do
corpo e do `agent_radius` do navmesh (Parte 7.3). Os três casam de propósito.

**A regra:** nunca escale um nó de física. Escale o sprite.

## 8.8 Quando o agente sai do chão (e congela para sempre)

Este bug apareceu jogando, depois de tudo parecer pronto: **o Alfredo andava uns 10 segundos e
parava de vez**, no estado ROTINA, com velocidade zero, para sempre.

### Medir antes de teorizar

Em vez de olhar o código e adivinhar, escrevi uma ferramenta que imprime a posição dele a cada
segundo (`ferramentas/diagnostico_alfredo.gd`):

```
   9s  pos=(  660.1,  507.4)  andou_no_seg=  61.2  estado=0  vel= 70.0
  10s  pos=(  639.2,  574.1)  andou_no_seg=  69.9  estado=0  vel= 70.0
  11s  pos=(  622.8,  605.5)  andou_no_seg=  35.5  estado=0  vel=  0.0
  12s  pos=(  622.8,  605.5)  andou_no_seg=   0.0  estado=0  vel=  0.0
  13s  pos=(  622.8,  605.5)  andou_no_seg=   0.0  estado=0  vel=  0.0
```

Isso já elimina metade das hipóteses: ele **não** está tentando andar e sendo bloqueado (a
velocidade é 0, não 70). Ele está achando que chegou.

A mesma ferramenta imprimiu o estado do agente, e apareceu a pista definitiva:

```
  destino alcancavel? false
```

### A causa: três camadas

**1. O caminho passava mais perto da parede do que o corpo cabia.** `agent_radius` era 8, e a
meia-largura do corpo é 14. Ele encostava no móvel, o `move_and_slide` o fazia escorregar, e
ele terminava **fora da área caminhável** — que é justamente a região a 14 px dos móveis.

**2. Um agente fora da malha não acha caminho nenhum.** E, crucialmente, ele não reclama:
`is_navigation_finished()` passa a responder **`true` para qualquer destino**. Aí o
`_passo_rotina` faz o que foi programado — "cheguei, vou esperar e sortear outro destino" — e
entra num laço infinito de sortear destinos que falham na hora. Parado, sem erro nenhum.

**3. O Caju empurrava ele.** Os dois eram corpos na mesma camada de física. Não existe valor de
`agent_radius` que proteja contra isso: a malha é gerada a partir dos **móveis**, e o gato não
é um móvel.

### As três correções

**`agent_radius` de 8 para 14**, igual à meia-largura do corpo. Testei 10, 12 e 14 com o
diagnóstico: os três mantêm todos os cômodos alcançáveis.

**Camadas de física separadas.** O gato e o humano deixam de se empurrar:

| Nó | `collision_layer` | `collision_mask` |
|---|---|---|
| os 27 móveis | 1 (`mundo`) | 1 |
| `Caju` | 2 (`caju`) | 1 — colide só com o mundo |
| `Alfredo` | 4 (`alfredo`) | 1 — colide só com o mundo |
| `Area2D` dos interagíveis | 0 | 2 — detecta só o Caju |

Vale dar nome às camadas em Projeto → Configurações → *Nomes de Camadas → 2D Física*: o
Inspetor passa a mostrar "mundo" em vez de "Layer 1".

> **Atenção ao efeito colateral:** ao mover o Caju para a camada 2, a `Area2D` dos
> interagíveis (que procurava na 1) parou de vê-lo, e **nenhuma interação funcionava mais**.
> Mudar camada é o tipo de coisa que quebra algo distante. Por isso virou teste automático:
> "interagivel detecta o Caju".

**Todo destino é empurrado para o chão.** Um `Marker2D` é colocado a olho no editor; se cair
dentro de uma parede, aquele destino é inalcançável e o agente responde "cheguei" na hora:

```gdscript
func _no_piso(ponto: Vector2) -> Vector2:
	if not _navegacao_pronta():
		return ponto
	return NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), ponto)
```

Passando todo destino por aqui, ele é sempre alcançável **por construção**. Isso é melhor que
ajustar os 9 marcadores na mão: continua valendo quando alguém mover um marcador, ou quando o
`agent_radius` mudar e a malha encolher.

### E as duas redes de segurança

Nada disso garante que ele nunca mais saia da malha, então há duas defesas.

**Resgate**, para quando está claramente fora — ele anda em linha reta de volta ao chão,
ignorando o caminho:

```gdscript
func _resgatar_se_fora_do_piso() -> bool:
	if not _navegacao_pronta():
		return false
	var piso := NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), global_position)
	if global_position.distance_to(piso) <= TOLERANCIA_PISO:
		if _resgatando:
			_resgatando = false      # voltou: o caminho antigo é lixo
			_espera = 0.0
			_ir_para_rota()
		return false

	_resgatando = true
	velocity = global_position.direction_to(piso) * VELOCIDADE_RESGATE
	# ... animação ...
	move_and_slide()
	return true
```

**Vigia de travamento**, para todo o resto — fora por 2 px (que o resgate tolera mas o servidor
de navegação não), entalado entre dois móveis, laço de destinos que falham:

```gdscript
const LIMITE_TRAVADO := 6.0     # a espera legítima mais longa da rotina é 3 s
const MOVIMENTO_MINIMO := 5.0

func _vigiar_travamento(delta: float) -> void:
	if _estado == Estado.BRAVO or not _navegacao_pronta():
		_tempo_travado = 0.0
		return

	if _pos_vigia.distance_to(global_position) > MOVIMENTO_MINIMO:
		_pos_vigia = global_position
		_tempo_travado = 0.0
		return

	_tempo_travado += delta
	if _tempo_travado < LIMITE_TRAVADO:
		return

	_tempo_travado = 0.0
	global_position = _no_piso(global_position)    # empurrão de poucos pixels
	_pos_vigia = global_position
	_espera = 0.0
	_ir_para_rota()
```

**Por que 6 segundos:** a parada legítima mais longa é `ESPERA_ROTINA_MAX = 3 s`. Escolher 6
deixa margem para não dar falso positivo, e ainda é rápido o suficiente para o jogador não
perceber. Escolher o limite a partir de um número que já existe no código é melhor que chutar.

**Por que um teleporte é aceitável:** o empurrão é de poucos pixels, invisível na tela — e
infinitamente melhor que um Alfredo congelado no meio da cozinha. Solução perfeita que não
existe perde para solução feia que funciona.

### O resultado, medido

Com as três correções, 60 segundos de observação:

```
segundos observados: 60
distancia total andada: 3028 px
numero de paradas: 6
maior parada: 2 s   (limite legitimo da rotina = 3 s)
```

E virou teste de regressão, para não voltar:

```
  ok    Alfredo nunca congela (20 s de ronda)
  ok    interagivel detecta o Caju
```

**A lição maior desta seção:** quando um bug aparece, escreva primeiro a ferramenta que
**mede** o sintoma. Os cinco minutos gastos no `diagnostico_alfredo.gd` apontaram direto para
`destino alcancavel? false` — e sem ele eu teria ficado relendo a máquina de estados, que
estava correta.

## Teste agora

Rode e observe por um minuto: o Alfredo faz a ronda parando em cômodos diferentes. Aperte `Q`
para miar: ele para o que está fazendo e vem até onde você estava. Vá até a estante e segure
`E` com ele por perto: ao chegar a menos de 60 px, ele te pega, você volta para a sala e a
suspeita sobe 15.

Ou rode o teste automático, que faz tudo isso sem você:

```powershell
& $godot --path $proj --headless ferramentas/teste_jogo.tscn
```

## Se der errado

| Sintoma | Causa |
|---|---|
| Ele nunca te pega | o Caju não está chamando `marcar_acao_secreta()` — isso é o `objetivo.gd`, não a ação de gato (essa é de propósito) |
| Ele te pega arranhando o sofá | você pôs `marcar_acao_secreta()` no `acao_gato.gd` por engano |
| É impossível fugir dele | `VELOCIDADE_CACA` está acima dos 100 do Caju. Era 120 no código original |
| Ele trava em cima do gato | os dois estão na mesma camada de física e se empurram. Aqui isso é aceitável |

```bash
git commit -am "IA do Alfredo: maquina de estados, rotas e flagrante"
```

---

# Parte 9 — Narrativa

Três apresentações diferentes de texto, um sistema só.

## 9.1 O que é pausar, e a pegadinha do `process_mode`

```gdscript
get_tree().paused = true
```

Isso faz o Godot **parar de chamar `_process` e `_physics_process`** em toda a árvore. O
tempo congela, o Alfredo para, os interagíveis param de progredir.

Só que a HUD também para — e aí a tela de derrota aparece e o botão "Tentar novamente" não
responde ao clique, porque o `Control` não está processando entrada. O jogo trava de verdade.

**O conserto** é dizer que a HUD é exceção. No Inspetor do nó `HUD`, *Process → Mode →
Sempre* (no arquivo: `process_mode = 3`):

```
[node name="HUD" type="CanvasLayer"]
process_mode = 3
```

Os quatro modos que existem:

| Modo | Comportamento |
|---|---|
| Herdar (padrão) | faz o que o pai faz |
| **Pausável** | para quando o jogo pausa. É o que você quer para o mundo |
| **Sempre** | roda pausado ou não. É o que a interface precisa |
| **Quando Pausado** | roda **só** pausado. Serve para um menu de pausa dedicado |

**A regra:** o que precisa funcionar durante a pausa é `Sempre`. Se um botão de menu não
responde, olhe aqui primeiro.

## 9.2 Pensamento: um balão no mundo, não na tela

O balão fica **dentro da cena do Caju**, como filho dele. Isso significa que ele acompanha o
gato **sem uma linha de código** — mesma ideia da câmera na Parte 0.

Mas espere: a Parte 4 disse que texto é coisa de interface e vai no `CanvasLayer`. Por que
aqui é diferente?

Porque este texto **pertence ao mundo**: ele aponta para o gato. Se estivesse na HUD, eu
precisaria converter a posição do gato para coordenadas de tela a cada quadro. Como filho, é
de graça.

O que isso custa: o texto passa a ser afetado pela câmera. Como a câmera está em **zoom 1**,
cada pixel de fonte é um pixel de tela e o texto sai nítido. Se um dia a câmera ganhar zoom,
o balão fica embaçado e vai ter que virar um `Control` na HUD. Está escrito no comentário do
arquivo para o dia em que isso acontecer.

**A fila** existe por um motivo prático: concluir uma etapa pode disparar dois pensamentos
quase juntos, e sem fila o segundo apagaria o primeiro antes de dar tempo de ler.

```gdscript
func _ao_pensar(texto: String) -> void:
	_fila.append(texto)
	if _restante <= 0.0:
		_mostrar_proximo()
```

## 9.3 Pensamento de descoberta: o tutorial que não é tela de tutorial

Cada interagível tem um export:

```gdscript
@export_multiline var pensamento: String = ""
```

E a base dispara na **primeira** vez que o gato chega perto:

```gdscript
func _ao_entrar(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return
	_caju = corpo
	Jogo.pensar_uma_vez("prox:" + id, pensamento)
```

O "uma vez" mora no `jogo.gd`, com um dicionário de chaves já vistas:

```gdscript
func pensar_uma_vez(chave: String, texto: String) -> void:
	if texto == "" or _pensamentos_vistos.has(chave):
		return
	_pensamentos_vistos[chave] = true
	pensamento.emit(texto)
```

**Por que no `jogo.gd` e não em cada objeto:** porque `iniciar_partida()` limpa o dicionário,
e aí reiniciar a partida faz os pensamentos voltarem. Se cada objeto guardasse o próprio
"já mostrei", isso funcionaria por acidente (o objeto é recriado ao recarregar a cena) — mas
deixaria de funcionar no dia em que alguém quisesse reiniciar sem recarregar. Estado de
partida vive junto com o resto do estado de partida.

O efeito no jogo: ao passar perto do sofá pela primeira vez, o Caju pensa *"Se eu arranhar o
sofá, o Alfredo vem brigar aqui — e me esquece no resto da casa."* O jogador aprende a
mecânica no momento em que ela é útil, e por isso a tela de tutorial pôde ficar curta: só os
controles e as duas formas de perder.

## 9.4 Diálogo: esperando o jogador terminar de ler

O Mr. T tem seis falas, e a etapa `mr_t` **não pode** ser concluída antes da conversa acabar.
Isso é uma espera assíncrona, e a solução usa sinal com uma opção que vale conhecer:

```gdscript
# objetivo.gd
func _concluir() -> void:
	if falas.is_empty():
		Jogo.concluir_objetivo(id)
		return

	_aguardando_dialogo = true
	Jogo.dialogo_terminado.connect(_no_fim_do_dialogo, CONNECT_ONE_SHOT)
	Jogo.conversar(nome_falante, falas)
```

`CONNECT_ONE_SHOT` desconecta sozinho depois de disparar uma vez. Sem ele, cada partida
acumularia uma ligação nova e a etapa concluiria várias vezes.

E do outro lado, na HUD, **a ordem das duas últimas linhas importa**:

```gdscript
func _avancar_dialogo() -> void:
	_fala_atual += 1
	if _fala_atual < _falas.size():
		_fala.text = _falas[_fala_atual]
		return

	_caixa_dialogo.visible = false
	get_tree().paused = false     # despausa PRIMEIRO...
	Jogo.encerrar_dialogo()       # ...e só então avisa quem esperava
```

Por que: `encerrar_dialogo()` faz a etapa concluir, o que dispara um balão de pensamento — e
o balão é um nó pausável, então não animaria. Despausar antes resolve.

**Este tipo de bug é típico de pausa:** a ordem em que você desliga as coisas passa a
importar.

## 9.5 Inventário: construir a lista no código

O painel do `Tab` tem duas listas que mudam a cada etapa, então elas são construídas na hora
em vez de existirem na cena:

```gdscript
func _ao_mudar_inventario() -> void:
	for filho in _lista_etapas.get_children():
		filho.queue_free()

	for i in Jogo.OBJETIVOS.size():
		var linha := Label.new()
		linha.add_theme_font_size_override("font_size", 14)
		var feito := Jogo.esta_concluido(i)
		linha.text = "%s  %s" % ["[x]" if feito else "[ ]", Jogo.OBJETIVOS[i]["titulo"]]
		if feito:
			linha.modulate = Color(0.6, 0.86, 0.6)      # verde: pronto
		elif i == Jogo.indice:
			linha.modulate = Color(1, 0.9, 0.55)        # amarelo: é a vez desta
		else:
			linha.modulate = Color(0.58, 0.56, 0.52)    # cinza: ainda não
		_lista_etapas.add_child(linha)
```

`queue_free()` e não `free()`: `queue_free` marca o nó para morrer no fim do quadro, o que é
seguro mesmo se algo ainda estiver mexendo nele. `free()` apaga na hora e pode derrubar o
jogo.

Sobre `[x]` e `[ ]`: eu queria `✓` e `○`, mas a fonte padrão do Godot pode não ter esses
símbolos, e um caractere que falta aparece como retângulo vazio. Preferi feio e garantido a
bonito e talvez. Se você adicionar uma fonte própria ao projeto, troque.

E o toggle:

```gdscript
func _alternar_inventario() -> void:
	if not Jogo.em_partida:
		return                    # partida acabada: Tab não faz nada
	var abrir := not _painel_inventario.visible
	_painel_inventario.visible = abrir
	get_tree().paused = abrir
```

O `if not Jogo.em_partida` evita um bug bobo: sem ele, apertar `Tab` na tela de derrota
**despausaria o jogo por baixo** da tela de derrota.

## Teste agora

Vá até o Mr. T no quintal e segure `E`: a caixa de diálogo abre, o cronômetro **para**, e
você avança as seis falas com `E`. Ao terminar, a etapa é marcada e o Caju pensa *"Ele fala
bonito... mas por que eu saí de lá me sentindo pior?"*. Aperte `Tab`: a primeira linha tem
`[x]` em verde.

## Se der errado

| Sintoma | Causa |
|---|---|
| A caixa abre e o jogo não pausa | falta o `get_tree().paused = true` |
| A caixa abre e nada responde | a HUD não está com `process_mode = Sempre` |
| A etapa conclui antes do diálogo | `_esta_ativo()` não está checando `_aguardando_dialogo` |
| O balão não aparece depois do diálogo | você chamou `encerrar_dialogo()` antes de despausar |
| Os pensamentos não voltam ao reiniciar | `_pensamentos_vistos` não está sendo limpo no `iniciar_partida()` |

```bash
git commit -am "narrativa: dialogo, pensamentos e inventario"
```

---

# Parte 10 — Menu, finais e reinício

## 10.1 Trocar de cena

O menu é uma cena simples, e o botão "Jogar" faz:

```gdscript
func _jogar() -> void:
	get_tree().change_scene_to_file("res://cenas/mapa2.tscn")
```

`change_scene_to_file` **destrói** a cena atual e carrega a outra. O autoload `Jogo`
sobrevive — é justamente para isso que ele existe.

E no `project.godot`, *Cena Principal* passa a ser o menu, então `F5` abre por ele.

## 10.2 Quatro finais, uma tabela

Os textos ficam no `jogo.gd`, indexados pelo `enum Motivo`:

```gdscript
enum Motivo { SUSPEITA, TEMPO, ATIVOU, DESISTIU }

const FINAIS := [
	{   # SUSPEITA
		"vitoria": false,
		"titulo": "Alfredo descobriu o plano",
		"texto": "Ele juntou as peças: o papel sumido, o computador ligado, ...",
	},
	# ... TEMPO, ATIVOU, DESISTIU
]
```

Como o enum vale 0, 1, 2, 3 na ordem em que foi declarado, `FINAIS[motivo]` acha o final
certo direto. E a HUD fica com quatro linhas em vez de um `match` de quatro casos:

```gdscript
func _ao_terminar(motivo: Jogo.Motivo) -> void:
	var final: Dictionary = Jogo.FINAIS[motivo]
	_fim_titulo.text = final["titulo"]
	_fim_texto.text = final["texto"]
	_fim_titulo.modulate = Color(0.72, 0.94, 0.7) if final["vitoria"] else Color(0.96, 0.6, 0.52)
	_painel_fim.visible = true
```

> **Isto tem um preço:** se alguém reordenar o `enum`, os finais trocam de lugar em silêncio.
> É um risco aceitável para quatro itens num arquivo só; para vinte, eu usaria chaves de
> texto.

## 10.3 A escolha final

Ao concluir a quinta etapa, o `jogo.gd` **não** declara vitória — ele passa a decisão para o
jogador:

```gdscript
	if indice >= OBJETIVOS.size():
		escolha_final.emit()
		return
```

A HUD abre o painel e pausa. As duas teclas viram os dois finais:

```gdscript
	if _painel_escolha.visible:
		if evento.is_action_pressed("interagir"):
			Jogo.decidir(true)      # ativar  -> ATIVOU
		elif evento.is_action_pressed("disfarce"):
			Jogo.decidir(false)     # desistir -> DESISTIU
		return
```

Reaproveitar `E` e `F` em vez de criar teclas novas: o jogador já tem esses dois dedos
posicionados, e não precisa aprender nada novo no momento mais dramático do jogo.

## 10.4 Reiniciar

```gdscript
func _reiniciar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
```

Duas linhas, e vale entender por que basta:

1. `paused = false` — a tela de derrota só existe com o jogo pausado, e recarregar não
   despausa sozinho.
2. `reload_current_scene()` — recria o mapa do zero. Todo estado que vive **nos nós** (usos
   restantes, recargas, posições) volta ao original de graça, porque os nós são novos.
3. O `_ready()` do mapa novo chama `Jogo.iniciar_partida()`, que zera o estado que vive **no
   autoload** (tempo, suspeita, objetivos, inventário, pensamentos vistos).

É essa divisão que faz o reinício ser barato: **estado de nó** se resolve recriando o nó;
**estado de autoload** se resolve numa função que zera tudo explicitamente. Se você misturar
os dois — guardar tempo restante num nó, ou usos restantes no autoload — o reinício fica
cheio de casos especiais.

## Teste agora

`F5` abre o menu. "Jogar" leva ao jogo com o tutorial na frente. Conclua as cinco etapas
(ou rode o teste automático) e o painel de escolha aparece. Aperte `F`: o final "Caju mudou
de ideia" em verde. "Tentar novamente" tem que voltar com `05:00`, suspeita zero, inventário
vazio.

## Se der errado

| Sintoma | Causa |
|---|---|
| Reiniciar e o jogo fica congelado | faltou `paused = false` antes do `reload` |
| Reiniciar e a suspeita continua alta | `iniciar_partida()` não está sendo chamado, ou não zera tudo |
| Reiniciar e as ações de gato continuam sem usos | os usos deveriam viver no nó; se estão no autoload, `iniciar_partida()` tem que zerar |

```bash
git commit -am "menu, escolha final, quatro finais e reinicio"
```

---

# Parte 11 — Profundidade (Y-sort)

## 11.1 O problema

Numa vista de cima, quem está mais **abaixo** na tela está mais **na frente**. O gato andando
na frente do sofá tem que cobrir o sofá; andando atrás, tem que ser coberto.

Antes desta Parte, o Caju desenhava **sempre por cima de tudo** — atravessava a cama, o carro,
as paredes.

## 11.2 A ordem real de desenho no Godot

Duas coisas decidem quem desenha por cima, **nesta ordem**:

1. **`z_index`** — um número. Menor desenha primeiro (fica atrás). Isso vem antes de tudo.
2. **Y-sort** — *dentro do mesmo `z_index`*, se o pai tem `y_sort_enabled`, os filhos são
   ordenados pela posição Y deles.
3. Empate: ordem na árvore de nós.

É por isso que o chão é resolvido com `z_index` e não com coordenada. Um `Node2D` chamado
`Piso`, com `z_index = -1`, recebe o desenho da planta e o tapete:

```
Mapa2                  y_sort_enabled = true
├── Piso               z_index = -1      <- garantidamente atrás de tudo
│   ├── FinalBase
│   └── FinalTapete
├── ... os 26 móveis
├── Caju
└── Alfredo
```

Colocar o chão no Y-sort junto com o resto seria frágil: ele está em `y = 481`, e todo móvel
com Y menor que isso ficaria **atrás do chão**. Com `z_index`, não depende de coordenada
nenhuma.

## 11.3 Por que ligar o Y-sort não bastava

Aqui está o problema de verdade deste projeto. Cada móvel era assim:

```
Cama              StaticBody2D    position = (0, 0)        <- o corpo não tem posição!
├── FinalCama     Sprite2D        position = (684, 241)    <- a posição real está AQUI
└── 01            CollisionPolygon2D
```

Todos os corpos em `(0, 0)`, com a posição real no `Sprite2D` **filho**.

O Y-sort ordena os filhos pelo **Y deles**. Como os 26 corpos com sprite estão todos em `y = 0`, eles
empatam em zero, e todo mundo com `y > 0` — inclusive o Caju — desenha **na frente de todos os
móveis**. Ligar o flag deixaria o jogo pior do que estava.

## 11.4 A transformação, em três passos

Para cada móvel, com `S` = a posição do sprite:

```
1. corpo.position  += S      # a posição sobe do filho para o pai
2. sprite.position  = (0,0)  # e o filho zera
3. cada nó de colisão: position -= S
```

Nada muda na tela nem na colisão — os pontos dos polígonos **não são tocados**, só o
`position` de cada nó de colisão. O que muda é que o corpo passa a ter um Y de verdade para
ordenar.

Exemplo real, a cama:

| Nó | Antes | Depois |
|---|---|---|
| `Cama` (corpo) | `(0, 0)` | `(684, 241)` |
| `FinalCama` (sprite) | `(684, 241)` | *sem posição* = `(0,0)` |
| `01` (colisão) | `(402, -380)` | `(-282, -621)` |

`(402 - 684, -380 - 241) = (-282, -621)`. O sprite e a colisão continuam **exatamente** onde
estavam no mundo.

**Faça em um móvel primeiro**, no editor: selecione a `Cama`, anote a posição do
`FinalCama`, ponha no corpo, zere no sprite, subtraia na colisão. Rode e confira que a cama
não se moveu. Só depois repita. São 27 `StaticBody2D` no mapa, dos quais 26 têm sprite e precisam da
transformação (o `ParedesExternas` só tem colisão, não desenha nada). Para 26, vale escrever
um script que faça a conta.

### Por que ordenar pelo Y funciona nesta arte

Nesta projeção isométrica, o Y de tela é `(gx + gy) · tan30` — ou seja, é **exatamente** o
eixo de profundidade da cena. Ordenar por Y aqui não é aproximação, é a conta certa.

O que **é** aproximação: usar o **centro** de cada móvel como referência. Para móveis
compridos (a `FINAL_parede8` tem 2125 px de largura), o centro pode não representar bem onde
a peça "está" em profundidade. Na prática ficou correto em todos os casos que testei; se
aparecer um errado, o conserto é um `z_index` naquela peça específica, não uma solução geral.

## 11.5 O origin do personagem vai para os pés

Se o Caju ordena pelo **meio do corpo**, ele parece flutuar em relação aos móveis. O certo é
ordenar por **onde ele pisa**.

A regra: `corpo.position += CollisionShape2D.position`, e subtrair o mesmo vetor de todos os
filhos.

No Caju o deslocamento é `(1.166687, 12.3333435)` — a posição da forma de colisão, que é onde
ficam os pés:

| Nó | Antes | Depois |
|---|---|---|
| `Caju` no mapa | `(701, 446)` | `(702.17, 458.33)` |
| `AnimatedSprite2D` | `(0, 0.333)` | `(-1.167, -12.0)` |
| `CollisionShape2D` | `(1.167, 12.333)` | `(0, 0)` |
| `Camera2D` | `(0, 0)` | `(-1.167, -12.333)` |
| `Balao` | `(0, 0)` | `(-1.167, -12.333)` |

A câmera e o balão são deslocados também, para o enquadramento e o balão ficarem **idênticos**
ao que eram.

Uma exceção proposital: no Alfredo, o `NavigationAgent2D` **fica** em `(0, 0)`. Agora `(0,0)`
são os pés, e é de lá que o caminho deve ser calculado — o agente ganhou uma posição melhor
de graça.

## 11.6 A rede de segurança

Reposicionar 26 móveis e cerca de 40 nós de colisão à mão, ou por script, é exatamente o tipo de coisa
onde um sinal trocado passa despercebido. Então antes de mexer, tire uma foto do estado atual:

```powershell
& $godot --path $proj --headless --script res://ferramentas/dump_colisoes.gd > antes.txt
```

A ferramenta imprime a posição **global** de cada sprite e de cada nó de colisão — inclusive
os pontos dos polígonos, já transformados:

```
POLY  Cama/01    672.00,208.00 598.00,251.00 599.61,251.87 603.00,251.00 698.00,305.00 770.00,264.00
SPR   Cama/FinalCama    684.00,241.00 esc=(0.5, 0.5)
```

Faça a mudança, rode de novo, e compare. **O diff tem que ser vazio.** No meu caso as únicas
diferenças foram os caminhos dos nós que mudaram de pai (`FinalBase` → `Piso/FinalBase`), com
as coordenadas idênticas — que era exatamente o esperado.

> **Este é o padrão geral para refatoração:** se a mudança não deveria alterar o
> comportamento, ache uma forma de **medir** o comportamento antes e depois. Vale para
> geometria, para saída de função, para o que for. É o que separa "eu acho que não quebrei"
> de "eu sei que não quebrei".

## Teste agora

Ande com o Caju e confira:

- passa **atrás** da cama, do sofá, da poltrona, da estante, da geladeira e do carro;
- passa **na frente** dos mesmos, quando está do lado de cá;
- o chão e o tapete **nunca** cobrem um móvel;
- o balão de pensamento nunca fica atrás de nada (ele tem `z_index = 30`).

Se preferir conferir sem jogar, `ferramentas/captura.gd` põe o gato em posições escolhidas e
salva uma foto de cada uma.

## Se der errado

| Sintoma | Causa |
|---|---|
| Tudo ficou atrás do chão | o `Piso` não tem `z_index = -1`, ou os corpos ainda estão em `(0,0)` |
| Um móvel se moveu | erro de sinal no passo 3: é `position - S`, não `+ S`. O diff mostra qual |
| O gato colide onde não tem nada | você mexeu nos pontos do `polygon` em vez do `position` do nó de colisão |
| O gato parece flutuar | o origin dele não foi para os pés |

```bash
git commit -am "profundidade: y-sort nos moveis e origin nos pes"
```

---

# Parte 12 — Deixar o jogo justo

## 12.1 Todos os números num lugar

Balanceamento é código, e código espalhado não se ajusta. Tudo o que decide se o jogo é
justo está no topo do [scripts/jogo.gd](../miaugerdon/scripts/jogo.gd):

```gdscript
const TEMPO_TOTAL := 300.0
const SUSPEITA_MAX := 100.0
const DECAIMENTO_BAIXA := 1.0
const LIMPAR_SE := 4.0
const FLAGRANTE := 15.0
const LIMITE_MEDIA := 35.0
const LIMITE_ALTA := 70.0
const FATOR_OBSERVADO := 2.5
```

mais a tabela `OBJETIVOS` (duração e suspeita por segundo de cada etapa) e os exports das
ações de gato no `mapa2.tscn`.

## 12.2 A conta que precisa fechar

Somando o custo das cinco etapas, se feitas sem interrupção:

| etapa | duração | suspeita/s | total |
|---|---|---|---|
| `mr_t` | 2 s | +3 | 6 |
| `papel_caneta` | 4 s | +5 | 20 |
| `escrever_plano` | 7 s | +5 | 35 |
| `computador` | 7 s | +5 | 35 |
| `maquina` | 10 s | +5 | **50** |
| | | | **146** |

Duas propriedades que essa tabela **precisa** ter:

**Nenhuma etapa sozinha pode matar.** A pior é a máquina, com 50 — metade da barra. Numa
versão anterior desses números a máquina custava 10/s por 10 s = exatamente 100, e o jogo era
**inganhável**: chegar na última etapa com a barra em zero e ainda perder. Sempre confira
isso ao mexer.

**A soma tem que passar de 100.** Se não passar, dá para fazer o jogo inteiro sem nunca se
disfarçar, e as seis ações de gato viram enfeite. Com 146, o jogador é obrigado a baixar a
suspeita ao menos duas vezes no meio do caminho.

## 12.3 O que NÃO mexer

**`DECAIMENTO_BAIXA` só age na faixa BAIXA.** Isto não é otimização, é a regra que segura o
jogo em pé:

```gdscript
	if faixa() == Faixa.BAIXA and suspeita > 0.0:
		reduzir_suspeita(DECAIMENTO_BAIXA * delta)
```

Se você tirar a condição e deixar a suspeita cair em qualquer nível, **basta andar em círculos
para zerar a barra**, e todo o sistema de ações de gato deixa de ter função. Já testei: o jogo
fica trivial e as seis ações ficam sem propósito.

**`LIMPAR_SE = 4.0` é fraco de propósito.** A 4 por segundo, limpar 100 de suspeita custa 25
segundos parado — 8% do cronômetro. Eu tinha posto 12 no começo, e a 12/s a tecla `F` virava
um botão de "resetar o jogo": oito segundos parado e a barra zerava. Toda a tensão sumia.

**`FATOR_OBSERVADO = 2.5` é o número mais afiado da tabela.** Com ele, a soma de 146 vira 365
se o jogador fizer tudo com o Alfredo olhando — inganhável de propósito. O que segura isso em
pé são duas coisas: o aviso na tela chega **antes** de apertar `E`, e soltar o `E` custa pouco
(o progresso decai a 25%). Se ao jogar parecer punitivo demais, este é o primeiro número a
baixar — 1,8 ainda deixa o posicionamento importar.

**Regra geral:** antes de aumentar um número que ajuda o jogador, pergunte se ele passa a ser
a resposta para tudo. Se passar, o resto do sistema morre. E antes de aumentar um número que
o atrapalha, pergunte se ele tem como saber — punição sem aviso é sorte, não dificuldade.

## 12.4 Como testar

Duas perguntas, e as duas têm resposta objetiva:

**É ganhável?** Uma partida jogada bem tem que sobrar tempo. Se você conhece o mapa e ainda
perde, `TEMPO_TOTAL` é o primeiro botão — é o mais seguro de mexer, porque afeta o ritmo sem
mexer em nenhuma outra regra.

**É trivial?** Ande em círculos sem se disfarçar e tente ganhar. Se der, a regra do
decaimento quebrou.

E há um teste automático que cobre as regras (não a diversão):

```powershell
& $godot --path $proj --headless ferramentas/teste_jogo.tscn
```

```
  ok    decaimento so acontece na faixa BAIXA
  ok    cadeia de 5 objetivos chega na escolha final
  ok    suspeita em 100 termina por SUSPEITA
  ok    cronometro em zero termina por TEMPO
  ok    reiniciar zera tudo
```

O caso de borda que vale conferir à mão: leve flagrante com a barra em 90. Os +15 estouram
os 100 e a derrota é por suspeita, ali mesmo.

---

# Parte 13 — Armadilhas deste projeto

Consulta rápida. Todos são problemas **reais**, encontrados aqui — não hipóteses.

## `y_sort_enabled` dentro do `_physics_process`

**Sintoma:** o código parece cuidar da profundidade, e a profundidade não funciona.
**Causa:** duas coisas erradas juntas — rodava 60 vezes por segundo sem necessidade, e estava
no nó errado (`y_sort_enabled` ordena os **filhos**, não a si mesmo).
**Conserto:** tirar do `_physics_process`, e ligar o flag no **pai** — Parte 11.
**Como reconhecer em outro lugar:** configuração dentro de `_process`. Se o valor não muda,
não pertence ali.

## `scale` num corpo de física

**Sintoma:** colisão imprecisa, e o `radius` do `NavigationAgent2D` valendo o dobro do que
está escrito.
**Causa:** `scale = (2,2)` no `CharacterBody2D` escala a forma de colisão e tudo o que é
filho.
**Conserto:** corpo em escala 1, escala só no `AnimatedSprite2D`, forma de colisão com os
números reais — Parte 8.7.

## A falha silenciosa: IA parada sem erro no console

**Sintoma:** o Alfredo não sai do lugar. Console limpo.
**Causa:** três coisas ao mesmo tempo — `alvo` não preenchido na instância, grupo `jogador`
que nunca existiu, e nenhum `NavigationRegion2D` no mapa. E um `if not alvo: return` engolindo
tudo.
**Conserto:** Parte 7 inteira.
**A lição:** saída antecipada silenciosa é o esconderijo favorito de bug. Em função que não
deveria ser chamada sem alvo, use `push_warning`.

## Y-sort não funciona porque a posição está no filho

**Sintoma:** liga o Y-sort e tudo fica atrás do chão.
**Causa:** os corpos em `(0,0)` com a posição real no `Sprite2D` filho — todos empatam em
zero.
**Conserto:** a transformação de três passos da Parte 11.4.

## Consulta de navegação respondendo `(0,0)`

**Sintoma:** `map_get_closest_point` devolve `(0,0)` para qualquer ponto, e nenhum erro
aparece.
**Causa:** `get_navigation_map()` devolve RID nulo nas primeiras frames, **e** a primeira
iteração do mapa ainda não contém a malha da região.
**Conserto:** esperar pela condição, não por um número de frames — Parte 7.5.
**Como reconhecer:** vale para todos os servidores do Godot. Se um `await physics_frame`
"quase funciona", espere pela condição.

## Cache de `uid` mentindo depois de mover arquivo por fora

**Sintoma:** `Cannot open file 'res://cenas/caju.tscn'` para um caminho que não está escrito
em lugar nenhum.
**Causa:** `.godot/uid_cache.bin` guarda "qual uid mora em qual caminho", e só é atualizado
quando o **Godot** move o arquivo.
**Conserto:** apagar o cache e reimportar (`--headless --import`) — Parte 1.3. Ou mover pelo
painel do Godot e não passar por isso.

## `PackedVector2Array([...])` em `const`

**Sintoma:** `Assigned value for constant "X" isn't a constant expression`.
**Causa:** `const` em GDScript só aceita expressão constante, e `PackedVector2Array(...)` é
uma **chamada de construtor**.
**Conserto:** guarde como `Array` (`const X := [Vector2(...), ...]`) e converta no uso:
`PackedVector2Array(X)`.

## Autoload não existe com `--script`

**Sintoma:** `Compile Error: Identifier not found: Jogo` num script de ferramenta.
**Causa:** rodando com `--script`, os autoloads não estão registrados na hora de compilar
aquele arquivo.
**Conserto:** faça a ferramenta ser uma **cena** e rode
`godot --headless ferramentas/x.tscn`. (Curiosamente, scripts carregados
*indiretamente* — os das cenas que a ferramenta carrega — acham o `Jogo` normalmente.)

## Nome único duplicado

**Sintoma:** `%Titulo` pega o nó errado, ou o Godot reclama de nome repetido.
**Causa:** *Acessar como Nome Único* precisa ser único **na cena**, e eu tinha quatro nós
`Titulo` (um por painel).
**Conserto:** renomear — `FimTitulo`, `FimTexto`.

## `flip_h` junto com `offset` num `Sprite2D`

**Sintoma:** o sprite desaparece ou pula para o lado errado.
**Causa:** `flip_h` também espelha o efeito do `offset`, então um `offset` calculado para
recentrar o desenho aponta para o lado contrário.
**Conserto:** neste projeto, tirei o `flip_h` do Mr. T. Se precisar dos dois, espelhe pelo
`scale.x` negativo em vez do `flip_h`, ou recalcule o `offset`.

## Agente de navegação fora da malha: congela em silêncio

**Sintoma:** o Alfredo anda uns 10 s e para de vez. Estado correto, velocidade 0, console
limpo.
**Causa:** empurrado para fora da área caminhável (por raspar na parede, ou por encontrão do
Caju). Fora da malha, `is_navigation_finished()` responde `true` para **qualquer** destino, e a
lógica de "cheguei, vou sortear outro destino" entra em laço infinito sem sair do lugar.
**Conserto:** `agent_radius >= meia-largura do corpo`, camadas de física separadas para os
personagens, todo destino empurrado para o chão mais próximo, e duas redes de segurança
(resgate + vigia de travamento) — Parte 8.8.
**Como reconhecer em outro lugar:** qualquer agente de navegação que possa ser movido pela
física. Se um NPC "para de funcionar depois de um tempo", suspeite disso antes da IA.

## Raycast que bate no próprio personagem

**Sintoma:** a linha de visão responde "não vejo" sempre, mesmo com o gato na frente.
**Causa:** o raio foi lançado com a máscara padrão (todas as camadas), então bate no primeiro
corpo que encontra — que pode ser o próprio alvo, ou quem lançou.
**Conserto:** máscara restrita ao que deve bloquear (aqui, só a camada `mundo`):
`consulta.collision_mask = 1` — Parte 8.6.
**Como reconhecer:** qualquer `intersect_ray` que "nunca encontra caminho livre". Comece pela
máscara.

## Mudar camada de física quebra coisa distante

**Sintoma:** separei o Caju e o Alfredo em camadas diferentes e **nenhuma interação funcionava
mais** — nenhum prompt aparecia em objeto nenhum.
**Causa:** a `Area2D` dos interagíveis procurava corpos na camada 1. O Caju tinha saído dela.
**Conserto:** máscara da área para a camada nova do Caju.
**A lição:** camada de física é acoplamento invisível — não aparece em nenhum `get_node`, e o
compilador não ajuda. Ao mexer numa, liste **tudo** que detecta aquele nó.

## Teste que passa às vezes

**Sintoma:** o teste "Alfredo sai do lugar" passava três vezes e falhava na quarta, sem nada
ter mudado.
**Causa:** ele media a distância percorrida numa **janela fixa** de 2,5 s. Mas ao começar a
ronda, o Alfredo pode ficar até 3 s parado (a espera de "fazer tarefa") se o mapa de navegação
ainda não estava pronto no primeiro destino. Dependendo do sorteio, a janela inteira caía
dentro da parada.
**Conserto:** esperar **até** a condição acontecer, com um limite generoso, em vez de medir
uma janela:

```gdscript
	var maior := 0.0
	for i in 420:                                  # ~7 segundos de limite
		await get_tree().physics_frame
		maior = maxf(maior, antes.distance_to(_alfredo.global_position))
		if maior > 20.0:
			return true
	print("      (andou no maximo %.1f px)" % maior)
	return false
```

**A regra:** teste que depende de "quanto tempo passou" é instável. Teste pela condição, e
quando falhar, **imprima o valor que chegou** — sem o `print` do máximo, o próximo a ver essa
falha não teria como saber se ele andou 19 px ou 0.

## Corrotina sem `await`

**Sintoma:** a ferramenta de captura salvava cada foto **uma posição atrasada**.
**Causa:** `_salvar()` tem um `await` dentro, então é corrotina. Chamada sem `await`, ela
devolve na hora e o resto do código continua — a foto era tirada depois do gato já ter se
mexido.
**Conserto:** `await _salvar(nome)`.
**A regra:** se a função tem `await` dentro, quem chama precisa de `await` também.

---

# Parte 14 — Como continuar sozinha

Três extensões prováveis, em ordem de dificuldade. Se o tutorial funcionou, as três devem
parecer fáceis.

## 14.1 Adicionar som

O jogo não tem áudio. O documento de design lista 19 sons.

1. Ponha os arquivos em `sprites/`... não: crie `audio/` e ponha lá. `.ogg` para música,
   `.wav` para efeito curto (o `.wav` não tem atraso de decodificação).
2. Para um som **do mundo** (o copo caindo, o Alfredo andando): um `AudioStreamPlayer2D` como
   filho do objeto — o volume acompanha a distância de graça.
3. Para um som **de interface** (clique, alerta de suspeita): um `AudioStreamPlayer` comum na
   HUD.
4. Ligue nos sinais que já existem. Um exemplo que dá quase de graça:

```gdscript
# na HUD, dentro do _ready()
Jogo.faixa_alterada.connect(func(f: Jogo.Faixa) -> void:
	if f == Jogo.Faixa.ALTA:
		$SomAlerta.play())
```

Repare que **não precisa mexer no `jogo.gd`**. Os sinais já contam tudo o que acontece — é a
recompensa da Parte 2.

5. Para música que não pode morrer na troca de cena, um autoload pequeno só para áudio é
   aceitável. É o único segundo autoload que eu acharia justificado aqui.

## 14.2 Adicionar uma etapa nova ao plano

Digamos "esconder o plano embaixo do tapete".

1. Em `jogo.gd`, um item novo em `OBJETIVOS`:

```gdscript
	{
		"id": "esconder_plano",
		"titulo": "Esconda o plano embaixo do tapete",
		"duracao": 5.0,
		"suspeita": 5.0,
		"itens": [],
		"pensamento": "Se ele achar isso, acabou.",
	},
```

2. No `mapa2.tscn`, instancie `cenas/objetos/objetivo.tscn` dentro do nó `Objetivos`,
   posicione onde quiser, e no Inspetor preencha `id = "esconder_plano"`, um `rotulo` curto e
   um `pensamento`.
3. **Refaça a conta do balanceamento** (Parte 12): a soma subiu 25. Ainda passa de 100 (bom) e
   nenhuma etapa sozinha mata (bom). Mas o cronômetro agora precisa cobrir 5 segundos a mais
   de interação, mais o caminho até lá — considere subir `TEMPO_TOTAL`.
4. Rode `ferramentas/diagnostico.gd` para conferir que a posição nova não está dentro de um
   móvel.

Não precisa tocar em HUD, inventário, Alfredo ou script nenhum. O inventário passa a mostrar
seis linhas porque ele lê `Jogo.OBJETIVOS`.

## 14.3 Adicionar uma ação de gato nova

Digamos "subir na cortina".

1. No `mapa2.tscn`, instancie `cenas/objetos/acao_gato.tscn` dentro do nó `Acoes`.
2. No Inspetor: `id = "cortina"`, `rotulo = "Subir na cortina"`, `duracao`,
   `reduz_suspeita`, `atrai_alfredo`, `recarga`, `usos`, e um `pensamento` de descoberta.
3. Se for um objeto que não existe no desenho da casa, ponha uma cor em `cor_placeholder` e
   ele aparece como um losango. Quando tiver arte, preencha `textura` e o losango desaparece
   sozinho.
4. Pergunta de balanceamento: quanto de suspeita a mais o jogador passa a poder desfazer? Se
   as ações somarem muito mais que 146, o jogo fica fácil.

Zero linhas de código.

## 14.4 O que eu faria em seguida

Se fosse continuar este projeto, na ordem:

1. **Áudio.** É o que mais muda a sensação por hora de trabalho.
2. **Animações próprias** para as ações de gato. Hoje elas reaproveitam `parado_*`, e o
   jogador não *vê* o gato arranhando o sofá — só o texto dizendo que ele arranhou.
3. **Arte do Mr. T** e das telas de fim.
4. **Alfredo com memória.** Hoje ele sorteia rotas. Se ele lembrasse "vi o gato mexendo no
   computador", poderia voltar lá — o que é mais assustador e não custa muito código, porque
   a máquina de estados já está pronta para um estado novo.

