extends StaticBody3D

@export_category("Configurações do Recurso")
@export var tipo_recurso: String = "ouro"
@export var quantidade_recurso: int = Global.ouro # Mudado para bater com a checagem da unidade

func _ready() -> void:
	# Garante que o ouro entra no grupo assim que o jogo começa
	add_to_group("recursos")

# Função para quando o aldeão coletar
func extrair_recurso(quantidade_pedida: int) -> int:
	if quantidade_recurso <= 0:
		return 0
		
	var coletado = min(quantidade_pedida, quantidade_recurso)
	quantidade_recurso -= coletado
	print(name, " [OURO] restante: ", quantidade_recurso)
	
	if quantidade_recurso <= 0:
		print(name, " foi completamente esgotado!")
		
		# IMPORTANTE: Remove do grupo antes de sumir para a IA limpar o alvo instantaneamente
		if is_in_group("recursos"):
			remove_from_group("recursos")
			
		queue_free() # O ouro some do mapa quando acaba
		
	return coletado
