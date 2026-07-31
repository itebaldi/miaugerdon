extends Node

## Foto da tela inicial. Roda COM janela:
##   godot --path <projeto> --resolution 1152x648 ferramentas/captura_menu.tscn

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://capturas/")
	add_child(load("res://cenas/ui/menu.tscn").instantiate())
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var destino := "C:/Users/isado/AppData/Local/Temp/claude/c--Users-isado-isa-flat-miaugerdon/a696e3b9-0678-4cd2-b38d-967853f16331/scratchpad/menu.png"
	get_viewport().get_texture().get_image().save_png(destino)
	print("menu salvo")
	get_tree().quit(0)
