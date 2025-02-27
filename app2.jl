using Dash
using DataFrames
using PlotlyJS
using CSV
using HTTP

# Load data
response = HTTP.get("https://plotly.github.io/datasets/country_indicators.csv")
df = CSV.read(IOBuffer(String(response.body)), DataFrame)

# Initialize app
app = dash(external_stylesheets=["https://codepen.io/chriddyp/pen/bWLwgP.css"])

# Helper function for creating time series
function create_time_series(dff, axis_type, title)
    fig = Plot(
        dff,
        x=:Year,
        y=:Value,
        mode="lines+markers"
    )
    
    relayout!(fig, 
        height=225,
        margin=Dict(:l => 20, :b => 30, :r => 10, :t => 10),
        xaxis=Dict(:showgrid => false),
        yaxis=Dict(:type => axis_type == "Linear" ? "linear" : "log"),
        annotations=[
            Dict(
                :x => 0,
                :y => 0.85,
                :xanchor => "left",
                :yanchor => "bottom",
                :xref => "paper",
                :yref => "paper",
                :showarrow => false,
                :align => "left",
                :text => title
            )
        ]
    )
    return fig
end

# Layout
app.layout = html_div() do
    html_div([
        html_div([
            dcc_dropdown(
                id="crossfilter-xaxis-column",
                options=[Dict("label" => i, "value" => i) for i in unique(df[!, "Indicator Name"])],
                value="Fertility rate, total (births per woman)"
            ),
            dcc_radioitems(
                id="crossfilter-xaxis-type",
                options=[Dict("label" => i, "value" => i) for i in ["Linear", "Log"]],
                value="Linear",
                style=Dict("display" => "inline-block", "marginTop" => "5px")
            )
        ], style=Dict("width" => "49%", "display" => "inline-block")),

        html_div([
            dcc_dropdown(
                id="crossfilter-yaxis-column",
                options=[Dict("label" => i, "value" => i) for i in unique(df[!, "Indicator Name"])],
                value="Life expectancy at birth, total (years)"
            ),
            dcc_radioitems(
                id="crossfilter-yaxis-type",
                options=[Dict("label" => i, "value" => i) for i in ["Linear", "Log"]],
                value="Linear",
                style=Dict("display" => "inline-block", "marginTop" => "5px")
            )
        ], style=Dict("width" => "49%", "float" => "right", "display" => "inline-block"))
    ], style=Dict("padding" => "10px 5px")),

    html_div([
        dcc_graph(
            id="crossfilter-indicator-scatter",
            hoverData=Dict("points" => [Dict("customdata" => "Japan")])
        )
    ], style=Dict("width" => "49%", "display" => "inline-block", "padding" => "0 20")),

    html_div([
        dcc_graph(id="x-time-series"),
        dcc_graph(id="y-time-series"),
    ], style=Dict("display" => "inline-block", "width" => "49%")),

    html_div([
        dcc_slider(
            id="crossfilter-year--slider",
            min=minimum(df[!, "Year"]),
            max=maximum(df[!, "Year"]),
            value=maximum(df[!, "Year"]),
            marks=Dict(string(year) => string(year) for year in unique(df[!, "Year"])),
            step=5,
            included=false,
            updatemode="drag"
        )
    ], style=Dict("width" => "49%", "padding" => "0px 20px 20px 20px"))
end

# Callbacks

function render_main_plot(xaxis_column_name, yaxis_column_name,
    xaxis_type, yaxis_type, year_value)

    dff = @view df[df.Year .== year_value, :]
    
    x_data = dff[dff[!, "Indicator Name"] .== xaxis_column_name, "Value"]
    y_data = dff[dff[!, "Indicator Name"] .== yaxis_column_name, "Value"]
    country_names = dff[dff[!, "Indicator Name"] .== yaxis_column_name, "Country Name"]

    fig = Plot(
        scatter(;
            x=x_data,
            y=y_data,
            mode="markers",
            hovertext=country_names,
            customdata=country_names
        )
    )
    
    relayout!(fig,
        xaxis_title=xaxis_column_name,
        yaxis_title=yaxis_column_name,
        xaxis_type=xaxis_type == "Linear" ? "linear" : "log",
        yaxis_type=yaxis_type == "Linear" ? "linear" : "log",
        margin=Dict(:l => 40, :b => 40, :t => 10, :r => 0),
        hovermode="closest"
    )
    
    return fig
end

# Update main scatter plot
callback!(render_main_plot, app,
    Output("crossfilter-indicator-scatter", "figure"),
    Input("crossfilter-xaxis-column", "value"),
    Input("crossfilter-yaxis-column", "value"),
    Input("crossfilter-xaxis-type", "value"),
    Input("crossfilter-yaxis-type", "value"),
    Input("crossfilter-year--slider", "value"))

function render_time_series(hoverData, axis_column_name, axis_type)
    country_name = hoverData["points"][1]["customdata"]
    dff = @view df[(df[!, "Country Name"] .== country_name) .& (df[!, "Indicator Name"] .== axis_column_name), :]
    title = "<b>$country_name</b><br>$axis_column_name"
    return create_time_series(dff, axis_type, title)
end

# Update x-axis time series
callback!(render_time_series, app,
    Output("x-time-series", "figure"),                      # Output: Time series plot for x-axis variable
    Input("crossfilter-indicator-scatter", "hoverData"),    # Input: Hover data containing selected country
    Input("crossfilter-xaxis-column", "value"),             # Input: Selected x-axis indicator
    Input("crossfilter-xaxis-type", "value"))               # Input: Linear/Log scale for x-axis

# Update y-axis time series
callback!(render_time_series, app,
    Output("y-time-series", "figure"),                      # Output: Time series plot for y-axis variable
    Input("crossfilter-indicator-scatter", "hoverData"),    # Input: Hover data containing selected country  
    Input("crossfilter-yaxis-column", "value"),             # Input: Selected y-axis indicator
    Input("crossfilter-yaxis-type", "value"))               # Input: Linear/Log scale for y-axis
