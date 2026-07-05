@tool
extends Node3D

@export_category("Ações de Exportação")
@export var exportar_arvore_completa: bool = false : set = _set_exportar_arvore
@export var exportar_cepo_apenas: bool = false : set = _set_exportar_cepo

@export_category("Configurações do Tronco")
@export var altura: float = 5.0
@export var raio_base: float = 0.35
@export var segmentos: int = 12
@export var aneis: int = 8

@export_category("Configurações da Copa")
@export var quantidade_folhas: int = 8
@export var raio_copa: float = 1.8

func _set_exportar_arvore(valor: bool) -> void:
	if valor:
		gerar_e_salvar_mesh(false, "res://recurso_arvore.mesh")

func _set_exportar_cepo(valor: bool) -> void:
	if valor:
		gerar_e_salvar_mesh(true, "res://recurso_arvore_cepo.mesh")

func gerar_e_salvar_mesh(apenas_cepo: bool, caminho_salvamento: String) -> void:
	# Se for apenas o cepo, forçamos uma altura baixa e removemos as folhas
	var alt_final = 0.4 if apenas_cepo else altura
	var aneis_finais = 2 if apenas_cepo else aneis
	var qtd_folhas_finais = 0 if apenas_cepo else quantidade_folhas
	
	var global_vertices : Array[Vector3] = []
	var global_indices : Array[int] = []
	var global_colors : Array[Color] = []
	
	var cor_tronco = Color(0.4, 0.25, 0.15)
	var cor_folha = Color(0.15, 0.45, 0.15)

	# 1. Geração da Geometria do Tronco
	for y in range(aneis_finais + 1):
		var t = float(y) / aneis_finais
		# Se for cepo, o raio diminui menos para parecer um corte reto
		var raio_atual = lerpf(raio_base, raio_base * (0.8 if apenas_cepo else 0.18), t)
		var altura_atual = alt_final * t
		
		var desvio_x = sin(altura_atual * 0.7) * 0.2 if not apenas_cepo else 0.0
		var desvio_z = cos(altura_atual) * 0.12 if not apenas_cepo else 0.0
		
		for i in range(segmentos):
			var ang = TAU * i / segmentos
			var ruido = randfn(0.0, 0.01)
			var x = cos(ang) * (raio_atual + ruido) + desvio_x
			var z = sin(ang) * (raio_atual + ruido) + desvio_z
			
			global_vertices.append(Vector3(x, altura_atual, z))
			global_colors.append(cor_tronco)
			
	for y in range(aneis_finais):
		for i in range(segmentos):
			var vert_id_inferior_a = y * segmentos + i
			var vert_id_inferior_b = y * segmentos + ((i + 1) % segmentos)
			var vert_id_superior_a = (y + 1) * segmentos + i
			var vert_id_superior_b = (y + 1) * segmentos + ((i + 1) % segmentos)
			
			global_indices.append_array([vert_id_inferior_a, vert_id_superior_b, vert_id_superior_a])
			global_indices.append_array([vert_id_inferior_a, vert_id_inferior_b, vert_id_superior_b])

	# 2. Geração da Copa (Pulada se for apenas_cepo)
	for f in range(qtd_folhas_finais):
		var centro_esfera = Vector3(randf_range(-raio_copa*0.4, raio_copa*0.4), alt_final - randf_range(0.2, 1.2), randf_range(-raio_copa*0.4, raio_copa*0.4))
		var raio_esfera = randf_range(0.6, raio_copa)
		var id_offset = global_vertices.size()
		var lat_seg = 5
		var lon_seg = 6
		
		for lat in range(lat_seg + 1):
			var theta = lat * PI / lat_seg
			for lon in range(lon_seg):
				var phi = lon * TAU / lon_seg
				var pos = Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)) * raio_esfera
				global_vertices.append(centro_esfera + pos)
				global_colors.append(cor_folha * randf_range(0.9, 1.1))
				
		for lat in range(lat_seg):
			for lon in range(lon_seg):
				var lon_prox = (lon + 1) % lon_seg
				var a = id_offset + (lat * lon_seg + lon)
				var b = id_offset + (lat * lon_seg + lon_prox)
				var c = id_offset + ((lat + 1) * lon_seg + lon)
				var d = id_offset + ((lat + 1) * lon_seg + lon_prox)
				global_indices.append_array([a, d, c])
				global_indices.append_array([a, b, d])

	# 3. Processamento Flat Shading
	var flat_vertices : Array[Vector3] = []
	var flat_normals : Array[Vector3] = []
	var flat_colors : Array[Color] = []
	var flat_indices : Array[int] = []
	
	for i in range(0, global_indices.size(), 3):
		var i0 = global_indices[i]; var i1 = global_indices[i+1]; var i2 = global_indices[i+2]
		var v0 = global_vertices[i0]; var v1 = global_vertices[i1]; var v2 = global_vertices[i2]
		var normal = (v1 - v0).cross(v2 - v0).normalized()
		var idx = flat_vertices.size()
		flat_vertices.append_array([v0, v1, v2])
		flat_normals.append_array([normal, normal, normal])
		flat_colors.append_array([global_colors[i0], global_colors[i1], global_colors[i2]])
		flat_indices.append_array([idx, idx + 1, idx + 2])

	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(flat_vertices)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(flat_normals)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(flat_indices)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(flat_colors)
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	ResourceSaver.save(arr_mesh, caminho_salvamento)
	print("✅ Arquivo gerado em: ", caminho_salvamento)
