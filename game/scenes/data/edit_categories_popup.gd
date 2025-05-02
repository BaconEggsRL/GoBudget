@tool
class_name EditCategoriesPopup
extends PanelContainer

@onready var parent = get_parent()
@onready var window = parent if parent is ColorRect else self


# Drag movement

var dragging := false
var drag_start_position := Vector2()
var popup_start_position := Vector2()

var is_maximized := false
var original_position: Vector2
var original_size: Vector2



# Drag resizing 

var resizing := false
var drag_start: Vector2
var resize_direction: String = ""  # To keep track of the edge being resized (horizontal or vertical)

# Define the resize zone area (e.g., the area around the edges)
const RESIZE_ZONE_SIZE = 15  # Pixels on the edge for resizing

@onready var resizable_area = self



@export var maximize_btn:Button
@export var confirm_btn:Button
@export var abort_btn:Button

@export var title_label:Label

var action:String = "edit_categories"
var action_data:Dictionary = {}


const CATEGORY = preload("res://scenes/data/category.tscn")
@export var cat_container:VBoxContainer
@export var scroll_container:ScrollContainer

signal confirmed

	
func _ready() -> void:
	if not Engine.is_editor_hint():
		# load save data categories
		_hide_and_reset_window_data()
		# resize
		# Set up mouse filters for the resizable area
		resizable_area.mouse_filter = Control.MOUSE_FILTER_PASS
		resizable_area.connect("gui_input", _on_resizable_area_input)
	else:
		self.show()
	

func _on_resizable_area_input(event: InputEvent):
	# print(event)
	
	if event is InputEventMouseMotion and not resizing:
		_check_resize_cursor(event.position)
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and resize_direction != "":
			# Start resizing
			resizing = true
			drag_start = get_global_mouse_position()
			original_size = size
			original_position = global_position
		elif not event.pressed and resizing:
			# Stop resizing
			resizing = false
			resize_direction = ""
			original_size = size
			original_position = global_position
		


# Check if the mouse is hovering over the edges (uses local position of input event.)
func _check_resize_cursor(mouse_position: Vector2):
	# print(mouse_position)
	
	# Check if mouse is within the resize zone
	if mouse_position.x <= RESIZE_ZONE_SIZE:
		# Left edge
		if mouse_position.y <= RESIZE_ZONE_SIZE:
			# Top-left corner
			_set_cursor(Control.CursorShape.CURSOR_FDIAGSIZE)
			resize_direction = "top_left"
		elif mouse_position.y >= size.y - RESIZE_ZONE_SIZE:
			# Bottom-left corner
			_set_cursor(Control.CursorShape.CURSOR_BDIAGSIZE)
			resize_direction = "bottom_left"
		else:
			# Left edge
			_set_cursor(Control.CursorShape.CURSOR_HSIZE)
			resize_direction = "left"
	elif mouse_position.x >= size.x - RESIZE_ZONE_SIZE:
		# Right edge
		if mouse_position.y <= RESIZE_ZONE_SIZE:
			# Top-right corner
			_set_cursor(Control.CursorShape.CURSOR_BDIAGSIZE)
			resize_direction = "top_right"
		elif mouse_position.y >= size.y - RESIZE_ZONE_SIZE:
			# Bottom-right corner
			_set_cursor(Control.CursorShape.CURSOR_FDIAGSIZE)
			resize_direction = "bottom_right"
		else:
			# Right edge
			_set_cursor(Control.CursorShape.CURSOR_HSIZE)
			resize_direction = "right"
	elif mouse_position.y <= RESIZE_ZONE_SIZE:
		# Top edge
		_set_cursor(Control.CursorShape.CURSOR_VSIZE)
		resize_direction = "top"
	elif mouse_position.y >= size.y - RESIZE_ZONE_SIZE:
		# Bottom edge
		_set_cursor(Control.CursorShape.CURSOR_VSIZE)
		resize_direction = "bottom"
	else:
		# Reset cursor if not over a resize zone
		_set_cursor(Control.CursorShape.CURSOR_ARROW)
		resize_direction = ""
	
	# print(mouse_position, resize_direction)
		


