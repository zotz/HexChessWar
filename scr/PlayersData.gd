extends Node

var colors = ['white', 'black']

var master_color 
var puppet_color 

var peer

var chess_type
var war_level

# I know I am doing something wrong below but how to fix?
var kinga = 1
var kingd = 1
var kingv = 1
var kingr = 1
var queena = 1
var queend = 1
var queenv = 1
var queenr = 1
var bishopa = 1
var bishopd = 1
var bishopv = 1
var bishopr = 1
var knighta = 1
var knightd = 1
var knightv = 1
var knightr = 1
var rooka = 1
var rookd = 1
var rookv = 1
var rookr = 1
var pawna = 1
var pawnd = 1
var pawnv = 1
var pawnr = 1


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
