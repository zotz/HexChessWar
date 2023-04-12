extends Node2D

# Game.gd ?

var game_debug = true
onready var gs = $"../Game"
onready var tilemap = $"../Game/TileMap"
onready var batrep = $"../Game/HUD"

var range_of_movement = Array()

var turn = "white"
var turn_history = {}
var current_turn_index = 0

var clickable = true

var active_piece
var apiece
var dpiece

var player_colors

var game_type_node
var is_multiplayer

var whitescore = '0'
var blackscore = '0'
var attackwins = '0'
var defendwins = "0"
var whitewins = "0"
var blackwins = "0"
var incrsc
var warresult
var warresultl2 = "AttackWins"
var battlechance
var l1_battlechancediv
#var zattackwon = true
var attack1
var attack1type
var defend1
var defend1type
var luck
var battlecount = 0


onready var config = get_node('/root/PlayersData').call_config()
onready var war_level = get_node('/root/PlayersData').war_level
onready var rng = get_node('/root/PlayersData').get_rng()
#onready var l1_battlechancediv = get_node('/root/PlayersData').l1_battlechancediv


signal promotion_done

func _ready():
	rng.randomize()
	$TileMap.draw_map()
	$TileMap.visible = true
	#if war_level == "Level2":
	#	$'../Game/HUD/GameStats/VBoxContainer/HBCWhiteScore'.visible = true
	#	$'../Game/HUD/GameStats/VBoxContainer/HBCBlackScore'.visible = true
	#	$'../Game/HUD/GameStats/VBoxContainer/HBCWhiteWins'.visible = true
	#	$'../Game/HUD/GameStats/VBoxContainer/HBCBlackWins'.visible = true
	#	$'../Game/HUD/GameStats/VBoxContainer/HBCAttackWins'.visible = true
	#	$'../Game/HUD/GameStats/VBoxContainer/HBCDefendWins'.visible = true
	
	$Camera2D.set_global_position(Vector2(50, 0))
	
	if get_tree().has_network_peer ():
		game_type_node = $"../Multiplayer"
		is_multiplayer = true
	else:
		game_type_node = $"../Singleplayer"
	
	set_player_colors()
	game_type_node.prepare_game()
	
# warning-ignore:return_value_discarded
	$'../Game/HUD/EndGame/TryAgain'.connect('pressed', game_type_node, '_on_TryAgain_pressed')
# warning-ignore:return_value_discarded
	$'../Game/HUD/EndGame/Exit'.connect('pressed', game_type_node, '_on_Exit_pressed')
	
	for button in $HUD/PromotionBox.get_children():
		button.connect('pressed', self, '_on_Promotion_pressed', [button.text])

func append_turn_history():
	var coord_dictionary = {}
	var jumped_over_copy = {}
	
	for piece in $TileMap.chessmen_list.duplicate():
		coord_dictionary[piece.tile_position]=[piece.type, piece.color]
	
	for tile in $TileMap.jumped_over_tiles:
		jumped_over_copy[tile] = $TileMap.jumped_over_tiles[tile].tile_position
		
	turn_history[current_turn_index] = [turn, coord_dictionary, jumped_over_copy, $TileMap.fifty_moves_counter]

func adjust_turn_history():
	var to_clean = turn_history.keys().slice(current_turn_index+1, -1)
	
	for key in to_clean:
		turn_history.erase(key)

func set_player_colors():
	if is_multiplayer:
		if get_tree().is_network_server():
			player_colors = [get_node('/root/PlayersData').master_color]
		else:
			player_colors = [get_node('/root/PlayersData').puppet_color]
	else:	
		player_colors = get_node('/root/PlayersData').colors
	
func get_attack_color():
		return turn

