using Dash
using CSV
using DataFrames
using PlotlyJS
using Base64
using Dates
using Statistics

app = Dash.dash(
    external_stylesheets=[
        "https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css",
        "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"
    ],
    update_title="Loading..."
)
#methods(dash)
#methods(html_div)

app.layout = html_div() do
    [
    html_h2("WaSiM Timeseries Data"),    
    dcc_upload(
            id = "upload-data",
            children = [
                html_div("Drag and Drop or "),
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
        html_div(id = "output-graph")
    ]
end

function parse_contents(contents, filename)
    # Read the contents of the uploaded file
    content_type, content_string = split(contents, ',')

    decoded = base64decode(content_string)
    ms = ["-9999.0", "-9999", "lin", "log", "--"]
    df = CSV.File(IOBuffer(decoded); delim="\t", header=1, normalizenames=true,
        missingstring=ms, types=Float64) |> DataFrame
    dropmissing!(df, 1)
    for i in 1:3
        df[!, i] = map(x -> Int(x), df[!, i])
    end
    df.date = Date.(string.(df[!, 1], "-", df[!, 2], "-", df[!, 3]), "yyyy-mm-dd")
    df = df[:, Not(1:4)]
    #dropmissing!(df)
    
    #fig = PlotlyJS.make_subplots(shared_xaxes=true)
    #fig = PlotlyJS.make_subplots()
    # tcols = size(df)[2] - 1

    # for i in 1:tcols
    #     PlotlyJS.add_trace!(fig, 
    #     PlotlyJS.scatter(x=df.date, y=df[:, i], name=names(df)[i])
    #     )
    # end

    s = (filter(x->!occursin(r"year|date",x),names(df)))
    #renamer - remove char _   
    for x in s
        newname=replace(x,"_"=>" ")
        rename!(df,Dict(x=>newname))
    end
    s = Symbol.(filter(x->!occursin(r"year|date",x),names(df)))
    
    fig = PlotlyJS.make_subplots(shared_xaxes=true, shared_yaxes=true)

    for i in s
        PlotlyJS.add_trace!(fig, 
        PlotlyJS.scatter(x=df.date, y=df[:, i], name=i)
        )
    end

    ti = filename
    #fact = 1.1
    fact = .88
    PlotlyJS.relayout!(fig,
        template="seaborn",
        #template="simple_white",
        height=650*fact,
        width=1200*fact,
        title_text="",
        #xperiod = first(df.date),
        #xperiodalignment = "start",
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
                "x" => 0.11,
                #"x" => 5.11,
                "xanchor" => "left",
                #"xanchor" => "auto",
                "y" => 1.1,
                #"yanchor" => "top"
                "yanchor" => "auto"
            ),
        ]
        )

    
    ############df_yearmean ##################
    # begin    
    #     function yrmean(x::DataFrame)
    #         #df = copy(x)
    #         df = x
    #         # y = filter(x->!occursin("date",x),names(df))
    #         # s = map(y -> Symbol(y),y)
    #         df[!, :year] = year.(df[!,:date]);
    #         y = filter(x -> !(occursin(r"year|date", x)), names(df))
    #         dfm = DataFrames.combine(groupby(df, :year), y .=> mean .=> y);
    #         return(dfm)
    #     end
        
    #     # df = readdf(glob("qges")|>first)
    #     dfm = copy(df)
    #     dfm = yrmean(dfm)

    #     fig_mean = PlotlyJS.plot(dfm, kind = "bar");
    #     s = Symbol.(filter(x->!occursin(r"year|date",x),names(dfm)))
        
    #     for i in s;
    #         PlotlyJS.add_trace!(fig_mean, 
    #         PlotlyJS.bar(x=dfm.year, y=dfm[:,i],
    #         name=i)       );
    #     end
    #     #filename="qges.sd"
    #     #fact=0.4

    #     ti = split(filename,".")|>first
        
    #     PlotlyJS.relayout!(fig_mean,
    #         #template="seaborn",
    #         template="simple_white",
    #         # template="plotly_dark",
    #         height=650*fact,
    #         width=1200*fact,
    #         title_text=ti,
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
    # end
    #####################df_yearsum ##################
    begin
        function yrsum(x::DataFrame)
            df = copy(x)
            y = filter(x->!occursin("date",x),names(df))
            s = map(y -> Symbol(y),y)
            df[!, :year] = year.(df[!,:date]);
            df_yearsum = DataFrames.combine(groupby(df, :year), y .=> sum .=> y);
            return(df_yearsum)
        end


        dfyr = yrsum(df)
        
        fig2 = PlotlyJS.plot(dfyr, kind = "bar");
        
        # s = (filter(x->!occursin(r"year|date",x),names(dfyr)))
        # #renamer - remove chars   
        # for x in s
        #     newname=replace(x,"_"=>" ")
        #     #println(newname)
        #     rename!(df,Dict(x=>newname))
        # end
        s = Symbol.(filter(x->!occursin(r"year|date",x),names(dfyr)))
        
        for i in s;
            PlotlyJS.add_trace!(fig2, 
            PlotlyJS.bar(x=dfyr.year, y=dfyr[:,i],
            name=i)       );
        end
        # ti = split(filename,".")|>first
        # PlotlyJS.relayout!(fig2,
        #     template="seaborn",
        #     # template="simple_white",
        #     # template="plotly_dark",
        #     height=650*fact,
        #     width=1200*fact,
        #     title_text=ti,
        #     updatemenus=[
        #     Dict(
        #         "type" => "buttons",
        #         "direction" => "left",
        #         "buttons" => [
        #             Dict(
        #                 "args" => [Dict("yaxis.type" => "linear")],
        #                 "label" => "Linear Scale",
        #                 "method" => "relayout"
        #             ),
        #             Dict(
        #                 "args" => [Dict("yaxis.type" => "log")],
        #                 "label" => "Log Scale",
        #                 "method" => "relayout"
        #             )
        #         ],
        #         "pad" => Dict("r" => 1, "t" => 10),
        #         "showactive" => true,
        #         "x" => 0.11,
        #         #"x" => 5.11,
        #         "xanchor" => "left",
        #         #"xanchor" => "auto",
        #         "y" => 1.1,
        #         #"yanchor" => "top"
        #         "yanchor" => "auto"
        #     ),
        #     ]
        #     )
    
    end

    # function subplots1()
    #     p1 = fig
    #     p2 = fig2
    #     p = [p1 p2]
    #     p
    # end

    function subplots1(filename)
        p1 = fig
        p2 = fig2
        p = [p1 p2]
        ti = split(filename,".")|>first
        fact = 1.11
        PlotlyJS.relayout!(p,
            template="seaborn",
            # template="simple_white",
            # template="plotly_dark",
            height=650*fact,
            width=1200*fact,
            title_text=ti,
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
                "x" => 0.11,
                #"x" => 5.11,
                "xanchor" => "left",
                #"xanchor" => "auto",
                "y" => 1.1,
                #"yanchor" => "top"
                "yanchor" => "auto"
            ),
            ]
            )
        p
    end
    return subplots1(filename)

    # p = [p1 p2; p3 p4]  ##four panels

    # function subplots1()
    #     p1 = fig
    #     p2 = fig_mean
    #     p3 = fig2
    #     p = [p1 p2;p3]
    #     p
    # end
    # return subplots1()
    
    # fin = make_subplots(rows=1, cols=2)
    # # add_trace!(fig, row=1, col=1)
    # # add_trace!(fig2, row=1, col=2)
    # add_trace!(fin, trace1, row=1, col=1)
    # add_trace!(fin, trace2, row=1, col=2)
    # relayout!(fin, title_text="Subplot Example")   
    # return fin
end

callback!(
    app,
    Output("output-graph", "children"),
#    Output("yrsum-graph", "children"),
    [Input("upload-data", "contents")],
    [State("upload-data", "filename")]
) do contents, filenames
    if contents !== nothing
        graphs = []
        for (content, filename) in zip(contents, filenames)
            graph = html_div([
                #html_h4(filename),
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

run_server(app, "0.0.0.0", 8052, debug = true)
#run_server(app, debug=true)
#run_server(app, "127.0.0.1", 8050)



# using PlotlyJS
# ssup()
# # create first graph
# trace1 = scatter(;x=[1, 2, 3], y=[4, 5, 6])
# # create second graph
# trace2 = scatter(;x=[1, 2, 3], y=[6, 5, 4])
# # create subplot
# fig = make_subplots(rows=1, cols=2)
# add_trace!(fig, trace1, row=1, col=1)
# add_trace!(fig, trace2, row=1, col=2)
# relayout!(fig, title_text="Subplot Example")
# display(fig)


# using PlotlyJS
# function subplots1()
#     p1 = linescatter1()
#     p2 = linescatter2()
#     p = [p1 p2]
#     p
# end
# subplots1()