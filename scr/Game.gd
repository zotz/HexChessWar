extends Node2D

var game_debug = true

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

var whitescore
var blackscore
var incrsc
var warresult
var battlechance
var l1_battlechancediv
var zattackwon = true
var attack1
var attack1type
var defend1
var defend1type
var luck
var rng = RandomNumberGenerator.new()
var battlecount = 0

onready var war_level = get_node('/root/PlayersData').war_level
#onready var l1_battlechancediv = get_node('/root/PlayersData').l1_battlechancediv
onready var config = get_node('/root/PlayersData').call_config()

signal promotion_done

func _ready():
	$TileMap.draw_map()
	$TileMap.visible = true
	
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
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		print("A - InputEventMouseButton just happened")
		if event.pressed and clickable and turn in player_colors:
			print("B - this is event.pressed and clickable and turn in player_colors")
			var clicked_cell = $TileMap.world_to_map(get_global_mouse_position())
			print("C - clicked cell set to: ", clicked_cell)
			
			if clicked_cell in range_of_movement:
				print("D - clicked_cell is in range_of_movement")
				range_of_movement = []
				
				print("E - calling player_turn")
				player_turn(clicked_cell)
				print("F - back from player_turn")
				
				var promotion_piece
				if 'Pawn' == active_piece.type and clicked_cell in $TileMap.promotion_tiles:
					$HUD/PromotionBox.visible = true
					$HUD/PromotionBox/Queen.grab_focus()
					clickable = false
					$HUD/MenuBox.visible = false
					promotion_piece = yield(self, "promotion_done")
					
				change_turns()
				
				if is_multiplayer:
					game_type_node.sync_multiplayer(clicked_cell)
					
					if promotion_piece:
						game_type_node.rpc("sync_promotion", promotion_piece)
				
				check_for_game_over()
				
			elif clicked_cell in $TileMap.chessmen_coords:
				var piece = $TileMap.chessmen_coords[clicked_cell]
				if piece.tile_position == clicked_cell and piece.color == turn:
					$TileMap.draw_map()
					active_piece = piece
					set_possible_moves()

func cwl1(apiece, dpiece):
	if game_debug: print("In Chess War L1")
	if game_debug: print("War Level from config is: ", war_level)
	print("Sending battle report to HUD")
	#l1_battlechancediv = get_node('/root/PlayersData').l1_battlechancediv
	l1_battlechancediv = config.get_value('options', 'l1_battlechancediv')
	$HUD/BattleReport/BattleReport.text = "In Chess War L1\n"
	$HUD/BattleReport.visible = true
	print("Sent battle report to HUD and set visible")
	if game_debug: print("Attacker: ",apiece)
	$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Attacker: " + str(apiece) + "\n"
	if game_debug: print("Defender: ", dpiece)
	$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Defender: " + str(dpiece) + "\n"
	battlechance = randf()
	if game_debug: print("Battlechance is: ",battlechance)
	$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Battlechance is: "+ str(battlechance) + "\n"
	#$HUD/Announcement.visible = true
	if battlechance <= l1_battlechancediv:
		if game_debug: print("Attack wins with battlechance = ", battlechance)
		$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Attack wins with battlechance = " + str(battlechance) + "\n"
		print("01 - zattackwon is: ", zattackwon)
		zattackwon = true
		print("02 - zattackwon is: ", zattackwon)
		# we return the piece to kill
		battlecount = battlecount + 1
		print(battlecount, " battles have now been fought.")
		return dpiece
	else:
		if game_debug: print("Defend wins with battlechance = ", battlechance)
		$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Defend wins with battlechance = " + str(battlechance) + "\n"
		print("03 - zattackwon is: ", zattackwon)
		zattackwon = false
		print("04 - zattackwon is: ", zattackwon)
		# we return the piece to kill
		battlecount = battlecount + 1
		print(battlecount, " battles have now been fought.")
		return apiece
		#temp pretend attacker won
		#return dpiece

