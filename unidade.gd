extends CharacterBody3D

@export var speed: float = 5.0
@export var capacidade_maxima: int = 10
@export var velocidade_coleta: float = 1.0 

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var is_selected: bool = false
var alvo_recurso: StaticBody3D = null
var madeira_carregada: int = 0
var tempo_proxima_coleta: float = 0.0

var indo_para_base: bool = false
# NOVA VARIÁVEL: Diz se a unidade está ativamente sob ordens de colheita
var modo_trabalho: bool = false 

func _ready() -> void:
	actor_setup.call_deferred()

func actor_setup():
	await Engine.get_main_loop().process_frame
	set_movement_target(global_position)

func _physics_process(delta: float) -> void:
	# 1. CHECA ENTREGA: Se estiver cheio e chegar na base, descarrega primeiro
	if madeira_carregada >= capacidade_maxima:
		checar_entrega_na_base()
	
	# 2. ESTADO DE ENTREGA: Se ainda estiver cheio, foca apenas em ir para a base
	if madeira_carregada >= capacidade_maxima:
		if not indo_para_base:
			ir_para_base_mais_proxima()
		mover_unidade()
		return

	# 3. ESTADO DE COLETA: Se tem uma árvore salva e ela ainda é válida
	if alvo_recurso and is_instance_valid(alvo_recurso):
		var distancia = global_position.distance_to(alvo_recurso.global_position)
		if distancia < 2.0:
			processar_coleta(delta)
			return
		else:
			mover_unidade()
			return

	# GATILHO DE CORREÇÃO: Só procura recurso automaticamente se estivesse trabalhando!
	if modo_trabalho and not indo_para_base and (alvo_recurso == null or not is_instance_valid(alvo_recurso)):
		tempo_proxima_coleta = 0.0
		alvo_recurso = null
		procurar_proximo_recurso()
		return

	# 4. MOVIMENTAÇÃO PADRÃO (Cliques normais no chão do mapa / Parado)
	if navigation_agent.is_navigation_finished():
		return
		
	mover_unidade()

func mover_unidade() -> void:
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	var new_velocity: Vector3 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized() * speed

	velocity = new_velocity
	move_and_slide()

func set_movement_target(movement_target: Vector3) -> void:
	navigation_agent.target_position = movement_target

# --- SISTEMA DE SELEÇÃO ---
func select() -> void:
	is_selected = true
	print("Unidade selecionada: ", name)

func deselect() -> void:
	is_selected = false

# --- SISTEMA ECONÔMICO ---
func definir_alvo_coleta(recurso: StaticBody3D) -> void:
	alvo_recurso = recurso
	indo_para_base = false
	modo_trabalho = true # Ativa o modo de trabalho ao coletar
	if madeira_carregada < capacidade_maxima:
		set_movement_target(recurso.global_position)
		print(name, " indo coletar ", recurso.name)
	else:
		ir_para_base_mais_proxima()

func limpar_alvo_coleta() -> void:
	alvo_recurso = null
	indo_para_base = false
	modo_trabalho = false # Desativa se limparmos manualmente o alvo

func processar_coleta(delta: float) -> void:
	if not alvo_recurso or not is_instance_valid(alvo_recurso):
		alvo_recurso = null
		if modo_trabalho: procurar_proximo_recurso()
		return

	tempo_proxima_coleta += delta
	if tempo_proxima_coleta >= velocidade_coleta:
		tempo_proxima_coleta = 0.0
		
		var coletado = alvo_recurso.extrair_recurso(2)
		madeira_carregada += coletado
		print(name, " coletou +", coletado, " de madeira. Estoque atual: ", madeira_carregada)
		
		if not is_instance_valid(alvo_recurso) or ("quantidade_madeira" in alvo_recurso and alvo_recurso.quantidade_madeira <= 0):
			print(name, ": A árvore ", alvo_recurso.name, " foi totalmente esgotada!")
			alvo_recurso = null
			
			if madeira_carregada < capacidade_maxima and modo_trabalho:
				procurar_proximo_recurso()

func ir_para_base_mais_proxima() -> void:
	var bases = get_tree().get_nodes_in_group("bases")
	if bases.size() == 0:
		print(name, ": Nenhuma base encontrada no mapa para descarregar!")
		return
		
	var base_mais_proxima = bases[0]
	var menor_distancia = global_position.distance_to(base_mais_proxima.global_position)
	
	for base in bases:
		var dist = global_position.distance_to(base.global_position)
		if dist < menor_distancia:
			menor_distancia = dist
			base_mais_proxima = base
			
	indo_para_base = true
	set_movement_target(base_mais_proxima.global_position)

func checar_entrega_na_base() -> void:
	var bases = get_tree().get_nodes_in_group("bases")
	for base in bases:
		if global_position.distance_to(base.global_position) < 5.0: 
			if madeira_carregada > 0:
				base.receber_recurso("madeira", madeira_carregada)
				madeira_carregada = 0 
				indo_para_base = false 
				
				if alvo_recurso and is_instance_valid(alvo_recurso):
					set_movement_target(alvo_recurso.global_position)
				else:
					if modo_trabalho:
						alvo_recurso = null
						procurar_proximo_recurso()

func procurar_proximo_recurso() -> void:
	var recursos = get_tree().get_nodes_in_group("recursos")
	if recursos.size() == 0:
		modo_trabalho = false
		print(name, ": Toda a madeira do mapa foi esgotada!")
		return
		
	var recurso_mais_proximo = null
	var menor_distancia = 9999.0
	
	for recurso in recursos:
		if is_instance_valid(recurso):
			var dist = global_position.distance_to(recurso.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				recurso_mais_proximo = recurso
				
	if recurso_mais_proximo:
		definir_alvo_coleta(recurso_mais_proximo)