func get_defend_color():
	var d_color
	if turn == 'white':
		d_color = 'black'
	else:
		d_color = 'white'
	return d_color
	
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if game_debug: print("A - InputEventMouseButton just happened")
		if event.pressed and clickable and turn in player_colors:
			if game_debug: print("B - this is event.pressed and clickable and turn in player_colors")
			var clicked_cell = $TileMap.world_to_map(get_global_mouse_position())
			if game_debug: print("C - clicked cell set to: ", clicked_cell)
			
			if clicked_cell in range_of_movement:
				if game_debug: print("D - clicked_cell is in range_of_movement")
				range_of_movement = []
				
				if game_debug: print("E - calling player_turn")
				player_turn(clicked_cell)
				if game_debug: print("F - back from player_turn")
				
				var promotion_piece
				if 'Pawn' == active_piece.type and clicked_cell in $TileMap.promotion_tiles:
					$HUD/PromotionBox.visible = true
					$HUD/PromotionBox/Queen.grab_focus()
					clickable = false
					$HUD/MenuBox.visible = false
					promotion_piece = yield(self, "promotion_done")
					
				change_turns()
				# I think this below was drew's doing and needs to be changed for hte new BattleReport popup panel
				# will the try below work?
				if turn =='white':
					$'../Game/HUD/GameStats/VBoxContainer/HBCTurn/Turn'.text = 'White'
					$HUD/BattleReport/HUD/BTGameStats/VBoxContainer/HBCTurn/Turn.text = 'White'
				else:
					#$'../Game/HUD/GameStats/VBoxContainer/HBCTurn/Turn'.text = 'Black'
					$HUD/BattleReport/HUD/BTGameStats/VBoxContainer/HBCTurn/Turn.text = 'Black'
				
				if is_multiplayer:
					game_type_node.sync_multiplayer(clicked_cell)
					
					if promotion_piece:
						game_type_node.rpc("sync_promotion", promotion_piece)
				
				check_for_game_over()
				
			elif clicked_cell in $TileMap.chessmen_coords:
				if game_debug: print("Is this where we first click on a piece to move?")
				var piece = $TileMap.chessmen_coords[clicked_cell]
				if piece.tile_position == clicked_cell and piece.color == turn:
					$TileMap.draw_map()
					active_piece = piece
					set_possible_moves()

func update_stats_display():
	$HUD/BattleReport/HUD/BTGameStats.show()
	# white score
	$HUD/BattleReport/HUD/BTGameStats/VBoxContainer/HBCWhiteScore/WhtScoreNum.text = whitescore
	#$c/BattleReport/HUD/BTGameStats/VBoxContainer/HBCWhiteScore/WhtScoreNum.text = whitescore
	# black score
	$HUD/BattleReport/HUD/BTGameStats/VBoxContainer/HBCBlackScore/BlkScoreNum.text = blackscore
	#$c/BattleReport/HUD/BTGameStats/VBoxContainer/HBCBlackScore/BlkScoreNum.text = blackscore
	# white wins
	$HUD/BattleReport/HUD/BTGameStats/VBoxContainer/HBCWhiteWins/WhtWinsNum.text = whitewins
	#$c/BattleReport/HUD/BTGameStats/VBoxContainer/HBCWhiteWins/WhtWinsNum.text = whitewins
	# black wins
	$HUD/BattleReport/HUD/BTGameStats/VBoxContainer/HBCBlackWins/BlkWinsNum.text = blackwins
	#$c/BattleReport/HUD/BTGameStats/VBoxContainer/HBCBlackWins/BlkWinsNum.text = blackwins
	# attack wins
	$HUD/BattleReport/HUD/BTGameStats/VBoxContainer/HBCAttackWins/AttackWinsNum.text = attackwins
	#$c/BattleReport/HUD/BTGameStats/VBoxContainer/HBCAttackWins/AttackWinsNum.text = attackwins
	# defend wins
	$HUD/BattleReport/HUD/BTGameStats/VBoxContainer/HBCDefendWins/DefendWinsNum.text = defendwins
	#$c/BattleReport/HUD/BTGameStats/VBoxContainer/HBCDefendWins/DefendWinsNum.text = defendwins



