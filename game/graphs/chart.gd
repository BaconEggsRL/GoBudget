class_name BaconChartArea
extends Control

@onready var axis_font: Font = Label.new().get_theme_font("font").duplicate()

@export var _draw_line:bool = false
@export var _draw_bar:bool = true

@export var _show_grid:bool = false

@onready var bg: ColorRect = $"../bg"

@export var bg_color:Color = Color.BLACK

@export_range(1, 10, 1.0) var grid_width:int = 1
@export var grid_line_color:Color = Color.DIM_GRAY

@onready var markers: Control = $markers
#@export var marker_color:Color = Color.GREEN:
	#set = _set_marker_color

@export_range(1, 50, 1.0) var line_width:int = 5  # 120 for bar, 5 for line
@export var line_color:Color = Color.GREEN

@export_range(0.0, 1.0, 0.01) var bar_width_ratio: float = 1.0
@export var bar_color:Color = Color.YELLOW


var budget_bar_color = Color(0.0, 0.4, 1.0, 0.4)  # RGBA: semi-transparent blue
var green_color = Color(0.0, 0.8, 0.4, 1.0)  # A fresh, vibrant green
var red_color = Color(1.0, 0.2, 0.2, 1.0)  # A vivid but not overpowering red
		

@export var dot_texture: Texture2D = preload('res://art/graph-plot-white.png')

# ordered data
#const data = [
	#{'x': 'MON', 'y': 1.0},
	#{'x': 'TUE', 'y': 2.0},
	#{'x': 'WED', 'y': 3.0},
	#{'x': 'THU', 'y': 4.0},
	#{'x': 'FRI', 'y': 5.0},
	#{'x': 'SAT', 'y': 6.0},
	#{'x': 'SUN', 'y': 7.0},
	#{'x': 'SUN', 'y': 8.0},
#]

# random data
#var data = [
	#{'x': 'MON', 'y': 7.0},
	#{'x': 'TUE', 'y': 8.0},
	#{'x': 'WED', 'y': 3.0},
	#{'x': 'THU', 'y': 5.0},
	#{'x': 'FRI', 'y': 4.0},
	#{'x': 'SAT', 'y': 6.0},
	#{'x': 'SUN', 'y': 1.0},
	#{'x': 'MON', 'y': 7.0},
	#{'x': 'TUE', 'y': 8.0},
	#{'x': 'WED', 'y': 3.0},
	#{'x': 'THU', 'y': 5.0},
	#{'x': 'FRI', 'y': 4.0},
	#{'x': 'SAT', 'y': 6.0},
	#{'x': 'SUN', 'y': 1.0},
#]

var data = [
	{'x': 'MON', 'y': 7.0},
	{'x': 'TUE', 'y': -8.0},
	{'x': 'WED', 'y': 3.0},
	{'x': 'THU', 'y': 5.0},
	{'x': 'FRI', 'y': 4.0},
	{'x': 'SAT', 'y': -6.0},
	{'x': 'SUN', 'y': 1.0},
]

#var data = [
	#{'x': 'MON', 'y': 50.62},
	#{'x': 'TUE', 'y': 49.35},
	#{'x': 'WED', 'y': 9.08},
	#{'x': 'THU', 'y': 265.32},
	#{'x': 'FRI', 'y': 142.92},
	#{'x': 'SAT', 'y': 23.16},
	#{'x': 'SUN', 'y': 117.90},
#]

#var data = [
	#{'x': 'MON', 'y': -50.62},
	#{'x': 'TUE', 'y': 49.35},
	#{'x': 'WED', 'y': -9.08},
	#{'x': 'THU', 'y': 265.32},
	#{'x': 'FRI', 'y': -142.92},
	#{'x': 'SAT', 'y': -23.16},
	#{'x': 'SUN', 'y': 117.90},
#]

