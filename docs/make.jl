push!(LOAD_PATH,"../src/")
using Documenter, Reese_Jones_with_functions

makedocs(modules = [Reese_Jones_with_functions], sitename = "Reese_Jones_with_functions.jl")

deploydocs(repo = "github.com/stivella/Reese_Jones_with_functions.jl.git", devbranch = "main")
