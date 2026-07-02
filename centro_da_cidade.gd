extends StaticBody3D

# Função que será acionada quando o aldeão descarregar aqui
func receber_recurso(tipo: String, quantidade: int) -> void:
	# Por enquanto, printamos no console o ganho global do jogador
	print("📦 [ECONOMIA GLOBAL] ", quantidade, " unidades de ", tipo.to_upper(), " entregues no Centro da Cidade!")
