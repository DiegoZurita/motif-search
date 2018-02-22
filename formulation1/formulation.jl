using JuMP
using Cbc

m = Model(solver=CbcSolver())

motify_frequency_description_file = "data/sample1/motify_frequency_description.csv"
vertices_color_file = "data/sample1/vertices_colors.csv"
edges_file = "data/sample1/edges.csv"

motify_frequency_description_data = round.(Int64, readcsv(motify_frequency_description_file))
number_of_colors = size(motify_frequency_description_data)[2]

vertices_color_data = round.(Int64, readcsv(vertices_color_file))
number_of_vertices = size(vertices_color_data)[2]


##### Reading adjacency list file
edges_file_lines = readlines(edges_file)
adjacency_list = Array{Array{Int64}}(number_of_vertices)

for i = 1:number_of_vertices	
	adjacency_list[i] = [parse(Int, ss) for ss in split(edges_file_lines[i])]
end 


###### creating expressions to each color in problem
colors_contraints_exprexions = Array{JuMP.GenericAffExpr, 1}(number_of_colors)

for i = 1:number_of_colors
	colors_contraints_exprexions[i] = AffExpr()	
end


#Vertices
@variable(m, x[1:number_of_vertices], Bin)

#Edges
edges_pos_in_formulation = Tuple{String, JuMP.Variable}[]
edges_sum_expr = AffExpr()

for i in 1:number_of_vertices
	for j in adjacency_list[i]
		if j > i 

			key = "$(i) $(j)"

			push!(
				edges_pos_in_formulation,
				( key, @variable(m, category = :Bin, basename = key) )			
			)

			new_var = edges_pos_in_formulation[end][2]
			edges_sum_expr += new_var
		end
	end
end

egdes_pos_dict = Dict(edges_pos_in_formulation)

@objective(m, Min, sum(x) - edges_sum_expr)

for i = 1:number_of_vertices
	vertice_color = vertices_color_data[i]
	colors_contraints_exprexions[vertice_color] += x[i]
end

for i = 1:number_of_colors
	@constraint(m, colors_contraints_exprexions[i] == motify_frequency_description_data[i])
end


for edge_tuple in egdes_pos_dict
	edge = split(edge_tuple[1])

	start_vertice = parse(Int, edge[1])
	end_vertice = parse(Int, edge[2])


	@constraint(m, edge_tuple[2] <= x[start_vertice])
	@constraint(m, edge_tuple[2] <= x[end_vertice])
end


println(m)

status = solve(m)

println(status)
println("Objective value: ", getobjectivevalue(m))

println("Vertices")
println(getvalue(x))
println("Edges")
for edge_tuple in egdes_pos_dict
	val = getvalue(edge_tuple[2])

	if val != 0 
		println(edge_tuple[2], " : ", val)
	end
end