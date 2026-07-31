extends Node

## Investiga por que o Alfredo não anda.
##
##   godot --path <projeto> --headless ferramentas/diagnostico_alfredo.tscn

var _cena: Node
var _alfredo: CharacterBody2D
var _caju: Node2D


func _ready() -> void:
	_cena = load("res://cenas/mapa2.tscn").instantiate()
	add_child(_cena)
	_alfredo = _cena.get_node("Alfredo")
	_caju = _cena.get_node("Caju")

	# fecha o tutorial (que pausa o jogo)
	for i in 20:
		await get_tree().physics_frame
	(_cena.get_node("HUD") as CanvasLayer)._fechar_tutorial()
	for i in 20:
		await get_tree().physics_frame

	_onde_nasce("Alfredo", _alfredo, _alfredo.get_node("CollisionShape2D").global_position)
	_onde_nasce("Caju", _caju, _caju.get_node("CollisionShape2D").global_position)

	print("")
	print("--- estado interno do Alfredo ---")
	print("  alvo = ", _alfredo.alvo)
	print("  rotas encontradas = ", _alfredo._rotas.size())
	print("  estado = ", _alfredo._estado, "  (0=ROTINA 1=INVESTIGANDO 2=PERSEGUINDO 3=BRAVO)")
	var agente: NavigationAgent2D = _alfredo.nav_agent
	print("  destino = ", agente.target_position)
	print("  navegacao terminada? ", agente.is_navigation_finished())
	print("  destino alcancavel? ", agente.is_target_reachable())
	print("  pontos no caminho = ", agente.get_current_navigation_path().size())

	print("")
	print("--- posicao do Alfredo a cada segundo (60s) ---")
	var inicio: Vector2 = _alfredo.global_position
	var anterior := inicio
	for s in 60:
		for i in 60:
			await get_tree().physics_frame
		var agora: Vector2 = _alfredo.global_position
		print("  %2ds  pos=(%7.1f,%7.1f)  andou_no_seg=%6.1f  total=%7.1f  estado=%d  vel=%5.1f"
			% [s + 1, agora.x, agora.y, anterior.distance_to(agora),
			   inicio.distance_to(agora), _alfredo._estado, _alfredo.velocity.length()])
		anterior = agora

	get_tree().quit(0)


func _onde_nasce(nome: String, no: Node2D, pos_colisao: Vector2) -> void:
	print("")
	print("--- %s nasce em %s (colisao em %s) ---" % [nome, no.global_position, pos_colisao])

	var espaco := get_viewport().world_2d.direct_space_state
	var consulta := PhysicsPointQueryParameters2D.new()
	consulta.position = pos_colisao
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	consulta.collision_mask = 1
	var dentro: Array[String] = []
	for b in espaco.intersect_point(consulta, 8):
		var corpo: Node = b["collider"]
		if corpo is StaticBody2D:
			dentro.append(str(corpo.name))
	print("  DENTRO de corpo estatico: ", dentro if dentro else "nada (ok)")

	var regiao: NavigationRegion2D = _cena.get_node("Navegacao")
	var mapa := regiao.get_navigation_map()
	var perto := NavigationServer2D.map_get_closest_point(mapa, pos_colisao)
	print("  piso mais perto: %s  (desvio %.1f px)" % [perto, perto.distance_to(pos_colisao)])
