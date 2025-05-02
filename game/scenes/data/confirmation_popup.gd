@tool
class_name ConfirmationPopup
extends PanelContainer

@onready var parent = get_parent()
@onready var window = parent if parent is ColorRect else self

var dragging := false
var drag_start_position := Vector2()
var popup_start_position := Vector2()

@export var confirm_btn:Button
@export var abort_btn:Button

@export var title_label:Label

var action:String = "delete_all_sources"
var action_data:Dictionary = {}


signal confirmed

	
func _ready() -> void:
	if not Engine.is_editor_hint():
		window.hide()
	else:
		self.show()


func popup_centered(_action:String, _action_data:Dictionary) -> void:
	self.action = _action
	self.action_data = _action_data
	
	match action:
		"delete_data_source":
			self.title_label.text = "Delete Data Source"
		"delete_all_data_sources":
			self.title_label.text = "Delete All Data Sources"
		_:
			push_warning("No acion found: %s" % action)
			
	window.show()


func _on_confirm_pressed() -> void:
	confirmed.emit(action, action_data)
	window.hide()
	
func _on_close_pressed() -> void:
	window.hide()

func _on_abort_pressed() -> void:
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
				popup_start_position = self.global_position
			else:
				# Stop dragging
				dragging = false

func _process(_delta: float) -> void:
	if dragging:
		var mouse_pos = get_global_mouse_position()
		self.global_position = popup_start_position + (mouse_pos - drag_start_position)
