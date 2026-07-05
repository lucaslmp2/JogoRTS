extends Node3D

@export var move_speed: float = 20.0
@export var zoom_speed: float = 5.0
@export var edge_margin: float = 15.0 # Pixels de margem para ativar o movimento do mouse
@export var cena_construcao: PackedScene # Arrasta a cena construcao.tscn aqui no Inspetor
var fantasma_atual: Node3D = null
var modo_construcao_ativo: bool = false
@onready var camera: Camera3D = $Camera3D

# CORREÇÃO: Usando acesso por Nome Único (%) para evitar erros de nó não encontrado
@onready var hud: Control = %HUD 

# Limites de Zoom
var min_zoom: float = 5.0
var max_zoom: float = 30.0
var target_zoom: float = 15.0

# Variáveis para a caixa de seleção
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	handle_keyboard_input(delta)
	handle_mouse_edge_input(delta)
	handle_zoom(delta)
	
	# Se estiver posicionando uma estrutura, faz o fantasma seguir o mouse
	if modo_construcao_ativo and is_instance_valid(fantasma_atual):
		var pos_3d = get_mouse_3d_position()
		if pos_3d != Vector3.ZERO:
			fantasma_atual.global_position = pos_3d

func _unhandled_input(event: InputEvent) -> void:
	# Atalho temporário: Aperta "B" para entrar no modo de construção
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		iniciar_modo_construcao()

	# 1. TRATA APENAS EVENTOS DE CLIQUES E BOTÕES DO MOUSE
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = max(min_zoom, target_zoom - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = min(max_zoom, target_zoom + zoom_speed)
	
		# Clique com o Botão Esquerdo (Substitua esse bloco no rts_camera.gd)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if modo_construcao_ativo:
				if event.pressed:
					confirmar_posicionamento_construcao()
				return 
				
			if event.pressed:
				dragging = true
				drag_start = event.position
				if hud and hud.has_method("start_box"): 
					hud.start_box(drag_start)
			else:
				dragging = false
				if hud and hud.has_method("end_box"): 
					hud.end_box()
				
				# CHECAGEM DE CLIQUE ÚNICO: Se a distância arrastada for mínima, foi um clique simples
				if drag_start.distance_to(event.position) < 5.0:
					selecionar_por_clique_unico(event.position)
				else:
					# Se arrastou, calcula a caixa normalmente
					select_units_in_box(drag_start, event.position)

		# Clique com o Botão DIREITO
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if modo_construcao_ativo:
				cancelar_modo_construcao()
				return
				
			var pos_3d = get_mouse_3d_position()
			var space_state = get_world_3d().direct_space_state
			var current_mouse_pos = get_viewport().get_mouse_position()
			var ray_origin = camera.project_ray_origin(current_mouse_pos)
			var ray_end = ray_origin + camera.project_ray_normal(current_mouse_pos) * 2000.0
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			var result = space_state.intersect_ray(query)
			
			if result:
				var objeto_clicado = result.collider
				var ponto_clicado = result.position
				
				for unidade in get_tree().get_nodes_in_group("unidades_jogador"):
					if "is_selected" in unidade and unidade.is_selected:
						if objeto_clicado.is_in_group("construcoes") and "esta_construido" in objeto_clicado and not objeto_clicado.esta_construido:
							if unidade.has_method("definir_alvo_construcao"):
								unidade.definir_alvo_construcao(objeto_clicado)
						elif objeto_clicado.is_in_group("recursos"):
							if unidade.has_method("definir_alvo_coleta"): unidade.definir_alvo_coleta(objeto_clicado)
						else:
							if unidade.has_method("limpar_alvo_coleta"): unidade.limpar_alvo_coleta()
							if "modo_trabalho" in unidade: unidade.modo_trabalho = false
							unidade.set_movement_target(ponto_clicado)

	# 2. ADICIONE ESTE BLOCO DE VOLTA: Trata a movimentação do mouse para arrastar o retângulo
	elif event is InputEventMouseMotion:
		if dragging and not modo_construcao_ativo:
			if hud and hud.has_method("update_box"):
				hud.update_box(event.position)

# --- FUNÇÕES AUXILIARES DO SISTEMA DE CONSTRUÇÃO ---
func iniciar_modo_construcao() -> void:
	if modo_construcao_ativo: return
	
	# Criamos uma instância temporária apenas para checar o custo antes de instanciar de verdade
	var temp_inst = cena_construcao.instantiate()
	if Global.madeira < temp_inst.custo_madeira or Global.ouro < temp_inst.custo_ouro:
		print("❌ Recursos insuficientes para construir ", temp_inst.nome_edificio)
		temp_inst.queue_free()
		return
		
	fantasma_atual = temp_inst
	get_tree().root.add_child(fantasma_atual) # Adiciona temporariamente ao mundo
	fantasma_atual.ativar_modo_fantasma()
	modo_construcao_ativo = true
	print("🔨 Modo Construção Ativo! Clique no chão para posicionar.")

func confirmar_posicionamento_construcao() -> void:
	if not is_instance_valid(fantasma_atual): return
	
	# Cobra os recursos do jogador de forma definitiva
	Global.madeira -= fantasma_atual.custo_madeira
	Global.ouro -= fantasma_atual.custo_ouro
	
	fantasma_atual.implantar_no_chao()
	
	# Manda os aldeões que estavam selecionados irem trabalhar nela automaticamente!
	for unidade in get_tree().get_nodes_in_group("unidades_jogador"):
		if "is_selected" in unidade and unidade.is_selected:
			if unidade.has_method("definir_alvo_construcao"):
				unidade.definir_alvo_construcao(fantasma_atual)
				
	# Limpa as variáveis da câmera para o jogador poder criar novas estruturas depois
	fantasma_atual = null
	modo_construcao_ativo = false

func cancelar_modo_construcao() -> void:
	if is_instance_valid(fantasma_atual):
		fantasma_atual.queue_free()
	fantasma_atual = null
	modo_construcao_ativo = false
	print("❌ Construção cancelada.")

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


# Função para descobrir quem está dentro do retângulo arrastado
func select_units_in_box(start: Vector2, end: Vector2) -> void:
	if start.distance_to(end) < 5:
		end = start + Vector2(5, 5)
		start = start - Vector2(5, 5)
		
	var box = Rect2(start, end - start).abs()
	var primeira_selecionada: CharacterBody3D = null
	var contagem_selecionadas: int = 0
	
	for unidade in get_tree().get_nodes_in_group("unidades_jogador"):
		var screen_pos = camera.unproject_position(unidade.global_position)
		
		if box.has_point(screen_pos):
			unidade.select()
			contagem_selecionadas += 1
			if primeira_selecionada == null:
				primeira_selecionada = unidade
		else:
			if not Input.is_key_pressed(KEY_SHIFT):
				unidade.deselect()

	# Se houver unidades ativas na árvore (caso o shift esteja acumulando)
	# Vamos contar todas que estão marcadas como selecionadas no grupo de verdade
	var total_geral = 0
	for u in get_tree().get_nodes_in_group("unidades_jogador"):
		if "is_selected" in u and u.is_selected:
			total_geral += 1

	# --- INTEGRADO COM A HUD ATUALIZADA ---
	if primeira_selecionada and is_instance_valid(primeira_selecionada):
		if hud and hud.has_method("exibir_detalhes_unidade"):
			# Passamos a primeira unidade e a contagem total de selecionadas
			hud.exibir_detalhes_unidade(primeira_selecionada, total_geral)
	else:
		if not Input.is_key_pressed(KEY_SHIFT):
			if hud and hud.has_method("esconder_detalhes"):
				hud.esconder_detalhes()

# Suavização do Zoom
func handle_zoom(delta: float) -> void:
	camera.position.y = lerp(camera.position.y, target_zoom, 10.0 * delta)
	camera.position.z = lerp(camera.position.z, target_zoom, 10.0 * delta)
	
	var angle = remap(camera.position.y, min_zoom, max_zoom, -35.0, -60.0)
	camera.rotation_degrees.x = lerp(camera.rotation_degrees.x, angle, 10.0 * delta)

# Função auxiliar de Raycasting para pegar a posição do mouse no cenário 3D
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
func selecionar_por_clique_unico(mouse_pos: Vector2) -> void:
	# Limpa seleções antigas a menos que Shift esteja pressionado
	if not Input.is_key_pressed(KEY_SHIFT):
		for u in get_tree().get_nodes_in_group("unidades_jogador"):
			u.deselect()

	# Lança um raio para detectar colisões com unidades no cenário 3D
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 2000.0
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		var objeto_clicado = result.collider
		if objeto_clicado.is_in_group("unidades_jogador"):
			objeto_clicado.select()
			if hud and hud.has_method("exibir_detalhes_unidade"):
				hud.exibir_detalhes_unidade(objeto_clicado, 1)
			return

	# Se clicou no chão vazio, esconde os detalhes da HUD
	if not Input.is_key_pressed(KEY_SHIFT):
		if hud and hud.has_method("esconder_detalhes"):
			hud.esconder_detalhes()
