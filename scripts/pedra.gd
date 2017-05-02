extends KinematicBody2D

var jogador
var habilitado = true # indica se a pedra esta habilitada para mover
var na_mesa = false    # indica que a pedra ja foi jogada
var is_held
#var ori = 'V' #Orientação da peça (Vertical / Horizontal)
#var area = ''
var elem_1  = ''
var elem_2 = ''
var original_pos_x = 0
var original_pos_y = 0
var labels

func _ready():
	jogador = get_node('..').get_name()
	original_pos_x = get_pos()[0]
	original_pos_y = get_pos()[1]
	set_process(true)

func _process(delta):
	if(habilitado):
		if is_held:
			#print('x: '+str(get_pos()[0]) + '  y: ' + str(get_pos()[1]))
			self.set_global_pos(get_global_mouse_pos())
#	else:
#		self.set_process(false)
#		self.disconnect("input", self, "_on_Area2D_input_event")

func _on_ClickArea2D_input_event( viewport, event, shape_idx ):
	if(habilitado):
		if event.is_action_pressed("left_click"):
			#print('clicou')
			is_held = true
		if event.is_action_released("left_click"):
			#print('soltou')
			is_held = false
			get_node('../../..').posPedra(jogador +'/'+ get_name()) #Table posiciona a pedra

func back_to_original_pos():
	set_pos(Vector2(original_pos_x, original_pos_y))

func setLabels(labels):
	self.labels = labels
	var e = labels.split('|')
	elem_1 = e[0]
	get_node('./frente/TopLabel').set_text(elem_1)
	elem_2 = e[1]
	get_node('./frente/BotLabel').set_text(elem_2)

func flip():
	self.ori = 'H'
	set_rotd(-90)


