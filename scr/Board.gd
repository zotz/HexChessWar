extends "res://scr/Movement.gd"

var board_debug = true

var tile_colors = Dictionary()

var fifty_moves_counter = 0

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

onready var promotion_tiles = delete_duplicates(
	$Mapping.draw_diagonal_line(Vector2(0, -5), 5, 1, 1)
	+ $Mapping.draw_diagonal_line(Vector2(0, -5), 5, -1, 1)
	+ $Mapping.draw_diagonal_line(Vector2(0, 5), 5, 1, -1)
	+ $Mapping.draw_diagonal_line(Vector2(0, 5), 5, -1, -1)) 

onready var verticals_1 = $Mapping.draw_diagonal_line(Vector2(-5, -3), 5, 1, -1)
onready var verticals_2 = $Mapping.draw_diagonal_line(Vector2(5, -3), 4, -1, -1)
onready var config = get_node('/root/PlayersData').call_config()


func _ready():
	self.Mapping = $Mapping
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





func draw_map():
	set_verticals(verticals_1)
	set_verticals(verticals_2)

func set_verticals(tile_array):
	var tilenumbers = [0, 1, 2]
	var index = 0
	for vertical in tile_array:
		var tile = vertical
		var i = 0
		var index_while = index
		
		while tile in coord_tiles:
			set_cell(tile[0], tile[1], tilenumbers[index_while])
			tile_colors[tile] = tilenumbers[index_while]
			
			tile = Vector2(vertical[0], vertical[1]+i)
			i+=1
			
			index_while+=1
			if index_while == tilenumbers.size():
				index_while = 0
				
		index+=1
		if index == tilenumbers.size():
			index = 0
			
func set_cells(set_tiles, tile_number):
	for tile in set_tiles:
		set_cell(tile[0], tile[1], tile_number)

func set_abilities(piece, type):
	# try setting the pieces abilities
	match(type):
		"King":
			piece.current_attack = kinga
			piece.current_defend = kingd
			piece.recuperate = kingr
			piece.value = kingv
			piece.max_attack = kinga
			piece.max_defend = kingd
		"Queen":
			piece.current_attack = queena
			piece.current_defend = queend
			piece.recuperate = queenr
			piece.value = queenv
			piece.max_attack = queena
			piece.max_defend = queend
		"Rook":
			piece.current_attack = rooka
			piece.current_defend = rookd
			piece.recuperate = rookr
			piece.value = rookv
			piece.max_attack = rooka
			piece.max_defend = rookd
		"Bishop":
			piece.current_attack = bishopa
			piece.current_defend = bishopd
			piece.recuperate = bishopr
			piece.value = bishopv
			piece.max_attack = bishopa
			piece.max_defend = bishopd
		"Knight":
			piece.current_attack = knighta
			piece.current_defend = knightd
			piece.recuperate = knightr
			piece.value = knightv
			piece.max_attack = knighta
			piece.max_defend = knightd
		"Pawn":
			piece.current_attack = pawna
			piece.current_defend = pawnd
			piece.recuperate = pawnr
			piece.value = pawnv
			piece.max_attack = pawna
			piece.max_defend = pawnd



func add_piece(piece, tile_position, type, color = null):
	add_child(piece)
		
	piece.tile_position = tile_position
	piece.position = map_to_world(piece.tile_position)
	piece.type = type
	set_abilities(piece, piece.type)
	if board_debug: print("Piece type in Board.gd is: ", piece.type)
	# if board_debug: print("In add_piece, piece, piece.tile_position, piece.position, piece.type follows: ", piece, " || ",piece.tile_position, " || ", piece.position, " || ", piece.type)

	piece.visible = true
	
	if color == 'black' or color == null and tile_position[1] < 0:
		piece.get_child(0).visible = true
		piece.color = 'black'
	elif color == 'white' or color == null and tile_position[1] > 0:
		piece.get_child(1).visible = true
		piece.color = 'white'
	
	if piece.type == 'King':
		kings[piece.color] = piece
	
	chessmen_list.append(piece)
	chessmen_coords[tile_position] = piece

