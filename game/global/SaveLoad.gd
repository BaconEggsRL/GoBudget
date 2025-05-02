extends Node

const save_location = "user://SaveFile.tres"

var SaveFileData: SaveDataResource = SaveDataResource.new()

func _ready() -> void:
	_load()

func _save() -> void:
	ResourceSaver.save(SaveFileData, save_location)

func _load() -> void:
	if FileAccess.file_exists(save_location):
		SaveFileData = ResourceLoader.load(save_location).duplicate(true)

func _reset() -> void:
	SaveFileData = SaveDataResource.new()
	_save()
	
func save_data(key_name: String, new_value) -> void:
	if _has_property(SaveFileData, key_name):
		SaveFileData.set(key_name, new_value)
		_save()
	else:
		push_warning("Property '%s' does not exist in SaveFileData." % key_name)

func load_data(key_name: String) -> Variant:
	_load()
	if _has_property(SaveFileData, key_name):
		return SaveFileData.get(key_name)
	else:
		push_warning("Property '%s' does not exist in SaveFileData." % key_name)
		return null  # Return null if the property does not exist

func _has_property(resource: Resource, property_name: String) -> bool:
	for prop in resource.get_property_list():
		if prop.name == property_name:
			return true
	return false


# Function to load CSV data from a file
func load_csv(file_path: String) -> Dictionary:
	var result = {"records": []}
	var _data:Array = []  # This will hold the final array of parsed CSV rows
	var file = FileAccess.open(file_path, FileAccess.READ)  # Open file for reading
	
	if file == null:
		print("Failed to open file: ", file_path)
		return result
	
	# Read all lines in the CSV file
	while file.eof_reached() == false:
		var line = file.get_csv_line()  # Get the next CSV line (as an array of strings)
		if line:
			_data.append(line)  # Append the line to the data array

	file.close()  # Close the file
	result.records = _data
	return result
