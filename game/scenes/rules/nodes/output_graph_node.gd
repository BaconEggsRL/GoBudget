class_name OutputGraphNode
extends SimpleGraphNode

@export var cat: OptionButton
@export var subcat: OptionButton
@export var priority: SpinBox

@export var node_data_keys := ["cat_idx", "subcat_idx", "priority"]


var categories:Dictionary = {}
var categories_order:Array = []


# add categories and subcategories to select
func _ready() -> void:
	# call parent ready
	super()
	# init data
	_reload_data()


func _on_cat_item_selected(index: int = cat.selected) -> void:
	print("selected cat: ", index)
	subcat.clear()
	
	if index != -1:
		var cat_name = categories_order[index]
		for sub_name in categories[cat_name].subs:
			subcat.add_item(sub_name)


# initialize category data on ready and when categories changed
func _reload_data() -> void:
	# connect signal
	if not cat.item_selected.is_connected(_on_cat_item_selected):
		cat.item_selected.connect(_on_cat_item_selected)
		
	# get global categories
	categories = SaveLoad.load_data("categories")
	categories_order = SaveLoad.load_data("categories_order")
	
	# initialize cat
	cat.clear()
	for cat_name in categories_order:
		cat.add_item(cat_name)
	
	# initialize subcat
	_on_cat_item_selected()
	
