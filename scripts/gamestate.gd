extends Node

# Porta do jogo
const DEFAULT_PORT = 10567
# Numero máximo de jogadores
const MAX_PEERS = 4
# Arquivo com as pedras
const file_jogo = 'res://lista_jogos/pedras_1.txt'
# Número de pedras iniciais na mão
var num_pedras_iniciais = 7
# Pedra que dá início ao jogo
var pedra_inicial = "Acido|Hidreto"

# Name for my player
var player_name = "N"
# Names for remote players in id:name format
var players = {}

# All players including myself
export var all_players = {}
export var players_order = [1]

#lista de pedras
var pedras = [] 

#mãos dos jogadores (id: lista de pedras)
var mao = {}

#guarda quem é o jogador da vez, de quem é o turno
export var vez = ''

#guarda o numero de turnos passados, para identificar o jogo travado
var num_passadas = 0

#nome da label, a esquerda e a direita, na mesa
var left_label = ''
var right_label = ''

var num_pedras_E = 0
var num_pedras_D = 0

# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Callback from SceneTree
func _player_connected(id):
	# This is not used, because _connected_ok is called for clients
	# on success and will do the job.
	pass

# Callback from SceneTree
func _player_disconnected(id):
	if (get_tree().is_network_server()):
		if (has_node("/root/Table")): # Game is in progress
			emit_signal("game_error", "Jogador " + players[id] + " desconectou")
			end_game()
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)
	else:
		rpc_id(1, "_player_disconnected", get_tree().get_network_unique_id())

# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	rpc("register_player", get_tree().get_network_unique_id(), player_name)
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server)
func _server_disconnected():
	emit_signal("game_error", "Servidor deconectado")
	end_game()

# Callback from SceneTree, only for clients (not server)
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

# Lobby management functions
remote func register_player(id, name):
	print("87 register_player, "+str(id)+" "+name)
	if (get_tree().is_network_server()):
		players_order.push_back(id)
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, player_name) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, name) # Send new dude to player
	players[id] = name
	emit_signal("player_list_changed")

remote func unregister_player(id):
	players.erase(id)
	players_order.erase(id)
	emit_signal("player_list_changed")

remote func aviso_log(msg): #função para testes
	get_node('../Table/HUD/log_label').set_text(str(msg))

remote func aviso_log_all(msg): #função para testes
	get_node('../Table/HUD/log_label').set_text(str(msg))
	for p in players.keys():
		rpc_id(p, 'aviso_log', str(msg))

func begin_game():
	assert(get_tree().is_network_server())

	# Call to pre-start game
	for p in players.keys():
		rpc_id(p, "pre_start_game")
	pre_start_game()

remote func pre_start_game():
	print('119 pre_start_game')
	# Change scene
	var table = load("res://cenas/Table.tscn").instance()
	get_tree().get_root().add_child(table)
	get_tree().get_root().get_node('Lobby').hide()
	
	get_all_players()
	print('126 '+str(all_players))
	var player_scene = load("res://cenas/Player.tscn")
	for p_id in all_players:
		var player = player_scene.instance()
		player.set_name(str(p_id))
		
		if(get_tree().is_network_server()):
			player.set_network_mode(NETWORK_MODE_MASTER)
		else:
			player.set_network_mode(NETWORK_MODE_SLAVE)
	
		table.get_node("Players").add_child(player)
#	
#	# Set up HUD
	#for p_id in players_order:
		
#	table.get_node("HUD").add_player(get_tree().get_network_unique_id(), player_name, num_pedras_iniciais)
#	for pn in players.keys():
#		table.get_node("HUD").add_player(pn, players[pn], num_pedras_iniciais)
		
	if (not get_tree().is_network_server()):
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		ler_arquivo_config()
		get_maos_jogadores()
		post_start_game()

sync func draw_score():
	#aviso_log(str(players_order)+ '---' + str(all_players))
	for id in players_order:
		get_node("../Table/HUD").add_player(id, all_players[id], num_pedras_iniciais)

remote func post_start_game():
	get_all_players()
	print("152: "+str(all_players.keys()))
	for i in all_players.keys():
		print(str(i)+ '  ' + str(all_players[i]))
	print("155: "+str(all_players))
	print("156: " +str(players))
	print("157: "+str(vez))
	for p in players.keys():
		get_node('../Table/Players/'+str(p)).esconde_pedras(true)
	if(get_tree().is_network_server()):
		print('172: '+str(players_order))
		rpc('sync_list_players', players_order)
		rpc('draw_score')
	get_tree().set_pause(false) # Unpause and unleash the game!

