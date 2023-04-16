function print_sorted_sizes(rootdir::String)
    sizes = Dict{String,Int}()
    for entry in readdir(rootdir)
        if entry != "." && entry != ".." # skip current and parent directory links
            fullpath = joinpath(rootdir, entry)
            if isfile(fullpath)
                sizes[fullpath] = stat(fullpath).size
            elseif isdir(fullpath)
                for (subdir, _, filenames) in walkdir(fullpath)
                    for filename in filenames
                        fullpath = joinpath(subdir, filename)
                        sizes[fullpath] = stat(fullpath).size
                    end
                end
            end
        end
    end
    sorted_sizes = sort(collect(sizes), by=x->x[2], rev=true)
    for (name, size) in sorted_sizes
#        println(rpad(name, 60, ' '), rpad(size ÷ 10^6, 10, ' '), "MB")
        printstyled(rpad(name, 60, ' '), rpad(size ÷ 10^6, 10, ' '), "MB\n",color=:green)
    end
end

#        printstyled("$(f):\t $(sizes[f] / 1_000_000) MB\n",color=:green)

print_sorted_sizes(".")
