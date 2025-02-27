now = time()
include("app2.jl")
using Dash

# @info "Server Started in $(time() - now) seconds"
if length(ARGS) > 0
    run_server(app, "0.0.0.0", parse(Int, ARGS[1]))
else
    run_server(app, debug=true)
end
