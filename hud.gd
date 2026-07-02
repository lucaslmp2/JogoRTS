extends Control

var is_dragging: bool = false
var start_pos: Vector2 = Vector2.ZERO
var current_pos: Vector2 = Vector2.ZERO

var box_color: Color = Color(0, 1, 0, 0.2) # Verde transparente para o fundo
var line_color: Color = Color(0, 1, 0, 0.8) # Verde mais forte para a borda
var line_width: float = 2.0

func _process(_delta: float) -> void:
	# Força a Godot a redesenhar a tela a cada frame se estiver arrastando
	if is_dragging:
		queue_redraw()

func _draw() -> void:
	if is_dragging:
		var rect = Rect2(start_pos, current_pos - start_pos)
		# Desenha o fundo preenchido transparente
		draw_rect(rect, box_color, true)
		# Desenha a borda da caixinha
		draw_rect(rect, line_color, false, line_width)

# Funções para a câmera avisar o HUD quando o mouse está arrastando
func start_box(pos: Vector2) -> void:
	start_pos = pos
	current_pos = pos
	is_dragging = true

func update_box(pos: Vector2) -> void:
	current_pos = pos

func end_box() -> void:
	is_dragging = false
	queue_redraw() # Limpa o desenho da tela
