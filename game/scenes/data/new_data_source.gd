@tool
class_name DataSourcePopup
extends PanelContainer

@onready var parent = get_parent()
@onready var window = parent if parent is ColorRect else self

var dragging := false
var drag_start_position := Vector2()
var popup_start_position := Vector2()

@export var date:OptionButton
@export var description:OptionButton
@export var amount:OptionButton
@export var source_category:OptionButton
@export var flip_amount:CheckBox
@onready var option_btns:Array[OptionButton] = [date, description, amount, source_category]
# @onready var substrings:Array[String] = ["Date", "Description", "Amount", "SourceCategory"]
# use name of btn as substring
@export var submit_btn:Button
@export var enter_name:LineEdit

@export var choose_file_btn:Button
@export var file_vbox:VBoxContainer
@export var filepath_label:RichTextLabel
@export var columns_vbox:VBoxContainer

@onready var file_dialog = FileDialog.new()

@onready var data:Array = []

@export var title_label:Label


var action:String = "add_new_data_source"
var action_data:Dictionary = {}

var old_name:String = ""


signal add_data_source
signal edit_data_source



	
func _ready() -> void:
	if not Engine.is_editor_hint():
		Html5FileExchange.web_file_canceled.connect(_on_web_file_canceled)
		Html5FileExchange.web_file_loaded.connect(_on_web_file_loaded)
	
		window.hide()
		# Configure the file dialog
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE  # Set to open file
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM  # Allow access to the file system
		file_dialog.use_native_dialog = true  # Use native Windows file picker
		file_dialog.title = "Select a CSV File"
		file_dialog.filters = ["*.csv"]
		file_dialog.file_selected.connect(_on_file_dialog_file_selected)
		file_dialog.close_requested.connect(_on_file_dialog_close_requested)
		file_dialog.canceled.connect(_on_file_dialog_close_requested)
		add_child(file_dialog)
		
	else:
		self.show()
	
	# choose_file_btn.text = "Choose File..."
	# filepath_label.hide()
	# columns_vbox.hide()
	# self.set_size(Vector2(self.size.x, get_combined_minimum_size().y))
	# self.set_anchors_preset(Control.PRESET_CENTER, true)
	# submit_btn.disabled = true
	
	for opt_btn in option_btns:
		opt_btn.item_selected.connect(_on_item_selected)
	

func _on_enter_name_text_changed(_new_text: String) -> void:
	update_submit_btn()
	
func _on_item_selected(_index:int) -> void:
	update_submit_btn()


func update_submit_btn() -> void:
	var result = is_submit_disabled()
	submit_btn.disabled = result[0]
	submit_btn.tooltip_text = result[1]
	
	
func is_name_valid(name_to_check:String) -> bool:
	# name cannot be empty
	if name_to_check == "":
		return false
		
	# name must be unique
	var data_sources = SaveLoad.load_data("data_sources")
	for src in data_sources:
		var src_name = src.name
		if name_to_check.to_lower() == src_name.to_lower():
			if src_name != old_name:
				return false
			
	return true
		
	
func is_submit_disabled() -> Array:
	
	if columns_vbox.visible == false:
		return [true, "Select a file first"]
		
	if not is_name_valid(enter_name.text):
		if enter_name.text == "":
			return [true, "Name cannot be empty"]
		else:
			return [true, "Name must be unique"]
			
	for opt_btn in option_btns:
		if opt_btn.selected == -1:
			return [true, "All column data must have a valid mapping"]

	return [false, ""]
	
	
func _on_close_pressed() -> void:
	window.hide()
	
func _on_cancel_pressed() -> void:
	window.hide()
	
	
func popup_centered(_action:String, _action_data:Dictionary) -> void:
	update_submit_btn()
	
	self.action = _action
	self.action_data = _action_data
	
	match action:
		"add_new_data_source":
			# title
			title_label.text = "Add New Data Source"
			# name
			enter_name.text = ""
			enter_name.editable = true
			enter_name.mouse_filter = Control.MOUSE_FILTER_STOP
			old_name = ""
			# raw_csv_data_filepath
			filepath_label.text = ""
			# filename
			choose_file_btn.text = "Choose File..."
			# option btns
			columns_vbox.hide()
			
		"edit_data_source":
			submit_btn.disabled = false
			
			# title
			title_label.text = "Edit Data Source"
			
			# name
			var src_name = action_data.src_name
			enter_name.text = src_name
			old_name = src_name
			# enter_name.editable = false
			# enter_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# raw_csv_data_filepath
			var raw_csv_data_filepath = ""
			var data_sources = SaveLoad.load_data("data_sources")
			var data_source
			for src in data_sources:
				if src.name == src_name:
					raw_csv_data_filepath = src.raw_csv_data_filepath
					data_source = src
			filepath_label.text = raw_csv_data_filepath
			# filename
			var filename:String = raw_csv_data_filepath.get_file()
			choose_file_btn.text = filename
			
			# reload options
			var DATA = SaveLoad.load_csv(raw_csv_data_filepath)
			data = DATA.records
			var headers = data[0]
			
			# assign option buttons to header values
			for opt_btn:OptionButton in option_btns:
				opt_btn.clear()
				# add items
				for h in headers:
					opt_btn.add_item(h)
			
			# set option btns
			for opt_btn in option_btns:
				opt_btn.selected = data_source.columns[opt_btn.name]
			
			# set flip amount
			flip_amount.button_pressed = data_source.flip_amount
			
			# show option btns
			columns_vbox.show()
			
		_:
			push_warning("No acion found: %s" % action)
	
	# Ensure the panel resizes properly
	#await get_tree().process_frame  # Wait a frame to let the UI update
	#self.custom_minimum_size = Vector2.ZERO  # Reset minimum size
	#self.queue_sort()
	#self.queue_redraw()
	#window.queue_redraw()
	
	
	window.show()

	
	#await get_tree().process_frame
	#await get_tree().process_frame  # Ensure UI updates
