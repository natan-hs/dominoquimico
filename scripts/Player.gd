extends Node2D

#var num_pedras

func set_pedras(pedras):
	for i in range(0, pedras.size()):
		get_node('Pedra'+str(i)).setLabels(str(pedras[i]))

func habilita():
	for i in range(0, gamestate.get('num_pedras_iniciais')):
		get_node('Pedra'+str(i)).set('habilitado', true)

func desabilita():
	for i in range(0, gamestate.get('num_pedras_iniciais')):
		get_node('Pedra'+str(i)).set('habilitado', false)

func esconde_pedras(esconder):
	var num_pedras = gamestate.get('num_pedras_iniciais')
	if(esconder):
		for i in range(0, num_pedras):
			get_node('Pedra'+str(i)).hide()
	else:
		for i in range(0, num_pedras):
			get_node('Pedra'+str(i)).show()

func reseta_posicoes():
	for i in range(0, gamestate.get('num_pedras_iniciais')):
		get_node('Pedra'+str(i)).back_to_original_pos()