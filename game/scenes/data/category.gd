class_name CategoryVBox
extends VBoxContainer


const SUBCATEGORY = preload("res://scenes/data/subcategory.tscn")


@export var subcats:VBoxContainer
# @onready var subcat_1: SubcategoryHBox = $subcats/subcat1
@export var order_num:int
@export var order_label:Label
@export var category_name:LineEdit
@export var budget:SpinBox


signal new_cat_name
signal delete_cat
signal new_cat_order


func _ready() -> void:
	# _connect_subcat_signals(subcat_1)
	pass
	


func add_subcat(placeholder_name:String="Subcategory") -> void:
	print("create sub-category")
	var parent = subcats
	var new_child:SubcategoryHBox = SUBCATEGORY.instantiate()
	# update name
	new_child.subcategory_name.placeholder_text = placeholder_name
	# add child subcat and move to 2nd to last position (before add btn)
	parent.add_child(new_child)
	var index = max(parent.get_child_count() - 2, 0)
	parent.move_child(new_child, index)
	# connect signals
	_connect_subcat_signals(new_child)
	


func _connect_subcat_signals(new_child:SubcategoryHBox) -> void:
	new_child.new_subcat_name.connect(_on_new_subcat_name)
	new_child.delete_subcat.connect(_on_delete_subcat_pressed)



func _on_create_subcategory_pressed() -> void:
	self.add_subcat()

func _on_delete_subcat_pressed(subcat:SubcategoryHBox) -> void:
	print("delete sub-category: %s" % str(subcat))
	subcat.queue_free.call_deferred()
	
func _on_new_subcat_name(new_text:String) -> void:
	print(new_text)




func _on_category_name_text_changed(new_text: String) -> void:
	new_cat_name.emit(new_text)


func _on_delete_category_pressed() -> void:
	delete_cat.emit(self)





#func _ready():
	#mouse_filter = Control.MOUSE_FILTER_PASS

# this works but there's no previw
func _get_drag_data(_pos: Vector2):
	
	var cat = get_node("cat")
	var preview_test:Control = cat.duplicate()
	preview_test.modulate.a = 0.5
	preview_test.size.x = cat.size.x # / 2.0
	
	#var preview_label = Label.new()
	#preview_label.text = category_name.text if category_name.text != "" else category_name.placeholder_text
	#preview_label.modulate.a = 0.5
	
	var preview_wrapper = Control.new()
	
	preview_wrapper.add_child(preview_test)
	preview_test.position = -_pos
	
	set_drag_preview(preview_wrapper)
	
	return self
	
	
	
	

func _can_drop_data(_pos: Vector2, _data):
	return _data is CategoryVBox  # Only accept other CategoryVBox

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
		new_cat_order.emit()
