class_name SavePopupPanel
extends PanelContainer

@export var title_line: LineEdit
@export var color_frame: ColorPickerButton
@export var color_selected: ColorPickerButton

var active_node: SimpleGraphNode
@onready var window = self

signal save

var dragging := false
var drag_start_position := Vector2()
var window_start_position := Vector2()

func _ready() -> void:
	window.hide()

func activate(node: SimpleGraphNode) -> void:
	active_node = node
	title_line.text = node.title
	color_frame.color = active_node.get_theme_stylebox("titlebar").duplicate().bg_color
	color_selected.color = active_node.get_theme_stylebox("titlebar_selected").duplicate().bg_color
	popup_centered()

func _on_save_pressed() -> void:
	active_node.set_title(title_line.text)
	active_node.queue_redraw()
	save.emit()
	window.hide()

func popup_centered() -> void:
	window.show()

func _on_color_frame_button_color_changed(color: Color) -> void:
	active_node.set_border_color(color_frame.color, color_selected.color)

func _on_color_selected_button_color_changed(color: Color) -> void:
	active_node.set_border_color(color_frame.color, color_selected.color)

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