func cwl1(apiece, dpiece):
	if game_debug: print("In Chess War L1")
	if game_debug: print("War Level from config is: ", war_level)
	if game_debug: print("The attacker is a ", apiece.color, " ", apiece.type)
	if game_debug: print("The defender is a ", dpiece.color, " ", dpiece.type)
	if game_debug: print("Sending battle report to HUD")
	$HUD/BattleReport/HUD/BTGameStats.show()
	$HUD/BattleReport/HUD/BattleReport.show()
	#l1_battlechancediv = get_node('/root/PlayersData').l1_battlechancediv
	l1_battlechancediv = config.get_value('options', 'l1_battlechancediv')
	#$HUD/BattleReport/BattleReport.text = "In Chess War L1\n"
	$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = "[b][u][color=white]In Chess War L1[/color][/u][/b]\n\n"
	#$HUD/BattleReport.visible = true
	if game_debug: print("Sent battle report to HUD and set visible")
	if game_debug: print("Attacker: ",apiece)
	$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "Attacker: " + str(apiece) + "\n"
	#$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Attacker: " + str(apiece) + "\n"
	if game_debug: print("Defender: ", dpiece)
	$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "Defender: " + str(dpiece) + "\n"
	#$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Defender: " + str(dpiece) + "\n"
	battlechance = randf()
	if game_debug: print("Battlechance is: ",battlechance)
	$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "Battlechance is: "+ str(battlechance) + "\n"
	#$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Battlechance is: "+ str(battlechance) + "\n"
	#$HUD/Announcement.visible = true
	if battlechance <= l1_battlechancediv:
		attackwins = str(int(attackwins) + 1)
		print("apiece color is: ",apiece.color)
		if apiece.color == 'white':
			whitewins = str(int(whitewins) + 1)
		else:
			blackwins = str(int(blackwins) + 1)
		if game_debug: print("Attack wins with battlechance = ", battlechance)
		$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "Attack wins with battlechance = " + str(battlechance) + "\n"
		#$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Attack wins with battlechance = " + str(battlechance) + "\n"
		if game_debug: print("01 - warresult is: ", warresult)
		if game_debug: print("Setting warresult to AttackWins in Level: ", war_level)
		warresult = "AttackWins"
		if game_debug: print("02 - warresult is: ", warresult)
		# we return the piece to kill
		battlecount = battlecount + 1
		if game_debug: print(battlecount, " battles have now been fought.")
		#return dpiece
		#warresult = "AttackWins"
		return warresult
	else:
		defendwins = str(int(defendwins) + 1)
		if dpiece.color == 'white':
			whitewins = str(int(whitewins) + 1)
		else:
			blackwins = str(int(blackwins) + 1)
		if game_debug: print("Defend wins with battlechance = ", battlechance)
		$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "Defend wins with battlechance = " + str(battlechance) + "\n"
		#$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Defend wins with battlechance = " + str(battlechance) + "\n"
		if game_debug: print("03 - warresult is: ", warresult)
		if game_debug: print("Setting warresult to DefendWins in Level: ", war_level)
		warresult = "DefendWins"
		if game_debug: print("04 - waresult is: ", warresult)
		# we return the piece to kill
		battlecount = battlecount + 1
		if game_debug: print(battlecount, " battles have now been fought.")
		#return apiece
		#warresult = "DefendWins"
		return warresult


