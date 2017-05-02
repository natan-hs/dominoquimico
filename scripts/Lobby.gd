extends Control

var my_ip

func _ready():
	my_ip = get_my_ip()
	get_node('PanelConnect/PanelCriarSala/NomeJogadorInput').set_text('Jogador')
	#get_node('PanelConnect/PanelEntrarSala/IpSalaInput').set_text('192.168.3.102')
	get_node('PanelConnect/PanelEntrarSala/IpSalaInput').set_text(get_my_ip())#'127.0.0.1')
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")

func _on_voltar_MainMenuBtn_pressed():
	get_tree().change_scene("res://cenas/MainMenu.tscn")

func _on_voltar_PanelConnectBtn_pressed():
	var name = get_node("PanelConnect/PanelCriarSala/NomeJogadorInput").get_text()
	gamestate.exit_game(name)
	get_node("PanelConnect").show()
	get_node("PanelEspera").hide()
	get_node("PanelConnect/PanelCriarSala/CriarSalaBtn").set_disabled(false)
	get_node("PanelConnect/PanelEntrarSala/EntrarSalaBtn").set_disabled(false)

func _on_CriarSalaBtn_pressed():
	if (get_node("PanelConnect/PanelCriarSala/NomeJogadorInput").get_text() == ""):
		get_node("PanelConnect/statusLabel").set_text("Insira um nome para jogar")
		return
	get_node("PanelConnect").hide()
	get_node("PanelEspera").show()
	get_node("PanelEspera/ip_sala_label").set_text("IP da sala: " + my_ip)
	get_node("PanelConnect/statusLabel").set_text("")

	var name = get_node("PanelConnect/PanelCriarSala/NomeJogadorInput").get_text()
	gamestate.host_game(name)
	refresh_lobby()

func _on_iniciarBtn_pressed():
	gamestate.begin_game()

func _on_EntrarSalaBtn_pressed():
	var ip = get_node("PanelConnect/PanelEntrarSala/IpSalaInput").get_text()
	get_node("PanelConnect/statusLabel").set_text("")
#	get_node("PanelConnect/PanelCriarSala/CriarSalaBtn").set_disabled(true)
#	get_node("PanelConnect/PanelEntrarSala/EntrarSalaBtn").set_disabled(true)
	
	var name = get_node("PanelConnect/PanelCriarSala/NomeJogadorInput").get_text()
	gamestate.join_game(ip, name)
	get_node("PanelEspera/ip_sala_label").set_text("IP da sala: " + ip)
	# refresh_lobby() gets called by the player_list_changed signal

func _on_connection_failed():
	get_node("PanelConnect/PanelCriarSala/CriarSalaBtn").set_disabled(false)
	get_node("PanelConnect/PanelEntrarSala/EntrarSalaBtn").set_disabled(false)
	get_node("PanelConnect/statusLabel").set_text("Falha ao conectar.")

func _on_connection_success():
	get_node("PanelConnect").hide()
	get_node("PanelEspera").show()
	
func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	get_node("PanelEspera/ListaJogadores").clear()
	get_node("PanelEspera/ListaJogadores").add_item(gamestate.get_player_name())# + " (Você)")
	for p in players:
		get_node("PanelEspera/ListaJogadores").add_item(p)
	get_node("PanelEspera/iniciarBtn").set_disabled(not get_tree().is_network_server())
	if(not get_tree().is_network_server()):
		get_node("PanelEspera/iniciarBtn").hide()
	else:
		get_node("PanelEspera/iniciarBtn").show()

func _on_game_ended():
	show()
	get_node("PanelConnect").show()
	get_node("PanelEspera").hide()
	get_node("PanelConnect/PanelCriarSala/CriarSalaBtn").set_disabled(false)
	get_node("PanelConnect/PanelEntrarSala/EntrarSalaBtn").set_disabled(false)
#	get_tree().quit() #PARA TESTE

func _on_game_error(errtxt):
	get_node("erroBox").set_text(errtxt)
	get_node("erroBox").popup_centered_minsize()

func get_my_ip():
	var ipsaux = IP.get_local_addresses()
	var ips = []
	for nip in range(0, ipsaux.size()):
		if(nip%2 != 0):
			ips.append(ipsaux[nip])
	return ips[ips.size()-2]