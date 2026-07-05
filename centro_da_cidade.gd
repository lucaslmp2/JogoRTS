extends StaticBody3D

# Função que será acionada quando o aldeão descarregar aqui
func receber_recurso(tipo: String, quantidade: int) -> void:
	# 1. Checa qual é o tipo de recurso e SOMA (+=) ao estoque global correto
	match tipo.to_lower():
		"comida":
			Global.comida += quantidade
		"madeira":
			Global.madeira += quantidade
		"ouro":
			Global.ouro += quantidade
		_:
			print("⚠️ Tipo de recurso desconhecido recebido: ", tipo)
			return

	# 2. Printa o feedback correto no console
	print("📦 [CENTRO DA CIDADE] Recebeu +", quantidade, " de ", tipo.to_upper())
