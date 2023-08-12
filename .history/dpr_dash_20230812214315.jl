using Dash
using DataFrames
using PlotlyJS
using CSV
import Base64.base64decode
using Dates
using Statistics
using Plots

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
    ms = ["-9999.0", "-9999", "lin", "log", "--"]
    df = CSV.File(IOBuffer(decoded);
        #delim=" ", 
        #ignorerepeated=true,
        silencewarnings=true,
        header=1, 
        normalizenames=true,
        #ignoreemptyrows=true,
        missingstring=ms, types=Float64) |> DataFrame
    dropmissing!(df, 1)
    for i in 1:3
        df[!, i] = map(x -> Int(x), df[!, i])
    end
    df.date = Date.(string.(df[!, 1], "-", df[!, 2], "-", df[!, 3]), "yyyy-mm-dd")
    df = df[:, Not(1:4)]
    
    DataFrames.metadata!(df, "filename", filename, style=:note)
    #dropmissing!(df)
    
    printstyled("generating graphs...\n",color=:green)
    # ###first figure ###########################
    begin

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
        xaxis_rangeslider_visible=true,
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
    end
    
    ##############hist aggregated#################
    #s = (filter(x->!occursin(r"year|date",x),names(df)))
    begin
        #fig_hist=plot(
            fig_hist = PlotlyJS.make_subplots(shared_xaxes=true, shared_yaxes=true)

            for i in s
                PlotlyJS.add_trace!(fig_hist, 
                histogram(df, x=:date, y=i, histfunc="avg", 
		xbins_size="M1", 
		name=string(i)
		)
		)
            end

            PlotlyJS.relayout!(fig_hist,
                template="seaborn",
                xaxis_rangeslider_visible=true,
                #template="simple_white",
                height=650*fact,
                width=1200*fact,
                title_text="monthly average",
                bargap=0.1,
                    xaxis=attr(showgrid=true, ticklabelmode="period", dtick="M1", tickformat="%b\n%Y")
                )
            
       
    end
    
    
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
        
        fig2 = PlotlyJS.plot(dfyr, kind = "bar",
		texttemplate="%{text:.2s}",
		textposition="outside"
		);
	        
        s = Symbol.(filter(x->!occursin(r"year|date",x),names(dfyr)))
        
        for i in s;
            PlotlyJS.add_trace!(fig2, 
            PlotlyJS.bar(x=dfyr.year, y=dfyr[:,i],
            name=i)       );
        end

            PlotlyJS.relayout!(fig2,
            template="seaborn",
            # template="simple_white",
            # template="plotly_dark",
            height=650*fact,
            width=1200*fact,
            title_text="yearly cumulated")

    end


    ############df_yearmean ##################
    begin    
        function yrmean(x::DataFrame)
            df = x
            df[!, :year] = year.(df[!,:date]);
            y = filter(x -> !(occursin(r"year|date", x)), names(df))
            dfm = DataFrames.combine(groupby(df, :year), y .=> mean .=> y);
            return(dfm)
        end
        
        dfm = copy(df)
        dfm = yrmean(dfm)

        fig_mean = PlotlyJS.plot(dfm, kind = "bar" ,
		texttemplate="%{text:.2s}",
		textposition="outside"
		);
		
        s = Symbol.(filter(x->!occursin(r"year|date",x),names(dfm)))
        
        for i in s;
            PlotlyJS.add_trace!(fig_mean, 
            PlotlyJS.bar(x=dfm.year, y=dfm[:,i],
            name=i)       );
        end

        PlotlyJS.relayout!(fig_mean,
            template="seaborn",
            # template="simple_white",
            # template="plotly_dark",
            height=650*fact,
            width=1200*fact,
            title_text="yearly average")

        
    end


    function subplots1(filename)
        p1 = fig
        p2 = fig2
        p3 = fig_mean
        p4 = fig_hist
        p = [p1 p4; p2 p3]
        ti = split(filename,".")|>first
        fact = 1.11
        PlotlyJS.relayout!(p,
            template="seaborn",
            # template="simple_white",
            # template="plotly_dark",
            height=650*fact,
            width=1200*fact,
            title_text=ti,
	    texttemplate="%{text:.2s}",
	    textposition="outside",
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

    # function waread(x::String)
    #     """
    #     Fastest Reader. is also dfr.
    #     Read the text file, preserve line 1 as header column
    #     """
    #     ms = ["-9999","lin","log","--"]
    #     df = CSV.read(x, DataFrame; delim="\t", header=1, missingstring=ms, normalizenames=true, types=Float64)
    #     df = dropmissing(df, 1)
    #     dt2 = map(row -> Date(Int(row[1]), Int(row[2]), Int(row[3])), eachrow(df))
    #     df.date = dt2
    #     df = select(df, Not(1:4))
    #     DataFrames.metadata!(df, "filename", x, style=:note)
    #     for x in names(df)
    #         if startswith(x,"_")
    #             newname=replace(x,"_"=>"C", count=1)
    #             rename!(df,Dict(x=>newname))
    #         end
    #     end
    #     return df 
    # end

    function kge2(simulated::Vector{Float64}, observed::Vector{Float64})
        r = cor(simulated, observed)
        α = std(simulated) / std(observed)
        β = mean(simulated) / mean(observed)
        return 1 - sqrt((r - 1)^2 + (α - 1)^2 + (β - 1)^2)
    end

    function nse(predictions::Vector{Float64}, targets::Vector{Float64})
        return (1 - (sum((predictions .- targets).^2) / sum((targets .- mean(targets)).^2)))
    end

    #function dpr(a::AbstractString,b::AbstractString)
    # function dpr(a::DataFrame,b::DataFrame)
    #     """
    #     correlation plots on dataframe
    #     """
    #     # a = waread(a)
    #     # b = waread(b)
    #     # colA = ncol(a)-1
    #     # colB = ncol(b)-1

    #     # a = a[!,Cols(colA,:date)]
    #     # b = b[!,Cols(colB,:date)]
        
    #     a = a[!,Cols(1,:date)]
    #     b = b[!,Cols(1,:date)] 

    #     df = mall(a,b)
    #     dropmissing!(df)
        
    #     df = hcat(df[!,Not(Cols(r"date"i))],df[:,Cols(r"date"i)])
    #     v = (names(df[!,1:2]))
    #     a = reshape(v, 1, 2)

    #     Plots.plot(df.date,[df[!,1], df[!,2]],  label=a, 
    #     #    seriestype = :bar,
    #         xlabel="Date", ylabel="[mm/day]",
    #         legend = :topleft)

    #     r2 = round(cor(df[!,1], df[!,2])^2, digits=2)
    #     kge = round(kge2(df[!,1], df[!,2]), digits=2)

    #     nse_value = round(nse(df[!,1], df[!,2]), digits=2)

    #     annotate!(
    #         last(df.date), 0.95*maximum(df[!,1]),
    #     text("KGE = $kge\nNSE = $nse_value\nR² = $r2", 10, :black, :right)
    #     )
    # end

    # function dpr(df::DataFrame)
    #     """
    #     correlation plots on dataframe
    #     """
    #     # a = waread(a)
    #     # b = waread(b)
    #     # colA = ncol(a)-1
    #     # colB = ncol(b)-1

    #     # a = a[!,Cols(colA,:date)]
    #     # b = b[!,Cols(colB,:date)]
        
    #     #a = df[!,Cols(1,:date)]
    #     #b = df[!,Cols(ncol(df)-1,:date)] 

        
    #     dropmissing!(df)
        
    #     df = hcat(df[!,Not(Cols(r"date"i))],df[:,Cols(r"date"i)])
    #     v = (names(df[!,1:2]))
    #     a = reshape(v, 1, 2)

    #     Plots.plot(df.date,[df[!,1], df[!,2]],  label=a, 
    #     #    seriestype = :bar,
    #         xlabel="Date", ylabel="[mm/day]",
    #         legend = :topleft)

    #     r2 = round(cor(df[!,1], df[!,2])^2, digits=2)
    #     kge = round(kge2(df[!,1], df[!,2]), digits=2)

    #     nse_value = round(nse(df[!,1], df[!,2]), digits=2)

    #     annotate!(
    #         last(df.date), 0.95*maximum(df[!,1]),
    #     text("KGE = $kge\nNSE = $nse_value\nR² = $r2", 10, :black, :right)
    #     )
    # end

    # function tpjs(x::DataFrame)
    #     """
    #     theplot optimized to PlotlyJS
    #     """
    #     ndf = x
    #     nm=names(ndf)[2]     #obscol
    #     ##subset DF by value (all positive vals..)
    #     ndf = filter(nm => x -> x > 0, ndf)
    #     rename!(ndf, [:Simulated,:Observed,:Date]) #wie in gof3.r
    #     dropmissing!(ndf)
    #     overall_pearson_r = cor(ndf[!, :Observed], ndf[!, :Simulated])
    #     r2 = overall_pearson_r^2
    #     #qpl(ndf)
    #     nse_score = nse(ndf)
    #     kge_score = kge(ndf)
    #     ti = try
    #         basename(last(collect(DataFrames.metadata(ndf)))[2])
    #     catch
    #     @warn "No basename in metadata!"
    #         raw""
    #     end 
    #     subs = "Pearson R²: $(round(r2, digits=2))<br>NSE: $(round(nse_score, digits=2))<br>KGE: $(round(kge_score, digits=2))"
    #     p = Plots.plot(
    #     ndf[!, :Date], ndf[!, :Simulated], color=:red, 
    #     label="Modeled",
    #     title=ti, ylabel="[mm/day]", xlabel="modeled time", 
    #     yscale=:log10, 
    #     legend=:outerbottomleft);
    #     plot!(p, ndf[!, :Date], ndf[!, :Observed],
    #     line=:dash, color=:blue, 
    #     label="Observed")
    #     annotate!(
    #         last(ndf.Date), mean(ndf[!,2]),
    #         text("$subs", 10, :black, :right))
    #     return p
    # end

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

    
    #return subplots1(filename)
    
    #Plots.plotlyjs()

    pd 
    
    return 

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

run_server(app, "127.0.0.1", 8050, debug = true)