func cwl2(apiece, dpiece):
	print("In Chess War L2")
	print("Level 2 is currently just Level 1 - fix in future!")
	print("War Level from config is: ", war_level)
	print("cwl2 - apiece on enter is: ", apiece)
	print("cwl2 - dpiece on enter is: ", dpiece)
	$HUD/BattleReport/BattleReport.text = "In Chess War L2\n"
	$HUD/BattleReport.visible = true
	var lp1 = 1
	print("Attacker: ", apiece)
	attack1 = apiece.current_attack
	print("Attack1 is: ", attack1)
	attack1type = apiece.type
	print("attack1type is: ", attack1type)
	$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Attacker: " + str(apiece) + "\n"
	print("Defender: ", dpiece)
	defend1 = dpiece.current_defend
	defend1type = dpiece.type
	print("Attacker, ", apiece, " has an attack strength of ", attack1)
	print("Defender, ", dpiece, " has a defend strength of ",defend1)
	$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Defender: " + str(dpiece) + "\n"
	#while (attack1 != 0) && (defend1 != 0):
	#while (attack1 > 0) && (defend1 > 0):
	print("cwl2 before while: ", attack1, " | ", defend1)
	while (attack1 > 0) and (defend1 > 0):
		# trying to run this loop slower
		#yield(get_tree().create_timer(1.0), "timeout")
		for zn in 100000:
			var zo
			zo = 0
			zo = zo + 1
		print("A1 - Attack = ", attack1, "            |            Defend = ", defend1,"")
		luck = rng.randi_range(0,8)
		if luck == 0:
			print("The attacking ", apiece, " lands a mighty blow!")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "The attacking " + attack1type + " lands a mighty blow!\n"
			defend1 = int((defend1 * 5) / 6 )
			print("defend1 is now: ", defend1)
		if luck == 1:
			print("D1 - The defending ", dpiece, " gets in a gallant thrust!")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "D1 - The defending " + defend1type + " gets in a gallant thrust!\n"
			if lp1 == 1:
				attack1 = int(attack1 / 2)
				print("It does great damage to the attacker!")
				$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "It does great damage to the attacker!\n"
				lp1 = 2
				print("attack1 is now: ", attack1)
			else:
				attack1 = int((attack1 * 5) /6)
				print("attack1 is now: ", attack1)
		if luck == 2:
			print("The valiant attacker draws blood.")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "The valiant attacker draws blood.\n"
			defend1 = int((defend1 * 4) / 5 )
			print("defend1 is now: ", defend1)
		if luck == 3:
			print("The ", defend1type, " puts up a strong defence and wounds the ", attack1type, "!!")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "The " + defend1type + " puts up a strong defence and wounds the " + attack1type + "!!\n"
			attack1 = int((attack1 * 4) / 5)
			print("attack1 is now: ", attack1)
		if luck == 4:
			print("With a mighty cut, the ", attack1type, " wounds the ", defend1type, ".")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "With a mighty cut, the " + attack1type + " wounds the " + defend1type + ".\n"
			defend1 = int((defend1 * 9) / 10)
			print("defend1 is now: ", defend1)
		if luck == 5:
			print("The defender lands  a crushing blow!")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "The defender lands  a crushing blow!\n"
			attack1 = int((attack1 * 9) /10)
			print("attack1 is now: ", attack1)
		if luck == 6:
			print("OH! Surely the ", defend1type, " cannot long endure such a furious attack.")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "OH! Surely the " + defend1type + " cannot long endure such a furious attack.\n"
			defend1 = int((defend1 * 14) / 15)
			print("defend1 is now: ", defend1)
		if luck == 7:
			print("The ", attack1type, "'s attack falters and the ", defend1type, " gets in a blow in return.")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "The " + attack1type + "'s attack falters and the " + defend1type + " gets in a blow in return.\n"
			attack1 = int((attack1 * 14) / 15)
			print("attack1 is now: ", attack1)
		if luck == 8:
			print("The combatants take a much needed rest.")
			$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "The combatants take a much needed rest.\n"
			print("attack1 is now: ", attack1)
			print("defend1 is now: ", defend1)
	print("A2 - Attack = ", attack1, "            |            Defend = ", defend1,"")
	$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "Attack = " + str(attack1) + "            |            Defend = " + str(defend1) + "\n"
	print("before defend1 == 0 check, defend1 is now: ", defend1, " attack1 is now: ",attack1)
	if (defend1 == 0):
		print("Below should be true")
		print(defend1==0)
		print("was above true?")
		print("defend1 == 0? A3 - Attack = ", attack1, "            |            Defend = ", defend1,"")
		print("defend1 is: ", defend1)
		print("The attacking ", attack1type, " defeated the defending ", defend1type, "!")
		$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "The attacking " + attack1type + " defeated the defending " + defend1type + "!\n"
		zattackwon = true
		incrsc = apiece.value
		if attack1 == 0:
			attack1 = 1
			print("defend1 was 0 and attack1 was 0 so we made attack1 equal 1")
		apiece.current_attack = attack1
		# we return the piece to kill
		return dpiece
	else:
		print("defend1 != 0? A4 - Attack = ", attack1, "            |            Defend = ", defend1,"")
		#Defend wins
		print("D2 - The defending ", defend1type,  " defeated the attacking ", attack1type, " !")
		$HUD/BattleReport/BattleReport.text = $HUD/BattleReport/BattleReport.text + "D2 - The defending " + defend1type +  " defeated the attacking " + attack1type + " !\n"
		zattackwon = false
		incrsc = dpiece.value
		# we return the piece to kill
		# - out this back somehow? 
		# dpiece.current.defend = defend1
		return apiece