func cwl2(apiece, dpiece):
	#$Control/BattleReport/HUD.show()
	#$Options.show()
	#$'../Game/HUD/BattleReport'.show()
	#$HUD/BattleReport/HUD.show()
	#$ColorRect/BattleReport.visible = true	# This stuff needs serious fixing.... Start Here.
	#onready var batrep = $"../Game/HUD"
	$HUD/BattleReport/HUD/BTGameStats.show()
	$HUD/BattleReport/HUD/BattleReport.show()
	#if game_debug: print("In Chess War L2")
	#if game_debug: print("War Level from config is: ", war_level)
	if game_debug: print("cwl2 - apiece on enter is: ", apiece.color, apiece.type, apiece)
	if game_debug: print("cwl2 - dpiece on enter is: ", dpiece.color, dpiece.type, dpiece)
	#if game_debug: print("The attacker is a ", apiece.color, " ", apiece.type)
	#if game_debug: print("The defender is a ", dpiece.color, " ", dpiece.type)
	#HUD/BattleReport/BRLabel
	#$c/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = "[b][u][color=white]In Chess War L2[/color][/u][/b]\n\n"
	$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = "[b][u][color=white]In Chess War L2[/color][/u][/b]\n\n"
	#$HUD/BattleReport/BattleReport.text = "In Chess War L2\n"
	#$HUD/BattleReport.visible = true
	$HUD/BattleReport/HUD/BattleReport.show()
	var lp1 = 1
	if game_debug: print("Attacker: ", apiece.color, apiece.type)
	attack1 = apiece.current_attack
	if game_debug: print("Attack1 is: ", attack1)
	attack1type = apiece.type
	#if game_debug: print("attack1type is: ", attack1type)
	$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text  + "[color=aqua]Attacker " + apiece.color + " " + attack1type + "[/color]\n"
	if game_debug: print("Defender: ", dpiece.color, dpiece.type)
	defend1 = dpiece.current_defend
	defend1type = dpiece.type
	if game_debug: print("Attacker, ", apiece.color, apiece.type, " has an attack strength of ", attack1)
	if game_debug: print("Defender, ", dpiece.color, dpiece.type, " has a defend strength of ",defend1)
	$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=yellow]Defender: " + dpiece.color + " " + defend1type + "[/color]\n"
	#while (attack1 != 0) && (defend1 != 0):
	#while (attack1 > 0) && (defend1 > 0):
	if game_debug: print("cwl2 before while: ", attack1, " | ", defend1)
	var battlerounds = 0
	var battlereportrounds = 15
	while (attack1 > 0) and (defend1 > 0):
		# trying to run this loop slower
		if game_debug: print("Trying to yeild for a time...")
		yield(get_tree().create_timer(0.4), "timeout")
		# this is a stupid attempt at a delay loop
		# and it seems to be in the wrong place besides
		# or something is behavin in  way I do not expect.
		# I want to slow down battle updates to the HUD
		#$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + Time.get_time_string_from_system() +"==Before delay loop.==\n"
		#for zn in 10000:
		#	var zo
		#	zo = 0
		#	zo = zo + 1
		#$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "=====After delay loop.==\n"
		if game_debug: print("A1 - Attack = ", attack1, "            |            Defend = ", defend1,"")
		luck = rng.randi_range(0,8)
		if luck == 0:
			if game_debug: print("The attacking ", apiece.color, " ", apiece.type, " lands a mighty blow!")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=aqua]The attacking " + apiece.color + " " + attack1type + " lands a mighty blow![/color]\n"
			defend1 = int((defend1 * 5) / 6 )
			if game_debug: print("defend1 is now: ", defend1)
		if luck == 1:
			if game_debug: print("D1 - The defending ", dpiece, " gets in a gallant thrust!")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=yellow]The defending " + dpiece.color + " " + defend1type + " gets in a gallant thrust![/color]\n"
			if lp1 == 1:
				attack1 = int(attack1 / 2)
				if game_debug: print("It does great damage to the attacker!")
				$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=yellow]It does great damage to the attacker![/color]\n"
				lp1 = 2
				if game_debug: print("attack1 is now: ", attack1)
			else:
				attack1 = int((attack1 * 5) /6)
				if game_debug: print("attack1 is now: ", attack1)
		if luck == 2:
			if game_debug: print("The valiant attacker draws blood.")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=aqua]The valiant attacking " + apiece.color + " " + apiece.type + " draws blood.[/color]\n"
			defend1 = int((defend1 * 4) / 5 )
			if game_debug: print("defend1 is now: ", defend1)
		if luck == 3:
			if game_debug: print("The " + dpiece.color + " " + defend1type, " puts up a strong defence and wounds the " + apiece.color + " " + attack1type + "!!")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=yellow]The " + dpiece.color + " " + defend1type + " puts up a strong defence and wounds the " + apiece.color + " " + attack1type + "!![/color]\n"
			attack1 = int((attack1 * 4) / 5)
			if game_debug: print("attack1 is now: ", attack1)
		if luck == 4:
			if game_debug: print("With a mighty cut, the ", attack1type, " wounds the ", defend1type, ".")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=aqua]With a mighty cut, the " + apiece.color + " " + attack1type + " wounds the " + dpiece.color + " " + defend1type + ".[/color]\n"
			defend1 = int((defend1 * 9) / 10)
			if game_debug: print("defend1 is now: ", defend1)
		if luck == 5:
			if game_debug: print("The defender lands  a crushing blow!")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=yellow]The defending " + dpiece.color + " " + defend1type + " lands  a crushing blow![/color]\n"
			attack1 = int((attack1 * 9) /10)
			if game_debug: print("attack1 is now: ", attack1)
		if luck == 6:
			if game_debug: print("OH! Surely the ", defend1type, " cannot long endure such a furious attack.")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=aqua]OH! Surely the " + dpiece.color + " " + defend1type + " cannot long endure such a furious attack.[/color]\n"
			defend1 = int((defend1 * 14) / 15)
			if game_debug: print("defend1 is now: ", defend1)
		if luck == 7:
			if game_debug: print("The ", attack1type, "'s attack falters and the ", defend1type, " gets in a blow in return.")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=yellow]The " + apiece.color + " " + attack1type + "'s attack falters and the " + dpiece.color + " " + defend1type + " gets in a blow in return.[/color]\n"
			attack1 = int((attack1 * 14) / 15)
			if game_debug: print("attack1 is now: ", attack1)
		if luck == 8:
			#if game_debug: print("The combatants take a much needed rest.")
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "[color=white]The combatants take a much needed rest.[/color] [right][color=aqua]"+str(attack1)+"[/color]|[color=yellow]"+str(defend1)+"  [/color][/right]\n"
			if game_debug: print("attack1 is now: ", attack1)
			if game_debug: print("defend1 is now: ", defend1)
		battlerounds = battlerounds +1
		if game_debug: print("battlerounds is now: ", battlerounds)
		if battlerounds == battlereportrounds:
			battlerounds = 0
			$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = "The battle continues.\n"
	if game_debug: print("A2 - Attack = ", attack1, "            |            Defend = ", defend1,"")
	$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "Attack = " + str(attack1) + "            |            Defend = " + str(defend1) + "\n"
	if game_debug: print("before defend1 == 0 check, defend1 is now: ", defend1, " attack1 is now: ",attack1)
	if (defend1 == 0):
		# ATTACK WINS
		attackwins = str(int(attackwins) + 1)
		$'../Game/HUD/GameStats/VBoxContainer/HBCAttackWins/AttackWinsNum'.text = attackwins
		if game_debug: print("Below should be true")
		if game_debug: print(defend1==0)
		if game_debug: print("was above true?")
		if game_debug: print("defend1 == 0? A3 - Attack = ", attack1, "            |            Defend = ", defend1,"")
		if game_debug: print("defend1 is: ", defend1)
		if game_debug: print("The attacking ", attack1type, " defeated the defending ", defend1type, "!")
		$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "The attacking " + apiece.color + " " + attack1type + " defeated the defending " + dpiece.color + " " + defend1type + "!\n"
		#if game_debug: print("Setting warresult to Attackwins in Level: ", war_level)
		#warresult = "AttackWins" # Not Needed?
		incrsc = apiece.value
		if attack1 == 0:
			attack1 = 1
			if game_debug: print("defend1 was 0 and attack1 was 0 so we made attack1 equal 1")
		apiece.current_attack = attack1
		if game_debug: print("incrsc is: ", incrsc)
		if apiece.color == 'white':
			whitescore = str(int(whitescore) + dpiece.value)
			$'../Game/HUD/GameStats/VBoxContainer/HBCWhiteScore/WhtScoreNum'.text = whitescore
			if game_debug: print("whitewins is: ", whitewins)
			whitewins = str(int(whitewins) + 1)
			if game_debug: print("whitewins is: ", whitewins)
			$'../Game/HUD/GameStats/VBoxContainer/HBCWhiteWins/WhtWinsNum'.text = whitewins
		else:
			blackscore = str(int(blackscore) + dpiece.value)
			$'../Game/HUD/GameStats/VBoxContainer/HBCBlackScore/BlkScoreNum'.text = blackscore
			blackwins = str(int(blackwins) + 1)
			if game_debug: print("whitewins is: ", blackwins)
			$'../Game/HUD/GameStats/VBoxContainer/HBCBlackWins/BlkWinsNum'.text = blackwins
		# we return the piece to kill (loser)
		#return dpiece
		warresult = "AttackWins"
		return warresult
	else:
		#DEFEND WINS
		defendwins = str(int(defendwins) + 1)
		$'../Game/HUD/GameStats/VBoxContainer/HBCDefendWins/DefendWinsNum'.text = defendwins
		if game_debug: print("defend1 != 0? A4 - Attack = ", attack1, "            |            Defend = ", defend1,"")
		if game_debug: print("D2 - The defending ", defend1type,  " defeated the attacking ", attack1type, " !")
		$HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text = $HUD/BattleReport/HUD/BattleReport/BRLabel.bbcode_text + "The defending " + dpiece.color + " " + defend1type +  " defeated the attacking " + apiece.color + " " + attack1type + " !\n"
		#if game_debug: print("Setting warresult to DefendWins in Level: ", war_level)
		#warrestul = "DefendWins #not needed ?
		incrsc = dpiece.value
		if apiece.color == 'white':
			blackscore = str(int(blackscore) + apiece.value)
			$'../Game/HUD/GameStats/VBoxContainer/HBCBlackScore/BlkScoreNum'.text = blackscore
			if game_debug: print("blackwins is: ", blackwins)
			blackwins = str(int(blackwins) + 1)
			if game_debug: print("blackwins is: ", blackwins)
			$'../Game/HUD/GameStats/VBoxContainer/HBCBlackWins/BlkWinsNum'.text = blackwins
			
		else:
			blackscore = str(int(blackscore) + apiece.value)
			$'../Game/HUD/GameStats/VBoxContainer/HBCBlackScore/BlkScoreNum'.text = blackscore
		# we return the piece to kill
		# - out this back somehow? 
		# dpiece.current.defend = defend1
		#return apiece
		warresult = "DefendWins"
		return warresult




