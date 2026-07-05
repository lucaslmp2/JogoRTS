extends StaticBody3D

@export var nome_edificio: String = "Quartel"
@export var custo_madeira: int = 150
@export var custo_ouro: int = 50
@export var tempo_construcao_total: float = 10.0 # Segundos para terminar

var progresso_atual: float = 0.0
var esta_construido: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# Materiais para o efeito "Fantasma" e "Normal"
var material_fantasma: StandardMaterial3D
var material_normal: StandardMaterial3D

func _ready() -> void:
	# Cria dinamicamente um material translúcido verde para o modo fantasma
	material_fantasma = StandardMaterial3D.new()
	material_fantasma.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	material_fantasma.albedo_color = Color(0, 1, 0, 0.4) # Verde transparente
	
	# Guarda o material original do modelo
	if mesh_instance.mesh.get_surface_count() > 0:
		material_normal = mesh_instance.get_active_material(0)

func ativar_modo_fantasma() -> void:
	collision_shape.disabled = true
	mesh_instance.set_surface_override_material(0, material_fantasma)
	if has_node("NavigationObstacle3D"):
		$NavigationObstacle3D.affect_navigation_mesh = false

func implantar_no_chao() -> void:
	# O jogador clicou, o edifício fixa no local mas começa com progresso 0
	mesh_instance.set_surface_override_material(0, material_fantasma)
	# Muda a cor para algo que indique que está pendente (ex: amarelo ou azul translúcido)
	material_fantasma.albedo_color = Color(1, 0.8, 0, 0.4) 

func avancar_construcao(quantidade: float) -> void:
	if esta_construido: return
	
	progresso_atual += quantidade
	print(name, " - Progresso: ", int((progresso_atual / tempo_construcao_total) * 100), "%")
	
	if progresso_atual >= tempo_construcao_total:
		finalizar_construcao()

func finalizar_construcao() -> void:
	esta_construido = true
	collision_shape.disabled = false # Devolve a colisão física normal
	mesh_instance.set_surface_override_material(0, material_normal) # Textura original
	
	# Se você adicionou o nó NavigationObstacle3D, ative-o aqui:
	if has_node("NavigationObstacle3D"):
		$NavigationObstacle3D.affect_navigation_mesh = true
		
	print("🎉 ", nome_edificio, " construído com sucesso! Caminho bloqueado.")
