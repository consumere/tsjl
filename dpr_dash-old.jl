using Dash
using DataFrames
using PlotlyJS
import CSV: read as rd
import Base64.base64decode
using Dates
using Statistics

#using Plots

app = Dash.dash(
    external_stylesheets=[
        "https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css",
        "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"
    ],
    update_title="Loading..."
)

app.layout = html_div() do
    [
        html_h4("WaSiM Timeseries Analyzer"),    
        dcc_upload(
            id = "upload-data",
            children = [
                html_div("Drag and Drop"),
                html_a("Select Files")
            ],
            style = Dict(
                "width" => "99%",
                "height" => "60px",
                "lineHeight" => "60px",
                "borderWidth" => "1.5px",
                "borderStyle" => "dashed",
                "borderRadius" => "5px",
                "textAlign" => "center",
                "margin" => "10px"
            ),
            multiple = true
        ),
        dcc_loading(
            id = "loading",
            type = "circle",
            children = [
                html_div(id = "output-graph")
            ]
        )
    ]
end

function parse_contents(contents, filename)
    printstyled("reading $filename...\n",color=:green)
    # Read the contents of the uploaded file
    content_type, content_string = split(contents, ',')
    decoded = base64decode(content_string)

    # ms = ["-9999.0", "-9999", "lin", "log", "--"]
    # df = CSV.File(IOBuffer(decoded);
    #     #delim=" ", 
    #     #ignorerepeated=true,
    #     silencewarnings=true,
    #     header=1, 
    #     normalizenames=true,
    #     #ignoreemptyrows=true,
    #     missingstring=ms, types=Float64) |> DataFrame
    # dropmissing!(df, 1)
    # for i in 1:3
    #     df[!, i] = map(x -> Int(x), df[!, i])
    # end
    # df.date = Date.(string.(df[!, 1], "-", df[!, 2], "-", df[!, 3]), "yyyy-mm-dd")
    # df = df[:, Not(1:4)]
    
    # DataFrames.metadata!(df, "filename", filename, style=:note)
    # #dropmissing!(df)
    
    printstyled("generating graph...\n",color=:green)

    function waread(x::Any)
        """
        Read the text file, preserve line 1 as header column
        import CSV: read as rd !!!
        """
        ms = ["-9999","lin","log","--"]
        df = rd(x, DataFrame; delim="\t", header=1, missingstring=ms, normalizenames=true, types=Float64)
        df = dropmissing(df, 1)
        dt2 = map(row -> Date(Int(row[1]), Int(row[2]), Int(row[3])), eachrow(df))
        df.date = dt2
        df = select(df, Not(1:4))
        for x in names(df)
            if startswith(x,"_")
                newname=replace(x,"_"=>"C", count=1)
                rename!(df,Dict(x=>newname))
            end
        end
        return df 
    end

    df = waread(IOBuffer(decoded);)
    DataFrames.metadata!(df, "filename", filename, style=:note)
    #dropmissing!(df)
    
    printstyled("generating graphs...\n",color=:green)

    function kge2(simulated::Vector{Float64}, observed::Vector{Float64})
        r = cor(simulated, observed)
        α = std(simulated) / std(observed)
        β = mean(simulated) / mean(observed)
        return 1 - sqrt((r - 1)^2 + (α - 1)^2 + (β - 1)^2)
    end

    function nse(predictions::Vector{Float64}, targets::Vector{Float64})
        return (1 - (sum((predictions .- targets).^2) / sum((targets .- mean(targets)).^2)))
    end


    function nse(df::DataFrame)
        simulated, observed = vec(Matrix(df[!,Cols(1)])),vec(Matrix(df[!,Cols(2)]))
        return (1 - (sum((simulated .- observed).^2) / sum((observed .- mean(observed)).^2)))
    end

    function kge(df::DataFrame)
        simulated, observed = vec(Matrix(df[!,Cols(1)])),vec(Matrix(df[!,Cols(2)]))
        r = cor(observed, simulated)
        α = std(simulated) / std(observed)
        β = mean(simulated) / mean(observed)
        return 1 - sqrt((r - 1)^2 + (α - 1)^2 + (β - 1)^2)
    end 

    function dfpjs(df::DataFrame;)
        
        ti = try
            DataFrames.metadata(df)|>only|>last|>basename
        catch
            @warn "No basename in metadata!"
            ti = raw""
        end

        s = (filter(x->!occursin(r"year|date",x),names(df)))
        #renamer - remove char _   
        for x in s
            newname=replace(x,"_"=>" ")
            rename!(df,Dict(x=>newname))
        end
        s = Symbol.(filter(x->!occursin(r"year|date",x),names(df)))

        ##make scores
        overall_pearson_r = cor(df[!,2], df[!,1])
        r2 = overall_pearson_r^2
        nse_score = nse(df)
        kge_score = kge(df)

        subs = "Pearson R²: $(round(r2, digits=2))<br>NSE: $(round(nse_score, digits=2))<br>KGE: $(round(kge_score, digits=2))"

        fig = PlotlyJS.make_subplots(shared_xaxes=true, shared_yaxes=true)

        for i in s
            PlotlyJS.add_trace!(fig, 
            PlotlyJS.scatter(x=df.date, y=df[:, i], name=i)
            )
        end

        fact = 1.1
        PlotlyJS.relayout!(fig,
            template="seaborn",
            #template="simple_white",
            height=650*fact,
            width=1200*fact,
            title_text=ti,
            xaxis_rangeslider_visible=true,
            xaxis=PlotlyJS.attr(    rangeslider_visible=true,rangeselector=PlotlyJS.attr(
                buttons=[
                    PlotlyJS.attr(count=1, label="1m", step="month", stepmode="backward"),
                    PlotlyJS.attr(count=6, label="6m", step="month", stepmode="backward"),
                    PlotlyJS.attr(count=1, label="YTD", step="year", stepmode="todate"),
                    PlotlyJS.attr(count=1, label="1y", step="year", stepmode="backward"),
                    PlotlyJS.attr(step="all")
                ]    )),
            annotations=[attr(
                        text=subs,
                        x=maximum(df.date),
                        y=maximum(df[!,2]),
                        xanchor="right",
                        yanchor="bottom",
                        xref="x",
                        yref="y",
                        showarrow=false,
                        bordercolor="#c7c7c7",
                        borderwidth=2,
                        borderpad=4,
                        bgcolor="#ff7f0e",
                        opacity=0.6,
                        font = attr(
            size = 16  # Increase the font size here
        )
                    )],
            updatemenus=[
                Dict(
                    "type" => "buttons",
                    "direction" => "left",
                    "buttons" => [
                        Dict(
                            "args" => [Dict("yaxis.type" => "linear")],
                            "label" => "Linear Scale",
                            "method" => "relayout"
                        ),
                        Dict(
                            "args" => [Dict("yaxis.type" => "log")],
                            "label" => "Log Scale",
                            "method" => "relayout"
                        )
                    ],
                    "pad" => Dict("r" => 1, "t" => 10),
                    "showactive" => true,
                    "x" => .20,
                    "xanchor" => "left",
                    "y" => 1.09,
                    "yanchor" => "auto"
                ),
            ]
            )

            return fig

    end
    

    # function subplots1(filename)
    #     p1 = fig
    #     p2 = fig2
    #     p3 = fig_mean
    #     p4 = fig_hist
    #     p = [p1 p4; p2 p3]
    #     ti = split(filename,".")|>first
    #     fact = 1.11
    #     PlotlyJS.relayout!(p,
    #         template="seaborn",
    #         # template="simple_white",
    #         # template="plotly_dark",
    #         height=650*fact,
    #         width=1200*fact,
    #         title_text=ti,
	#     texttemplate="%{text:.2s}",
	#     textposition="outside",
    #         updatemenus=[
    #         Dict(
    #             "type" => "buttons",
    #             "direction" => "left",
    #             "buttons" => [
    #                 Dict(
    #                     "args" => [Dict("yaxis.type" => "linear")],
    #                     "label" => "Linear Scale",
    #                     "method" => "relayout"
    #                 ),
    #                 Dict(
    #                     "args" => [Dict("yaxis.type" => "log")],
    #                     "label" => "Log Scale",
    #                     "method" => "relayout"
    #                 )
    #             ],
    #             "pad" => Dict("r" => 1, "t" => 10),
    #             "showactive" => true,
    #             "x" => 0.11,
    #             #"x" => 5.11,
    #             "xanchor" => "left",
    #             #"xanchor" => "auto",
    #             "y" => 1.1,
    #             #"yanchor" => "top"
    #             "yanchor" => "auto"
    #         ),
    #         ]
    #         )
    #     p
    # end

    pd = dfpjs(df)

    # Combine the subplots vertically
    #combined_plot = vcat([pd, subplots1(filename)]...)
    #combined_plot = hcat([subplots1(filename), pd ]...)

    #combined_plot = [pd subplots1(filename)]
    
    return pd


end

callback!(
    app,
    Output("output-graph", "children"),
    [Input("upload-data", "contents")],
    [State("upload-data", "filename")]
) do contents, filenames
    if contents !== nothing
        graphs = []
        for (content, filename) in zip(contents, filenames)
            graph = html_div([
                dcc_graph(
                    id = filename,
                    figure = parse_contents(content, filename) #, filename
                )
            ])
            push!(graphs, graph)
        end
        return graphs
    end
end

#run_server(app, "127.0.0.1", 8050, debug = true)
run_server(app, debug = true)