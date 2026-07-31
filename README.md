# Miaugerdon: a vingança do gato

Jogo de furtividade em vista superior, feito em **Godot 4.7**.

Caju é um gato laranja que descobriu que o Alfredo vai adotar um cachorro. Transtornado, ele
decide dominar o mundo. Você tem 5 minutos para cumprir as cinco etapas do plano sem que o
Alfredo desconfie — e no fim, decide se ativa a máquina de controle mental ou se muda de
ideia.

Trabalho de Isadora e Jonatan.

## Como jogar

Abra o `Godot_v4.7.1-stable_win64.exe`, escolha *Importar* e aponte para
`miaugerdon/project.godot`. Depois aperte `F5`.

| Tecla | Ação |
|---|---|
| `W` `A` `S` `D` | andar |
| `E` | segurar para interagir |
| `F` | limpar-se (parado) — baixa a suspeita devagar |
| `Q` | miar — faz barulho e chama o Alfredo para onde você está |
| `Tab` | ver o plano e o que você já conseguiu |

**Duas formas de perder:** o cronômetro zerar, ou a barra de suspeita encher.
Elas empurram para lados opostos — baixar a suspeita custa tempo parado, e correr contra o
relógio faz a suspeita subir. Achar o ritmo entre as duas é o jogo.

**Como baixar a suspeita:** agindo como um gato normal. Espalhados pela casa há seis coisas
para fazer — derrubar o copo, comer na tigela, arranhar o sofá, dormir na cama, cavar a terra
do vaso, brincar no tapete. Três delas fazem barulho e trazem o Alfredo, mesmo baixando a
suspeita. É a decisão interessante.

**Onde você faz importa.** Enquanto o Alfredo estiver **te vendo**, trabalhar no plano custa
2,5 vezes mais suspeita — e um aviso pisca no alto da tela antes, para você poder esperar ou se
esconder atrás de um móvel. Parede e móvel bloqueiam a visão dele de verdade.

Pego no meio de uma etapa do plano, você perde o progresso e volta para a sala. Pego arranhando
o sofá, nada acontece — é só um gato sendo gato, e ele pode olhar à vontade.

## Documentação

| Arquivo | O que tem |
|---|---|
| [docs/PLANO.md](docs/PLANO.md) | **por que o jogo é assim**: recorte, regras, os 4 finais, e a tabela de balanceamento (é onde mexer para deixar mais fácil ou mais difícil) |
| [docs/TUTORIAL.md](docs/TUTORIAL.md) | **como o código funciona**, passo a passo, escrito para quem nunca abriu o Godot |

## Estrutura

```
miaugerdon/                      raiz do projeto Godot (res://)
├── project.godot
├── cenas/
│   ├── mapa2.tscn               o nível — a casa inteira
│   ├── navmesh_casa.tres        mapa de navegação, gerado (ver ferramentas/)
│   ├── personagens/             caju, alfredo
│   ├── objetos/                 objetivo, acao_gato
│   └── ui/                      menu, hud, balao
├── scripts/                     mesma divisão de cenas/
│   ├── jogo.gd                  autoload: tempo, suspeita, objetivos, narrativa
│   └── mapa2.gd
├── sprites/
│   ├── personagens/             caju, alfredo, gato (Mr. T)
│   └── objetos/                 a casa desenhada peça por peça
└── ferramentas/                 scripts de conferência, não entram no jogo
```

`cenas/` e `scripts/` têm as mesmas subpastas, então o script de uma cena está sempre no
caminho equivalente.

## Ferramentas de conferência

Todas rodam sem precisar jogar. `$godot` é o caminho do executável e `$proj` a pasta
`miaugerdon/`.

```powershell
# as cenas carregam sem erro?
& $godot --path $proj --headless --quit-after 4

# navegação: o navmesh existe, cada cômodo é alcançável, e nenhum objeto
# interativo está enfiado dentro de um móvel
& $godot --path $proj --headless --script res://ferramentas/diagnostico.gd

# o loop do jogo funciona? (suspeita, faixas, barulho, os 4 finais, reiniciar)
& $godot --path $proj --headless ferramentas/teste_jogo.tscn

# regerar o mapa de navegação — RODE ISTO se mexer numa parede ou num móvel
& $godot --path $proj --headless --script res://ferramentas/gerar_navmesh.gd

# ver a área caminhável desenhada por cima do jogo
& $godot --path $proj --debug-navigation cenas/mapa2.tscn
```

`ferramentas/diagnostico_alfredo.gd` imprime a posição do Alfredo a cada segundo, e o estado
interno do agente de navegação. Serve para quando ele parecer preso:

```powershell
& $godot --path $proj --headless ferramentas/diagnostico_alfredo.tscn
```

`ferramentas/dump_colisoes.gd` imprime a posição global de cada colisão e sprite. Serve para
conferir, antes e depois de mexer na profundidade dos objetos, que nada saiu do lugar — a
Parte 11 do tutorial explica. E `ferramentas/captura.gd` tira fotos do jogo em situações
escolhidas, para conferir profundidade e interface sem jogar (precisa rodar com janela).

## O que ainda não tem

- **Áudio.** O documento de design lista 19 sons e o projeto não tem nenhum arquivo. A Parte
  14 do tutorial ensina a adicionar.
- **Animações próprias** para as ações de gato: elas reaproveitam as animações de andar e de
  ficar parado que já existiam.
- **Arte do Mr. T e das telas de fim.** O Mr. T é o sprite de gato com um topete louro, e os
  finais são painéis de texto.
