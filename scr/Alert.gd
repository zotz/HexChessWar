extends PopupPanel

func open(txt: String, duration):
	print("Made it to open in Alert...", txt, " ", duration)
	$c/Label.text = txt
	#$HUD.show()
	popup_centered()
	$Timer.start(duration)


func _on_Timer_timeout():
	#$HUD.hide()
	hide()
