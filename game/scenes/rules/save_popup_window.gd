@tool
class_name SavePopupWindow
extends Window

@export var save_popup_panel: SavePopupPanel


func _ready():
	if not Engine.is_editor_hint():  # Only run at runtime
		await get_tree().process_frame
		resize_to_fit_content()
		self.hide()

func _process(_delta):
	if Engine.is_editor_hint():  # Runs only in the editor
		resize_to_fit_content()

func resize_to_fit_content():
	if save_popup_panel:
		self.size = save_popup_panel.size  # Directly use the panel's size
		save_popup_panel.queue_redraw()  # Ensure the window updates visually


func _on_close_requested() -> void:
	save_popup_panel.active_node.selected = false
	self.hide()
