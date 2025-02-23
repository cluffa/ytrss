using Oxygen
using HTTP

# Get port from command line arguments or use default
port = if length(ARGS) > 0
    parse(Int, ARGS[1])
else
    8080
end

@get("/") do
    # blank rss feed
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
    <channel>
    <title>Blank RSS Feed</title>
    <link>http://example.com</link>
    <description>Blank RSS Feed</description>
    <item>
    <title>Blank RSS Feed</title>
    <link>http://example.com</link>
    <description>Blank RSS Feed</description>
    </item>
    </channel>
    </rss>
    """
end

serve(port=port)