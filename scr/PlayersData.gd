extends Node

var colors = ['white', 'black']

var master_color 
var puppet_color 

var peer

var chess_type
var war_level

func call_config ():
	var config = ConfigFile.new()
	
	var err = config.load("res://config.cfg")

	if err != OK:
		config.set_value('options', 'chess_type', 'Glinski')
		config.set_value('options', 'war_level', 'Level0')
		config.set_value('options', 'kinga', 99999)
		config.set_value('options', 'kingd', 95)
		config.set_value('options', 'kingv', 500)
		config.set_value('options', 'kingr', 1)
		config.set_value('options', 'queena', 80)
		config.set_value('options', 'queend', 45)
		config.set_value('options', 'queenv', 9)
		config.set_value('options', 'queenr', .15)
		config.set_value('options', 'bishopa', 50)
		config.set_value('options', 'bishopd', 15)
		config.set_value('options', 'bishopv', 3)
		config.set_value('options', 'bishopr', .1)
		config.set_value('options', 'knighta', 50)
		config.set_value('options', 'knightd', 15)
		config.set_value('options', 'knightv', 3)
		config.set_value('options', 'knightr', .1)
		config.set_value('options', 'rooka', 60)
		config.set_value('options', 'rookd', 25)
		config.set_value('options', 'rookv', 5)
		config.set_value('options', 'rookr', .1)
		config.set_value('options', 'pawna', 45)
		config.set_value('options', 'pawnd', 7)
		config.set_value('options', 'pawnv', 1)
		config.set_value('options', 'pawnr', .15)
		config.set_value('options', 'l1_battlechancediv', .75)

		
	return config
