extends Node2D

var num_pedras_mao = 2  # número inicial de pedras na mão de cada jogador
var file_jogo = 'res://lista_jogos/pedras_1.txt'
var pedra_inicial
var pedra = []
var num_pedras_E = 0
var num_pedras_D = 0

var fim_jogo_box = preload('res://cenas/fim_jogo.tscn')

var posicoes_E = [[-75,0,1],[-150,0,1],[-225,0,1],
[-300,0,1],[-375,0,1],[-440,-15,0],[-415,-80,-1],
[-340,-80,-1],[-265,-80,-1],[-190,-80,-1],[-115,-80,-1],
[-40,-80,-1],[-25,-145,0],[-90,-160,1],[-165,-160,1],
[-240,-160,1],[-315,-160,1],[-380,-170,0],[-315,-220,-1]
,[-240,-220,-1],[-165,-220,-1]] 

var posicoes_D = [[75,0,1],[150,0,1],[225,0,1],[300,0,1],
[375,0,1],[440,-15,0],[415,-80,-1],[340,-80,-1],[265,-80,-1],
[190,-80,-1],[115,-80,-1],[40,-80,-1],[25,-145,0],[90,-160,1],
[165,-160,1],[240,-160,1],[315,-160,1],[380,-170,0],[315,-220,-1],
[240,-220,-1],[165,-220,-1]] 

var pos_dobras = [5,12,17] #posições que a fileira de pedras dobra

var correspondecias = { 'Acido':['HCN','Hl','H2S','HF','H2CrO4'], 
'Base':['Fe(OH)3','Cr(OH)3','Ba(OH)2','Fe(OH)3','Cr(OH)3'],
'Hidreto':['NH3','CaH2','HCl','H2O','CaH2'],
'Oxido':['SiO2','TiO','P2O3','CrO3','V2O5'],
'Sal':['Na2CO3','FeCl3','NaBrO4','HClO4','NaCl']}

func _ready():
	#gamestate.aviso_log(gamestate.get('player_name'))
	pedra_inicial = gamestate.get('pedra_inicial')
	var fim_jogo_box_i = fim_jogo_box.instance() 
	fim_jogo_box_i.set_name('fim_jogo')
	fim_jogo_box_i.hide();
	get_node('HUD').add_child(fim_jogo_box_i)
	pos_screen()

#posiciona mesa no centro da camera
func pos_screen():
	var projectResolution=Vector2(Globals.get("display/width"),Globals.get("display/height"))
	self.set_pos(Vector2(projectResolution[0]/2-0, projectResolution[1]/2-0))

func inst_maos():
	var mao = gamestate.get('mao')
	for p_id in mao.keys():
		for i in range(0, mao[p_id].size()):
			var pedra = get_node("Players/"+ str(p_id) +"/Pedra"+str(i))
			pedra.setLabels(mao[p_id][i])
	get_node("Players/"+str(get_tree().get_network_unique_id())).show()

sync func esconder_instrucao_label():
	get_node('HUD/instrucao_label').hide()

#Chamado por posPedra após decidir se a pedra se encaixa na mesa
sync func setPosPedra(pedra, area, pos, ang):
	var id_jogador = int(pedra.split('/')[1])
	var pedra_inst = get_node(pedra)
	var top = pedra_inst.get('elem_1')
	var bot = pedra_inst.get('elem_2')
	pedra_inst.show()
	if(area == 'C'):
		pedra_inst.set_pos(Vector2(0,0))
		pedra_inst.set_rotd(90)
	elif(area == 'E'):
		pedra_inst.set_pos(array2V2(posicoes_E[pos]))
		if((pos_dobras.find(pos) != -1) && (correspondecias.keys().find(top) != -1)&&
		(correspondecias.keys().find(bot) != -1)): 
			if(ang == -90):
				pedra_inst.set_rotd(180)
		elif(posicoes_E[pos][2] == 1):
			pedra_inst.set_rotd(ang)
		elif(posicoes_E[pos][2] == -1):
			pedra_inst.set_rotd(-ang)
	elif(area == 'D'):
		pedra_inst.set_pos(array2V2(posicoes_D[pos]))
		if((pos_dobras.find(pos) != -1) && (correspondecias.keys().find(top) != -1)&&
		(correspondecias.keys().find(bot) != -1)): 
			if(ang == 90):
				pedra_inst.set_rotd(180)
		elif(posicoes_D[pos][2] == 1):
			pedra_inst.set_rotd(ang)
		elif(posicoes_D[pos][2] == -1):
			pedra_inst.set_rotd(-ang)
	pedra_inst.set('habilitado', false)
	pedra_inst.set('na_mesa', true)
	pedra_inst.get_node('ClickArea2D/CollisionShape2D').set_trigger(true)
	pedra_inst.get_node('ClickArea2D').hide()
	get_node('HUD').sub_point(id_jogador)
	if(get_node('HUD').player_labels[id_jogador].score == 0):
		var vencedor = gamestate.get('all_players')[id_jogador]
		rpc('show_fim_jogo_box', str(vencedor)+'\nGANHOU!')
	gamestate.rpc('reset_num_passadas')

