extends Control


const OUTPUT_GRAPH_NODE = preload("res://scenes/rules/nodes/output_graph_node.tscn")
const CONDITIONAL_GRAPH_NODE = preload("res://scenes/rules/nodes/conditional_graph_node.tscn")
const AMOUNT_CHECK_NODE = preload("res://scenes/rules/nodes/amount_check_node.tscn")
const LOGIC_GATE_NODE = preload("res://scenes/rules/nodes/logic_gate_node.tscn")

const SOURCE_BOX = preload("res://scenes/data/source_box.tscn")


var first_load:bool = true

@export var rules_container:Control
@export var rules_graph:GraphEdit
@export var graph_options:HBoxContainer
@onready var graph_menu_hbox:HBoxContainer = rules_graph.get_menu_hbox()


@export var result_label:Label

@export var debugger_description:LineEdit
@export var debugger_amount:SpinBox
@export var debugger_source_category:LineEdit

# popups
@export var save_popup:SavePopupPanel
@export var add_node_popup:AddNodePopupPanel
@export var right_click_popup:RightClickPopup
@export var data_source_popup:DataSourcePopup
@export var confirmation_popup:ConfirmationPopup
@export var edit_categories_popup:EditCategoriesPopup

@export var data_sources_container:VBoxContainer
@export var data_sources_menu:VBoxContainer


@export var table_container:Control
@export var plot_container:BaconChart

@export var raw_table_container:Control
@export var raw_table:DynamicTable
@export var transaction_table:DynamicTable

# Reference to dynamic table
@export var dynamic_table:DynamicTable


var headers				# array of columns header
var data				# array of data, rows and columns
var ordering = true		# default sorting direction, ascending 
var last_column = -1	# last sorted column
var selected_row = -1	# last selected row

@onready var file_dialog := FileDialog.new()
# @export var selected_folder_label:RichTextLabel
@export var selected_folder_label:LineEdit


@export var month_option_btn:OptionButton
@export var year_option_btn:OptionButton


@onready var time = Time.get_datetime_dict_from_system()
@onready var year:int = time["year"]
@onready var month:int = time["month"]
@onready var day:int = time["day"]

@onready var month_options:Array = []
@onready var year_options:Array = []  # populated at runtime

@onready var data_filepath:String = ""  # res://transactions/dummy_transactions.csv

@export var load_data:Button
@export var show_table:Button
@export var show_plot:Button

@onready var current_view:String = ""


