class_name ConditionalGraphNode
extends SimpleGraphNode

@onready var substring: TextEdit = $VBoxContainer/substring
@onready var column_name: OptionButton = $VBoxContainer/column_name

@export var node_data_keys := ["substring", "idx"]
