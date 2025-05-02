class_name SubcategoryHBox
extends HBoxContainer

@export var subcategory_name:LineEdit
@export var delete_subcategory:Button

signal new_subcat_name
signal delete_subcat

func _ready() -> void:
	# subcategory_name.placeholder_text = ""
	pass

func _on_delete_subcategory_pressed() -> void:
	delete_subcat.emit(self)

func _on_subcategory_name_text_changed(new_text: String) -> void:
	new_subcat_name.emit(new_text)
