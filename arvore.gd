extends StaticBody3D

@export_category("Configurações do Recurso")
@export var tipo_recurso: String = "madeira"
@export var quantidade_recurso: int = Global.madeira

# Pré-carrega a malha do cepo gerada pelo construtor
var malha_cepo = preload("res://recurso_arvore_cepo.mesh")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	add_to_group("recursos")

func extrair_recurso(quantidade_pedida: int) -> int:
	if quantidade_recurso <= 0:
		return 0

	var quantidade_coletada = min(quantidade_pedida, quantidade_recurso)
	quantidade_recurso -= quantidade_coletada
	
	print(name, " [MADEIRA] restante: ", quantidade_recurso)
	
	# Quando a madeira esgota, a árvore "perde a forma" e vira um toco estático
	if quantidade_recurso <= 0:
		transformar_em_cepo()
		
	return quantidade_coletada

func transformar_em_cepo() -> void:
	print(name, " foi completamente cortada. Substituindo por malha de cepo.")
	
	# 1. Troca o visual para o toco residual curto
	if mesh_instance:
		mesh_instance.mesh = malha_cepo
		
	# 2. Desativa as colisões para evitar que as unidades colidam ou cliquem nele
	if collision_shape:
		collision_shape.disabled = true
		
	# 3. Remove do grupo de recursos para a IA ignorar este nó de agora em diante
	if is_in_group("recursos"):
		remove_from_group("recursos")
