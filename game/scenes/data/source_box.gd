class_name SourceBox
extends HBoxContainer

@export var name_label:Label
@export var view_data:Button
@export var edit_data:Button
@export var delete_data:Button

@export var active_checkbox:CheckBox

@export var src_name:String = ""


func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

func _get_drag_data(_pos: Vector2):
	var preview = duplicate()  # Create a copy of this node for the preview
	preview.modulate.a = 0.5   # Make it semi-transparent
	
	var c = Control.new()
	c.add_child(preview)
	preview.position = Vector2.ZERO - _pos
	
	set_drag_preview(c)
	return self  # Return self to indicate it's being dragged

func _can_drop_data(_pos: Vector2, _data):
	return _data is HBoxContainer  # Only accept other HBoxContainers

func _drop_data(_pos: Vector2, _data):
	var parent_vbox = get_parent() as VBoxContainer
	if not parent_vbox:
		return

	# Get current and target indices
	var old_index = parent_vbox.get_children().find(_data)
	var new_index = parent_vbox.get_children().find(self)

	# Swap positions within the parent VBoxContainer
	if old_index != new_index:
		parent_vbox.move_child(_data, new_index)
		save_new_order(old_index, new_index)
		
		
func save_new_order(old_index:int, new_index:int) -> void:
	var data_sources = SaveLoad.load_data("data_sources")

	# Remove the old element
	var temp = data_sources.pop_at(old_index)

	# Insert at the new index (handling out-of-bounds cases)
	data_sources.insert(new_index, temp)

	# Save the updated order
	SaveLoad.save_data("data_sources", data_sources)
	


func _on_active_checkbox_toggled(toggled_on: bool) -> void:
	var data_sources = SaveLoad.load_data("data_sources")
	
	var index:int = 0
	var i:int = 0
	for src in data_sources:
		if src.name == src_name:
			index = i
		i += 1
		
	data_sources[index].active = toggled_on
	SaveLoad.save_data("data_sources", data_sources)
