extends StaticBody3D

@export var quantidade_madeira: int = 100
var tipo_recurso: String = "madeira"

# Função para quando o aldeão coletar
func extrair_recurso(quantidade_pedida: int) -> int:
	if quantidade_madeira <= 0:
		return 0
		
	var coletado = min(quantidade_pedida, quantidade_madeira)
	quantidade_madeira -= coletado
	print(name, " restante: ", quantidade_madeira)
	
	if quantidade_madeira <= 0:
		print(name, " foi completamente esgotada!")
		queue_free() # A árvore some do mapa quando acaba
		
	return coletado
