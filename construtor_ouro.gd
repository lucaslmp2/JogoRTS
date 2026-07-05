@tool
extends Node3D

@export_category("Ação")
@export var exportar_malha_ouro: bool = false : set = _set_exportar_malha

@export_category("Configurações do Ouro")
@export var numero_de_pepitas: int = 5
@export var tamanho_base: float = 1.2
@export var variacao_escala: float = 0.4
@export var espalhamento: float = 0.8

func _set_exportar_malha(valor: bool) -> void:
	if valor:
		gerar_e_salvar_ouro()

func gerar_e_salvar_ouro() -> void:
	print("💰 A iniciar a geração do recurso Ouro Refinado...")
	
	var global_vertices : Array[Vector3] = []
	var global_normals : Array[Vector3] = []
	var global_indices : Array[int] = []
	var global_colors : Array[Color] = [] # Adicionado para variação de cor realista
	
	var vertices_base_pepita : Array[Vector3] = [
		# Topo (0)
		Vector3(0.00, 1.15, 0.00),

		# Anel superior (1 ao 9)
		Vector3(0.55, 0.95, 0.10), Vector3(0.82, 0.82, 0.45), Vector3(0.30, 0.88, 0.78),
		Vector3(-0.35, 0.92, 0.70), Vector3(-0.80, 0.80, 0.30), Vector3(-0.72, 0.88, -0.35),
		Vector3(-0.15, 0.90, -0.82), Vector3(0.48, 0.82, -0.72), Vector3(0.90, 0.82, -0.20),

		# Corpo (10 ao 18)
		Vector3(1.10, 0.40, 0.10), Vector3(0.82, 0.28, 0.88), Vector3(0.15, 0.12, 1.05),
		Vector3(-0.62, 0.22, 0.92), Vector3(-1.02, 0.32, 0.28), Vector3(-0.92, 0.22, -0.62),
		Vector3(-0.25, 0.18, -1.02), Vector3(0.60, 0.26, -0.90), Vector3(1.02, 0.34, -0.42),

		# Base (19 ao 24)
		Vector3(0.70, 0.00, 0.32), Vector3(0.18, 0.00, 0.82), Vector3(-0.55, 0.00, 0.58),
		Vector3(-0.82, 0.00, -0.12), Vector3(-0.32, 0.00, -0.75), Vector3(0.45, 0.00, -0.62)
	]
	
	# Corrigido e completado os triângulos dos anéis (2 triângulos por segmento de quadrilátero)
	var indices_base_pepita : Array[int] = [
		# Topo (Leitura CCW correta)
		0, 1, 2,  0, 2, 3,  0, 3, 4,  0, 4, 5,  0, 5, 6,  0, 6, 7,  0, 7, 8,  0, 8, 9,  0, 9, 1,

		# Corpo superior (Conectando Anel Superior ao Corpo com triangulação dupla)
		1, 10, 2,   10, 11, 2,
		2, 11, 3,   11, 12, 3,
		3, 12, 4,   12, 13, 4,
		4, 13, 5,   13, 14, 5,
		5, 14, 6,   14, 15, 6,
		6, 15, 7,   15, 16, 7,
		7, 16, 8,   16, 17, 8,
		8, 17, 9,   17, 18, 9,
		9, 18, 1,   18, 1, 10,

		# Corpo inferior (Conectando Corpo à Base)
		10, 19, 11,  11, 19, 20,
		11, 20, 12,  12, 20, 21,
		12, 21, 13,  13, 21, 22,
		13, 22, 14,  14, 22, 23,
		14, 23, 15,  15, 23, 24,
		15, 24, 16,  16, 24, 22,
		16, 22, 17,  17, 22, 19,
		17, 19, 18,  18, 19, 10,

		# Base (Fechamento do fundo)
		19, 20, 21,  19, 21, 22,  19, 22, 23,  19, 23, 24
	]
	
	randomize()
	
	for p in range(numero_de_pepitas):
		var id_offset : int = global_vertices.size()
		
		var offset_pos : Vector3 = Vector3.ZERO
		if p > 0:
			offset_pos = Vector3(randf_range(-espalhamento, espalhamento), 0, randf_range(-espalhamento, espalhamento))
			
		var escala_aleatoria : float = tamanho_base + randf_range(-variacao_escala, variacao_escala)
		var rotacao_y : float = randf_range(0.0, TAU)
		
		# Define uma tonalidade de ouro ligeiramente diferente para cada pepita (Realismo)
		var tom_dourado = Color(
			randf_range(0.85, 1.0), # Vermelho
			randf_range(0.65, 0.75), # Verde
			randf_range(0.0, 0.1)    # Azul (Baixo para manter dourado)
		)
		
		for v in vertices_base_pepita:
			var escala = Vector3(
				escala_aleatoria * randf_range(0.8,1.3),
				escala_aleatoria * randf_range(0.7,1.2),
				escala_aleatoria * randf_range(0.8,1.3)
			)
			
			var v_mod = Vector3(
				v.x * escala.x,
				v.y * escala.y,
				v.z * escala.z
			)
			var intensidade = 0.12 * escala_aleatoria
			v_mod += Vector3(
				randfn(0.0, intensidade),
				randfn(0.0, intensidade * 0.5),
				randfn(0.0, intensidade)
			)
			var ruido = Vector3(
			randf_range(-0.12, 0.12),
			randf_range(-0.08, 0.10),
			randf_range(-0.12, 0.12)
			)
			
			v_mod += ruido
			if v.y < 0: v_mod.y = 0 
			
			var v_rot = Vector3(
				v_mod.x * cos(rotacao_y) - v_mod.z * sin(rotacao_y),
				v_mod.y,
				v_mod.x * sin(rotacao_y) + v_mod.z * cos(rotacao_y)
			)
			
			global_vertices.append(v_rot + offset_pos)
			global_colors.append(tom_dourado) # Salva a variação de cor no vértice
		
		for i in indices_base_pepita:
			global_indices.append(id_offset + i)
			
	# Geração Duplicada de Vértices para Efeito Flat Shading Perfeito (Lapidado)
	var flat_vertices : Array[Vector3] = []
	var flat_normals : Array[Vector3] = []
	var flat_colors : Array[Color] = []
	var flat_indices : Array[int] = []
	
	for i in range(0, global_indices.size(), 3):
		var i0 = global_indices[i]
		var i1 = global_indices[i+1]
		var i2 = global_indices[i+2]
		
		var v0 = global_vertices[i0]
		var v1 = global_vertices[i1]
		var v2 = global_vertices[i2]
		
		var normal = (v1 - v0).cross(v2 - v0).normalized()
		
		var current_index = flat_vertices.size()
		flat_vertices.append_array([v0, v1, v2])
		flat_normals.append_array([normal, normal, normal])
		flat_colors.append_array([global_colors[i0], global_colors[i1], global_colors[i2]])
		flat_indices.append_array([current_index, current_index + 1, current_index + 2])

	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(flat_vertices)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(flat_normals)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(flat_indices)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(flat_colors) # Atribui as cores dos vértices
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var caminho_salvamento = "res://recurso_ouro.mesh"
	var erro = ResourceSaver.save(arr_mesh, caminho_salvamento)
	
	if erro == OK:
		print("✅ Ficheiro de Ouro REFINADO guardado com sucesso em: ", caminho_salvamento)
	else:
		print("❌ Erro ao guardar o ficheiro Mesh: ", erro)
