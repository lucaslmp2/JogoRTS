extends CharacterBody3D

enum Estado { PARADO, PASTANDO, FUGINDO, MORTO }
var estado_atual: Estado = Estado.PARADO

@export_category("Configurações do Recurso")
@export var tipo_recurso: String = "comida"
@export var quantidade_recurso: int = Global.comida
@export var vida_animal: float = 30.0 # Vida do animal (precisa de hits para morrer)

@export_category("Movimentação do Animal")
@export var velocidade_passeio: float = 1.5
@export var velocidade_fuga: float = 4.0
@export var raio_visao_fuga: float = 6.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var tempo_proximo_passo: float = 0.0
var alvo_fuga: Node3D = null

func _ready() -> void:
	add_to_group("recursos")
	definir_novo_ponto_passeio()

func _physics_process(delta: float) -> void:
	# Se já estiver morto, ele não se move nem processa IA de fuga
	if estado_atual == Estado.MORTO:
		return

	checar_perigo_ao_redor()

	match estado_atual:
		Estado.PARADO:
			tempo_proximo_passo += delta
			if tempo_proximo_passo >= randf_range(3.0, 7.0):
				definir_novo_ponto_passeio()
				
		Estado.PASTANDO:
			if navigation_agent.is_navigation_finished():
				estado_atual = Estado.PARADO
				tempo_proximo_passo = 0.0
			else:
				mover_animal(velocidade_passeio)
				
		Estado.FUGINDO:
			if alvo_fuga and is_instance_valid(alvo_fuga):
				calcular_rota_de_fuga(alvo_fuga.global_position)
				mover_animal(velocidade_fuga)
				
				if global_position.distance_to(alvo_fuga.global_position) > raio_visao_fuga * 1.5:
					estado_atual = Estado.PARADO
					alvo_fuga = null
			else:
				estado_atual = Estado.PARADO

func mover_animal(velocidade: float) -> void:
	var current_pos = global_position
	var next_path_pos = navigation_agent.get_next_path_position()
	
	# CORREÇÃO: Mude de * velocity para * velocidade
	var nova_velocidade = (next_path_pos - current_pos).normalized() * velocidade
	velocity = nova_velocidade
	
	if velocity.length() > 0.1:
		var look_target = global_position + Vector3(velocity.x, 0, velocity.z)
		look_at(look_target, Vector3.UP)
		
	move_and_slide()

func definir_novo_ponto_passeio() -> void:
	var direcao_aleatoria = Vector3(randf_range(-5.0, 5.0), 0, randf_range(-5.0, 5.0))
	navigation_agent.target_position = global_position + direcao_aleatoria
	estado_atual = Estado.PASTANDO

func checar_perigo_ao_redor() -> void:
	var unidades = get_tree().get_nodes_in_group("unidades_jogador")
	for unidade in unidades:
		if is_instance_valid(unidade):
			var dist = global_position.distance_to(unidade.global_position)
			if dist < raio_visao_fuga:
				alvo_fuga = unidade
				estado_atual = Estado.FUGINDO
				return

func calcular_rota_de_fuga(posicao_inimigo: Vector3) -> void:
	var direcao_oposta = (global_position - posicao_inimigo).normalized()
	navigation_agent.target_position = global_position + (direcao_oposta * 4.0)

# --- SISTEMA DE COMBATE / EXTRAÇÃO ---
func extrair_recurso(quantidade_pedida: int) -> int:
	# 1. SE ESTIVER VIVO: O "hit" tira vida em vez de dar comida
	if estado_atual != Estado.MORTO:
		var dano_recebido = 10.0 # Pode ser baseado no dano da unidade se preferires
		vida_animal -= dano_recebido
		print(name, " recebeu hit! Vida restante: ", vida_animal)
		
		# Ativa a fuga imediata ao tomar um hit
		tempo_proximo_passo = 0.0
		estado_atual = Estado.FUGINDO
		
		if vida_animal <= 0:
			morrer()
			
		return 0 # Retorna 0 comida porque ele ainda não virou carcaça!

	# 2. SE ESTIVER MORTO: Funciona como coleta normal de carcaça estática
	if quantidade_recurso <= 0:
		return 0
		
	var coletado = min(quantidade_pedida, quantidade_recurso)
	quantidade_recurso -= coletado
	print(name, " [CARCAÇA DE COMIDA] restante: ", quantidade_recurso)
	
	if quantidade_recurso <= 0:
		print(name, " foi totalmente coletado!")
		if is_in_group("recursos"):
			remove_from_group("recursos")
		queue_free()
		
	return coletado

func morrer() -> void:
	estado_atual = Estado.MORTO
	velocity = Vector3.ZERO
	print(name, " MORREU! Pronto para coleta de carne.")
	
	# Opcional: Se tiveres uma malha/escala diferente para o animal morto, podes mudar aqui:
	# rotation_degrees.z = 90 # Deita o modelo de lado para simular morte
