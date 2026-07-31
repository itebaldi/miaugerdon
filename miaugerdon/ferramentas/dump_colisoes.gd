extends SceneTree

## Imprime a posição GLOBAL de cada sprite e de cada nó de colisão do mapa2.
##
##   godot --path <projeto> --headless --script res://ferramentas/dump_colisoes.gd
##
## Serve como rede de segurança para o passe de profundidade (Y-sort): aquele passe move a
## posição de 27 móveis do nó filho para o nó pai e compensa nos nós de colisão. Se a conta
## estiver certa, NADA muda de lugar no mundo — e a prova é rodar isto antes e depois e
## comparar. Diff vazio = a colisão continua exatamente onde estava.


func _initialize() -> void:
	var cena: Node = load("res://cenas/mapa2.tscn").instantiate()
	root.add_child(cena)
	await physics_frame

	var linhas: Array[String] = []
	_varrer(cena, cena, linhas)
	linhas.sort()
	for l in linhas:
		print(l)
	quit(0)


func _varrer(no: Node, raiz: Node, linhas: Array[String]) -> void:
	if no is CollisionPolygon2D:
		var pontos := PackedStringArray()
		for p in no.polygon:
			var g: Vector2 = no.global_transform * p
			pontos.append("%.2f,%.2f" % [g.x, g.y])
		linhas.append("POLY  %-46s %s" % [raiz.get_path_to(no), " ".join(pontos)])
	elif no is CollisionShape2D:
		var g: Vector2 = no.global_position
		var extra := ""
		if no.shape is RectangleShape2D:
			extra = "rect%s" % no.shape.size
		elif no.shape is CircleShape2D:
			extra = "circ%.2f" % no.shape.radius
		elif no.shape is CapsuleShape2D:
			extra = "caps%.2f/%.2f" % [no.shape.radius, no.shape.height]
		linhas.append("SHAPE %-46s %.2f,%.2f rot=%.4f esc=%s %s"
			% [raiz.get_path_to(no), g.x, g.y, no.global_rotation, no.global_scale, extra])
	elif no is Sprite2D:
		var g: Vector2 = no.global_position
		linhas.append("SPR   %-46s %.2f,%.2f esc=%s" % [raiz.get_path_to(no), g.x, g.y, no.global_scale])

	for f in no.get_children():
		_varrer(f, raiz, linhas)
