class_name SaveDataResource
extends Resource

@export var transaction_folder:String = ""  # Path to transaction data folder
# @export var csv_data:Array = []  # CSV Data Record


# Dict of categories and subcategories array
@export var categories:Dictionary = {
	"Housing": 
		{
			"budget": 1400,
			"subs": ["Rent & Utilities"],
		},
	"Insurance": 
		{
			"budget": 200,
			"subs": ["Renters Insurance", "Car Insurance"],
		},
	"Food": 
		{
			"budget": 500,
			"subs": ["Supermarkets", "Restaurants"],
		},
	"Transportation": 
		{
			"budget": 100,
			"subs": ["Gasoline"],
		},
	"Subscriptions": 
		{
			"budget": 50,
			"subs": ["Phone Bill", "Crunchyroll", "Spotify", "Gym", "Car Wash"],
		},
	"Misc": 
		{
			"budget": 500,
			"subs": ["Merchandise"],
		}
}


# Store node order of categories
@export var categories_order:Array = [
	"Housing", 
	"Insurance", 
	"Food", 
	"Transportation", 
	"Subscriptions", 
	"Misc" 
]


@export var graph:Dictionary = {
	"nodes": [],
	"edges": [],
}  # Graph data


@export var data_sources:Array = [
	{
		"name": "source_1",
		"raw_csv_data_filepath": "res://transactions/2026/01-26/raw_test.csv",
		"raw_csv_data": [],  # raw (parsed) csv data
		"transaction_csv_data": [],  # transaction csv data
		"columns": {
			"Date": 0,
			"Description": 1,
			"Amount": 2,
			"SourceCategory": 3,
		},  # column mapping
		"active": true,
		"flip_amount": false,
	}
]