var data_original = data.duplicate(true)
@export_range (1, 50) var x_ticks: int = data_original.size():
	set = _set_x_tick_labels

@export_range (2, 12) var y_ticks: int = 9:
	set = _set_y_tick_labels

@onready var y_ticks_container: VBoxContainer = $"../../y_ticks_container"
@onready var x_ticks_container: HBoxContainer = $"../../x_ticks_container"



var points:PackedVector2Array
var grid_points:PackedVector2Array


var x_numerical = true
var y_numerical = true


var min_x
var min_y
var max_x
var max_y


var line_rect_width
var line_rect_height

var line_rect_x
var line_rect_y

var categories = {}
var budget = []


@onready var title: Label = $"../../title"
@onready var y_label: Label = $"../../y_label"
@onready var x_label: Label = $"../../x_label"


func update_data(new_data:Array, _categories:Dictionary) -> void:
	data = new_data.duplicate(true)
	
	categories = _categories
	for point in data:
		var cat = point.x
		var x = cat
		var y = -1.0 * categories[cat].budget
		budget.append({"x": x, "y": y})
	print(budget)
	
	data_original = data.duplicate(true)
	x_ticks = data_original.size()
	
	data_original += budget.duplicate(true)
	_init_points()
	
	
func _ready() -> void:
	title.text = "Spent vs. Budget"
	x_label.text = "Category"
	y_label.text = "Amount"
	
	# check if values are numerical
	for val in data:
		if not [TYPE_INT, TYPE_FLOAT].has(typeof(val['x'])):
			x_numerical = false
		if not [TYPE_INT, TYPE_FLOAT].has(typeof(val['y'])):
			y_numerical = false
			
	# initialize min x, max x, etc.
	_init_bounds(data_original)

	# add tick labels
	_init_tick_labels()
	
	# fix updated rect sizes not having correct values after altering labels
	await get_tree().process_frame
	
	# set initial size
	_reset_size()
	# draw points
	_init_points()



func update_show_hide() -> void:
	# print("AKISDUKASHKJDASHJKDHJKASD")
	if self.visible == true:
		# fix updated rect sizes not having correct values after altering labels
		if self.is_inside_tree():
			await get_tree().process_frame
		# initialize min x, max x, etc.
		_init_bounds(data_original)
		# add tick labels
		_init_tick_labels()
		# fix updated rect sizes not having correct values after altering labels
		if self.is_inside_tree():
			await get_tree().process_frame
		# set initial size
		_reset_size()
		# draw points
		_init_points()
		
		
		
	
# pass data_original on init
# then data after that
func _init_bounds(_data:Array) -> void:

	# reset min max
	min_x = null
	max_x = null
	
	# min x, min y only need to be set the first time. After that do not update it
	# min_y = null
	# max_y = null
	
	
	# get min and max values (use index if value isn't a number, e.g. weekdays)
	for i in range(len(_data)):
		var x_val = get_val(_data[i]['x'], i)
		var y_val = get_val(_data[i]['y'], i)
		
		if min_x == null or x_val < min_x:
			min_x = x_val
		if max_x == null or x_val > max_x:
			max_x = x_val
		if min_y == null or y_val < min_y:
			min_y = y_val
		if max_y == null or y_val > max_y:
			max_y = y_val
			
		# Force 0.0 to be included in the ticks if it's not already in the range
		if min_y > 0.0:
			min_y = 0.0
		if max_y < 0.0:
			max_y = 0.0
			
			
func _init_tick_labels() -> void:
	# add tick labels to each axis
	_set_x_tick_labels(x_ticks)
	_set_y_tick_labels(y_ticks)

	
#func _set_marker_color(value:Color) -> void:
	#marker_color = value
	#print(marker_color)
	#if is_inside_tree():
		#for c in get_tree().get_nodes_in_group("marker"):
			#c.set_modulate(marker_color)


