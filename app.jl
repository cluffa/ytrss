using Dash
using PlotlyBase
using HTTP

# Load data

# CSV file format:
# Country Name,Indicator Name,Year,Value
# Arab World,"Agriculture, value added (% of GDP)",1962,0.760995978569

let response = HTTP.get("https://plotly.github.io/datasets/country_indicators.csv")
    buff = IOBuffer(response.body)
    @info header = strip.(split(readline(buff), ","))
    global df = @NamedTuple{CountryName::Vector{String}, IndicatorName::Vector{String}, Year::Vector{Int32}, Value::Vector{Union{Float32,Nothing}}}((String[], String[], Int32[], Union{Float32,Nothing}[]))

    while !eof(buff)
        line = readline(buff)
        # parse data, accounting for missing values and quotes
        data = strip.(split(line, r",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", keepempty=true), '\"')

        push!(df.CountryName, data[1])
        push!(df.IndicatorName, data[2])
        push!(df.Year, parse(Int32, data[3]))

        if length(data) < 4 || data[4] == ""
            push!(df.Value, nothing)
        else
            push!(df.Value, parse(Float32, data[4]))
        end
    end

    close(buff)
end

IndicatorNames = unique(df.IndicatorName)
Years = unique(df.Year)

# Initialize app
app = dash(external_stylesheets=["https://codepen.io/chriddyp/pen/bWLwgP.css"])

# Helper function for creating time series
function create_time_series(x, y, axis_type, title)
    fig = Plot(
        x,
        y,
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
                options=[Dict("label" => i, "value" => i) for i in IndicatorNames],
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
                options=[Dict("label" => i, "value" => i) for i in IndicatorNames],
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
            min=minimum(Years),
            max=maximum(Years),
            value=maximum(Years),
            marks=Dict(string(year) => string(year) for year in Years),
            step=5,
            included=false,
            updatemode="drag"
        )
    ], style=Dict("width" => "49%", "padding" => "0px 20px 20px 20px"))
end

# Callbacks

function render_main_plot(xaxis_column_name, yaxis_column_name,
    xaxis_type, yaxis_type, year_value)

    # dff = @view df[df.Year .== year_value, :]
    isYear = df.Year .== year_value
    
    # x_data = dff[dff[!, "Indicator Name"] .== xaxis_column_name, "Value"]
    x_data = df.Value[isYear .& (df.IndicatorName .== xaxis_column_name)]

    # y_data = dff[dff[!, "Indicator Name"] .== yaxis_column_name, "Value"]
    y_data = df.Value[isYear .& (df.IndicatorName .== yaxis_column_name)]

    # country_names = dff[dff[!, "Indicator Name"] .== yaxis_column_name, "Country Name"]
    country_names = df.CountryName[isYear .& (df.IndicatorName .== yaxis_column_name)]

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
    # dff = @view df[(df[!, "Country Name"] .== country_name) .& (df[!, "Indicator Name"] .== axis_column_name), :]

    includeRow = (df.CountryName .== country_name) .& (df.IndicatorName .== axis_column_name)

    title = "<b>$country_name</b><br>$axis_column_name"
    return create_time_series(df.Year[includeRow], df.Value[includeRow], axis_type, title)
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