func player_turn(clicked_cell, sync_mult = false):
	warresult = "AttackWins"
	if game_debug: print("G - at top of player_turn")
	if sync_mult:
		active_piece = get_node(game_type_node.active_piece_path)
		apiece = active_piece
		
	if clicked_cell in $TileMap.chessmen_coords:
		warresult = "AttackWins"
		if game_debug: print("01 - Active piece is: ", active_piece)
		dpiece = $TileMap.chessmen_coords[clicked_cell]
		if game_debug: print("01 - dpiece is: ", dpiece)


		if war_level == "Level0":
			if game_debug: print("\n\n-----In War Level: ", war_level)
			warresult = "AttackWins"
			print("Level 0 war result is: ", warresult)
		elif war_level == "Level1":
			if game_debug: print("\n\n-----In War Level: ", war_level)
			warresult = cwl1(active_piece, dpiece)
			print("Level 1 war result is: ", warresult)
		elif war_level == "Level2":
			if game_debug: print("\n\n-----In War Level: ", war_level)
			apiece = active_piece
			if game_debug: print("Attacker: ", apiece)
			attack1 = apiece.current_attack
			if game_debug: print("Attack1 is: ", attack1)
			attack1type = apiece.type
			if game_debug: print("attack1type is: ", attack1type)
			if game_debug: print("calling L2 active_piece, dpiece - ", active_piece, dpiece)
			print("calling L2 active_piece, dpiece - ", active_piece, dpiece)
			$HUD/BattleReport/HUD/BTGameStats.show()
			$HUD/BattleReport/HUD/BattleReport.show()
			warresultl2 = yield(cwl2(active_piece, dpiece), "completed")
			warresult = warresultl2
			print("Level 2 war result is: ", warresult)
		else:
			# should neve get here but just in case and
			# to make adding new levels easier
			if game_debug: print("If we got here, something went wrong, pretend.")
			warresult = "AttackWins"
			print("Level ERROR war result is: ", warresult)
		
		if game_debug: print("After any battles fought, warresult is: ", warresult)

		update_stats_display()
		print("checking warresult and  dealing with pieces: ", apiece, dpiece)
		if warresult == "AttackWins":
			print("AttackWins Kill: ", dpiece," ???")
			if game_debug: print("AttackWins true piece to kill is: ", $TileMap.chessmen_coords[clicked_cell])
			if game_debug: print("Attack Won - Gonna try kill: ", dpiece)
			#$TileMap.kill_piece($TileMap.chessmen_coords[clicked_cell])
			$TileMap.kill_piece(dpiece)
		else:
			# how do I kill the attacker
			# something is wrong, the attacker is still showing on the board.
			if game_debug: print("DefendWins piece to kill is: ", apiece)
			$TileMap.kill_piece(apiece)
			#pass
				
	elif 'Pawn' == active_piece.type and clicked_cell in $TileMap.jumped_over_tiles\
	and clicked_cell in $TileMap.pawn_attack(active_piece, active_piece.tile_position, false):
		$TileMap.kill_piece($TileMap.jumped_over_tiles[clicked_cell])
		
		if get_tree().is_network_server():
			var dead_npc_path = str($TileMap.jumped_over_tiles[clicked_cell].get_path())
			game_type_node.rpc("sync_kill_piece", dead_npc_path)


	#$TileMap.draw_map()
	print("=== ",warresult)
	if warresult == "AttackWins":
		if game_debug: print("Attacker won, moving to new location")
		$TileMap.move_piece(active_piece, clicked_cell)
		$TileMap.draw_map()
		$TileMap.update_jumped_over_tiles(active_piece)
	else:
		if game_debug: print("==Defender won, move not needed")
		$TileMap.draw_map()
		$TileMap.update_jumped_over_tiles(active_piece)
	#$TileMap.draw_map()
	#$TileMap.update_jumped_over_tiles(active_piece)




	
