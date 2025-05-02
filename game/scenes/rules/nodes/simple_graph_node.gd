class_name SimpleGraphNode
extends GraphNode

@onready var titlebar:HBoxContainer = self.get_titlebar_hbox()
const BTN_THEME = preload("res://btn_theme.tres")




@export var node_name := ""
@export var node_offset := Vector2.ZERO
@export var node_title := ""

@export var node_color_frame:Color = BTN_THEME.get_stylebox("titlebar", &"GraphNode").duplicate().bg_color
@export var node_color_selected:Color = BTN_THEME.get_stylebox("titlebar_selected", &"GraphNode").duplicate().bg_color

@export var node_data := {"cat": "", "subcat": ""}
@export var node_size := Vector2.ZERO

@export var node_type:String = "SimpleGraphNode"


# @onready var cat: TextEdit = $VBoxContainer/cat
# @onready var subcat: TextEdit = $VBoxContainer/subcat
# @export var node_data_keys := ["cat", "subcat"]


signal change_title


func _ready() -> void:
	# delete request
	if not delete_request.is_connected(_on_delete_request):
		self.delete_request.connect(_on_delete_request)
	if not gui_input.is_connected(_on_gui_input):
		self.gui_input.connect(_on_gui_input)
	
	# add slots
	# set_slot(0, true, 0, Color(1,1,1,1), true, 0, Color(0,1,0,1))
	
	# add close btn
	var close_btn:Button = Button.new()
	close_btn.pressed.connect(_on_delete_request)
	close_btn.custom_minimum_size = Vector2(32, 0)
	close_btn.text = "x"
	close_btn.theme = BTN_THEME
	titlebar.add_child(close_btn)
	
	# Force the GraphNode to update layout
	await get_tree().process_frame  # Ensures the node is added before recalculating
	if node_size == Vector2.ZERO:
		self.set_size(self.get_combined_minimum_size())  # Recalculate the size
		queue_redraw()  # Forces a visual update
	else:
		self.set_size(self.node_size)
		queue_redraw()

	
	
func _on_delete_request() -> void:
	self.queue_free.call_deferred()


func _deselect_all_nodes() -> void:
	var parent = get_parent()  # GraphEdit
	if parent is GraphEdit:
		for node in parent.get_children():
			if node is GraphNode:
				node.set_selected(false)
				
				
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			#_deselect_all_nodes()
			#self.set_selected(true)
			#right_click.emit(self, event)
		if event.double_click:
			print("you double clicked me")
			change_title.emit(self)


func set_border_color(color_frame:Color, color_selected:Color) -> void:
	var color_frame_stylebox:StyleBoxFlat = self.get_theme_stylebox("titlebar").duplicate()
	var cf = color_frame_stylebox.bg_color
	color_frame_stylebox.bg_color = Color(color_frame.r, color_frame.g, color_frame.b, cf.a)
	self.add_theme_stylebox_override("titlebar", color_frame_stylebox)
	self.node_color_frame = color_frame_stylebox.bg_color
	
	var color_selected_stylebox:StyleBoxFlat = self.get_theme_stylebox("titlebar_selected").duplicate()
	var cs = color_selected_stylebox.bg_color
	color_selected_stylebox.bg_color = Color(color_selected.r, color_selected.g, color_selected.b, cs.a)
	self.add_theme_stylebox_override("titlebar_selected", color_selected_stylebox)
	self.node_color_selected = color_selected_stylebox.bg_color
