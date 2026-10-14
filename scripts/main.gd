extends Control

func _on_start_pressed() -> void:
	$StartButton.hide()
	$GameRoot.show()


func _on_action_pressed() -> void:
	$GameRoot/StatusLabel.text = "Akcja wykonana. (Na razie test kliknięcia.)"


func _on_options_pressed() -> void:
	$GameRoot/OptionsPanel.visible = not $GameRoot/OptionsPanel.visible
