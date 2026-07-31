extends Node2D

## O nível. Só precisa começar a partida — o resto é a cena.
##
## O mapa de navegação do Alfredo NÃO é gerado aqui: ele vem pronto em
## cenas/navmesh_casa.tres, produzido por ferramentas/gerar_navmesh.gd a partir dos
## colliders dos 27 móveis. Se você mexer numa parede ou num móvel, rode a ferramenta de
## novo. O porquê dessa escolha está no comentário de cabeçalho dela.

@export var mostrar_diagnostico := false

@onready var navegacao: NavigationRegion2D = $Navegacao


func _ready() -> void:
	if mostrar_diagnostico:
		var poli := navegacao.navigation_polygon
		print("[mapa2] navmesh: ", "AUSENTE" if poli == null else
			  "%d poligonos" % poli.get_polygon_count())

	# Roda DEPOIS do _ready() de todos os filhos (o Godot chama de baixo para cima), então
	# a HUD já está ligada nos sinais quando isto dispara os valores iniciais.
	Jogo.iniciar_partida()
