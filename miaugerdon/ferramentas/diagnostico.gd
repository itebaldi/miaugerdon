extends SceneTree

## Ferramenta temporária de conferência. Roda sem abrir janela:
##
##   godot --path <projeto> --headless --script res://ferramentas/diagnostico.gd
##
## Confere três coisas que só apareceriam jogando:
##  1. o navmesh foi gerado (tem polígonos)
##  2. cada ponto de rota do Alfredo é alcançável a partir dos outros
##  3. cada interagível está em piso livre, e não enfiado dentro de um móvel


func _initialize() -> void:
	var cena: Node = load("res://cenas/mapa2.tscn").instantiate()
	root.add_child(cena)

	# O mundo físico e o mapa de navegação só existem depois de um passo de física. E o
	# NavigationServer só aceita consulta depois da PRIMEIRA SINCRONIZAÇÃO do mapa: sem
	# esta espera, toda consulta responde "map query failed".
	# ARMADILHA: nas primeiras frames, get_navigation_map() da regiao devolve um RID NULO, e
	# consulta contra mapa nulo responde (0,0) caladamente. Além disso a primeira iteração
	# do mapa (id 1) ainda não contém a malha da região: ela entra na iteração 2.
	# Por isso: espera de física, RID buscado DEPOIS, e espera até a iteração >= 2.
	var regiao_nav: NavigationRegion2D = cena.get_node("Navegacao")
	var passos := 0
	while passos < 120:
		await physics_frame
		passos += 1
		var m: RID = regiao_nav.get_navigation_map()
		if m.is_valid() and NavigationServer2D.map_get_iteration_id(m) >= 2:
			break
	print("(mapa de navegacao pronto depois de %d passos de fisica)" % passos)

	var falhas := 0
	falhas += _conferir_navmesh(cena)
	falhas += _conferir_rotas(cena)
	falhas += _conferir_interagiveis(cena)

	print("")
	if falhas == 0:
		print("=== TUDO OK ===")
	else:
		print("=== %d PROBLEMA(S) ===" % falhas)
	quit(falhas)


func _conferir_navmesh(cena: Node) -> int:
	var regiao: NavigationRegion2D = cena.get_node("Navegacao")
	var poli := regiao.navigation_polygon
	print("--- navmesh ---")
	if poli == null:
		print("  FALHA: nenhum NavigationPolygon foi atribuido")
		return 1
	print("  poligonos: %d | vertices: %d" % [poli.get_polygon_count(), poli.vertices.size()])
	if poli.get_polygon_count() == 0:
		print("  FALHA: o bake nao gerou poligono nenhum")
		return 1

	var minimo := poli.vertices[0]
	var maximo := poli.vertices[0]
	for v in poli.vertices:
		minimo = minimo.min(v)
		maximo = maximo.max(v)
	print("  caixa dos vertices: %s .. %s" % [minimo, maximo])
	print("  regiao habilitada: %s | posicao: %s" % [regiao.enabled, regiao.global_position])
	var mapa := regiao.get_navigation_map()
	print("  mapa valido: %s | regioes no mapa: %d | iteracao: %d" % [
		mapa.is_valid(), NavigationServer2D.map_get_regions(mapa).size(),
		NavigationServer2D.map_get_iteration_id(mapa)])
	print("  closest_point(700,450) = %s" % NavigationServer2D.map_get_closest_point(mapa, Vector2(700, 450)))
	print("  region_get_bounds = %s" % NavigationServer2D.region_get_bounds(regiao.get_rid()))
	print("  map cell_size = %s | navmesh cell_size = %s" % [
		NavigationServer2D.map_get_cell_size(mapa), poli.cell_size])
	print("  primeiro poligono = %s" % [poli.get_polygon(0)])
	print("  vertices desse poligono = %s, %s, %s" % [
		poli.vertices[poli.get_polygon(0)[0]], poli.vertices[poli.get_polygon(0)[1]],
		poli.vertices[poli.get_polygon(0)[2]]])
	return 0


func _conferir_rotas(cena: Node) -> int:
	print("--- rotas do Alfredo ---")
	var regiao: NavigationRegion2D = cena.get_node("Navegacao")
	var mapa := regiao.get_navigation_map()
	var rotas := cena.get_node("Rotas").get_children()
	var origem: Vector2 = cena.get_node("Rotas/SalaEstar").global_position
	var falhas := 0

	for r in rotas:
		var destino: Vector2 = r.global_position
		var perto := NavigationServer2D.map_get_closest_point(mapa, destino)
		var desvio := perto.distance_to(destino)
		var caminho := NavigationServer2D.map_get_path(mapa, origem, destino, true)
		var chegou := caminho.size() > 0 and caminho[caminho.size() - 1].distance_to(perto) < 12.0
		var estado := "ok" if (chegou and desvio < 24.0) else "FALHA"
		if estado == "FALHA":
			falhas += 1
		print("  %-14s %s  (desvio do piso: %5.1f px, pontos no caminho: %d)"
			% [r.name, estado, desvio, caminho.size()])
	return falhas


func _conferir_interagiveis(cena: Node) -> int:
	print("--- interagiveis (dentro de movel = ruim) ---")
	var espaco := cena.get_viewport().world_2d.direct_space_state
	var regiao: NavigationRegion2D = cena.get_node("Navegacao")
	var mapa := regiao.get_navigation_map()
	var falhas := 0

	for grupo in ["Objetivos", "Acoes"]:
		for no in cena.get_node(grupo).get_children():
			var pos: Vector2 = no.global_position

			var consulta := PhysicsPointQueryParameters2D.new()
			consulta.position = pos
			consulta.collide_with_bodies = true
			consulta.collide_with_areas = false
			consulta.collision_mask = 1
			var batidas := espaco.intersect_point(consulta, 4)

			var dentro := ""
			for b in batidas:
				var corpo: Node = b["collider"]
				if corpo is StaticBody2D:
					dentro = str(corpo.name)
					break

			var perto := NavigationServer2D.map_get_closest_point(mapa, pos)
			var desvio := perto.distance_to(pos)

			var problema := dentro != "" or desvio > 40.0
			if problema:
				falhas += 1
			print("  %-14s %s  dentro_de=%-16s piso_mais_perto=%5.1f px"
				% [no.name, "FALHA" if problema else "ok  ", dentro if dentro else "-", desvio])
	return falhas