func dir_contents(path:String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
				dir_contents(file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		

	
	
func _ready():

	raw_table_container.hide()
	
	# edit categories popup
	edit_categories_popup.confirmed.connect(_on_edit_categories_confirmed)
	# confirmation popup
	confirmation_popup.confirmed.connect(_on_confirmation_popup_confirmed)
	# data source popup
	data_source_popup.add_data_source.connect(_on_add_new_data_source)
	data_source_popup.edit_data_source.connect(_on_edit_data_source)
	# load data sources
	for c in data_sources_container.get_children():
		c.free()
	var data_sources = SaveLoad.load_data("data_sources")
	for src in data_sources:
		add_source_to_list(src)
		pass
	
	# right click menu
	right_click_popup.paste.connect(_on_paste_nodes)
	right_click_popup.delete.connect(_on_delete_nodes)
	right_click_popup.add_node.connect(show_add_node_popup)
	
	# add node popup
	add_node_popup.add_node.connect(add_node)
	
	# save popup
	save_popup.save.connect(_on_save_graph_pressed)
	
	# move graph buttons to menu hbox
	graph_options.reparent(graph_menu_hbox)
	

	# hide menus
	rules_container.hide()
	table_container.hide()
	plot_container.hide()
	
	
	# Configure the file dialog
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR  # Set to select directories
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM  # Allow access to the file system
	file_dialog.use_native_dialog = true  # Use native Windows file picker
	file_dialog.title = "Select a Folder"
	file_dialog.dir_selected.connect(_on_file_dialog_folder_selected)
	file_dialog.close_requested.connect(_on_file_dialog_close_requested)
	file_dialog.canceled.connect(_on_file_dialog_close_requested)
	add_child(file_dialog)
	
	# update transaction folder
	selected_folder_label.text = SaveLoad.load_data("transaction_folder")
	
	# update year / month options
	update_options()
	
	####################################################################
	
	# Signals connections
	dynamic_table.cell_selected.connect(_on_cell_selected.bind(dynamic_table))
	dynamic_table.header_clicked.connect(_on_header_clicked.bind(dynamic_table))
	dynamic_table.column_resized.connect(_on_column_resized.bind(dynamic_table))
	
	raw_table.cell_selected.connect(_on_cell_selected.bind(raw_table))
	raw_table.header_clicked.connect(_on_header_clicked.bind(raw_table))
	raw_table.column_resized.connect(_on_column_resized.bind(raw_table))
	
	transaction_table.cell_selected.connect(_on_cell_selected.bind(transaction_table))
	transaction_table.header_clicked.connect(_on_header_clicked.bind(transaction_table))
	transaction_table.column_resized.connect(_on_column_resized.bind(transaction_table))
	
	####################################################################

	# load rules
	_on_load_graph_pressed()



# update plot data
func init_plot() -> void:
	var _categories = SaveLoad.load_data("categories")
	var _data = data
	
	var sum = {}
	
	for i in range(0, _data.size()):
		var transaction = _data[i]
		print(transaction)
		
		var amount = float(transaction[2])  # amount
		var cat:String = transaction[4]  # category
		# var cat:String = transaction[3]  # source category
		
		if not cat.is_empty() and amount is float:
			if not sum.has(cat):
				sum[cat] = amount
			else:
				sum[cat] = sum[cat] + amount
			
	print("sum = ", sum)
	var sum_array = []
	for cat in sum.keys():
		sum_array.append({"x": cat, "y": sum[cat]})
		
	print("sum_array = ", sum_array)
	plot_container.chart_area.update_data(sum_array, _categories)
	
	# Enable plot btn
	show_plot.disabled = false
	
	

func init_table() -> void:
	# Set table header
	# headers = ["ID|C", "Name", "Lastname", "Age|r", "Job", "City"] # use |align for alignment columns (l, c, r or L, C, R)
	var _data = data
	headers = _data.pop_at(0)
	# headers = data.pop_front()
	# print(data)  # array of data
	dynamic_table.set_headers(headers)
	
	# Insert data table
	dynamic_table.set_data(_data)

	# Enable table btn
	show_table.disabled = false



#####################################


# On selected cell callback
func _on_cell_selected(row, column, table) -> void:
	print("Cell selected on row ", row, ", column ", column)
	print("Cell value: ", table.get_cell_value(row, column))
	print("Row value: ", table.get_row_value(row))
	selected_row = row

# On clicked header cell callback
func _on_header_clicked(column, table) -> void:
	print("Header clicked on column ", column)
	if (column == last_column):
		ordering = not ordering			# invert previous column sort direction
	else:
		ordering = true				# default sort ordering direction
	var new_row = table.ordering_data(column, ordering, selected_row)
	selected_row = new_row				# restoring potential previous row selected
	last_column = column 
	table._selected_cell = [new_row, last_column] # select row at the nuew position

# On resized column callback
func _on_column_resized(column, new_width, table) -> void:
	print(table, " says: Column ", column, " resized at width ", new_width)


#####################################

func update_options() -> void:
	update_year_options()
	update_month_options()

func clear_options() -> void:
	clear_year_options()
	clear_month_options()

func clear_year_options() -> void:
	year_option_btn.clear()
	# update_data_filepath()

func clear_month_options() -> void:
	month_option_btn.clear()
	update_data_filepath()
	
func update_year_options() -> void:
	var folder:String = SaveLoad.load_data("transaction_folder")
	if not folder == "":
		year_options = DirAccess.get_directories_at(folder)
		_populate_option_button(year_option_btn, year_options)
		year_option_btn.select(year_options.size()-1)
		# print("dirs == ",dirs)
		# print(get_dir_contents(SaveLoad.load_data("transaction_folder")))
	
func update_month_options() -> void:
	if not year_options.is_empty():
		month_options = DirAccess.get_directories_at(SaveLoad.load_data("transaction_folder") + "/" + year_option_btn.get_item_text(year_option_btn.selected))
		_populate_option_button(month_option_btn, month_options)
		# month_option_btn.select(month-1)
		month_option_btn.select(month_options.size()-1)
		update_data_filepath()
	else:
		clear_month_options()


func _on_select_folder_pressed() -> void:
	set_always_on_top(false)
	file_dialog.popup_centered_ratio()  # Show the file dialog

func _on_file_dialog_close_requested() -> void:
	# print("cancel or close requested")
	set_always_on_top(true)
	
func _on_file_dialog_folder_selected(path: String) -> void:
	print("Selected folder: ", path)
	# You can store this path or use it as needed
	SaveLoad.save_data("transaction_folder", path)
	selected_folder_label.text = path
	update_options()
	set_always_on_top(true)

func set_always_on_top(input:bool) -> void:
	get_window().always_on_top = input
	
	

func _on_clear_data_pressed() -> void:
	SaveLoad._reset()
	selected_folder_label.text = SaveLoad.load_data("transaction_folder")
	clear_options()
	show_table.disabled = true
	show_plot.disabled = true
	rules_container.hide()
	table_container.hide()
	plot_container.hide()
	


func _populate_option_button(option_button:OptionButton, list:Array) -> void:
	option_button.clear()  # Remove any existing items
	for option in list:
		option_button.add_item(option)


func _on_add_month_pressed() -> void:
	var next:int = (month_option_btn.selected + 1) % month_options.size()
	month_option_btn.select(next)


func _on_subtract_month_pressed() -> void:
	var next: int = (month_option_btn.selected - 1 + month_options.size()) % month_options.size()
	month_option_btn.select(next)


func _on_current_month_pressed() -> void:
	# month_option_btn.select(month-1)
	month_option_btn.select(month_options.size()-1)



func _on_add_year_pressed() -> void:
	var next:int = (year_option_btn.selected + 1) % year_options.size()
	year_option_btn.select(next)


func _on_current_year_pressed() -> void:
	year_option_btn.select(year_options.size()-1)


func _on_subtract_year_pressed() -> void:
	var next: int = (year_option_btn.selected - 1 + year_options.size()) % year_options.size()
	year_option_btn.select(next)


func _on_year_btn_item_selected(_index: int) -> void:
	update_month_options()

func _on_month_btn_item_selected(_index: int) -> void:
	update_data_filepath()


func update_data_filepath() -> void:
	var folder:String = SaveLoad.load_data("transaction_folder")
	if not (folder == "" or year_options.is_empty() or month_options.is_empty()):
		#if folder.ends_with("/"):
			#folder = folder.substr(0, folder.length() - 1)
			
		data_filepath = folder + \
		"/" + \
		year_option_btn.get_item_text(year_option_btn.selected) + \
		"/" + \
		month_option_btn.get_item_text(month_option_btn.selected) + \
		"/" + \
		"transactions.csv"
	else:
		data_filepath = ""
	print("data_filepath = '%s'" % data_filepath)
	
	var file_exists = FileAccess.file_exists(data_filepath)
	if file_exists:
		load_data.disabled = false
	else:
		load_data.disabled = true

	
	
func _on_load_data_pressed() -> void:
	var file_exists = FileAccess.file_exists(data_filepath)
	if file_exists:
		var DATA = SaveLoad.load_csv(data_filepath)
		update_data(DATA.records)

func update_data(new_data:Array) -> void:
	data = new_data
	print("data = ", data)
	init_table()
	init_plot()


func _on_show_table_pressed() -> void:
	table_container.visible = !table_container.visible
	plot_container.hide()
	rules_container.hide()
	data_sources_menu.visible = not table_container.visible
	raw_table_container.hide()
	


func _on_show_plot_pressed() -> void:
	table_container.hide()
	plot_container.visible = !plot_container.visible
	rules_container.hide()
	data_sources_menu.visible = not plot_container.visible
	raw_table_container.hide()
		


func _on_edit_rules_pressed() -> void:
	table_container.hide()
	plot_container.hide()
	rules_container.visible = !rules_container.visible
	if first_load:
		_on_load_graph_pressed()
		first_load = false
	data_sources_menu.visible = not rules_container.visible
	raw_table_container.hide()



func add_node(node:SimpleGraphNode, use_context:bool=false) -> void:
	# get nodes
	var nodes = get_tree().get_nodes_in_group("graph_node")
	var num_nodes = nodes.size()

	# add node
	rules_graph.add_child(node)
	
	# set name
	node.node_name = node.name
	
	# set title
	node.title += " " + str(num_nodes+1)
	node.node_title = node.title

	# get node position
	var offset := Vector2.ZERO
	# use right click menu position
	if use_context:
		offset = right_click_popup.spawn_pos
	# use mouse position
	else:
		offset = (get_viewport().get_mouse_position() + rules_graph.scroll_offset) / rules_graph.zoom
	# set position
	node.position_offset = offset
	node.node_offset = offset
	
	# connect node signals
	node.change_title.connect(_on_node_change_title)
	


func _on_add_node_pressed() -> void:
	self.show_add_node_popup()
	
func show_add_node_popup() -> void:
	# show popup
	add_node_popup.show()
	



func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	# Remove existing connections, if any (each port only allows one connection.)
	for connection in rules_graph.connections:
		if connection["to_node"] == to_node and connection["to_port"] == to_port:
			# Remove the existing connection
			rules_graph.disconnect_node(connection["from_node"], connection["from_port"], to_node, to_port)
			
	# Make the connection
	rules_graph.connect_node(from_node, from_port, to_node, to_port)


func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	rules_graph.disconnect_node(from_node, from_port, to_node, to_port)


# sort list ascending (0,1,2,3...)
func sort_ascending(a:OutputGraphNode, b:OutputGraphNode):
	if a.priority.value < b.priority.value:
		return true
	return false

# sort list descending (3,2,1,0...)
func sort_descending(a:OutputGraphNode, b:OutputGraphNode):
	if a.priority.value > b.priority.value:
		return true
	return false
	
# debug graph output
func _on_get_result_pressed(transaction:={}) -> Array:
	var output_graph_nodes:Array = get_tree().get_nodes_in_group("output_graph_node")
	# first sort the graph nodes according to priority (higher priorty = returns first.)
	output_graph_nodes.sort_custom(sort_descending)
	# now iterate through sorted nodes and get output
	var result:Array = []
	for n in output_graph_nodes:
		if n is OutputGraphNode:  # redundant check for autocomplete
			result = eval_expression(n, transaction)
			if not result.is_empty():
				print("result = ", result)
				result_label.text = "result = %s" % str(result)
				return result
	# if no output
	result = ["Misc", "Merchandise"]
	print("result = ", result)
	result_label.text = "result = %s" % str(result)
	return result


# save the state of the graph edit node
func _on_save_graph_pressed() -> void:
	
	var graph_dict:Dictionary = SaveLoad.load_data("graph")
	
	graph_dict.nodes.clear()
	graph_dict.edges.clear()

	for n in rules_graph.get_children():
		if n is SimpleGraphNode:
			var node_dict = {}

			# node data
			node_dict.node_data = {}
			if n is OutputGraphNode:
				node_dict.node_type = "OutputGraphNode"
				node_dict.node_data.cat_idx = n.cat.selected
				node_dict.node_data.subcat_idx = n.subcat.selected
				node_dict.node_data.priority = n.priority.value
			elif n is ConditionalGraphNode:
				node_dict.node_type = "ConditionalGraphNode"
				node_dict.node_data.substring = n.substring.text
				node_dict.node_data.idx = n.column_name.selected
			elif n is AmountCheckNode:
				node_dict.node_type = "AmountCheckNode"
				node_dict.node_data.idx = n.condition.selected
				node_dict.node_data.abs_btn = n.abs_btn.button_pressed
				node_dict.node_data.amount = n.amount.value
			elif n is LogicGateNode:
				node_dict.node_type = "LogicGateNode"
				node_dict.node_data.idx = n.gate.selected
				node_dict.node_data.inputs = n.inputs.value
				
				
			# print(item_node.node_type)
			# print(item_node.node_data)
			
			# common data
			node_dict.node_name = n.name # the name is generated uniquely by simply incrementing an integer and writing "node_" + str(node_index).
			node_dict.node_offset = n.position_offset
			node_dict.node_title = n.title
			
			# color data
			node_dict.node_color_frame = n.node_color_frame
			node_dict.node_color_selected = n.node_color_selected
			
			# size data
			node_dict.node_size = n.size

			graph_dict.nodes.append(node_dict)
			

	for c in rules_graph.get_connection_list():
		var edge = {}
		edge.from_node_name = c["from_node"]
		edge.from_port = c["from_port"]
		edge.to_node_name = c["to_node"]
		edge.to_port = c["to_port"]
		
		graph_dict.edges.append(edge)
		
		
	SaveLoad.save_data("graph", graph_dict)
	
	print("saved graph = ", graph_dict)


func _on_load_graph_pressed() -> void:
	
	var graph_dict:Dictionary = SaveLoad.load_data("graph")

	# delete everything
	rules_graph.clear_connections()
	for n in rules_graph.get_children():
		if n is GraphNode:
			n.free()

	# create nodes
	var node_map = {}  # Store node references by name
	for node_dict in graph_dict.nodes:
		# node
		var n:SimpleGraphNode = await _get_node_from_dict(node_dict)

		######################################################
		# load name
		n.name = node_dict.node_name
		
		# load position
		n.position_offset = node_dict.node_offset
		
		# Store reference
		node_map[node_dict.node_name] = n  

	# Create connections (ensure nodes exist first)
	for c in graph_dict.edges:
		if c.from_node_name in node_map and c.to_node_name in node_map:
			rules_graph.connect_node(c.from_node_name, c.from_port, c.to_node_name, c.to_port)

	# Force UI to update
	rules_graph.queue_redraw()
	
	print("loaded graph = ", graph_dict)



func _on_add_node_popup(node:SimpleGraphNode) -> void:
	self.add_node(node, true)
	
	
	
func _on_node_change_title(node) -> void:
	if save_popup.visible == false:
		save_popup.activate(node)
	else:
		if save_popup.active_node == node:
			save_popup.hide()
		else:
			save_popup.activate(node)
			


func _on_node_change_selected(node) -> void:
	if save_popup.visible == false:
		save_popup.activate(node)
	else:
		if save_popup.active_node == node:
			save_popup.hide()
		else:
			save_popup.activate(node)
			

func get_selected_nodes() -> Array[SimpleGraphNode]:
	var selected_nodes:Array[SimpleGraphNode] = []
	var nodes = get_tree().get_nodes_in_group("graph_node")
	for n in nodes:
		if n is GraphNode:
			if n.selected:
				selected_nodes.append(n)
	# print("selected_nodes = ", selected_nodes)
	return selected_nodes


func deselect_all_nodes() -> void:
	var nodes = get_tree().get_nodes_in_group("graph_node")
	for n in nodes:
		if n is GraphNode:
			n.set_selected(false)
	
	
# on open popup
func _on_graph_edit_popup_request(_at_position: Vector2) -> void:
	# print("right_click_popup")
	# if right_click_popup.visible == false:
	var selected_nodes:Array[SimpleGraphNode] = get_selected_nodes()
	var mouse_pos = get_viewport().get_mouse_position()
	right_click_popup.activate(selected_nodes, mouse_pos)
	#else:
		#right_click_popup.hide()


func _on_graph_edit_copy_nodes_request() -> void:
	print("copy")
	var _selected_nodes:Array[SimpleGraphNode] = get_selected_nodes()
	right_click_popup.selected_nodes = _selected_nodes
	right_click_popup._on_copy()


func _on_graph_edit_cut_nodes_request() -> void:
	print("cut")
	var _selected_nodes:Array[SimpleGraphNode] = get_selected_nodes()
	right_click_popup.selected_nodes = _selected_nodes
	right_click_popup._on_cut()


func _on_graph_edit_delete_nodes_request(_nodes: Array[StringName]) -> void:
	print("delete -- graph edit")
	for node_name in _nodes:
		var n = rules_graph.get_node(NodePath(node_name))
		if n is SimpleGraphNode:
			n.delete_request.emit()

func _on_delete_nodes(_nodes: Array[SimpleGraphNode]) -> void:
	print("delete -- right click")
	print(_nodes)
	for n in _nodes:
		if n is SimpleGraphNode:
			print("delete = ", n)
			n.delete_request.emit()


func _on_graph_edit_duplicate_nodes_request() -> void:
	print("duplicate")
	var _selected_nodes:Array[SimpleGraphNode] = get_selected_nodes()
	right_click_popup.selected_nodes = _selected_nodes
	var mouse_pos = get_viewport().get_mouse_position()
	right_click_popup.spawn_pos = (mouse_pos + rules_graph.scroll_offset) / rules_graph.zoom
	right_click_popup._on_duplicate()
	

func _on_graph_edit_paste_nodes_request() -> void:
	print("paste")
	var _selected_nodes:Array[SimpleGraphNode] = get_selected_nodes()
	right_click_popup.selected_nodes = _selected_nodes
	var mouse_pos = get_viewport().get_mouse_position()
	right_click_popup.spawn_pos = (mouse_pos + rules_graph.scroll_offset) / rules_graph.zoom
	_on_paste_nodes()



func _get_node_from_dict(node_dict:Dictionary) -> SimpleGraphNode:
	
	var n:SimpleGraphNode
	
	# node data
	if node_dict.node_type == "OutputGraphNode":
		n = OUTPUT_GRAPH_NODE.instantiate()
		rules_graph.add_child(n)
		await get_tree().process_frame
		if n is OutputGraphNode:
			n.cat.select(node_dict.node_data.cat_idx)
			n._on_cat_item_selected()
			n.subcat.select(node_dict.node_data.subcat_idx)
			n.priority.value = node_dict.node_data.priority
		
	elif node_dict.node_type == "ConditionalGraphNode":
		n = CONDITIONAL_GRAPH_NODE.instantiate()
		rules_graph.add_child(n)
		await get_tree().process_frame
		if n is ConditionalGraphNode:
			n.substring.text = node_dict.node_data.substring
			n.column_name.select(node_dict.node_data.idx)
	
	elif node_dict.node_type == "AmountCheckNode":
		n = AMOUNT_CHECK_NODE.instantiate()
		rules_graph.add_child(n)
		await get_tree().process_frame
		if n is AmountCheckNode:
			n.condition.select(node_dict.node_data.idx)
			n.abs_btn.button_pressed = node_dict.node_data.abs_btn
			n.amount.value = node_dict.node_data.amount
			
	elif node_dict.node_type == "LogicGateNode":
		n = LOGIC_GATE_NODE.instantiate()
		rules_graph.add_child(n)
		await get_tree().process_frame
		if n is LogicGateNode:
			n.gate.select(node_dict.node_data.idx)
			n.inputs.value = node_dict.node_data.inputs
	
	# title
	n.title = node_dict.node_title
	
	# color data
	n.set_border_color(node_dict.node_color_frame, node_dict.node_color_selected)
	
	# size data
	n.node_size = node_dict.node_size
	n.set_size(node_dict.node_size)  # Apply size immediately
	
	# connect node signals
	n.change_title.connect(_on_node_change_title)
		
		
	return n
	
	
	
func _on_paste_nodes(
	graph_dict:Dictionary = right_click_popup.copy_buffer,
	use_context:bool = true
	) -> void:

	# deselect nodes
	deselect_all_nodes()
	
	var created_nodes = []
	# create nodes
	for node_dict in graph_dict.nodes:
		
		# node
		var n:SimpleGraphNode = await _get_node_from_dict(node_dict)
		
		###############################################
		# position
		var offset = node_dict.node_offset
		if use_context:
			offset += (right_click_popup.spawn_pos - graph_dict.nodes[0].node_offset)
		n.position_offset = offset
		
		# select node
		n.set_selected(true)
		
		# append node
		created_nodes.append(n)
		
		
	# create connections
	for c in graph_dict.edges:
		var from_node = created_nodes[c.from_node_index]
		var to_node = created_nodes[c.to_node_index]
		rules_graph.connect_node(from_node.name, 0, to_node.name, 0)

	# redraw to fix connections
	rules_graph.queue_redraw()


func _on_clear_graph_pressed() -> void:
	var nodes = get_tree().get_nodes_in_group("graph_node")
	for n in nodes:
		n.queue_free()
		
		
		
#######################################################



func get_inputs_for_node(graph_edit: GraphEdit, node_name: String) -> Array:
	var inputs = []
	for connection in graph_edit.connections:
		if connection["to_node"] == node_name:
			inputs.append(connection["from_node"])  # Add the source node
	return inputs
	
	
func eval_expression(terminal_node: SimpleGraphNode, transaction := {}) -> Variant:
	# get transaction from debugger values if none provided
	# print("transaction = ", transaction)
	if transaction.is_empty():
		transaction = {
			"description": debugger_description.text,
			"amount": debugger_amount.value,
			"source_category": debugger_source_category.text
		}

	var input_nodes: Array = get_inputs_for_node(rules_graph, terminal_node.name)
	var input_results = []

	# Recursively evaluate input nodes
	for node_name in input_nodes:
		var node = rules_graph.get_node(NodePath(node_name))  # Fetch actual node instance
		if node:
			input_results.append(eval_expression(node, transaction))

	# Determine function to call based on node type
	var terminal_result
	
	if terminal_node is OutputGraphNode:
		terminal_result = _OUTPUT(false if input_results.is_empty() else input_results[0], terminal_node.cat.text, terminal_node.subcat.text)
	elif terminal_node is ConditionalGraphNode:
		terminal_result = _CONDITIONAL_SUBSTRING(terminal_node.substring.text, terminal_node.column_name.selected, transaction)
	elif terminal_node is AmountCheckNode:
		terminal_result = _CONDITIONAL_AMOUNT(terminal_node.abs_btn.button_pressed, terminal_node.condition.selected, transaction.amount, terminal_node.amount.value)
	elif terminal_node is LogicGateNode:
		terminal_result = _LOGIC_GATE(input_results, terminal_node.gate.selected)
	else:
		push_error("Unknown node type: %s" % terminal_node.name)
		return null  # Handle unknown node types

	# Print result
	# print("Terminal Result for '", terminal_node.name, "': ", terminal_result)

	return terminal_result
	
	

func _OUTPUT(input:bool, category:String, subcategory:String) -> Array:
	if input:
		return [category, subcategory]
	else:
		return []
	
	
func _CONDITIONAL_SUBSTRING(substring:String, column:int, transaction:Dictionary) -> bool:
	var column_text:String = ""
	match column:
		0:  # Description
			column_text = transaction.description
		1:  # SourceCategory
			column_text = transaction.source_category
		_:
			push_warning("Column not found: ", column)
			column_text = ""
	return substring.to_lower() in column_text.to_lower()


func _CONDITIONAL_AMOUNT(use_absolute_value:bool, condition:int, _column_amount:float, compared_amount:float) -> bool:
	var column_amount:float = abs(_column_amount) if use_absolute_value else _column_amount
	print("column_amount = ", column_amount)
	var cond_str = "greater than" if condition==0 else "less than"
	print("condition = ", cond_str)
	print("compared_amount = ", compared_amount)
	
	match condition:
		0:  # Greater Than
			return column_amount > compared_amount
		1:  # Less Than
			return column_amount < compared_amount
		_:
			push_warning("Condition not found: ", condition)
			return false
		
		
func _LOGIC_GATE(inputs:Array, type:int) -> bool:
	if type == 0:
		return _LOGIC_AND(inputs)
	elif type == 1:
		return _LOGIC_OR(inputs)
	else:
		push_warning("Logic gate not found for type: %s" % type)
		return false

	
func _LOGIC_AND(inputs:Array) -> bool:
	if inputs.size() < 2:
		return false
	for i in inputs:
		if not i:
			return false
	return true
	
	
func _LOGIC_OR(inputs:Array) -> bool:
	for i in inputs:
		if i:
			return true
	return false
	
	
	
func example_function() -> Array[String]:
	var t = {}
	
	# Output 2
	if "TRAVELERS" in t["Decription"] and abs(t["Amount"]) < 25:
		return ["Insurance", "Renters Insurance"]
	
	# Output 2
	if "TRAVELERS" in t["Decription"] and abs(t["Amount"]) > 50:
		return ["Insurance", "Car Insurance"]
	
	# Default values
	return ["Misc", "Merchandise"]





# add new data source
func _on_add_data_source_pressed() -> void:
	var _action:String = "add_new_data_source"
	var _action_data:Dictionary = {}
	data_source_popup.popup_centered(_action, _action_data)


func _on_add_new_data_source(src:Dictionary) -> void:
	# get srcs
	var data_sources = SaveLoad.load_data("data_sources")
	
	# set default active
	src.active = true
	
	# add src
	data_sources.append(src)
	
	# save
	SaveLoad.save_data("data_sources", data_sources)
	
	# add to list
	add_source_to_list(src)
	
	
func _on_edit_data_source(src_name:String, new_data_source:Dictionary) -> void:
	# get srcs
	var data_sources = SaveLoad.load_data("data_sources")
	
	# find data source
	var index:int = 0
	for src in data_sources:
		if src.name == src_name:
			break
		index += 1
		
	# get active
	var active = data_sources[index].active
	new_data_source.active = active
	
	# update data source
	data_sources[index] = new_data_source
	
	# save
	SaveLoad.save_data("data_sources", data_sources)
	
	# add to list
	edit_source_in_list(index, new_data_source)
	
	
	
func add_source_to_list(src:Dictionary) -> void:
	# add to node list
	var source_box:SourceBox = SOURCE_BOX.instantiate()
	data_sources_container.add_child(source_box)
	
	# update vars, connect signals
	source_box.src_name = src.name
	source_box.name_label.text = src.name
	
	# signals
	source_box.view_data.pressed.connect(_on_source_view_data_pressed.bind(src.name))
	source_box.edit_data.pressed.connect(_on_source_edit_data_pressed.bind(src.name))
	source_box.delete_data.pressed.connect(_on_source_delete_data_pressed.bind(src.name))
	
	# set active
	source_box.active_checkbox.button_pressed = src.active

func edit_source_in_list(index:int, src:Dictionary) -> void:
	var children = data_sources_container.get_children()
	var source_box:SourceBox = children[index]
	
	# update vars, connect signals
	source_box.src_name = src.name
	source_box.name_label.text = src.name
	
	# Disconnect old signals (if already connected)
	if source_box.view_data.pressed.is_connected(_on_source_view_data_pressed):
		source_box.view_data.pressed.disconnect(_on_source_view_data_pressed)
	if source_box.edit_data.pressed.is_connected(_on_source_edit_data_pressed):
		source_box.edit_data.pressed.disconnect(_on_source_edit_data_pressed)
	if source_box.delete_data.pressed.is_connected(_on_source_delete_data_pressed):
		source_box.delete_data.pressed.disconnect(_on_source_delete_data_pressed)
	
	# connect signals
	source_box.view_data.pressed.connect(_on_source_view_data_pressed.bind(src.name))
	source_box.edit_data.pressed.connect(_on_source_edit_data_pressed.bind(src.name))
	source_box.delete_data.pressed.connect(_on_source_delete_data_pressed.bind(src.name))
	
	# set active
	source_box.active_checkbox.button_pressed = src.active




func _on_source_view_data_pressed(src_name:String) -> void:
	print("view data: ", src_name)
	
	# get data
	var _raw_csv_data = []
	var _transaction_csv_data = []
	
	for src in SaveLoad.load_data("data_sources"):
		if src.name == src_name:
			_raw_csv_data = src.raw_csv_data
			_transaction_csv_data = src.transaction_csv_data
			break
	
	# init raw table
	if not _raw_csv_data.is_empty():
		var _headers = _raw_csv_data.pop_at(0)
		_raw_csv_data.pop_at(-1)
		raw_table.set_headers(_headers)
		raw_table.set_data(_raw_csv_data)
	else:
		raw_table.set_headers([])
		raw_table.set_data([])
	
	# init transaction table
	if not _transaction_csv_data.is_empty():
		var _headers = _transaction_csv_data.pop_at(0)
		_transaction_csv_data.pop_at(-1)
		transaction_table.set_headers(_headers)
		transaction_table.set_data(_transaction_csv_data)
	else:
		transaction_table.set_headers([])
		transaction_table.set_data([])

	# hide data sources
	data_sources_menu.hide()
	
	# show tables
	if current_view != src_name:
		current_view = src_name
		raw_table_container.show()
	else:
		raw_table_container.visible = !raw_table_container.visible



func _on_source_edit_data_pressed(src_name:String) -> void:
	print("edit data: ", src_name)
	var _action:String = "edit_data_source"
	var _action_data:Dictionary = {"src_name": src_name}
	data_source_popup.popup_centered(_action, _action_data)


	

func _on_source_delete_data_pressed(src_name:String) -> void:
	print("delete data source: ", src_name)
	var _action:String = "delete_data_source"
	var _action_data:Dictionary = {"src_name": src_name}
	confirmation_popup.popup_centered(_action, _action_data)


func _on_delete_all_data_sources_pressed() -> void:
	print("delete all data sources")
	var _action:String = "delete_all_data_sources"
	var _action_data:Dictionary = {}
	confirmation_popup.popup_centered(_action, _action_data)


func delete_data_source(src_name:String) -> void:
	print("delete data source: ", src_name)
	# remove node from list
	var source_list:Array = data_sources_container.get_children()
	
	# find index given name
	var index:int = -1
	var i:int = 0
	for c:SourceBox in source_list:
		if c.src_name == src_name:
			index = i
			break
		i += 1
	if index == -1 or index > source_list.size()-1:
		push_warning("Index not found for src_name = ", src_name)
		return
		
	# delete
	source_list[index].free()
	
	# clear save data
	var data_sources = SaveLoad.load_data("data_sources")
	if data_sources is Array:
		data_sources.remove_at(index)
	SaveLoad.save_data("data_sources", data_sources)
	
	# debug
	var test = SaveLoad.load_data("data_sources")
	print(test)
	
	
func delete_all_data_sources() -> void:
	print("delete all data sources")
	# remove nodes from list
	for c:SourceBox in data_sources_container.get_children():
		c.free()
	# clear save data
	SaveLoad.save_data("data_sources", [])
	
	# debug
	var test = SaveLoad.load_data("data_sources")
	print(test)
	
	

func _on_edit_categories_confirmed(_action:String, _action_data:Dictionary) -> void:
	match _action:
		"edit_categories":
			update_output_nodes()
		_:
			push_warning("No action associated with string name: %s" % _action)
	pass

func update_output_nodes() -> void:
	for n in get_tree().get_nodes_in_group("graph_node"):
		if n is OutputGraphNode:
			n._reload_data()
	
	
	
func _on_confirmation_popup_confirmed(_action:String, _action_data:Dictionary) -> void:
	match _action:
		"delete_all_data_sources":
			delete_all_data_sources()
		"delete_data_source":
			delete_data_source(_action_data.src_name)
		_:
			push_warning("No action associated with string name: %s" % _action)
	pass



func format_date_string(date_str: String) -> String:
	var parts = date_str.split("/")  # ["01", "04", "2025"]
	if parts.size() != 3:
		return date_str  # Return as-is if the format is unexpected

	var _month = int(parts[0])  # Converts "01" -> 1
	var _day = int(parts[1])    # Converts "04" -> 4
	var _year = int(parts[2]) % 100  # Converts "2025" -> 25

	return "%d/%d/%02d" % [_month, _day, _year]



func _on_run_data_sources_pressed() -> void:
	
	# Filters
	# var is_expense = Filter.new("amount_type", "Expense", true)
	
	var not_cc_payment := Filter.new("source_category", "Credit Card Payment", false)
	var not_disc_payment := Filter.new("description", "E-PAYMENT", false)
	var not_ext_transfer := Filter.new("description", "EXT Transfer from", false)

	# var not_cashback = Filter.new("source_category", "Awards and Rebate Credits", false)
	var not_internet_payment := Filter.new("description", "INTERNET PAYMENT - THANK YOU", false)
	
	var filters:Array[Filter] = [not_cc_payment, not_disc_payment, not_ext_transfer, not_internet_payment]
	
	
	
	print("run data sources")
	
	var transaction_csv_data = []
	
	var data_sources = SaveLoad.load_data("data_sources")
	
	var index = 0
	for src in data_sources:
		if src.active == true:
			var src_data = run_data_source(src, filters)
			if index > 0:
				src_data.pop_at(0)
			transaction_csv_data.append_array(src_data)
			index += 1
	
	
	# debug print
	print("transaction_csv_data = ", transaction_csv_data)
	
	
	###############################################
	# update bar plot with category sums
	update_data(transaction_csv_data)


		
func run_data_source(src:Dictionary, filters:Array[Filter]) -> Array:
	# build transaction data to show on right table in data view
	# there are 4 columns (date, description, amount, sourcecat) plus 2 (cat, subcat)
	# so 6 columns in total
	
	var flip_amount = src.flip_amount
	
	# the raw csv data is an array of PackedStringArray for each row
	var raw_csv_data = src.raw_csv_data
	var transaction_csv_data = []
	
	# prevent empty table errors
	if raw_csv_data.is_empty():
		# src.transaction_csv_data = transaction_csv_data
		# _on_edit_data_source(src.name, src)
		return []
		

	var columns = src.columns
	var ordered_keys = [
		"Date", 
		"Description", 
		"Amount", 
		"SourceCategory", 
	]
	var new_keys = [
		"Category",
		"Subcategory",
	]
	var all_keys = ordered_keys + new_keys
	
	# Insert header row using the ordered_keys
	transaction_csv_data.append(PackedStringArray(all_keys))

	# Process the rest of the data rows (skip header)
	for i in range(1, raw_csv_data.size()):
		var row = raw_csv_data[i]
		
		# var new_row = PackedStringArray()
		var new_row = []
		
		for key in ordered_keys:
			var index = columns[key]
			if index < row.size():
				var value = row[index]
				if key == "Amount":
					if flip_amount:
						new_row.append(-1.0 * float(value))
					else:
						new_row.append(float(value))
				elif key == "Date":
					new_row.append(format_date_string(value))
				else:
					new_row.append(value)
			else:
				new_row.append("")  # fallback for missing values
		
		# print("new_row = ", new_row)
		# define transaction dict to run rules on
		var transaction = {
			"date": new_row[0],
			"description": new_row[1],
			"amount": float(new_row[2]),
			"source_category": new_row[3]
		}
		
		print ("transaction = ", transaction)
		# process rules on transaction to get [cat, subcat]
		var result:Array = _on_get_result_pressed(transaction)
		
		# append cat, subcat
		for new_key_index in new_keys.size():
			if new_key_index < result.size():
				new_row.append(result[new_key_index])
			else:
				new_row.append("")
		
		# add transaction row
		# only append if at least one cell is non-empty
		# and passes all filters
		var expense = true if transaction.amount < 0 else false
		var is_empty = true
		var keep = true
		
		for val in new_row:
			if str(val).strip_edges() != "":
				is_empty = false
				break
				
		for f in filters:
			var field_val = transaction.get(f.key)
			if (field_val == f.val) != f.truth:
				keep = false
				break
				
		if expense and keep and not is_empty:
			transaction_csv_data.append(new_row)
	
	
	
	# debug print
	# print("transaction_csv_data = ", transaction_csv_data)
	
	# update source data
	src.transaction_csv_data = transaction_csv_data
	
	# save data source
	_on_edit_data_source(src.name, src)
	
	# return to main func
	return transaction_csv_data


	
	
func _on_raw_table_view_back_pressed() -> void:
	raw_table_container.hide()
	data_sources_menu.show()


func _on_edit_categories_pressed() -> void:
	print("edit categories")
	var categories = SaveLoad.load_data("categories")
	print(categories)
	edit_categories_popup.popup_centered("edit_categories", categories)
	
	