#
	#var new_size = get_combined_minimum_size()
	#self.size = Vector2(self.size.x, new_size.y)  # Keep X constant
#
	#queue_redraw()
	#window.queue_redraw()

	
	
# submit new data source
func _on_submit_pressed() -> void:
	window.hide()
	# add data source to main
	var new_data_source:Dictionary = {
		"name": enter_name.text,
		"raw_csv_data_filepath": filepath_label.text,
		"raw_csv_data": data,
		"transaction_csv_data": [],
		"columns": {
			"Date": date.selected,
			"Description": description.selected,
			"Amount": amount.selected,
			"SourceCategory": source_category.selected,
		},  # column mapping
		# "active": true,
		"flip_amount": flip_amount.button_pressed,
	}
	# print("data_source = ")
	# print(data_source)
	if old_name == "":
		add_data_source.emit(new_data_source)
	else:
		edit_data_source.emit(old_name, new_data_source)
	


func _on_choose_file_pressed() -> void:
	set_always_on_top(false)
	# Check if running on a web build
	if OS.has_feature("web"):
		load_file_web()
	else:
		load_file_native()
	
	

func load_file_native() -> void:
	file_dialog.popup_centered_ratio()  # Show the file dialog
	
func load_file_web() -> void:
	Html5FileExchange.load_file()

func _on_web_file_canceled() -> void:
	_on_file_dialog_close_requested()
	pass
	
func _on_web_file_loaded(file_info:Dictionary) -> void:
	
	#var file_info = {
		#"file_type": file_type, 
		#"file_name": file_name, 
		#"file_data": file_data
	#}
	
	print("file_info: ", file_info)
	set_always_on_top(true)
	# show column picker
	columns_vbox.show()
	# update labels
	filepath_label.text = "(Web Loaded File)"
	var filename:String = file_info.file_name
	choose_file_btn.text = filename
	# filepath_label.show()
	
	# now, need to load CSV header and 
	# clear / re-populate option btns with columns from CSV file
	# then auto-select columns based on substring / name
	data = file_info.file_data
	print("data = ", data)
	var headers = data[0]
	print("headers =", headers)
	# assign option buttons to header values
	for opt_btn:OptionButton in option_btns:
		opt_btn.clear()
		# add items
		for h in headers:
			opt_btn.add_item(h)
		# select default value
		var substring_to_search:String = opt_btn.name
		if substring_to_search == "SourceCategory":
			substring_to_search = "Category"
		# date, description, amount, category
		var index:int = get_first_substring(headers, substring_to_search)
		opt_btn.select(index)
	
	# by default, update name to filename if empty
	if enter_name.text == "":
		enter_name.text = filename
	else:
		print(enter_name)
		print(enter_name.text)
	
	# enable submit button if all options have a value (not -1)
	# and there is a name (not "")
	# submit_btn.disabled = false
	update_submit_btn()
	
	
	
# update always on top
func _on_file_dialog_close_requested() -> void:
	print("cancel or close requested")
	set_always_on_top(true)
	
func _on_file_dialog_file_selected(data_filepath:String) -> void:
	print("file selected: ", data_filepath)
	set_always_on_top(true)
	# show column picker
	columns_vbox.show()
	# update labels
	filepath_label.text = data_filepath
	var filename:String = data_filepath.get_file()
	choose_file_btn.text = filename
	# filepath_label.show()
	
	# now, need to load CSV header and 
	# clear / re-populate option btns with columns from CSV file
	# then auto-select columns based on substring / name
	var DATA = SaveLoad.load_csv(data_filepath)
	data = DATA.records
	print("data = ", data)
	var headers = data[0]
	print("headers =", headers)
	# assign option buttons to header values
	for opt_btn:OptionButton in option_btns:
		opt_btn.clear()
		# add items
		for h in headers:
			opt_btn.add_item(h)
		# select default value
		var substring_to_search:String = opt_btn.name
		if substring_to_search == "SourceCategory":
			substring_to_search = "Category"
		# date, description, amount, category
		var index:int = get_first_substring(headers, substring_to_search)
		opt_btn.select(index)
	
	# by default, update name to filename if empty
	if enter_name.text == "":
		enter_name.text = filename
	
	# enable submit button if all options have a value (not -1)
	# and there is a name (not "")
	# submit_btn.disabled = false
	update_submit_btn()


# get first occurance of substring in list, or -1 if not found
func get_first_substring(list:Array, substring:String) -> int:
	var index:int = 0
	for string in list:
		if substring.to_lower() in string.to_lower():
			return index
		index += 1
	return -1
	
	
func set_always_on_top(input:bool) -> void:
	get_window().always_on_top = input
	
	
# =======================
# Dragging Logic
# =======================

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

func _process(_delta: float) -> void:
	if dragging:
		var mouse_pos = get_global_mouse_position()
		self.global_position = popup_start_position + (mouse_pos - drag_start_position)
