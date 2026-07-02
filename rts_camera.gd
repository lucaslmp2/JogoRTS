extends Node3D

@export var move_speed: float = 20.0
@export var zoom_speed: float = 5.0
@export var edge_margin: float = 15.0 # Pixels de margem para ativar o movimento do mouse

@onready var camera: Camera3D = $Camera3D

# Limites de Zoom
var min_zoom: float = 5.0
var max_zoom: float = 30.0
var target_zoom: float = 15.0

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

# 3. Controle de Zoom (Roda do Mouse)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = max(min_zoom, target_zoom - zoom_speed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = min(max_zoom, target_zoom + zoom_speed)

func handle_zoom(delta: float) -> void:
	# Suaviza o zoom alterando a altura (Y) e a distância (Z) da câmera em relação ao pivot
	camera.position.y = lerp(camera.position.y, target_zoom, 10.0 * delta)
	camera.position.z = lerp(camera.position.z, target_zoom, 10.0 * delta)
	
	# Dinâmica de ângulo: Quanto mais perto, mais inclinada para ver os detalhes. 
	# Quanto mais longe, mais vertical para ver o campo de batalha.
	var angle = remap(camera.position.y, min_zoom, max_zoom, -35.0, -60.0)
	camera.rotation_degrees.x = lerp(camera.rotation_degrees.x, angle, 10.0 * delta)
