extends MeshInstance3D

func _ready() -> void:
	# 1. Criar o ArrayMesh (o contentor para a nossa malha)
	var arr_mesh = ArrayMesh.new()
	
	# 2. Inicializar a matriz principal que a Godot espera receber
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX) # Reserva espaço para vértices, normais, UVs, etc.
	
	# 3. Definir os pontos no espaço 3D (Vértices)
	var vertices = PackedVector3Array([
		Vector3(0.0, 1.0, 0.0),   # Ponto 0: Topo
		Vector3(1.0, 0.0, 0.0),   # Ponto 1: Canto inferior direito
		Vector3(-1.0, 0.0, 0.0),  # Ponto 2: Canto inferior esquerdo
	])
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	# 4. Definir a orientação da luz (Normais - apontadas para trás/frente)
	var normals = PackedVector3Array([
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, 1.0),
	])
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	# 5. Definir a ordem de leitura dos pontos (Índices)
	# Na Godot, a ordem padrão é o sentido anti-horário (Counter-Clockwise)
	var indices = PackedInt32Array([
		0, 2, 1
	])
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# 6. Construir a superfície a partir dos nossos dados
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# 7. Atribuir a malha gerada a este nó MeshInstance3D
	self.mesh = arr_mesh
	
	# 8. Dar uma cor básica para conseguirmos ver bem no cenário
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.0, 0.0) # Vermelho
	material.cull_mode = BaseMaterial3D.CULL_DISABLED # Permite ver de ambos os lados
	self.material_override = material
