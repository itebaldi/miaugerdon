extends SceneTree

## Gera o mapa de navegaÃ§Ã£o da casa a partir dos colliders que jÃ¡ existem no mapa2 e salva
## como recurso, para a NavigationRegion2D jÃ¡ nascer com ele.
##
##   godot --path <projeto> --headless --script res://ferramentas/gerar_navmesh.gd
##
## POR QUE GERAR E SALVAR, em vez de gerar quando o jogo comeÃ§a:
##  - custo zero quando o jogo abre (o bake leva um tempinho e nÃ£o muda entre partidas);
##  - o resultado fica visÃ­vel e versionado: dÃ¡ para abrir o .tres e ver a malha, e um diff
##    do git mostra quando ela mudou;
##  - a regiÃ£o entra na Ã¡rvore jÃ¡ com a malha, sem depender de ordem de _ready().
##
## POR QUE GERAR EM VEZ DE DESENHAR Ã€ MÃƒO: os 27 mÃ³veis jÃ¡ tÃªm colisÃ£o. Desenhar um polÃ­gono
## de navegaÃ§Ã£o seria copiar essa informaÃ§Ã£o, e cÃ³pia diverge quando alguÃ©m move um mÃ³vel.
## Aqui a Ãºnica coisa escrita Ã  mÃ£o Ã© o contorno externo do terreno: 4 pontos.
##
## RODE ISTO DE NOVO se mexer em parede, mÃ³vel ou no contorno.

const DESTINO := "res://cenas/navmesh_casa.tres"

## Os quatro cantos do losango isomÃ©trico da propriedade, tirados dos polÃ­gonos de colisÃ£o
## de ParedesExternas e Parede8.
const CONTORNO_TERRENO := [
	Vector2(14, 590),     # oeste  (entrada da garagem)
	Vector2(762, 158),    # norte  (fundo do quarto)
	Vector2(1416, 522),   # leste  (fundo do quintal)
	Vector2(658, 960),    # sul    (frente da casa)
]

## Raio do "corpo" do Alfredo ao calcular o caminho. Alto demais fecha as portas e deixa
## cÃ´modos inalcanÃ§Ã¡veis; baixo demais ele raspa nas paredes.
## O corpo do Alfredo tem 28 px de largura, ou seja meia-largura 14. O raio do agente tem
## que ser >= isso, senao o caminho passa mais perto da parede do que o corpo cabe: ele
## raspa, escorrega, e pode acabar FORA da malha (e ai o agente nao acha caminho nenhum).
const RAIO_AGENTE := 14.0


func _initialize() -> void:
	var cena: Node = load("res://cenas/mapa2.tscn").instantiate()
	root.add_child(cena)
	await physics_frame

	var poligono := NavigationPolygon.new()
	poligono.agent_radius = RAIO_AGENTE
	poligono.cell_size = 1.0
	# SÃ³ colisÃ£o de corpo estÃ¡tico conta como obstÃ¡culo: assim o Caju e o Alfredo
	# (CharacterBody2D) e os interagÃ­veis (Area2D) ficam de fora.
	poligono.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	poligono.parsed_collision_mask = 1
	# O contorno Ã© a Ã¡rea CAMINHÃVEL; os obstÃ¡culos sÃ£o recortados dela.
	poligono.add_outline(PackedVector2Array(CONTORNO_TERRENO))

	var geometria := NavigationMeshSourceGeometryData2D.new()
	# `cena` Ã© o nÃ³ raiz a varrer â€” passar explicitamente evita depender de grupos ou de
	# reorganizar a Ã¡rvore sÃ³ para o bake achar os mÃ³veis.
	NavigationServer2D.parse_source_geometry_data(poligono, geometria, cena)
	NavigationServer2D.bake_from_source_geometry_data(poligono, geometria)

	print("poligonos: %d | vertices: %d" % [poligono.get_polygon_count(), poligono.vertices.size()])
	if poligono.get_polygon_count() == 0:
		print("FALHA: o bake nao gerou poligono nenhum. Confira o contorno e o raio.")
		quit(1)
		return

	var erro := ResourceSaver.save(poligono, DESTINO)
	if erro != OK:
		print("FALHA ao salvar %s (erro %d)" % [DESTINO, erro])
		quit(1)
		return

	print("salvo em %s" % DESTINO)
	quit(0)
