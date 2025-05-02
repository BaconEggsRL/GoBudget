# GoBudget:  
  
An open-source budgeting / personal finance application.  
Built using Godot Engine 4.4.1  
  
  
## Features:  
  
Load transactions from .csv file.  
Set custom rules for different data sources (bank, credit card.)  
Automatically categorize transactions using configurable graph nodes.  
Create budgets and and plot aggregate data.  


## How to Use:

The source code can be downloaded and compiled using the latest version of the Godot Editor (4.4.1).
Alternatively you can download the .exe or use the browser version from here:
https://baconeggsrl.itch.io/gobudget

Under "Select a data source", click "Add new..." to add a new data source.

Load a ".csv" file containing transaction data. Some example data is provided in the GitHub repository.

Hit "Run active sources" to generate table and plot views. Click "show table" or "show plot" in the toolbar menu to view the data. (Click the same button again to return to the main menu.)

Click "edit rules" to view the rules graph. Here you can automatically categorize transactions using configurable graph nodes.

* Click "Add Node..." or right click -> Add Node.
* Choose your desired node type (Output, Condition, Logic Gate)
* Connect nodes by dragging and dropping from the input/output slots.
* Use the Debug panel to run rules against a test transaction. Output nodes with higher priority will be processed first (100 being the highest.)
* Use the Edit Categories menu to create your own custom categories. This is where you can assign a budget amount for each category.

Once you are satisfied with your transaction rules, hit "Save" to store them in memory. (Save data will be loaded next time you open the program.)

Click "edit rules" again to return to the main menu. Now hit "Run active sources" to process your new rules on the transaction data. If you return to the table or plot view, you should see the changes reflected in the Category and Subcategory columns.


  
## 3rd party plugins:  
  
dynamicdatatable by jospic  
https://github.com/jospic/dynamicdatatable  
  
Plotting code based on Iaknihs' Godot Line Chart tutorial  
https://github.com/Iaknihs/tutorials/tree/master/Godot_Line_Chart)  


## Screenshots:  
  
### Main Menu  
Add, edit, or delete data sources. Hit "Run active sources" to regenerate transaction data and plots.
![Alt text](_screenshots/main_menu.png?raw=true "Main Menu")  

### Rules Graph  
Create rules using graph nodes to categorize transactions according to your needs.  
![Alt text](_screenshots/rules_graph.png?raw=true "Rules Graph")  

### Budget Plot  
See progress towards your budget (red = over budget, green = under budget.)  
The round markers have hover tooltips for each amount.  
![Alt text](_screenshots/budget_plot.png?raw=true "Budget Plot")  

