extends Control

export var player_labels = {}

func _ready():
	get_node('aviso_box').raise()
	get_node('nome_jogador_label').set_text(gamestate.get('player_name'))
	set_process(true)

func _process(delta):
	var id_vez = gamestate.get('vez')
	get_node('vez/vez_label').set_text(gamestate.get_player_name_by_id(id_vez))
	
	if(gamestate.all_players.keys().size() != 1):
		if(str(id_vez) != str(get_tree().get_network_unique_id())):
			get_node("passar_vez_btn").hide()
		else:
			get_node("passar_vez_btn").show()
		
#	gamestate.aviso_log(gamestate.get('players_order'))

func _on_sair_btn_pressed():
	#get_node('./confirmar_sair').show()
	#get_tree().change_scene("res://cenas/MainMenu.tscn")
	gamestate.end_game()

func _on_passar_vez_btn_pressed():
	get_node('..').passar_vez()

func _on_reset_btn_pressed():
	rpc_id(1, 'reset_game')

func _on_exit_btn_pressed():
	gamestate.end_game()

func add_player(id, name, num_pedras):
	var l = Label.new()
	l.set_align(Label.ALIGN_CENTER)
	l.set_text(name + "\n" + str(num_pedras) +" pedras")
	l.set_h_size_flags(SIZE_EXPAND_FILL)
	var font = DynamicFont.new()
	font.set_size(15)
	font.set_font_data(preload("res://fontes/montserrat.otf"))
	font.set_use_filter(true)
	l.add_font_override("font", font)
	l.add_color_override("font_color", Color(0,0,0))
	#l.set_pos(Vector2(30,20))
	get_node("score").add_child(l)

	player_labels[id] = { name = name, label = l, score = num_pedras }

func sub_point(id):
#	gamestate.aviso_log('sub: '+str(id))
	assert(int(id) in player_labels)
	var pl = player_labels[int(id)]
	pl.score  = pl.score - 1
	pl.label.set_text(pl.name + "\n" + str(pl.score)+ " pedras")

func get_vencedores():
	var player = []
	var menor = gamestate.get('num_pedras_iniciais')
	for i in player_labels.keys():
		if(player_labels[i].score <= menor):
			menor = player_labels[i].score
			player.append(str(player_labels[i].name))
	return player