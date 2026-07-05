extends CharacterBody3D

@export var speed: float = 5.0
@export var capacidade_maxima: int = 10
@export var velocidade_coleta: float = 1.0 

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var alvo_construcao: StaticBody3D = null
var velocidade_construcao: float = 1.0 # Quanto ele avança por segundo
var tempo_proxima_martelada: float = 0.0
var is_selected: bool = false
# Procure por esta linha no topo e altere o tipo:
var alvo_recurso: CollisionObject3D = null # Antes estava StaticBody3D
var tempo_proxima_coleta: float = 0.0

# VARIÁVEIS UNIFICADAS (Funcionam para qualquer tipo de recurso)
var recurso_carregado: int = 0
var tipo_recurso_atual: String = ""

var indo_para_base: bool = false
var modo_trabalho: bool = false 

func _ready() -> void:
	actor_setup.call_deferred()

func actor_setup():
	await Engine.get_main_loop().process_frame
	set_movement_target(global_position)

func _physics_process(delta: float) -> void:
	# Adicione isso dentro do _physics_process(delta) do seu unidade.gd:

	if alvo_construcao and is_instance_valid(alvo_construcao):
		var dist = global_position.distance_to(alvo_construcao.global_position)
		
		# Distância de alcance para martelar (ajuste conforme o tamanho do seu modelo)
		if dist <= 3.0: 
			velocity = Vector3.ZERO # Para de andar
			
			if alvo_construcao.esta_construido:
				# Se o edifício ficou pronto, o aldeão para de trabalhar
				alvo_construcao = null
				print(name, ": Terminei meu trabalho aqui!")
			else:
				# Processa as marteladas por segundo
				tempo_proxima_martelada += delta
				if tempo_proxima_martelada >= 1.0: # A cada 1 segundo
					tempo_proxima_martelada = 0.0
					alvo_construcao.avancar_construcao(velocidade_construcao)
		else:
			# Se estiver longe, continua caminhando até a fundação
			set_movement_target(alvo_construcao.global_position)
	# 1. CHECA ENTREGA: Se estiver cheio e chegar na base, descarrega primeiro
	if recurso_carregado >= capacidade_maxima:
		checar_entrega_na_base()
	
	# 2. ESTADO DE ENTREGA: Se ainda estiver cheio, foca apenas em ir para a base
	if recurso_carregado >= capacidade_maxima:
		if not indo_para_base:
			ir_para_base_mais_proxima()
		mover_unidade()
		return

# 3. ESTADO DE COLETA: Se tem um recurso salvo e ele ainda é válido
	if alvo_recurso and is_instance_valid(alvo_recurso):
		var distancia = global_position.distance_to(alvo_recurso.global_position)
		
		# Se for um animal (comida), podemos dar uma margem de coleta ligeiramente maior (ex: 2.2)
		var limite_distancia = 2.2 if tipo_recurso_atual == "comida" else 2.0
		
		if distancia < limite_distancia:
			processar_coleta(delta)
			# Se o animal parou para ser coletado, paramos a velocidade de navegação
			velocity = Vector3.ZERO 
			return
		else:
			# CORREÇÃO CRUCIAL: Se o alvo se move (animal), atualiza o destino da navegação em tempo real!
			if tipo_recurso_atual == "comida":
				set_movement_target(alvo_recurso.global_position)
				
			mover_unidade()
			return

	# GATILHO DE CORREÇÃO: Só procura recurso automaticamente se estivesse trabalhando e não tiver alvo válido
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
func definir_alvo_coleta(recurso: CollisionObject3D) -> void:
	# TRAVA DE SEGURANÇA: Se o alvo já for exatamente este recurso, não repete a ordem
	if alvo_recurso == recurso and modo_trabalho:
		return

	alvo_recurso = recurso
	indo_para_base = false
	modo_trabalho = true 
	
	# Identifica o tipo do recurso batendo no script dele (ouro ou madeira)
	if "tipo_recurso" in recurso:
		tipo_recurso_atual = recurso.tipo_recurso
	else:
		tipo_recurso_atual = "madeira"
		
	if recurso_carregado < capacidade_maxima:
		set_movement_target(recurso.global_position)
		print(name, " indo coletar ", tipo_recurso_atual, " em ", recurso.name)
	else:
		ir_para_base_mais_proxima()

