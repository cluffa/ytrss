using JSON3
using Dash
using DataFrames
using PlotlyJS

app = dash(external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"])

# CSS styles
styles = (
    pre = Dict(
        "border" => "thin lightgrey solid",
        "overflowX" => "hidden",
        "white-space" => "pre-wrap",
        "word-wrap" => "break-word",
        "text-overflow" => "ellipsis",
        "max-width" => "100%"
    ),
    header = Dict(
        "backgroundColor" => "#4CAF50",
        "color" => "white",
        "padding" => "10px 15px",
        "marginBottom" => "20px",
        "borderRadius" => "0",
        "fontWeight" => "bold",
        "fontSize" => "18px",
        "display" => "flex",
        "alignItems" => "center"
    ),
    app_container = Dict(
        "maxWidth" => "100%",
        "margin" => "0",
        "padding" => "0"
    ),
    plot_container = Dict(
        "width" => "100%",
        "marginBottom" => "20px"
    ),
    data_grid = Dict(
        "display" => "grid",
        "gridTemplateColumns" => "1fr 1fr",
        "gridGap" => "15px"
    ),
    card = Dict(
        "border" => "1px solid #ddd",
        "borderRadius" => "5px",
        "backgroundColor" => "#f9f9f9",
        "marginBottom" => "15px",
        "boxShadow" => "0 2px 4px rgba(0,0,0,0.1)"
    ),
    card_body = Dict(
        "padding" => "15px"
    ),
    panel_header = Dict(
        "backgroundColor" => "#f0f0f0",
        "padding" => "10px 15px",
        "borderBottom" => "1px solid #ddd",
        "fontWeight" => "bold"
    )
)

card(f) = html_div(f, style=styles.card)
card_body(f) = html_div(f, style=styles.card_body)
panel_header(f) = html_div(f, style=styles.panel_header)
app_container(f) = html_div(f, style=styles.app_container)
data_grid(f) = html_div(f, style=styles.data_grid)
plot_container(f) = html_div(f, style=styles.plot_container)
header(f) = html_div(f, style=styles.header)
pre(id) = html_pre(style=styles.pre, id = id)

inner = 5
n = 5 * inner
df = DataFrame(
    "x" => rand(1:0.1:5, n),
    "y" => rand(1:0.1:5, n),
    "customdata" => 1:n,
    "fruit" => repeat(["apple", "orange", "banana", "grape", "pear"], inner=inner)
)

fig = plot(df, x=:x, y=:y, color=:fruit, marker_size=20, custom_data=:customdata, mode="markers")

app.layout = plot_container() do
    # Main header
    header() do
        html_span("🔬 JuliaHub")
    end,
    
    # Data grid
    data_grid() do
        # Plot card
        card() do
            panel_header("Temperature Data"),
            card_body() do
                dcc_graph(
                    id="basic-interactions",
                    figure=fig
                )
            end
        end,

        # test card
        card() do
            panel_header("test"),
            card_body() do
                dcc_markdown("""
                    Click and drag on the graph to zoom or click on the zoom
                    buttons in the graph's menu bar.
                """),
                pre("test-data")
            end
        end,

        # First card
        card() do
            panel_header("Hover Data"),
            card_body() do
                dcc_markdown("""
                    Mouse over values in the graph.
                """),
                pre("hover-data")
            end
        end,

        # Second card
        card() do
            panel_header("Click Data"),
            card_body() do
                dcc_markdown("""
                    Click on points in the graph.
                """),
                pre("click-data")
            end
        end,
        
        # Fourth card
        card() do
            panel_header("Zoom and Relayout Data"),
            card_body() do
                dcc_markdown("""
                    Click and drag on the graph to zoom or click on the zoom
                    buttons in the graph's menu bar.
                """),
                pre("relayout-data")
            end
        end,

        # Third card
        card() do
            panel_header("Selection Data"),
            card_body() do
                dcc_markdown("""
                    Choose the lasso or rectangle tool in the graph's menu
                    bar and then select points in the graph.
                """),
                pre("selected-data")
            end
        end
    end
end

callback!(app,
    Output("hover-data", "children"),
    Input("basic-interactions", "hoverData")) do hoverData
    return JSON3.write(hoverData)
end

callback!(app,
    Output("click-data", "children"),
    Input("basic-interactions", "clickData")) do clickData
    return JSON3.write(clickData)
end

callback!(app,
    Output("selected-data", "children"),
    Input("basic-interactions", "selectedData")) do selectedData
    return JSON3.write(selectedData)
end

callback!(app,
    Output("relayout-data", "children"),
    Input("basic-interactions", "relayoutData")) do relayoutData
    return JSON3.write(relayoutData)
end


if length(ARGS) > 0
    run_server(app, "0.0.0.0", parse(Int, ARGS[1]))
else
    run_server(app, debug=true)
end
