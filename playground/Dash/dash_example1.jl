using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics

# include helper functions
include("utils.jl")  # tomographic dataset

# Load data
DataTomo, DataTopo = load_dataset();


data_fields =  keys(DataTomo.fields)
start_val = (10,41)
end_val = (10,49) 

global AppData
AppData = ();        # this will later hold the cross-section and plot data

# define the options on the lower-right
# OBSOLETE?
function lowerright_menu()
    html_div(style = Dict("border" => "0.5px solid", "border-radius" => 5, "margin-top" => 68), className = "three columns") do
        html_div(id = "freq-val",
        style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
       
        html_div(id = "damp-val",
        style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
        dcc_slider(
            id = "damp-slider",
            min = 1,
            max = 6,
            step = nothing,
            value = 1,
            marks = Dict([i => ("$(i)") for i in 1:6])
        ),

        html_div(id = "disp-val",
        style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
        dcc_slider(
            id = "disp-slider",
            min = -1.,
            max = 1.,
            step = 0.1,
            value = 0.5,
            marks = Dict([i => ("$i") for i in [-1, 0, 1]])
        ),

        html_div(id = "vel-val",
        style = Dict("margin-top" => "15px", "margin-left" => "15px",  "margin-bottom" => "5px")),
        dcc_slider(
            id = "vel-slider",
            min = -100.,
            max = 100.,
            step = 1.,
            value = 0.,
            marks = Dict([i => ("$i") for i in [-100, -50, 0, 50, 100]])
        ),

        dcc_checklist(
            options = [
                Dict("label" => "horizontal cross-section", "value" => false)
            ],
            value = ["MTL", "SF"],
        ),

        html_button("plot cross-section", id="button_cross", name="plot cross-section", n_clicks=0, contentEditable=true)

    end
end

"""
Creates topo plot & line that shows the cross-section
"""
function plot_topo(DataTopo,start_val=nothing, end_val=nothing)
    xdata =  DataTopo.lon.val[:,1]
    ydata =  DataTopo.lat.val[1,:]
    zdata =  DataTopo.depth.val[:,:,1]'
    if isnothing(start_val)
        start_val = (mean(xdata), minimum(ydata)+1)
    end
    if isnothing(end_val)
        end_val = (mean(xdata), maximum(ydata)-1)
    end
    colorscale = "Viridis";
    reversescale = false;

    pl = (
        id = "fig_topo",
        data = [heatmap(x = xdata, 
                        y = ydata, 
                        z = collect(eachcol(zdata)),
                        colorscale = colorscale,reversescale=reversescale,
                        zmin = -4, 
                        zmax = 4,
                        colorbar=attr(thickness=5)
                        )
                ],
        colorbar=Dict("orientation"=>"v", "len"=>0.5, "thickness"=>10,"title"=>"elevat"),
        layout = (  title = "topography [km]",
                    yaxis=attr(
                        title="Latitude",
                        tickfont_size= 14,
                        tickfont_color="rgb(100, 100, 100)"
                    ),
                    xaxis=attr(
                        title="Longitude",
                        tickfont_size= 14,
                        tickfont_color="rgb(10, 10, 10)"
                    ),
                    shapes = [
                            (   type = "line", x0=start_val[1], x1=end_val[1], 
                                            y0=start_val[2], y1=end_val[2],
                                editable = true)
                            ],
                    ),
        config = (edits    = (shapePosition =  true,)),                              
    )
    return pl
end


"""
Creates topo plot & line that shows the cross-section
"""
function plot_cross(Cross::Profile; zmax=nothing, zmin=nothing, shapes=[])
    colorscale = "Rgb";
    reversescale = true;
    println("updating cross section")
    data = Cross.data';
    if isnothing(zmax)
        zmin, zmax = extrema(data)
    end

    shapes_data = [];
    if !isempty(shapes)
        # a shape was added to the plot; add it again
        for shape in shapes
            
            if shape.type=="line"
                line = shape.data_curve
                val  = (type = "line",   x0=line[1], x1=line[3], y0=line[2], y1=line[4], editable = true,
                            label = (text=shape.label_text,),
                            line  = (color=shape.line_color, width=shape.line_width))
                    
            elseif shape.type=="path"
                val =  (type = "path", path=shape.data_curve, editable = true,
                            label = (text=shape.label_text,),
                            line  = (color=shape.line_color, width=shape.line_width))
                                
            end
            push!(shapes_data, val)
        end
    end

    pl = (  id = "fig_cross",
            data = [heatmap(x = Cross.x_cart, 
                            y = Cross.z_cart, 
                            z = collect(eachcol(data)),
                            colorscale   = colorscale,
                            reversescale = reversescale,
                            colorbar=attr(thickness=5),
                            zmin=zmin, zmax=zmax
                            )
                    ],                            
            colorbar=Dict("orientation"=>"v", "len"=>0.5, "thickness"=>10,"title"=>"elevat"),
            layout = (  title = "Cross-section",
                        xaxis=attr(
                            title="Length along cross-section [km]",
                            tickfont_size= 14,
                            tickfont_color="rgb(100, 100, 100)"
                        ),
                        yaxis=attr(
                            title="Depth [km]",
                            tickfont_size= 14,
                            tickfont_color="rgb(10, 10, 10)"
                        ),
                        shapes = shapes_data,
                        ),
            config = (edits    = (shapePosition =  true,)),  
        )
    return pl
end


function plot_cross(cross::Nothing) 
    println("default cross section")
    cross = get_cross_section(DataTomo, (10,41), (10,29))
    pl = plot_cross(cross)
    return pl
end
plot_cross() = plot_cross(nothing)  


# This creates the topography (mapview) plot (lower left)
function create_topo_plot(DataTopo,start_val=nothing, end_val=nothing)
   
    dcc_graph(
        id = "mapview",
        
        figure    = plot_topo(DataTopo, start_val, end_val),
        animate   = true,
        clickData = true,
        config = PlotConfig(displayModeBar=false, scrollZoom = false)
    )

end

# This creates the cross-section plot
function cross_section_plot()
    dcc_graph(
        id = "cross_section",
        figure = plot_cross(), 
        animate = false,
        responsive=false,
        config = PlotConfig(displayModeBar=true, modeBarButtonsToAdd=["drawline","drawopenpath","eraseshape"],displaylogo=false))
        
end




# sets some defaults for webpage
#app = dash(external_stylesheets = ["/assets/app.css"])  
app = dash(external_stylesheets = [dbc_themes.BOOTSTRAP])

app.title = "GMG Data picker"


options_fields = [(label = String(f), value="$f" ) for f in data_fields]

# Create the main layout
app.layout = dbc_container(className = "mxy-auto") do

    
    html_h1("GMG Data Picker v0.1", style = Dict("margin-top" => 50, "textAlign" => "center")),

    html_div([
        dbc_col([
            # plot with cross-section
            dbc_placeholder(xs=12, button=true),
            dbc_row([dbc_col([cross_section_plot()], width=10),
                     dbc_col([
                                dbc_row([dbc_button("Curve Interpretation",id="button-curve-interpretation"),
                                         dbc_collapse(
                                             dbc_card(dbc_cardbody([
                                                dbc_row([
                                                    dbc_label("Options",align="center"),
                                                   # dbc_checkbox(label="lock curve", id="lock-curve"),
                                                    dbc_input(placeholder="Name of curve",id="shape-name"),
                                                    dbc_input(placeholder="Linewidth",id="shape-linewidth"),
                                                    dbc_placeholder(button=true),
                                                    
                                                    dbc_button("Update latest curve",id="button-save-curve"),
                                                ])
                                                ])),
                                             id="collapse",
                                             is_open=false,
                                         ),
                                ])

                        
                            ], align="center"),
                    ], justify="center"),

            # info below plot
            dbc_row([
                    dbc_col([dcc_input(id="start_val", name="start_val", type="text", value="start: 10,40",style = Dict(:width => "100%"), debounce=true)]),
                    dbc_col([dcc_dropdown(
                                    id="dropdown_field",
                                    options = options_fields,
                                    value = "dVp_paf21",
                                    clearable=false, placeholder="Select Dataset",
                                ),
                                ]),
                    dbc_col([ dcc_rangeslider(
                                    id = "colorbar-slider",
                                    min = -5.,
                                    max = 5.,
                                    #step = .1,
                                    value=[-3, 3],
                                    allowCross=false,
                                    tooltip="always_visible"
                                    #marks = Dict([i => ("$i") for i in [-10, -5, 0, 5, 10]])
                                ),    
                                ]),
                    dbc_col([dcc_input(id="end_val", name="end_val", type="text", value="end: 10,50",style = Dict(:width => "100%"),placeholder="min")])
                    ]),
            ], width=12),

            # lower row | topography plot & buttons
            dbc_row([
                # plot topography
                
                dbc_col([create_topo_plot(DataTopo, start_val, end_val)]),
                
                # various menus @ lower right
                dbc_col([
                    dbc_row([html_div("various options")], justify="center"),
                    dbc_row([dbc_placeholder(xs=6, button=true)], align="center",justify="end"),
                   
                    #dbc_card(dbc_cardbody(["This is some text within a card body",
                    #         html_button(id="button-select", name="select", n_clicks=0, contentEditable=true),
                    #         dbc_placeholder(xs=6),
                    #]))
                    
                ], align="end")
                #dbc_col([
                #    dbc_row([html_button(id="button-select", name="select", n_clicks=0, contentEditable=true)])
                #])

            ])
           
        ]),


        #html_div(className = "row") do
        #    create_topo_plot(DataTopo, start_val, end_val),
        #    lowerright_menu()
        #end,
    
        html_pre(id="relayout-data")
end

#=
callback!(app,  Output("cross_section","figure"),
                Input("cross_section","figure"),
                Input("shape-name","value"),
                Input("shape-name","n_submit"),
                ) do fig_cross,shape_name, n

    # retrieve dataset
    #=
    layout=fig_cross.layout
    if !isnothing(n)
        @show fig_cross.layout
        

        @show keys(fig_cross)
       
    end
=#
  #  retB = plot_topo(DataTopo)
    fig  = plot_cross()

    
     
    return fig
end
=#

# this is the callback that is invoked if the line on the topography map is changed
callback!(app,  Output("start_val", "value"),
                Output("end_val", "value"),
                Input("mapview", "relayoutData")) do value

    retB = "start: 10,41"
    retC = "end: 10,49"

    # if we move the line value on the cross-section it will update this here:
    start_val, end_val = get_startend_cross_section(value)
    if !isnothing(start_val) 
        # Update textbox values
        retB = "start: $(@sprintf("%.2f", start_val[1])),$(@sprintf("%.2f", start_val[2]))"
        retC = "end: $(@sprintf("%.2f", end_val[1])),$(@sprintf("%.2f", end_val[2]))"

    end
    retA = [];
    
    return retB, retC
end

#Output("relayout-data", "children"), 
     

# This callback changes the cross-section line if we change the values by hand
callback!(app,  Output("mapview", "figure"), 
                Output("cross_section","figure"),
                Input("start_val", "n_submit"),
                Input("end_val", "n_submit"),
                Input("start_val", "value"),
                Input("end_val", "value"),
                Input("dropdown_field","value"),
                Input("colorbar-slider", "value"),
                Input("cross_section","relayoutData"),       # curves potentially added to cross-section
                Input("cross_section","figure"),             # figure with cross section
                Input("shape-name","value"),
                Input("shape-name","n_submit"),
                
                ) do n_start, n_end, start_value, end_value, selected_field, colorbar_value, cross_section_shape, fig_cross, shape_name, n_shape_name
    global AppData
    @show AppData

    modify_data = (name=shape_name,)
    shapes = interpret_drawn_curve(fig_cross.layout, modify_data);

    if !isnothing(n_shape_name)
        @show keys(fig_cross)
    end
    
    if (!isnothing(start_value) ) ||
        (!isnothing(end_value)  ) 
        
        # extract values:
        start_val1 = split(start_value,":")
        start_val1 = start_val1[end]

        end_val1 = split(end_value,":")
        end_val1 = end_val1[end]

        start_val, end_val = nothing, nothing
        s_str = split(start_val1,",")
        e_str = split(end_val1,  ",")
        if length(s_str)==2 && length(e_str)==2
            if !any(isempty.(s_str)) && !any(isempty.(e_str))
                x0,y0 = parse.(Float64,s_str)
                x1,y1 = parse.(Float64,e_str)
                start_val = (x0,y0)
                end_val = (x1,y1)
            end
        end
        
        retB = plot_topo(DataTopo,start_val, end_val)
        cross = get_cross_section(DataTomo, start_val, end_val, Symbol(selected_field))
        data = plot_cross(cross, zmin=colorbar_value[1], zmax=colorbar_value[2], shapes=shapes)


        AppData = (cross=cross,)
        return (retB, data)

    else
        retB = plot_topo(DataTopo)
        data = plot_cross(; shapes=shapes)
        return (retB, data)
    end
end


# open/close Curve interpretation
callback!(app,
    Output("collapse", "is_open"),
    [Input("button-curve-interpretation", "n_clicks")],
    [State("collapse", "is_open")], ) do  n, is_open
    
    if isnothing(n); n=0 end

    if n>0
        if is_open==1
            is_open = 0
        elseif is_open==0
            is_open = 1
        end
    end
    return is_open 
        
end






#=
callback!(app,  Output("relayout-data", "children"),
                Input("button-save-curve","n_clicks"),
                Input("cross_section","relayoutData")       # curves potentially added to cross-section
                ) do n, cross_section_shape

    # retrieve dataset
    @show n, cross_section_shape

    return nothing

end
=#

run_server(app)