# assumes the number of x_ticks equals the number of points being plotted
func _set_x_tick_labels(value:int) -> void:
	x_ticks = clamp(value, 1, data_original.size())  # prevent invalid values like 0
	print("x_ticks = %s" % str(x_ticks))
	
	data.clear()
	for i in range(x_ticks):
		var d = data_original[i]
		data.append(d)
	
	if is_inside_tree():
		_init_bounds(data)
		_reset_size()
		_init_points()


func _set_y_tick_labels(value:int) -> void:
	y_ticks = max(2, value)  # must be at least 2 to draw grid lines
	print("y_ticks = %s" % str(y_ticks))
	
	if is_inside_tree():
		_reset_size()
		_init_points()
	

func _reset_size() -> void:
	line_rect_width = self.size.x
	line_rect_height = self.size.y
	
	line_rect_x = (line_rect_width / x_ticks)
	line_rect_y = (line_rect_height / y_ticks)
	
	if x_ticks > 1:
		line_rect_width = line_rect_x * (x_ticks-1)
		
	# do not update rect_height
	# line_rect_height = line_rect_y * (y_ticks-1)

	
	
func _init_points() -> void:
	# add points
	points = PackedVector2Array()
	
	if markers:
		for c in markers.get_children():
			c.free()
			
	for i in range(len(data)):
		# add data points
		var x_val = get_val(data[i]['x'], i)
		var y_val = get_val(data[i]['y'], i)
		var scaled_x = scale_x(x_val)
		var scaled_y = scale_y(y_val)
		var point := Vector2(scaled_x, scaled_y)
		var color:Color
		if not budget.is_empty():
			var yb_val = get_val(budget[i]['y'], i)
			if abs(y_val) > abs(yb_val):
				color = red_color
			else:
				color = green_color
		self.add_point(point, data[i]['x'], y_val, color)
		
	for i in range(len(budget)):
		# add budget point
		var xb_val = get_val(budget[i]['x'], i)
		var yb_val = get_val(budget[i]['y'], i)
		var budget_point := Vector2(scale_x(xb_val), scale_y(yb_val))
		var color:Color = budget_bar_color
		#var y_val = get_val(data[i]['y'], i)
		#if abs(y_val) > abs(yb_val):
			#color = red_color
		#else:
			#color = green_color
		self.add_point(budget_point, budget[i]['x'], yb_val, color)

	

func add_point(point:Vector2, _point_name:String="", _point_value:float=0.0, _color:Color = Color.WHITE) -> void:
	points.append(point)
	
	# add sprite dot
	var marker = TextureRect.new()
	
	marker.set_texture(dot_texture)
	marker.set_modulate(_color)
	
	marker.set_position(point)
	marker.position -= marker.texture.get_size() / 2.0
	
	marker.mouse_filter = MOUSE_FILTER_STOP
	# marker.tooltip_text = '%s: %s\n%s: %s' % ["x", str(_point_name), "y", str(_point_value)]
	marker.tooltip_text = '%s: %s' % ["y", str(_point_value)]
	
	marker.add_to_group("marker")
	
	if markers:
		markers.add_child(marker)
	
	
	
	
