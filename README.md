# Miaugerdon: a vingança do gato

Jogo de furtividade em vista de cima, feito na **Godot 4.7**.

O Alfredo anunciou que vai adotar um cachorro. O Caju, que sempre soube quem manda na
casa, decide que a resposta proporcional é construir uma máquina de dominação mental
antes de o invasor chegar.

Você tem 5 minutos para cumprir as cinco etapas do plano sem o Alfredo desconfiar. E aí
decide se aperta o botão.

## Como jogar

Abra a pasta `miaugerdon/` na Godot 4.7 e rode com `F5`.

| tecla | |
|---|---|
| WASD | andar |
| E | segurar para interagir |
| F | limpar-se — baixa a suspeita devagar |
| Q | miar — chama o Alfredo para onde você está |
| Tab | ver o plano e o que já conseguiu |

Cada etapa do plano sobe a barra de suspeita do Alfredo. Fazer coisa de gato normal
(derrubar copo, dormir na cama, arranhar o sofá) baixa. Trabalhar no plano com ele
olhando custa bem mais caro.

Perde-se de duas formas: o cronômetro zerar ou a barra encher. Ganha-se de duas — e as
duas dependem do que o Caju decide no fim.

## Onde fica o quê

```
miaugerdon/            projeto Godot (res://)
├── cenas/
│   ├── mapa2.tscn     a casa: é aqui que o jogo acontece
│   ├── objetos/       o que dá para interagir
│   ├── personagens/   Caju e Alfredo
│   └── ui/            menu, HUD e os painéis
├── scripts/
│   ├── config.gd      todo o texto do jogo e os números de cada objeto
│   ├── jogo.gd        autoload: tempo, suspeita, objetivos e o fim da partida
│   └── ...            um script por cena, na mesma divisão de pastas
└── sprites/
```

Para mudar qualquer fala, rótulo ou pensamento, o arquivo é o `scripts/config.gd`. Ele
existe justamente para isso: texto guardado em `.tscn` era apagado pelo editor ao salvar
a cena.
