using JuMP
using Cbc

m = Model(solver=CbcSolver())

motify_frequency_description_file = "data/sample1/motify_frequency_description.csv"
adjancecy_matrix_file = "data/sample1/adjacency_matrix.csv"
vertices_color_file = "data/sample1/vertices_colors.csv"

motify_frequency_description_data = round.(Int64, readcsv(motify_frequency_description_file))
number_of_colors = size(motify_frequency_description_data)[2]

adjacency_matrix_data = round.(Int64, readcsv(adjancecy_matrix_file))

vertices_color_data = round.(Int64, readcsv(vertices_color_file))
number_of_vertices = size(vertices_color_data)[2]

colors_contraints_exprexions = Array{JuMP.GenericAffExpr, 1}(number_of_colors)

for i = 1:number_of_colors
	colors_contraints_exprexions[i] = AffExpr()	
end



#Vertices
@variable(m, x[1:number_of_vertices], Bin)
#Edges
@variable(m, y[i = 1:number_of_vertices, j = i:number_of_vertices; adjacency_matrix_data[i, j] == 1], Bin)

@objective(m, Min, sum(x) - sum(y))

for i = 1:number_of_vertices
	vertice_color = vertices_color_data[i]
	colors_contraints_exprexions[vertice_color] += x[i]
end

for i = 1:number_of_colors
	@constraint(m, colors_contraints_exprexions[i] == motify_frequency_description_data[i])
end

for i = 1:number_of_vertices
	for j = i:number_of_vertices
		if adjacency_matrix_data[i, j] == 1
			@constraint(m, y[i, j] <= x[i])	
			@constraint(m, y[i, j] <= x[j])	
		end
	end
end


println(m)
status = solve(m)

println(status)
println("Objective value: ", getobjectivevalue(m))

println("Vertices")
println(getvalue(x))
println("Edges")
println(getvalue(y))