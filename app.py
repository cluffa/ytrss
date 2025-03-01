import sys

import julia
from julia import Main

# Start Julia session
julia.install()
jl = julia.Julia()
port = sys.argv[1] if len(sys.argv) > 1 else 8050

# Execute Julia code
result = Main.eval(f"""
using Pkg; Pkg.activate(@__DIR__); Pkg.instantiate()
include("app.jl")
using Dash
run_server(app, "0.0.0.0", {port}, debug=false)
""")