func _draw():
	# set background color
	bg.color = bg_color
	
	


	# draw x tick labels
	for i in range(x_ticks):
		var value = data[i]['x']
		var x_pos = scale_x(i) - axis_font.get_string_size(value).x / 2.0
		
		var text = str(value)
		var text_size = axis_font.get_string_size(text)

		var y_pos = line_rect_height + text_size.y
		x_ticks_container.custom_minimum_size.y = abs(text_size.y)

		# Draw the label
		draw_string(axis_font, Vector2(x_pos, y_pos), value, HORIZONTAL_ALIGNMENT_CENTER)
			

	# draw y tick labels
	if y_ticks_container:
		for i in range(y_ticks):
			var value = snappedf(i * (max_y - min_y) / (y_ticks - 1) + min_y, 0.1)
			var y = scale_y(value)

			# Draw the text to the left of the chart area (you can tweak -10 or use margin)
			var text = str(value)
			var text_size = axis_font.get_string_size(text)
			var x_buffer = 4.0
			
			var x_pos = -text_size.x - x_buffer  # Position left of the chart
			y_ticks_container.custom_minimum_size.x = abs(x_pos)
			
			# i don't know why i have to divide by 4.0 here instead of 2.0, but it works
			draw_string(axis_font, Vector2(x_pos, y + text_size.y/4.0), text, HORIZONTAL_ALIGNMENT_RIGHT)
			
			# draw grid lines
			if _show_grid:
				draw_line(Vector2(0, y), Vector2(size.x, y), grid_line_color, grid_width, true)
	
	
	# Draw a horizontal white line at y = 0.0
	if min_y <= 0.0 and max_y >= 0.0:
		var y_zero = scale_y(0.0)
		draw_line(Vector2(0, y_zero), Vector2(size.x, y_zero), Color.WHITE, grid_width, true)
		
		
	# draw bar plot
	if _draw_bar:
		
		# budget bar
		
		if points.size() > 0:
			var max_bar_width = line_rect_x
			var bar_width = clamp(max_bar_width * bar_width_ratio, 1.0, max_bar_width)
			
			var zero_y = scale_y(0)
			
			for i in range(budget.size()):
				var point = points[i + data.size()]

				var y_val = budget[i]['y']
				var point_y = point.y
				
				if y_val >= 0:
					draw_line(Vector2(point.x, zero_y), Vector2(point.x, point_y), budget_bar_color, bar_width, true)
				else:
					draw_line(Vector2(point.x, zero_y), Vector2(point.x, point_y), budget_bar_color, bar_width, true)
					

		# data bar

		if points.size() > 0:
			var max_bar_width = line_rect_x
			var bar_width = clamp(max_bar_width * bar_width_ratio, 1.0, max_bar_width)
			
			var zero_y = scale_y(0)
			
			for i in range(data.size()):
				var point = points[i]

				var y_val = data[i]['y']
				var point_y = point.y
				
				var yb_val = budget[i]['y']
				
				var color:Color
				if abs(y_val) > abs(yb_val):
					color = red_color
				else:
					color = green_color
				
				if y_val >= 0:
					draw_line(Vector2(point.x, zero_y), Vector2(point.x, point_y), color, bar_width*0.8, true)
				else:
					draw_line(Vector2(point.x, zero_y), Vector2(point.x, point_y), color, bar_width*0.8, true)
		
		
		
	# draw line plot
	if _draw_line:
		if points.size() >= 2:
			draw_polyline(points, line_color, line_width, true)
			
			
	# debug
	#if points.size() >= 2:
		#for i in range(int(min_y), int(max_y) + 1):
			#var y = scale_y(i)
			#draw_line(Vector2(0, y), Vector2(size.x, y), Color.RED, 5, true)




func _process(_delta):
	queue_redraw()



#func scale_x(val):
	#var dx = max_x - min_x
	#return ((val - min_x) * line_rect_width / dx) + line_rect_x/2
func scale_x(val):
	var dx = max_x - min_x
	if dx == 0:
		return size.x / 2  # center it
	return ((val - min_x) * line_rect_width / dx) + line_rect_x / 2
	
	

#func scale_y(val):
	#var dy = max_y - min_y
	#return line_rect_height - ((val - min_y) * line_rect_height / dy) # + line_rect_y/2
func scale_y(val):
	var dy = max_y - min_y
	if dy == 0:
		return size.y / 2  # avoid divide by zero
	return line_rect_height - ((val - min_y) * line_rect_height / dy)
	
	
	

func get_val(val, idx):
	if [TYPE_INT, TYPE_FLOAT].has(typeof(val)):
		return val
	return idx


func _on_resized() -> void:
	# _init_points()
	pass