func _set_cursor(shape:Control.CursorShape, control:Control=self) -> void:
	control.mouse_default_cursor_shape = shape
	
	
# Resize the panel based on the direction
func _resize_panel(mouse_position: Vector2):
	# print("resizing")
	# print(mouse_position, drag_start)
	var delta = mouse_position - drag_start
	
	# Define minimum size constraints
	var min_width: int = 400  # Minimum width in pixels
	var min_height: int = 360  # Minimum height in pixels

	match resize_direction:
		"top":
			var new_height = original_size.y - delta.y
			if new_height >= min_height:
				size.y = new_height
				global_position.y = original_position.y + delta.y
		"bottom":
			size.y = max(original_size.y + delta.y, min_height)
		"left":
			var new_width = original_size.x - delta.x
			if new_width >= min_width:
				size.x = new_width
				global_position.x = original_position.x + delta.x
		"right":
			size.x = max(original_size.x + delta.x, min_width)
		"top_left":
			var new_width = original_size.x - delta.x
			var new_height = original_size.y - delta.y
			if new_width >= min_width:
				size.x = new_width
				global_position.x = original_position.x + delta.x
			if new_height >= min_height:
				size.y = new_height
				global_position.y = original_position.y + delta.y
		"top_right":
			var new_width = original_size.x + delta.x
			var new_height = original_size.y - delta.y
			size.x = max(new_width, min_width)
			if new_height >= min_height:
				size.y = new_height
				global_position.y = original_position.y + delta.y
		"bottom_left":
			var new_width = original_size.x - delta.x
			var new_height = original_size.y + delta.y
			if new_width >= min_width:
				size.x = new_width
				global_position.x = original_position.x + delta.x
			size.y = max(new_height, min_height)
		"bottom_right":
			size.x = max(original_size.x + delta.x, min_width)
			size.y = max(original_size.y + delta.y, min_height)
	
	

func clear_window_data() -> void:
	var _parent = cat_container
	for child in _parent.get_children():
		child.queue_free()
	await get_tree().process_frame


func load_save_data() -> void:
	# clear existing data, if it exists
	await clear_window_data()
	# load data
	var categories:Dictionary = SaveLoad.load_data("categories")
	var categories_order:Array = SaveLoad.load_data("categories_order")
	
	var _cats = categories_order
	for cat in _cats:
		var _subcats = categories[cat].subs
		var _budget = categories[cat].budget
		var temp = add_cat(cat, _budget)
		for subcat in _subcats:
			temp.add_subcat(subcat)
	# update order labels
	_update_order_text()
		


func add_cat(placeholder_name:String="Category", budget:float=0.0) -> CategoryVBox:
	print("create category")
	var _parent = cat_container
	var new_child:CategoryVBox = CATEGORY.instantiate()
	
	# update name
	new_child.category_name.placeholder_text = placeholder_name
	# update budget
	new_child.budget.value = budget
	
	# add child
	_parent.add_child(new_child)
	# connect signals
	_connect_cat_signals(new_child)
	return new_child
	

func get_order_text(num_str:String) -> String:
	return "   " + num_str + ") "

func _connect_cat_signals(new_child:CategoryVBox) -> void:
	new_child.new_cat_name.connect(_on_new_cat_name)
	new_child.delete_cat.connect(_on_delete_cat_pressed)
	new_child.new_cat_order.connect(_on_new_cat_order)
	pass
	

func _on_delete_cat_pressed(cat:CategoryVBox) -> void:
	print("delete category: %s" % str(cat))
	cat.queue_free.call_deferred()
	await get_tree().process_frame
	_update_order_text.call_deferred()


func _on_new_cat_order() -> void:
	_update_order_text.call_deferred()
	
func _update_order_text() -> void:
	await get_tree().process_frame
	var _parent = cat_container
	var count = 1
	for child:CategoryVBox in cat_container.get_children():
		child.order_label.text = get_order_text(str(count))
		child.order_num = count
		count += 1
	
	
func _on_new_cat_name(new_text:String) -> void:
	print(new_text)
	
	
	
func popup_centered(_action:String, _action_data:Dictionary) -> void:
	self.action = _action
	self.action_data = _action_data
	
	match action:
		"edit_categories":
			self.title_label.text = "Edit Categories"
			load_save_data()
		_:
			push_warning("No acion found: %s" % action)
			
	window.show()


