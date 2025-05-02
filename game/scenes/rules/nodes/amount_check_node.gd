class_name AmountCheckNode
extends SimpleGraphNode

@onready var condition: OptionButton = $VBoxContainer/condition
@onready var abs_btn: CheckBox = $VBoxContainer/abs_btn
@onready var amount: SpinBox = $VBoxContainer/amount

@onready var hint_label: Label = $VBoxContainer/if




@export var node_data_keys := ["idx", "abs_btn", "amount"]


func _on_abs_btn_toggled(toggled_on: bool) -> void:
	if toggled_on:
		hint_label.text = "if abs(Amount) is..."
	else:
		hint_label.text = "if Amount is..."
