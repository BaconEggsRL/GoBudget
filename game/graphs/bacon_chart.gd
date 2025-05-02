class_name BaconChart
extends Control

@export var chart_area:BaconChartArea


func _on_visibility_changed() -> void:
	# print("hello")
	chart_area.update_show_hide()