func player_turn(clicked_cell, sync_mult = false):
	print("G - at top of player_turn")
	if sync_mult:
		active_piece = get_node(game_type_node.active_piece_path)
		
	if clicked_cell in $TileMap.chessmen_coords:
		if game_debug: print("01 - Active piece is: ", active_piece)
		dpiece = $TileMap.chessmen_coords[clicked_cell]
		if game_debug: print("01 - dpiece is: ", dpiece)


		if war_level == "Level0":
			if game_debug: print("\n\n-----In War Level: ", war_level)
			warresult = dpiece
		elif war_level == "Level1":
			if game_debug: print("\n\n-----In War Level: ", war_level)
			warresult = cwl1(active_piece, dpiece)
		elif war_level == "Level2":
			if game_debug: print("\n\n-----In War Level: ", war_level)
			apiece = active_piece
			print("Attacker: ", apiece)
			attack1 = apiece.current_attack
			print("Attack1 is: ", attack1)
			attack1type = apiece.type
			print("attack1type is: ", attack1type)
			print("calling L2 active_piece, dpiece - ", active_piece, dpiece)
			warresult = cwl2(active_piece, dpiece)
		else:
			# should neve get here but just in case and
			# to make adding new levels easier
			warresult = dpiece
		
		print("After any battles fought, warresult is: ", warresult)


		if zattackwon:
			print("zattackwon true piece to kill is: ", $TileMap.chessmen_coords[clicked_cell])
			$TileMap.kill_piece($TileMap.chessmen_coords[clicked_cell])
		else:
			# how do I kill the attacker
			print("zattackwon false piece to kill is: ", warresult)
			$TileMap.kill_piece(warresult)
			pass
				
	elif 'Pawn' == active_piece.type and clicked_cell in $TileMap.jumped_over_tiles\
	and clicked_cell in $TileMap.pawn_attack(active_piece, active_piece.tile_position, false):
		$TileMap.kill_piece($TileMap.jumped_over_tiles[clicked_cell])
		
		if get_tree().is_network_server():
			var dead_npc_path = str($TileMap.jumped_over_tiles[clicked_cell].get_path())
			game_type_node.rpc("sync_kill_piece", dead_npc_path)

	if zattackwon:
		print("Attacker won, moving to new location")
		$TileMap.move_piece(active_piece, clicked_cell)
	else:
		print("Defender won, move not needed")
		zattackwon = true
	$TileMap.draw_map()
	$TileMap.update_jumped_over_tiles(active_piece)




	
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
