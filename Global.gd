extends Node

# Recursos Globais do Jogador
var madeira: int = 500:
	set(valor):
		madeira = valor
		emit_signal("recursos_atualizados")

var ouro: int = 500:
	set(valor):
		ouro = valor
		emit_signal("recursos_atualizados")

var comida: int = 500:
	set(valor):
		comida = valor
		emit_signal("recursos_atualizados")

signal recursos_atualizados
