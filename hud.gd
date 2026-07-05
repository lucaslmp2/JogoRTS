extends Control

@onready var label_madeira: Label = $PainelTopo/LabelMadeira
@onready var label_ouro: Label = $PainelTopo/LabelOuro
@onready var label_comida: Label = $PainelTopo/LabelComida
@onready var foto_unidade: ColorRect = $PainelRodape/HBox/FotoUnidade

@onready var painel_rodape: PanelContainer = $PainelRodape
@onready var nome_unidade: Label = $PainelRodape/HBox/VBox/NomeUnidade
@onready var vida_unidade: ProgressBar = $PainelRodape/HBox/VBox/VidaUnidade

var unidade_monitorada: CharacterBody3D = null

# --- VARIÁVEIS PARA O RETÂNGULO DE SELEÇÃO ---
var box_start: Vector2 = Vector2.ZERO
var box_end: Vector2 = Vector2.ZERO
var is_drawing_box: bool = false

func _ready() -> void:
	Global.recursos_atualizados.connect(atualizar_contadores_recursos)
	atualizar_contadores_recursos()
	painel_rodape.visible = false

func _process(_delta: float) -> void:
	if unidade_monitorada and is_instance_valid(unidade_monitorada):
		if "vida" in unidade_monitorada:
			vida_unidade.value = unidade_monitorada.vida
	else:
		if painel_rodape.visible:
			painel_rodape.visible = false

func atualizar_contadores_recursos() -> void:
	label_madeira.text = "Madeira: " + str(Global.madeira)
	label_ouro.text = "Ouro: " + str(Global.ouro)
	label_comida.text = "Comida: " + str(Global.comida)

# Substitua no seu hud.gd:

func exibir_detalhes_unidade(unidade: CharacterBody3D, quantidade_total: int) -> void:
	unidade_monitorada = unidade
	
	# Se tiver apenas 1 unidade selecionada, mostra o nome dela normal
	if quantidade_total <= 1:
		nome_unidade.text = unidade.name
		vida_unidade.visible = true # Mostra a barra de vida para uma unidade
	else:
		# Se tiver mais de uma, mostra a contagem agregada!
		nome_unidade.text = "Unidades Selecionadas: " + str(quantidade_total)
		vida_unidade.visible = false # Oculta a barra de vida individual para seleções múltiplas
	
	if "vida_maxima" in unidade:
		vida_unidade.max_value = unidade.vida_maxima
		vida_unidade.value = unidade.vida
	else:
		vida_unidade.max_value = 100
		vida_unidade.value = 100
		
	painel_rodape.visible = true

func esconder_detalhes() -> void:
	unidade_monitorada = null
	painel_rodape.visible = false

# --- SISTEMA DE DESENHO DA CAIXA DE SELEÇÃO ---
func start_box(pos: Vector2) -> void:
	box_start = pos
	box_end = pos
	is_drawing_box = true

func update_box(pos: Vector2) -> void:
	box_end = pos
	queue_redraw() # Força a Godot a rodar a função _draw() a cada frame do arrasto

func end_box() -> void:
	is_drawing_box = false
	queue_redraw() # Limpa o retângulo da tela ao soltar o clique

func _draw() -> void:
	if is_drawing_box:
		# 1. Desenha o preenchimento semi-transparente (Verde bem suave)
		draw_rect(Rect2(box_start, box_end - box_start), Color(0, 1, 0, 0.15), true)
		# 2. Desenha a borda da caixa (Verde mais firme com 2 pixels de espessura)
		draw_rect(Rect2(box_start, box_end - box_start), Color(0, 1, 0, 0.75), false, 2.0)
