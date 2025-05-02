@tool
class_name LogicGateNode
extends SimpleGraphNode

@onready var gate: OptionButton = $VBoxContainer/gate
@onready var inputs: SpinBox = $VBoxContainer/inputs

@export var node_data_keys := ["idx", "inputs"]

var num_inputs:int = 2


signal default_gate_changed
@export_range (0,1) var default_gate:int = 0:
	get:
		return default_gate
	set(value):
		default_gate_changed.emit()
		default_gate = value


func _ready() -> void:
	super()
	default_gate_changed.connect(_on_default_gate_changed)
	call_deferred("_on_default_gate_changed")
	call_deferred("init_slots")


func _on_default_gate_changed() -> void:
	gate.select(default_gate)


#func _clear_slots() -> void:
	#clear_all_slots()
	#for c in self.get_children():
		#if c.is_in_group("slot"):
			#c.free()
	#
#func reset_slots() -> void:
	#self._clear_slots()
	#self._set_slots()
	## output slot
	#self.set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	
func init_slots() -> void:
	# output slot
	self.set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	# add additional slots
	_add_slots()
	
	
func _add_slots(num_inputs_to_add:int = 1) -> void:
	print()
	print("num_inputs_to_add = ", num_inputs_to_add)
	
	var _start_amount:int = get_input_port_count()
	var _end_amount:int = _start_amount + num_inputs_to_add
	
	for i in num_inputs_to_add:
		var c = Control.new()
		c.add_to_group("slot")
		c.custom_minimum_size.y = 100
		self.add_child(c)

		var slot:int = i + _start_amount
		self.set_slot(slot, true, 0, Color.WHITE, false, 0, Color.GREEN)
		print("added slot ", slot)
	
	# debug
	print("num inputs = ", get_input_port_count())
	print("num outputs = ", get_output_port_count())
	

func get_slot_children() -> Array:
	var slot_children := []
	for child in get_children():
		if child.is_in_group("slot"):
			slot_children.append(child)
	return slot_children
	

func _remove_slots(num_inputs_to_remove:int = 1) -> void:
	print()
	print("num_inputs_to_remove = ", num_inputs_to_remove)
	
	for i in range(num_inputs_to_remove):
		var slot = get_input_port_count() - 1
		if slot < 0:
			break
		
		# Remove connections related to this slot
		var rules_graph:GraphEdit = self.get_parent()
		var connections = rules_graph.get_connection_list()
		for connection in connections:
			if connection["to_node"] == name and connection["to_port"] == slot:
				rules_graph.disconnect_node(connection["from_node"], connection["from_port"], name, slot)
			elif connection["from_node"] == name and connection["from_port"] == slot:
				rules_graph.disconnect_node(name, slot, connection["to_node"], connection["to_port"])
		
		# Clear the slot from GraphNode's internal slot list
		self.clear_slot(slot)
		
		# Clear slot children
		var slot_children = get_slot_children()
		if slot-1 < slot_children.size():
			var c: Node = slot_children[slot-1]
			if c.is_in_group("slot"):
				c.queue_free()
				print("removed slot ", slot)
		else:
			print("slot ", slot, " not found in children array")
	
	# Debug info
	print("num inputs = ", get_input_port_count())
	print("num outputs = ", get_output_port_count())


# VOODOO BLACK MAGIC DO NOT TOUCH!!!
func resize_to_minimum():
	await get_tree().process_frame
	set_size(Vector2.ZERO)  # Reset size before resizing
	await get_tree().process_frame
	var min_size = get_combined_minimum_size()
	set_size(min_size)  # Resize to minimum required size
	await get_tree().process_frame
	queue_redraw()  # Force UI refresh
	print("Resized GraphNode to:", min_size)
	
	
func _on_inputs_value_changed(_value: float) -> void:
	var new_value = int(_value)
	print()
	print("old_value = ", num_inputs)
	print("new_value = ", new_value)
	# call_deferred("reset_slots")
	var diff = new_value - num_inputs
	if diff > 0:
		_add_slots(diff)
	elif diff < 0:
		_remove_slots(abs(diff))
		
	# update value
	num_inputs = new_value
	resize_to_minimum()  # Resize after slot changes
	
