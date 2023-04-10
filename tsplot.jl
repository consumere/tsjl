#plotly time Series
if length(ARGS) <= 0
	println("need args! <timeseries file>...")
    exit()
end

#julia --threads auto -q tsplot.jl $x
#/mnt/c/Users/Public/Documents/Python_Scripts/julia/tsplot.jl
file=ARGS[1];

if endswith(file,".nc")
	println("need <timeseries file>...")
    exit()
end

pt = split(file)[1]
m = match(r".*[.]",basename(file))
#outfile = string(m.match,"png")
###YES
#outfile = contains(basename(file),".") ? string(m.match,"png") : basename(file)*".png"
outfile = contains(basename(file),".") ? string(m.match,"html") : basename(file)*".html"
println("loading...\n",pt,"\nand save it to ",outfile,"...\n")

#using Query, DataFrames, CSV, Dates, PlotlyJS
using PlotlyJS, DataFrames, CSV, Dates

#path="/mnt/d/Wasim/regio/out/v8/vaporcm.v8.2000"
# df = CSV.read(path,DataFrame,missingstring=ms,delim="\t",ignorerepeated=true,silencewarnings=true,typemap=Dict(String=>Int64))
# df = df[completecases(df), :]
# xd=parse.(Int64,df[:,1:3])
# parse.(Date,xd,"yyyy-mm-dd")
#Date(xd)


function pline(path::AbstractString)
    ms=["-999","-9999","lin","log","LIN","LOG"]
    df = CSV.read(path,DataFrame,
    #missingstring="-9999", #also windows
    missingstring=ms,
    delim="\t",comment="-",
    silencewarnings=false,
    ntasks=4,downcast=true, # got unsupported keyword arguments "ntasks", "downcast" @windows                                          
    normalizenames=true,drop=(i, nm) -> i == 4) |> dropmissing
    df.date = Date.(string.(df.YY,"-",df.MM,"-",df.DD),"yyyy-mm-dd");
    df=df[:,Not(1:3)]
    # ms=["-9999","lin","log","LIN","LOG","--"] #comment="-",
    # #df = CSV.read(path,DataFrame,missingstring=ms,delim="\t",comment="-",ignorerepeated=true,silencewarnings=true,typemap=Dict(Int64=>String))  |> @dropna() |> DataFrame
    # df = CSV.read(path,DataFrame,missingstring=ms,delim="\t",ignorerepeated=true,silencewarnings=true,typemap=Dict(String=>Int64))
    # df = df[completecases(df), :]
    # #df = filter( [2]=> x -> !any(f -> f(x), (ismissing)), df)
    # #df = filter( [5]=> x -> isnumeric, df)
    # #parse.(Date, df[:,1:4])
    # #parse.(Date, string.(df.YY,"-",df.MM,"-",df.DD,"-",df.HH),"yyyy-mm-dd-HH")
    # df.date = Date.(string.(df.YY,"-",df.MM,"-",df.DD,"-",df.HH),"yyyy-mm-dd-HH");
    # df=df[:,Not(1:4)]
    nrows=size(df)[2]-1
    st=[]
    for i in 1:size(df)[2]-1; push!(st,string(propertynames(df)[i]));end
    p = make_subplots(rows=nrows, cols=1, 
    shared_xaxes=true, 
    shared_yaxes=false,
    vertical_spacing=0.05,
    #subplot_titles= st;
    )
    for i in 1:nrows;
            add_trace!(p, 
            scatter(x=df.date, y=df[:,i],
            name=st[i]),   row=i,     col=1);
    end
    #relayout!(p,height=600*2,width=900*2,title_text="Series of "*basename(path))
    relayout!(p,height=600*1.5,width=900*1.5,title_text="Series of "*basename(path))
    p
end
# using DataFrames, CSV, Dates, PlotlyJS
# function pline(path::AbstractString)
#     #skip = 1
#     #skip = isempty(skip) ? Int(1) : skip
#     dd = CSV.read(path, DataFrame, #header=skip, 
#     missingstring=["-999","-9999", "--"],comment="-",delim="\t")
#     df = filter( [2]=> x -> !any(f -> f(x), (ismissing, isnothing, isnan)), dd)
#     df.date = Date.(string.(df.YY,"-",df.MM,"-",df.DD,"-",df.HH),"yyyy-mm-dd-HH");
#     df=df[:,Not(1:4)]
#     nrows=size(df)[2]-1
#     st=[]
#     for i in 1:size(df)[2]-1; push!(st,string(propertynames(df)[i]));end
#     p = make_subplots(rows=nrows, cols=1, 
#     shared_xaxes=true, 
#     shared_yaxes=false,
#     vertical_spacing=0.05,
#     #subplot_titles= st;
#     )
#     for i in 1:nrows;
#             add_trace!(p, 
#             scatter(x=df.date, y=df[:,i],
#             name=st[i]),   row=i,     col=1);
#     end
#     relayout!(p,height=600*2,width=900*2,title_text="Series of "*basename(path))
#     p
# end

out = pline(file)
println("saving plotly plot to",outfile,"...")
savefig(out,outfile)
println("done! ...")

