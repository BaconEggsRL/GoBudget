extends Node
## Code taken and modified from https://github.com/Pukkah/HTML5-File-Exchange-for-Godot
## Thanks to Pukkah from GitHub for providing the original code

signal in_focus
signal web_file_loaded  ## Emits a signal for returning loaded image info
signal web_file_canceled


func _ready() -> void:
	if OS.has_feature("web"):
		_define_js()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		in_focus.emit()


func _define_js() -> void:
	(
		JavaScriptBridge
		. eval(
			"""
	var fileData;
	var fileType;
	var fileName;
	var canceled;
	function upload_csv() {
		canceled = true;
		var input = document.createElement('INPUT');
		input.setAttribute("type", "file");
		input.setAttribute(
			"accept", ".csv"
		);
		input.click();
		input.addEventListener('change', event => {
			if (event.target.files.length > 0){
				canceled = false;}
			var file = event.target.files[0];
			var reader = new FileReader();
			fileType = file.type;
			fileName = file.name;
			reader.readAsText(file);
			reader.onloadend = function (evt) {
				if (evt.target.readyState == FileReader.DONE) {
					fileData = evt.target.result;
				}
			}
		});
	}
	""",
			true
		)
	)


## If (load_directly = false) then image info (image and its name)
## will not be directly forwarded it to OpenSave
func load_file() -> void:
	if !OS.has_feature("web"):
		return
		
	# Execute JS function
	JavaScriptBridge.eval("upload_csv();", true)  # Opens prompt for choosing file
	await in_focus  # Wait until JS prompt is closed
	await get_tree().create_timer(0.5).timeout  # Give some time for async JS data load

	if JavaScriptBridge.eval("canceled;", true) == 1:  # If File Dialog closed w/o file
		print("File dialog closed / canceled")
		web_file_canceled.emit()
		return

	# Use data from png data
	var file_data_string: String
	while true:
		file_data_string = JavaScriptBridge.eval("fileData;", true)
		if file_data_string != null:
			break
		await get_tree().create_timer(1.0).timeout  # Need more time to load data

	var file_type: String = JavaScriptBridge.eval("fileType;", true)
	var file_name: String = JavaScriptBridge.eval("fileName;", true)
	
	#print("file_type = ", file_type)
	#print("file_name = ", file_name)
	#print("file_data = ", file_data)
	
	var file_data:Array = parse_csv_string(file_data_string)
	
	var file_info = {
		"file_type": file_type, 
		"file_name": file_name, 
		"file_data": file_data
	}
	
	web_file_loaded.emit(file_info)
	
	
func parse_csv_string(data_string: String) -> Array:
	data_string = data_string.replace("\r", "")  # Remove all carriage returns
	var rows = data_string.strip_edges().split("\n")
	var result = []

	for row in rows:
		var columns = row.split(",", false)
		result.append(columns)

	return result