func place_type_of_pieces(type, tiles):
	for tile in tiles:
		var piece_copy = type.duplicate()
		add_piece(piece_copy, tile, type.name)

func place_pieces():
	var pieces_places = {
	$Piece/King: $Mapping.king_tiles,
	$Piece/Queen: $Mapping.queen_tiles,
	$Piece/Rook: $Mapping.rook_tiles,
	$Piece/Bishop: $Mapping.bishop_tiles,
	$Piece/Knight: $Mapping.knight_tiles,
	$Piece/Pawn: initial_pawn_tiles_black + initial_pawn_tiles_white
	}
	
	for type in pieces_places:
		place_type_of_pieces(type, pieces_places[type])
	
	if $Mapping.chess_type == 'McCooey': #these pawns aren't allowed to double-jump in McCooey version
		initial_pawn_tiles_black.erase(Vector2(0, -2))
		initial_pawn_tiles_white.erase(Vector2(0, 2))

func kill_piece(NPC):
	print("In kill NPC, NPC is: ", NPC)
	NPC.visible = false
	chessmen_list.erase(NPC)
	chessmen_coords.erase(NPC.tile_position)
	fifty_moves_counter = 0

func move_piece(piece, new_position):
	print("In move piece passed in piece, new_position as follows: ", piece, new_position)
	chessmen_coords.erase(piece.tile_position)			
	piece.position = map_to_world(new_position)
	piece.tile_position = new_position
	chessmen_coords[new_position] = piece






func promote_pawn(pawn, promotion):
	kill_piece(pawn)
	var new_piece = get_node("Piece/"+promotion).duplicate()
	add_piece(new_piece, pawn.tile_position, promotion, pawn.color)

func check_checkmate_stalemate(turn):
	for tile_piece in chessmen_coords.duplicate():
		if chessmen_coords[tile_piece].color == turn\
		and check_possible_moves(chessmen_coords[tile_piece]) != []:
			return false
	
	if if_king_checked(turn):
		return 'checkmated'
	else:
		return 'stalemated'

func if_able_to_checkmate(color):
	var pieces_dict = {'Knight': 0, 'Bishop': 0}
	var bishops = Array()
	
	for piece in chessmen_list:
		if piece.color == color:
			
			if 'Pawn' == piece.type or 'Queen' == piece.type or 'Rook' == piece.type:
				return true
				
			elif 'Knight' == piece.type:
				pieces_dict['Knight'] += 1
				
			elif 'Bishop' == piece.type:
				pieces_dict['Bishop'] += 1
				bishops.append(piece)
	
	if pieces_dict['Knight'] >= 2:
		return true
	
	elif pieces_dict['Knight'] <= 1 and pieces_dict['Bishop'] <=1:
		return false
		
	elif pieces_dict['Knight'] == 0 and pieces_dict['Bishop'] == 2:
		return false
		
	elif pieces_dict['Bishop'] >= 3 and pieces_dict['Knight'] == 0:
		var colors = Array()
		
		for bishop in bishops:
			if not tile_colors[bishop.tile_position] in colors:
				colors.append(tile_colors[bishop.tile_position])
		
		if colors.size() == 3:
			return true
		
		else:
			return false
	
	else:
		return true

func if_king_checked(turn):
	var king = kings[turn]

	for piece in chessmen_list:
		if king.tile_position in find_possible_moves(piece):
			return true
			
	return false

func clean_up_jumped_over(color):
	for tile in jumped_over_tiles.keys():
		if jumped_over_tiles[tile].color == color:
			jumped_over_tiles.erase(tile)

func update_jumped_over_tiles(moved_piece):
	if moved_piece.type == "Pawn":
		for tile in passable_tiles:
			if passable_tiles[tile] == moved_piece:
				jumped_over_tiles[tile] = moved_piece

	passable_tiles = {}
