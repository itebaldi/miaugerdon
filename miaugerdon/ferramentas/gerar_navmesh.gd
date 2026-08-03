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

# um pouco maior que o corpo, para o lugar sugerido não ficar raspando
const FOLGA_CORPO := Vector2(36, 15)


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
	_conferir_rotas(poligono)
	quit(0)


# Marcador de rota fora da área caminhável faz o Alfredo entalar tentando chegar nele.
# Encolher a malha (mexer num móvel, mudar o RAIO_AGENTE) é justo o que quebra isso, então
# o aviso sai aqui, no momento em que acontece.
func _conferir_rotas(poligono: NavigationPolygon) -> void:
	var no_rotas := get_first_node_in_group("rotas")
	if no_rotas == null:
		return

	for marcador in no_rotas.get_children():
		if not marcador is Node2D:
			continue
		var pos: Vector2 = marcador.global_position
		if _na_malha(pos, poligono):
			continue

		print("ATENCAO: %s em (%d, %d) esta fora da area caminhavel"
			% [marcador.name, roundi(pos.x), roundi(pos.y)])
		var perto := _lugar_folgado(pos, poligono)
		if perto != Vector2.INF:
			print("         cabe em (%d, %d)" % [roundi(perto.x), roundi(perto.y)])


func _na_malha(ponto: Vector2, poligono: NavigationPolygon) -> bool:
	for i in poligono.get_polygon_count():
		var cantos := PackedVector2Array()
		for indice in poligono.get_polygon(i):
			cantos.append(poligono.vertices[indice])
		if Geometry2D.is_point_in_polygon(ponto, cantos):
			return true
	return false


func _lugar_folgado(origem: Vector2, poligono: NavigationPolygon) -> Vector2:
	var espaco := root.world_2d.direct_space_state
	var forma := RectangleShape2D.new()
	forma.size = FOLGA_CORPO
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.collision_mask = 1

	for raio in range(10, 200, 10):
		for passo in 24:
			var angulo := TAU * passo / 24.0
			var p: Vector2 = origem + Vector2(cos(angulo), sin(angulo)) * raio
			if not _na_malha(p, poligono):
				continue
			consulta.transform = Transform2D(0.0, p)
			if espaco.intersect_shape(consulta, 1).is_empty():
				return p
	return Vector2.INF
