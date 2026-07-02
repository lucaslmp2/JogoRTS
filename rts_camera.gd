extends Node3D

@export var move_speed: float = 20.0
@export var zoom_speed: float = 5.0
@export var edge_margin: float = 15.0 # Pixels de margem para ativar o movimento do mouse

@onready var camera: Camera3D = $Camera3D

# Limites de Zoom
var min_zoom: float = 5.0
var max_zoom: float = 30.0
var target_zoom: float = 15.0
# Variáveis para a caixa de seleção
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
@onready var hud: Control = $"../CanvasLayer/HUD" # Certifique-se que o caminho até o nó HUD está correto
func _process(delta: float) -> void:
	handle_keyboard_input(delta)
	handle_mouse_edge_input(delta)
	handle_zoom(delta)

# 1. Movimentação por Teclado (WASD / Setas)
func handle_keyboard_input(delta: float) -> void:
	var input_dir := Vector3.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.z += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.z -= 1
		
	input_dir = input_dir.normalized()
	global_translate(input_dir * move_speed * delta)

# 2. Movimentação ao levar o mouse nas bordas da tela
func handle_mouse_edge_input(delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_size := get_viewport().get_visible_rect().size
	var input_dir := Vector3.ZERO
	
	if mouse_pos.x >= screen_size.x - edge_margin:
		input_dir.x += 1
	elif mouse_pos.x <= edge_margin:
		input_dir.x -= 1
		
	if mouse_pos.y >= screen_size.y - edge_margin:
		input_dir.z += 1
	elif mouse_pos.y <= edge_margin:
		input_dir.z -= 1
		
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		global_translate(input_dir * move_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Controle de Zoom existente
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = max(min_zoom, target_zoom - zoom_speed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = min(max_zoom, target_zoom + zoom_speed)
# Clique com o Botão Direito para MOVER (Apenas as selecionadas!)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var target_position = get_mouse_3d_position()
			if target_position != Vector3.ZERO:
				for unidade in get_tree().get_nodes_in_group("unidades_jogador"):
					# Checa se a propriedade existe E se a unidade está marcada como selecionada
					if "is_selected" in unidade and unidade.is_selected:
						unidade.set_movement_target(target_position)
		# Clique com o Botão Esquerdo para SELECIONAR (Arrastar)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_start = event.position
				hud.start_box(drag_start)
			else:
				dragging = false
				hud.end_box()
				select_units_in_box(drag_start, event.position)

	if event is InputEventMouseMotion and dragging:
		hud.update_box(event.position)

# Função mágica que descobre quem está dentro do retângulo arrastado
func select_units_in_box(start: Vector2, end: Vector2) -> void:
	# Se o clique foi muito rápido (um clique simples), define uma área mínima
	if start.distance_to(end) < 5:
		end = start + Vector2(5, 5)
		start = start - Vector2(5, 5)
		
	var box = Rect2(start, end - start).abs()
	
	# Passa por todas as unidades do mapa e checa se a posição de tela delas está no retângulo
	for unidade in get_tree().get_nodes_in_group("unidades_jogador"):
		var screen_pos = camera.unproject_position(unidade.global_position)
		
		if box.has_point(screen_pos):
			unidade.select()
		else:
			# Se clicou fora ou arrastou fora, limpa a seleção anterior
			if not Input.is_key_pressed(KEY_SHIFT): # Segurar SHIFT permite somar seleções
				unidade.deselect()
# 4. Suavização do Zoom
func handle_zoom(delta: float) -> void:
	camera.position.y = lerp(camera.position.y, target_zoom, 10.0 * delta)
	camera.position.z = lerp(camera.position.z, target_zoom, 10.0 * delta)
	
	var angle = remap(camera.position.y, min_zoom, max_zoom, -35.0, -60.0)
	camera.rotation_degrees.x = lerp(camera.rotation_degrees.x, angle, 10.0 * delta)

# 5. Função auxiliar de Raycasting para pegar a posição do mouse no cenário 3D
func get_mouse_3d_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 2000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
	return Vector3.ZERO
