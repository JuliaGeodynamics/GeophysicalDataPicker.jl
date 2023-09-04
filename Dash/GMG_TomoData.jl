# This is the main file with the GUI to interpret tomographic data
# Note that it calls other files with GUI components for each of the tabs.
using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics
using UUIDs

# include helper functions
include("utils.jl")  # tomographic dataset
include("utils_curves.jl")
include("GMG_TomoData_Plots.jl")
include("Tab_CrossSections.jl")
include("Tab_3Dview.jl")
include("Tab_Setup.jl")

#session_id =     # this generates a unique number of our session

# Load data
DataTomo, DataTopo = load_dataset();

# xtract data
data_fields =  keys(DataTomo.fields)

# set the initial cross-section
start_val = (5.0,46.0)
end_val = (12.0,44.0) 

# Create a global variable with the data structure. Note that we will 
global AppData
AppData=NamedTuple()

# Sets some defaults for the layout of webpage
app = dash(external_stylesheets = [dbc_themes.BOOTSTRAP], prevent_initial_callbacks=false)

app.title = "GMG Data Picker"
options_fields = [(label = String(f), value="$f" ) for f in data_fields]

# Create the layout of the main GUI. Note that the layout of the different tabs is specified in separate routines
#app.layout = dbc_container(className = "mxy-auto") do
    
function main_layout()
    session_id = UUIDs.uuid4()
    dbc_container([
        dbc_col(dbc_row([
                dbc_dropdownmenu(
                        [dbc_dropdownmenuitem("Load state", disabled=true),
                        dbc_dropdownmenuitem("Save state", disabled=true),
                        dbc_dropdownmenuitem(divider=true),
                        ],
                        label="File",
                        id="id-dropdown-file"),

                        html_h1("GMG Data Picker v0.1", style = Dict("margin-top" => 50, "textAlign" => "center")),
                        
                        ]),
                        ),

            dbc_tabs(
                [
                    dbc_tab(tab_id="tab-setup",label="Setup",             children = [Tab_Data()]),
                    dbc_tab(tab_id="tab-cross", label="Cross-sections",    children = [Tab_CrossSection()]),
                    dbc_tab(tab_id="tab-3D", label="3D view",           children = [Tab_3Dview()])
                ],
            id = "tabs", active_tab="tab-setup",
        ),
            
        dcc_store(id="id-topo", data=DataTopo.lat),              
        dcc_store(id="session-id", data =  "")     # gives a unique number of our session
    ])

end

app.layout = main_layout()
    

# Specify different callbacks for the different tabs:
include("./Tab_Setup_Callbacks.jl")    
include("./Tab_CrossSections_Callback.jl")    
include("./Tab_3Dview_Callbacks.jl")    

run_server(app, debug=false)
