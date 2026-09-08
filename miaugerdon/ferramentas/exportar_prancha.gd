extends Node

# Exporta a prancha da abertura inteira como PNG, na resolução em que ela foi
# diagramada — nada de print de tela.
#
# Como rodar: com a cena ferramentas/exportar_prancha.tscn aberta, F6. O arquivo
# sai na raiz do repositório, ao lado da pasta do projeto.
#
# O truque é tirar o script da raiz da cena ANTES de colocá-la na árvore: sem
# ele a animação de revelação nunca começa, então todos os quadros e balões já
# nascem visíveis e na posição final. Depois a prancha é movida para um
# SubViewport do tamanho dela e fotografada de lá.

const ARQUIVO := "prancha_abertura.png"
const QUADROS_DE_ESPERA := 12


func _ready() -> void:
	var cena: Control = load("res://cenas/ui/abertura.tscn").instantiate()
	cena.set_script(null)
	add_child(cena)

	var palco: Control = cena.get_node("Palco")
	var prancha: Control = palco.get_node("Prancha")
	var medida := Vector2i(prancha.size)

	var alvo := SubViewport.new()
	alvo.size = medida
	alvo.transparent_bg = false
	alvo.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(alvo)

	palco.remove_child(prancha)
	alvo.add_child(prancha)
	prancha.position = Vector2.ZERO
	prancha.scale = Vector2.ONE

	# os balões medem o próprio texto num quadro adiado; sem esperar, alguns
	# saem antes de terminar de se ajustar
	for i in QUADROS_DE_ESPERA:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var caminho := ProjectSettings.globalize_path("res://").path_join("../" + ARQUIVO).simplify_path()
	var erro := alvo.get_texture().get_image().save_png(caminho)
	if erro == OK:
		print("prancha salva em %s (%d x %d)" % [caminho, medida.x, medida.y])
	else:
		push_error("falhou ao salvar a prancha: %d" % erro)
	get_tree().quit()