func posPedra(name):
	var pedra = get_node('Players/'+name)
	var num_pedras_E = int(gamestate.get('num_pedras_E'))-1
	var num_pedras_D = int(gamestate.get('num_pedras_D'))-1
	if(pedra.get('labels') == pedra_inicial):
		gamestate.rpc('set_left_label', pedra_inicial.split('|')[0])
		gamestate.rpc('set_right_label', pedra_inicial.split('|')[1])
		rpc('setPosPedra', 'Players/'+name, 'C', 0, 90)
		rpc('esconder_instrucao_label')
		passar_vez()
	else: 
		var ang = checa_compatibilidade(pedra)
		if (ang != 0 ): #Label bot | top compativel
			if(pedra.get_pos()[0] < 0): #Esquerda
				rpc('setPosPedra', 'Players/'+name, 'E', num_pedras_E, ang)
				#num_pedras_E += 1				
				if(ang<0):
					gamestate.rpc('set_left_label', pedra.get('elem_2') )
				else:
					gamestate.rpc('set_left_label', pedra.get('elem_1') )
			else: #Direita
				rpc('setPosPedra', 'Players/'+name, 'D', num_pedras_D, ang)
				#num_pedras_D += 1
				if(ang<0):
					gamestate.rpc('set_right_label', pedra.get('elem_1') )
				else:
					gamestate.rpc('set_right_label', pedra.get('elem_2') )
			passar_vez()
		else:
			pedra.back_to_original_pos()

func array2V2(array):
	return Vector2(array[0],array[1])

func checa_compatibilidade(pedra):
	var top = pedra.get('elem_1')
	var bot = pedra.get('elem_2')
	var left = gamestate.get('left_label')
	var right = gamestate.get('right_label')
	
	if(pedra.get_pos()[0] < 0): #Esquerda
		if((correspondecias.keys().find(top) != -1)&&
		   (correspondecias.keys().find(bot) != -1)): #verifica se a pedra é bucha
			if(left == top):
				return -90
			elif(left == bot):
				return 90
		elif(correspondecias.keys().find(left) != -1):
			if(correspondecias[left].find(top) != -1):
				return -90
			elif(correspondecias[left].find(bot) != -1):
				return 90
		elif(correspondecias.keys().find(top) != -1):
			if(correspondecias[top].find(left) != -1):
				return -90
		elif(correspondecias.keys().find(bot) != -1):
			if(correspondecias[bot].find(left) != -1):
				return 90
	else: #Direita
		if((correspondecias.keys().find(top) != -1)&&
		   (correspondecias.keys().find(bot) != -1)): #verifica se a pedra é bucha
			if(right == top):
				return 90
			elif(right == bot):
				return -90
		elif(correspondecias.keys().find(right) != -1):
			if(correspondecias[right].find(top) != -1):
				return 90
			elif(correspondecias[right].find(bot) != -1):
				return -90
		elif(correspondecias.keys().find(top) != -1):
			if(correspondecias[top].find(right) != -1):
				return 90
		elif(correspondecias.keys().find(bot) != -1):
			if(correspondecias[bot].find(right) != -1):
				return -90
	return 0

# reseta as posições das pedras
func resetar_posicoes():
	for i in gamestate.get('all_players').keys():
		get_node('Players/'+str(i)).reseta_posicoes()

func passar_vez():
	gamestate.rpc('inc_num_passadas')
	if(gamestate.get('num_passadas') > gamestate.all_players.size()):
		var vencedor = get_node('HUD').get_vencedores()
		if(vencedor.size() == 1):
			rpc('show_fim_jogo_box','Jogo Travado\n'+str(vencedor).replace('[','').replace(']','')+'\nvenceu')
		else:
			rpc('show_fim_jogo_box','Jogo Travado\n'+str(vencedor).replace('[','').replace(']','')+'\nvenceram')
		return
	var vez_atual = gamestate.get('vez')
	var num = gamestate.get('players_order').find(vez_atual)
	var prox = num + 1
	
	#se o numero proximo ultrapassar o limite de jogadores o proximo será o jogador na pos 0
	if(prox >= gamestate.all_players.size()):
		 prox = 0  
	
	var id = gamestate.get('players_order')[prox]

	gamestate.rpc('set_vez', int(id))
	gamestate.rpc('habilita_jogador_vez')

sync func show_fim_jogo_box(msg):
	esconder_jogadores()
	get_node('HUD/fim_jogo/Label').set_text(str(msg))
	get_node('HUD/fim_jogo').show()

func esconder_jogadores():
	for i in gamestate.all_players.keys():
		get_node('Players/'+str(i)).hide()