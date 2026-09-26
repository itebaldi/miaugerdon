extends PanelContainer

## Painel de pergaminho preso com fita crepe nos dois cantos de cima, como as
## fichas coladas na HQ de abertura. O pergaminho em si é o StyleBox do painel;
## aqui só entram as fitas, desenhadas por cima dele e por baixo do conteúdo.

const FITA := preload("res://sprites/ui/fita_crepe.png")
const TAMANHO_FITA := Vector2(112, 25)
const ANGULO_FITA := 0.6


func _draw() -> void:
	_desenhar_fita(Vector2(24, 14), -ANGULO_FITA)
	_desenhar_fita(Vector2(size.x - 24, 14), ANGULO_FITA)


func _desenhar_fita(centro: Vector2, angulo: float) -> void:
	draw_set_transform(centro, angulo)
	draw_texture_rect(FITA, Rect2(-TAMANHO_FITA / 2.0, TAMANHO_FITA), false)
	draw_set_transform(Vector2.ZERO)