func _on_maximize_pressed() -> void:
	if not is_maximized:
		original_position = self.global_position
		original_size = self.size

		self.global_position = Vector2.ZERO
		self.size = get_viewport_rect().size
		is_maximized = true
	else:
		self.global_position = original_position
		self.size = original_size
		is_maximized = false
		
		
func _on_confirm_pressed() -> void:
	# save categories in line edits to global and update placeholder text
	# update action data to contain new category data
	
	# update line edits (save new text as category)
	var categories:Dictionary = {}
	var categories_order:Array = []
	
	var cats = cat_container.get_children()
	
	for cat:CategoryVBox in cats:
		var cat_name = cat.category_name
		if cat_name.text != "":
			cat_name.placeholder_text = cat_name.text
			cat_name.text = ""
			
		var cat_str = cat_name.placeholder_text
		# var order_num = cat.order_num
		
		var temp = []  # placeholder array for subcats

		for subcat in cat.subcats.get_children():
			if subcat is SubcategoryHBox:
				var subcat_name = subcat.subcategory_name
				if subcat_name.text != "":
					subcat_name.placeholder_text = subcat_name.text
					subcat_name.text = ""
					
				var subcat_str = subcat_name.placeholder_text
				
				temp.append(subcat_str)
				
		# update cat
		categories[cat_str] = {}  # initialize empty dictionary
		categories[cat_str].subs = temp
		categories[cat_str].budget = cat.budget.value
		
		# append to order
		categories_order.append(cat_str)
		
		print(categories_order)

	
	# build dict from nodes
	# Dict of categories and subcategories array
	#@export var categories:Dictionary[String, Array] = {
		#"Housing": ["Rent & Utilities"],
		#"Insurance": ["Renters Insurance", "Car Insurance"],
		#"Food": ["Supermarkets", "Restaurants"],
		#"Transportation": ["Gasoline"],
		#"Subscriptions": ["Phone Bill", "Crunchyroll", "Spotify"],
		#"Misc": ["Merchandise"]
	#}

	# debug print
	# action_data = categories
	# print(action_data)
	
	# scroll to top
	# scroll_to_top.call_deferred()
	
	

	
	
	# update save data
	SaveLoad.save_data("categories", categories)
	await get_tree().process_frame
	SaveLoad.save_data("categories_order", categories_order)
	await get_tree().process_frame

	# check
	var load_cat_test = SaveLoad.load_data("categories")
	print("loaded cat data: ", load_cat_test)
	var load_order_test = SaveLoad.load_data("categories_order")
	print("loaded order data: ", load_order_test)
	
	# hide
	window.hide()
	
	# emit signal
	confirmed.emit(action, action_data)
	
	
	
	
func _on_close_pressed() -> void:
	_hide_and_reset_window_data()

func _on_abort_pressed() -> void:
	_hide_and_reset_window_data()


# when action is aborted or canceled, discard changes by reloading saved data.
func _hide_and_reset_window_data() -> void:
	window.hide()
	# clear existing data and load save data
	load_save_data()
	

	

func _on_create_category_pressed() -> void:
	add_cat()
	# update order labels
	_update_order_text()
	# scroll to bottom
	scroll_to_bottom.call_deferred()

func scroll_to_bottom():
	await get_tree().process_frame
	scroll_container.scroll_vertical = ceil(scroll_container.get_v_scroll_bar().max_value)

func scroll_to_top():
	await get_tree().process_frame
	scroll_container.scroll_vertical = 0

# =======================
# Dragging Logic
# =======================

# drag movement
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Start dragging
				dragging = true
				drag_start_position = mouse_event.global_position
				popup_start_position = self.global_position
			else:
				# Stop dragging
				dragging = false
#

func _process(_delta: float) -> void:
	if resizing:
		var mouse_pos = get_global_mouse_position()
		_resize_panel(mouse_pos)
		return
	if dragging:
		var mouse_pos = get_global_mouse_position()
		self.global_position = popup_start_position + (mouse_pos - drag_start_position)
		return
	