func limpar_alvo_coleta() -> void:
	alvo_recurso = null
	indo_para_base = false
	modo_trabalho = false 
	tipo_recurso_atual = ""

func processar_coleta(delta: float) -> void:
	if not alvo_recurso or not is_instance_valid(alvo_recurso):
		alvo_recurso = null
		if modo_trabalho: procurar_proximo_recurso()
		return

	tempo_proxima_coleta += delta
	if tempo_proxima_coleta >= velocidade_coleta:
		tempo_proxima_coleta = 0.0
		
		# Tenta extrair/dar hit
		var coletado = alvo_recurso.extrair_recurso(2)
		
		# MODIFICAÇÃO AQUI:
		if coletado <= 0:
			# Se for comida e o alvo ainda tiver vida, significa que a unidade está a caçar (dando hits). NÃO para!
			if tipo_recurso_atual == "comida" and "vida_animal" in alvo_recurso and alvo_recurso.vida_animal > 0:
				print(name, " está atacando o animal...")
				return # Continua atacando no próximo ciclo
			
			# Se não tinha vida (ou era árvore/ouro), aí sim esgotou de verdade
			print(name, ": O recurso em ", alvo_recurso.name, " esgotou!")
			alvo_recurso = null
			if modo_trabalho:
				procurar_proximo_recurso()
			return 
			
		recurso_carregado += coletado
		print(name, " coletou +", coletado, " de ", tipo_recurso_atual, ". Estoque atual: ", recurso_carregado)
		
		# Verificação de segurança caso o recurso acabe exatamente neste golpe
		var esgotado = false
		if "quantidade_recurso" in alvo_recurso and alvo_recurso.quantidade_recurso <= 0:
			esgotado = true
		elif "quantidade_madeira" in alvo_recurso and alvo_recurso.quantidade_madeira <= 0:
			esgotado = true

		if esgotado:
			print(name, ": ", alvo_recurso.name, " foi totalmente esgotado!")
			alvo_recurso = null
			if recurso_carregado < capacidade_maxima and modo_trabalho:
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
			if recurso_carregado > 0:
				# CORREÇÃO: Envia dinamicamente o tipo de recurso correto carregado
				base.receber_recurso(tipo_recurso_atual, recurso_carregado)
				recurso_carregado = 0 
				indo_para_base = false 
				
				# Retorna para o trabalho se o recurso original ainda for válido
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
		alvo_recurso = null
		print(name, ": Todos os recursos do mapa foram esgotados!")
		return
		
	var recurso_mais_proximo = null
	var menor_distancia = 9999.0
	
	for recurso in recursos:
		if is_instance_valid(recurso):
			# SEGURANÇA: Se por acaso o nó no grupo não for um corpo físico clicável, ignora
			if not recurso is CollisionObject3D:
				continue
				
			# Só foca em recursos do MESMO tipo que ela estava coletando antes
			var tipo_desse_recurso = recurso.tipo_recurso if "tipo_recurso" in recurso else "madeira"
			if tipo_recurso_atual != "" and tipo_desse_recurso != tipo_recurso_atual:
				continue
				
			var tem_conteudo = true
			if "quantidade_recurso" in recurso and recurso.quantidade_recurso <= 0:
				tem_conteudo = false
			elif "quantidade_madeira" in recurso and recurso.quantidade_madeira <= 0:
				tem_conteudo = false
				
			if tem_conteudo:
				var dist = global_position.distance_to(recurso.global_position)
				if dist < menor_distancia:
					menor_distancia = dist
					recurso_mais_proximo = recurso
				
	if recurso_mais_proximo and recurso_mais_proximo is CollisionObject3D:
		definir_alvo_coleta(recurso_mais_proximo)
	else:
		modo_trabalho = false
		alvo_recurso = null
		velocity = Vector3.ZERO
		print(name, ": Não há mais recursos válidos disponíveis do tipo ", tipo_recurso_atual)
func definir_alvo_construcao(estrutura: StaticBody3D) -> void:
	# Limpa alvos antigos de coleta para focar na obra
	limpar_alvo_coleta()
	modo_trabalho = false
	
	alvo_construcao = estrutura
	set_movement_target(estrutura.global_position)
	print(name, " indo construir ", estrutura.name)

# Certifique-se de limpar o alvo de construção se mandar o aldeão andar para o chão
func limpar_alvo_construcao() -> void:
	alvo_construcao = null
