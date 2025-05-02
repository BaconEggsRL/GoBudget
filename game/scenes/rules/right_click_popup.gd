class_name RightClickPopup
extends PopupMenu


enum ITEMS {
	ADD_NODE,
	SEPARATOR,
	CUT,
	COPY,
	PASTE,
	DELETE,
	DUPLICATE,
	CLEAR_COPY_BUFFER
}
@onready var menu: PopupMenu = self

@onready var selected_nodes:Array[SimpleGraphNode] = []
@onready var copy_buffer: Dictionary = {"nodes": [], "edges": []}

@export var rules_graph: GraphEdit

signal add_node
signal paste
signal delete

@onready var spawn_pos:Vector2 = Vector2.ZERO


# hide on right click
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			self.hide()


func _ready() -> void:
	self.hide()
	# Create popup menu
	menu.clear()
	
	menu.add_item("Add Node", ITEMS.ADD_NODE)
	menu.add_separator("", 2147483647)
	menu.add_item("Cut", ITEMS.CUT)
	menu.add_item("Copy", ITEMS.COPY)
	menu.add_item("Paste", ITEMS.PASTE)
	menu.add_item("Delete", ITEMS.DELETE)
	menu.add_item("Duplicate", ITEMS.DUPLICATE)
	menu.add_item("Clear Copy Buffer", ITEMS.CLEAR_COPY_BUFFER)
	
	menu.set_item_disabled(get_item_index(ITEMS.CUT), true)
	menu.set_item_disabled(get_item_index(ITEMS.COPY), true)
	menu.set_item_disabled(get_item_index(ITEMS.PASTE), true)
	menu.set_item_disabled(get_item_index(ITEMS.DELETE), true)
	menu.set_item_disabled(get_item_index(ITEMS.DUPLICATE), true)
	menu.set_item_disabled(get_item_index(ITEMS.CLEAR_COPY_BUFFER), true)
	
	# Add signal handler
	menu.id_pressed.connect(_on_popup_item_pressed)


# when right click
func activate(nodes: Array[SimpleGraphNode], mouse_pos: Vector2) -> void:
	# get position to spawn nodes at
	self.spawn_pos = (mouse_pos + rules_graph.scroll_offset) / rules_graph.zoom
	
	selected_nodes = nodes
	var item_actions_disabled:bool = selected_nodes.is_empty()
	var paste_clear_disabled:bool = copy_buffer.nodes.is_empty()
	
	menu.set_item_disabled(get_item_index(ITEMS.CUT), item_actions_disabled)
	menu.set_item_disabled(get_item_index(ITEMS.COPY), item_actions_disabled)
	menu.set_item_disabled(get_item_index(ITEMS.PASTE), paste_clear_disabled)
	menu.set_item_disabled(get_item_index(ITEMS.DELETE), item_actions_disabled)
	menu.set_item_disabled(get_item_index(ITEMS.DUPLICATE), item_actions_disabled)
	menu.set_item_disabled(get_item_index(ITEMS.CLEAR_COPY_BUFFER), paste_clear_disabled)
	
	popup(Rect2(mouse_pos, Vector2()))
	print("activated with selected_nodes = %s, at %s" % [nodes, mouse_pos])
	
	
func _on_popup_item_pressed(id: int) -> void:
	print("id = ", id)
	# Update item checked state
	# var item_index = menu.get_item_index(id)
	# var item_was_checked = menu.get_item_checked(item_index)
	# menu.set_item_checked(item_index, not item_was_checked)  # or is it id?

	# Run the signal handler for this item
	match id:
		ITEMS.ADD_NODE:
			_on_add_node()
		ITEMS.CUT:
			_on_cut()
		ITEMS.COPY:
			print("copy")
			_on_copy()
		ITEMS.PASTE:
			_on_paste()
		ITEMS.DELETE:
			_on_delete()
		ITEMS.DUPLICATE:
			_on_duplicate()
		ITEMS.CLEAR_COPY_BUFFER:
			_on_clear_copy_buffer()

func _on_add_node() -> void:
	add_node.emit()

func _on_cut() -> void:
	copy_nodes(selected_nodes)
	delete.emit(selected_nodes)

func _on_copy() -> void:
	copy_nodes(selected_nodes)

func _on_paste() -> void:
	paste.emit(copy_buffer)

func _on_delete() -> void:
	delete.emit(selected_nodes)

func _on_duplicate() -> void:
	# duplicate.emit(selected_nodes)
	_on_copy()
	_on_paste()

func _on_clear_copy_buffer() -> void:
	copy_buffer.nodes.clear()
	copy_buffer.edges.clear()
	# print("copy_buffer = ", copy_buffer)
	
	


func copy_nodes(nodes:Array[SimpleGraphNode]) -> void:
	# clear buffer
	_on_clear_copy_buffer()
	
	# nodes
	for n in nodes:
		
		var node_dict = {}
		
		node_dict.node_name = n.name
		node_dict.node_offset = n.position_offset
		node_dict.node_title = n.title
		
		# color data
		node_dict.node_color_frame = n.node_color_frame
		node_dict.node_color_selected = n.node_color_selected
		
		# node data
		if n is OutputGraphNode:
			node_dict.node_type = "OutputGraphNode"
			node_dict.node_data = {
				"cat_idx": n.cat.selected, 
				"subcat_idx": n.subcat.selected,
				"priority": n.priority.value
			}
		elif n is ConditionalGraphNode:
			node_dict.node_type = "ConditionalGraphNode"
			node_dict.node_data = {"substring": n.substring.text, "idx": n.column_name.selected}
		elif n is AmountCheckNode:
			node_dict.node_type = "AmountCheckNode"
			node_dict.node_data = {
				"idx": n.condition.selected, 
				"abs_btn": n.abs_btn.button_pressed, 
				"amount": n.amount.value
			}
		elif n is LogicGateNode:
			node_dict.node_type = "LogicGateNode"
			node_dict.node_data = {"idx": n.gate.selected, "inputs": n.inputs.value}
		
		# size data
		node_dict.node_size = n.size

		copy_buffer.nodes.append(node_dict)
		
	# edges
	copy_buffer.edges = get_edges(rules_graph, nodes)

	print("copy_buffer = ", copy_buffer)
	
	

func get_edges(graph_edit: GraphEdit, node_list: Array[SimpleGraphNode]) -> Array:
	var edges = []
	
	var connections = graph_edit.get_connection_list()
	var node_names = node_list.map(func(n): return n.name)  # Extract names of nodes in the list
	
	for connection in connections:
		var from_node = connection["from_node"]
		var to_node = connection["to_node"]
		
		# Check if both nodes in the connection exist in node_list
		if from_node in node_names and to_node in node_names:
			var edge = {}
			edge.from_node_index = node_list.find(graph_edit.get_node(NodePath(from_node)))
			edge.to_node_index = node_list.find(graph_edit.get_node(NodePath(to_node)))
			edges.append(edge)
	
	return edges
	
	
#func _unhandled_input(event: InputEvent) -> void:
	#if visible and event is InputEventMouseButton:
		## get_viewport().set_input_as_handled()  # Absorb the input
		#if event.pressed:
			#self.hide()  # Close the popup when clicking anywhere
