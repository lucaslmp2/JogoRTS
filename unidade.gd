extends CharacterBody3D

@export var speed: float = 5.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	# Evita que a unidade tente se mover logo no primeiro frame antes do mapa carregar
	actor_setup.call_deferred()

func actor_setup():
	# Aguarda a sincronização do servidor de navegação da Godot 4
	await Engine.get_main_loop().process_frame
	set_movement_target(global_position)

func _physics_process(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	# Calcula a direção para o próximo ponto da rota
	var new_velocity: Vector3 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized() * speed

	velocity = new_velocity
	move_and_slide()

# Esta função será chamada pela nossa câmera/controlador para mandar a unidade andar
func set_movement_target(movement_target: Vector3) -> void:
	# Correção: Na Godot 4, alteramos a propriedade 'target_position' diretamente
	navigation_agent.target_position = movement_target
