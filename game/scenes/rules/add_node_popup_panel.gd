class_name AddNodePopupPanel
extends PanelContainer

@onready var window = self

signal add_node

var dragging := false
var drag_start_position := Vector2()
var window_start_position := Vector2()


const CONDITIONAL_GRAPH_NODE = preload("res://scenes/rules/nodes/conditional_graph_node.tscn")
const OUTPUT_GRAPH_NODE = preload("res://scenes/rules/nodes/output_graph_node.tscn")
const AMOUNT_CHECK_NODE = preload("res://scenes/rules/nodes/amount_check_node.tscn")
const LOGIC_GATE_NODE = preload("res://scenes/rules/nodes/logic_gate_node.tscn")


func _ready() -> void:
	window.hide()




func _on_output_node_pressed() -> void:
	var node = OUTPUT_GRAPH_NODE.instantiate()
	add_node.emit(node)
	window.hide()

func _on_conditional_node_pressed() -> void:
	var node = CONDITIONAL_GRAPH_NODE.instantiate()
	add_node.emit(node)
	window.hide()

func _on_amount_node_pressed() -> void:
	var node = AMOUNT_CHECK_NODE.instantiate()
	add_node.emit(node)
	window.hide()

func _on_and_node_pressed() -> void:
	var node = LOGIC_GATE_NODE.instantiate()
	node.default_gate = 0
	add_node.emit(node)
	window.hide()
	
func _on_or_node_pressed() -> void:
	var node = LOGIC_GATE_NODE.instantiate()
	node.default_gate = 1
	add_node.emit(node)
	window.hide()



func _on_close_pressed() -> void:
	window.hide()

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
				window_start_position = window.global_position
			else:
				# Stop dragging
				dragging = false

func _process(_delta: float) -> void:
	if dragging:
		var mouse_pos = get_global_mouse_position()
		window.global_position = window_start_position + (mouse_pos - drag_start_position)
