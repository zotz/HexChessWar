extends Control

var kinga
var kingd
var kingv
var kingr
var queena
var queend
var queenv
var queenr
var bishopa
var bishopd
var bishopv
var bishopr
var knighta
var knightd
var knightv
var knightr
var rooka
var rookd
var rookv
var rookr
var pawna
var pawnd
var pawnv
var pawnr
var battlechance
var l1_battlechancediv

onready var config = get_node('/root/PlayersData').call_config()

func _ready():
	$Menu/VBoxContainer/Local.grab_focus()
	print("In menu.gd, ready!")
	#print("kinga is now: ", kinga)
	kinga = config.get_value('options', 'kinga')
	kingd = config.get_value('options', 'kingd')
	kingv = config.get_value('options', 'kingv')
	kingr = config.get_value('options', 'kingr')
	queena = config.get_value('options', 'queena')
	queend = config.get_value('options', 'queend')
	queenv = config.get_value('options', 'queenv')
	queenr = config.get_value('options', 'queenr')
	bishopa = config.get_value('options', 'bishopa')
	bishopd = config.get_value('options', 'bishopd')
	bishopv = config.get_value('options', 'bishopv')
	bishopr = config.get_value('options', 'bishopr')
	knighta = config.get_value('options', 'knighta')
	knightd = config.get_value('options', 'knightd')
	knightv = config.get_value('options', 'knightv')
	knightr = config.get_value('options', 'knightr')
	rooka = config.get_value('options', 'rooka')
	rookd = config.get_value('options', 'rookd')
	rookv = config.get_value('options', 'rookv')
	rookr = config.get_value('options', 'rookr')
	pawna = config.get_value('options', 'pawna')
	pawnd = config.get_value('options', 'pawnd')
	pawnv = config.get_value('options', 'pawnv')
	pawnr = config.get_value('options', 'pawnr')
	l1_battlechancediv = config.get_value('options', 'l1_battlechancediv')



func _on_Local_pressed():
	get_node('/root/PlayersData').chess_type = config.get_value('options', 'chess_type')
	get_node('/root/PlayersData').war_level = config.get_value('options', 'war_level')


	get_tree().set_network_peer(null)
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://scenes/board.tscn")

func _on_Options_pressed():
	print("In Menu, pressed Optioons.")
	print("kinga is now: ", kinga)
	$Menu.visible = false
	$ColorRect/BackPanel.visible = true
	$Options.visible = true
	$Options/VBoxContainer/HBoxContainer/Glinski.grab_focus()
	
	var chess_type = config.get_value('options', 'chess_type')
	
	for checkbox in get_tree().get_nodes_in_group('chess_types'):
		if checkbox.name == chess_type:
			checkbox.pressed = true
			break

	var war_level = config.get_value('options', 'war_level')

	for checkbox in get_tree().get_nodes_in_group('war_levels'):
		if checkbox.name == war_level:
			checkbox.pressed = true
			break


	print("In Menu, pressed Edit Config.")
	print("kinga is now: ", kinga)
	#$ConfigColorRect/PHVBC/PHTHBC/KingHolderVBC/KingValsVBC/KingdHBC/sb_kingd.value = config.get_value('options', 'kingd')
	$Options/HBoxContainer/vbc_king/hbc_kinga/sb_kinga.value = kinga
	$Options/HBoxContainer/vbc_king/hbc_kingd/sb_kingd.value = kingd
	$Options/HBoxContainer/vbc_king/hbc_kingr/sb_kingr.value = kingr
	$Options/HBoxContainer/vbc_king/hbc_kingv/sb_kingv.value = kingv
	$Options/HBoxContainer/vbc_queen/hbc_queena/sb_queena.value = queena
	$Options/HBoxContainer/vbc_queen/hbc_queend/sb_queend.value = queend
	$Options/HBoxContainer/vbc_queen/hbc_queenr/sb_queenr.value = queenr
	$Options/HBoxContainer/vbc_queen/hbc_queenv/sb_queenv.value = queenv
	$Options/HBoxContainer/vbc_bishop/hbc_bishopa/sb_bishopa.value = bishopa
	$Options/HBoxContainer/vbc_bishop/hbc_bishopd/sb_bishopd.value = bishopd
	$Options/HBoxContainer/vbc_bishop/hbc_bishopr/sb_bishopr.value = bishopr
	$Options/HBoxContainer/vbc_bishop/hbc_bishopv/sb_bishopv.value = bishopv
	$Options/HBoxContainer/vbc_knight/hbc_knighta/sb_knighta.value = knighta
	$Options/HBoxContainer/vbc_knight/hbc_knightd/sb_knightd.value = knightd
	$Options/HBoxContainer/vbc_knight/hbc_knightr/sb_knightr.value = knightr
	$Options/HBoxContainer/vbc_knight/hbc_knightv/sb_knightv.value = knightv
	$Options/HBoxContainer/vbc_rook/hbc_rooka/sb_rooka.value = rooka
	$Options/HBoxContainer/vbc_rook/hbc_rookd/sb_rookd.value = rookd
	$Options/HBoxContainer/vbc_rook/hbc_rookr/sb_rookr.value = rookr
	$Options/HBoxContainer/vbc_rook/hbc_rookv/sb_rookv.value = rookv
	$Options/HBoxContainer/vbc_pawn/hbc_pawna/sb_pawna.value = pawna
	$Options/HBoxContainer/vbc_pawn/hbc_pawnd/sb_pawnd.value = pawnd
	$Options/HBoxContainer/vbc_pawn/hbc_pawnr/sb_pawnr.value = pawnr
	$Options/HBoxContainer/vbc_pawn/hbc_pawnv/sb_pawnv.value = pawnv
	$Options/VBC_L1/HBC_battlechance/sb_battlechancediv.value = l1_battlechancediv

	