var players_ready = []

remote func ready_to_start(id):
	assert(get_tree().is_network_server())
	print('169 ready_to_start: '+str(id)+' in '+str(players_ready))
	if (not id in players_ready):
		players_ready.append(id)
	
	if (players_ready.size() == players.size()):
		get_all_players() # recarrega todos jogadores, para listar ter indices unicos
		print('176 '+str(all_players))
		#order_players()
		#rpc('sync_list_players', all_players)
		print('179 '+str(all_players))
		ler_arquivo_config()
		get_maos_jogadores() #sorteia as pedras
		for p in players.keys():
			rpc_id(p, "post_start_game")
		post_start_game()

func get_maos_jogadores():
	for p_id in all_players.keys():
		mao[p_id] = sorteia_pedras()
		if(mao[p_id].find(pedra_inicial) != -1):
			rpc('set_vez', p_id)
#			vez = p_id
	var json = mao.to_json()
	rpc('set_mao', json)
	rpc('habilita_jogador_vez')

#retorna uma mão para um jogador, retirando da lista "pedras"
func sorteia_pedras():
	var retorno = []
	var num_players = players.size()+1
	for p in range(0, num_pedras_iniciais):
		randomize()
		var i = randi()%(num_pedras_iniciais*num_players)
		while(pedras[i] == ''):
			i = randi()%(num_pedras_iniciais*num_players)
		retorno.append( pedras[i] )
		pedras[i] = ''
	return retorno

sync func set_mao(pedras):
	mao.parse_json( pedras )
	#get_node("../Table/HUD/log_label").set_text(str(mao))
	get_node("../Table").inst_maos()

sync func sync_list_players(list):
	players_order = list

sync func set_vez(id):
	vez = id

sync func inc_num_passadas():
	num_passadas = num_passadas + 1

sync func reset_num_passadas():
	num_passadas = 0

sync func set_left_label(label):
	left_label = label
	num_pedras_E = num_pedras_E + 1

sync func set_right_label(label):
	right_label = label
	num_pedras_D = num_pedras_D + 1

sync func habilita_jogador_vez():
	for id in all_players.keys():
		get_node('../Table/Players/'+str(id)).desabilita()
	get_node('../Table/Players/'+str(vez)).habilita()

func host_game(name):
	player_name = name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)

func join_game(ip, name):
	player_name = name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

remote func reset_game():
	print('reset_game')
#	assert(get_tree().is_network_server())
	
	# Todos os jogadores resetam o HUD e a posição de cada pedra
	#reset_HUD_e_pos()
#	for p in players.keys():
#		rpc_id(p, 'reset_HUD_e_pos')
	
	ler_arquivo_config() #recarrega as pedras
	get_maos_jogadores() #novo sorteio das mãos


remote func reset_HUD_e_pos():
	var table = get_node('../Table')
#	table.get_node("HUD").
#	for pn in players:
#		table.get_node("HUD").add_player(pn, players[pn], num_pedras_iniciais)
	table.resetar_posicoes()

func exit_game(name):
	var id = get_tree().get_network_unique_id()
	if (get_tree().is_network_server()):
		end_game()
	else:
		rpc_id(1, "disconnect_player", id)	
		
remote func disconnect_player(id):
	_player_disconnected(id)

func get_all_players():
	all_players[get_tree().get_network_unique_id()] = player_name
	for i in players.keys():
		all_players[i] = players[i]

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func get_player_name_by_id(id):
	if(all_players.keys().find(id) != -1):
		return all_players[int(id)]
	return "<sem valor>"

sync func reset_variables():
	#get_node("/root/Table").queue_free()
	vez = ''
	mao.clear()
	players.clear()
	all_players.clear()
	players_order = [1]
	players_ready = []
	num_passadas = 0
	left_label = ''
	right_label = ''
	num_pedras_E = 0
	num_pedras_D = 0
	print("296: apagou variaveis")

func end_game():
	if (has_node("/root/Table")): # Game is in progress
		# End it
		rpc('reset_variables')
		get_node("/root/Table").queue_free()
	
	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking

#return id of player by his/her name
func get_id(name):
	return list(players.keys())[list(players.values()).index(name)]

# Ler arquivo com as pedras do jogo
func ler_arquivo_config():
	print('318 ler_arquivo_config')
	pedras = []
	var file = File.new()
	file.open(file_jogo,file.READ)
	var line_counter = 0
	while !file.eof_reached():
		pedras.append( file.get_line() )
		line_counter+=1
		if(line_counter == (all_players.size()*num_pedras_iniciais)):
			file.close()
			return
	file.close()

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")