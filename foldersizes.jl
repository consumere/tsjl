function print_sorted_sizes(dir)
    folders = [joinpath(dir, f) for f in readdir(dir)]
    sizes = Dict()
    for f in folders
        if isdir(f)
            sizes[f] = get_folder_size(f)
        end
    end
    sorted_folders = sort(collect(keys(sizes)), by=x->sizes[x], rev=true)
    for f in sorted_folders
        printstyled(rpad(f,60, ' '), rpad(sizes[f] ÷ 10^6, 6, ' '), "MB\n",color=:green)
# 	println("$(f): $(sizes[f] / 1_000_000) MB")
    end
end

function get_folder_size(folder)
    files = readdir(folder)
    size = 0
    for file in files
        path = joinpath(folder, file)
        if isfile(path)
            size += stat(path).size
        elseif isdir(path)
            size += get_folder_size(path)
        end
    end
    return size
end


print_sorted_sizes(pwd())