func _on_Promotion_pressed(piece):
	$TileMap.promote_pawn(active_piece, piece)
	clickable = true
	$HUD/PromotionBox.visible = false
	
	if is_multiplayer:
		$HUD/MenuBox.visible = true
		
	emit_signal("promotion_done", piece)

func check_for_game_over():
	var checkmate_stalemate = $TileMap.check_checkmate_stalemate(turn)
	
	if checkmate_stalemate:
		game_over(turn + ' is ' + checkmate_stalemate)
	
	elif not $TileMap.if_able_to_checkmate('white') and not $TileMap.if_able_to_checkmate('black')\
	or fify_moves_rule() or threefold_rule():
		game_over('it is a draw')

func fify_moves_rule(amount_of_moves = 50):
	if 'Pawn' == active_piece.type:
		$TileMap.fifty_moves_counter = 0
		return false
	
	if turn == 'white':
		if $TileMap.fifty_moves_counter == amount_of_moves:
			return true
		else:
			$TileMap.fifty_moves_counter += 1
			return false

func threefold_rule(amount_of_moves = 3):
	if not get_tree().has_network_peer() or get_tree().is_network_server():
		var repeated_positions = 0
		var breaked
		var breaked_pawns
		
		for turn_step in turn_history.values():
			if turn == turn_step[0]:
				for key in turn_step[1].keys():
					
					breaked = false
					if turn_history[current_turn_index][1].has(key):
						if turn_step[1][key] != turn_history[current_turn_index][1][key]:
							breaked = true
							break
					else:
						breaked = true
						break
				
				if not breaked\
				and turn_step[2].size() == turn_history[current_turn_index][2].size():
					
					breaked_pawns = false
					
					for pawn_attack_tile in turn_step[2]:
						if not pawn_attack_tile in turn_history[current_turn_index][2]:
							breaked_pawns = true
							break
					
					if not breaked_pawns:
						repeated_positions += 1
					
		if repeated_positions >= amount_of_moves:
			return true
	
	else:
		rpc('threefold_rule')

func swap_turn():
	if turn == 'white':
		turn = 'black'
	else:
		turn = 'white'

func update_turn():
	$TileMap.clean_up_jumped_over(turn)
	current_turn_index += 1
	append_turn_history()
	adjust_turn_history()

func change_turns():
	if is_multiplayer:
		game_type_node.change_turns()
	else:
		swap_turn()
		update_turn()
		game_type_node.set_Undo_button()
		game_type_node.set_Redo_button()

func set_possible_moves():
	if is_multiplayer:
		game_type_node.set_possible_moves(str(active_piece.get_path()))
			
	else:
		range_of_movement = $TileMap.check_possible_moves(active_piece)
		draw_possible_moves()
		
func draw_possible_moves():
	$TileMap.set_cells(range_of_movement, 4)

func game_over(message, double_call = false):
	clickable = false
	$HUD/MenuBox.visible = false
	$HUD/RewindBox.visible = false
	$HUD/BackPanel.visible = false
	$HUD/Announcement/Announcement.text = message
	$HUD/Announcement.visible = true
	$HUD/EndGame.visible = true
	
	if is_multiplayer and not double_call:
		rpc('game_over', message, true)