func _on_BackPanel_pressed():
	$Menu/VBoxContainer/Local.grab_focus()
	$Menu.visible = true
	$ColorRect/BackPanel.visible = false
	$Options.visible = false
	
	for checkbox in get_tree().get_nodes_in_group('chess_types'):
		if checkbox.pressed:
			config.set_value('options', 'chess_type', checkbox.name)
			break

	for checkbox in get_tree().get_nodes_in_group('war_levels'):
		if checkbox.pressed:
			config.set_value('options', 'war_level', checkbox.name)
			break

	#print("kinga is now: ", kinga)
	kinga = $Options/HBoxContainer/vbc_king/hbc_kinga/sb_kinga.value
	kingd = $Options/HBoxContainer/vbc_king/hbc_kingd/sb_kingd.value
	kingr = $Options/HBoxContainer/vbc_king/hbc_kingr/sb_kingr.value
	kingv = $Options/HBoxContainer/vbc_king/hbc_kingv/sb_kingv.value
	config.set_value('options', 'kinga', kinga)
	config.set_value('options', 'kingd', kingd)
	config.set_value('options', 'kingr', kingr)
	config.set_value('options', 'kingv', kingv)
	queena = $Options/HBoxContainer/vbc_queen/hbc_queena/sb_queena.value
	queend = $Options/HBoxContainer/vbc_queen/hbc_queend/sb_queend.value
	queenr = $Options/HBoxContainer/vbc_queen/hbc_queenr/sb_queenr.value
	queenv = $Options/HBoxContainer/vbc_queen/hbc_queenv/sb_queenv.value
	config.set_value('options', 'queena', queena)
	config.set_value('options', 'queend', queend)
	config.set_value('options', 'queenr', queenr)
	config.set_value('options', 'queenv', queenv)
	bishopa = $Options/HBoxContainer/vbc_bishop/hbc_bishopa/sb_bishopa.value
	bishopd = $Options/HBoxContainer/vbc_bishop/hbc_bishopd/sb_bishopd.value
	bishopr = $Options/HBoxContainer/vbc_bishop/hbc_bishopr/sb_bishopr.value
	bishopv = $Options/HBoxContainer/vbc_bishop/hbc_bishopv/sb_bishopv.value
	config.set_value('options', 'bishopa', bishopa)
	config.set_value('options', 'bishopd', bishopd)
	config.set_value('options', 'bishopr', bishopr)
	config.set_value('options', 'bishopv', bishopv)
	knighta = $Options/HBoxContainer/vbc_knight/hbc_knighta/sb_knighta.value
	knightd = $Options/HBoxContainer/vbc_knight/hbc_knightd/sb_knightd.value
	knightr = $Options/HBoxContainer/vbc_knight/hbc_knightr/sb_knightr.value
	knightv = $Options/HBoxContainer/vbc_knight/hbc_knightv/sb_knightv.value
	config.set_value('options', 'knighta', knighta)
	config.set_value('options', 'knightd', knightd)
	config.set_value('options', 'knightr', knightr)
	config.set_value('options', 'knightv', knightv)
	rooka = $Options/HBoxContainer/vbc_rook/hbc_rooka/sb_rooka.value
	rookd = $Options/HBoxContainer/vbc_rook/hbc_rookd/sb_rookd.value
	rookr = $Options/HBoxContainer/vbc_rook/hbc_rookr/sb_rookr.value
	rookv = $Options/HBoxContainer/vbc_rook/hbc_rookv/sb_rookv.value
	config.set_value('options', 'rooka', rooka)
	config.set_value('options', 'rookd', rookd)
	config.set_value('options', 'rookr', rookr)
	config.set_value('options', 'rookv', rookv)
	pawna = $Options/HBoxContainer/vbc_pawn/hbc_pawna/sb_pawna.value
	pawnd = $Options/HBoxContainer/vbc_pawn/hbc_pawnd/sb_pawnd.value
	pawnr = $Options/HBoxContainer/vbc_pawn/hbc_pawnr/sb_pawnr.value
	pawnv = $Options/HBoxContainer/vbc_pawn/hbc_pawnv/sb_pawnv.value
	config.set_value('options', 'pawna', pawna)
	config.set_value('options', 'pawnd', pawnd)
	config.set_value('options', 'pawnr', pawnr)
	config.set_value('options', 'pawnv', pawnv)
	l1_battlechancediv = $Options/VBC_L1/HBC_battlechance/sb_battlechancediv.value
	config.set_value('options', 'l1_battlechancediv', l1_battlechancediv)
	
	config.save("res://config.cfg")


func _on_QuitGame_pressed():
	print("In Menu, pressed Quit Game.")
	get_tree().quit()
