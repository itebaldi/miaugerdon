extends SceneTree

# Gera o mapa de navegação da casa a partir da colisão dos móveis e salva em
# cenas/navmesh_casa.tres.
#
#   godot --path <projeto> --headless --script res://ferramentas/gerar_navmesh.gd
#
# Rode de novo se mexer em parede ou móvel.

const DESTINO := "res://cenas/navmesh_casa.tres"

# os quatro cantos do losango da propriedade, tirados da colisão de ParedesExternas
const CONTORNO := [
	Vector2(14, 590),
	Vector2(762, 158),
	Vector2(1416, 522),
	Vector2(658, 960),
]

# o corpo do Alfredo tem 28 px de largura; abaixo de 14 o caminho passa mais perto da
# parede do que ele cabe
const RAIO_AGENTE := 14.0


func _initialize() -> void:
	var cena: Node = load("res://cenas/mapa2.tscn").instantiate()
	root.add_child(cena)
	await physics_frame

	var poligono := NavigationPolygon.new()
	poligono.agent_radius = RAIO_AGENTE
	poligono.cell_size = 1.0
	poligono.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	poligono.parsed_collision_mask = 1
	poligono.add_outline(PackedVector2Array(CONTORNO))

	var geometria := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(poligono, geometria, cena)
	NavigationServer2D.bake_from_source_geometry_data(poligono, geometria)

	print("poligonos: %d | vertices: %d" % [poligono.get_polygon_count(), poligono.vertices.size()])
	if poligono.get_polygon_count() == 0:
		print("FALHA: nenhum poligono gerado")
		quit(1)
		return

	if ResourceSaver.save(poligono, DESTINO) != OK:
		print("FALHA ao salvar ", DESTINO)
		quit(1)
		return

	print("salvo em ", DESTINO)
	quit(0)
