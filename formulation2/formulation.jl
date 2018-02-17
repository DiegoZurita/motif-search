using JuMP
using Cbc

##########################METHODS########################################

function _enraizar(edges, v, cur, p) 

	if v[cur] != 0
		return
	end

	v[cur] = p

	for i in edges[cur]
		_enraizar(edges, v, i, cur)
	end
end


function _getVericeColor(u, vertices_colors) 
	return round.(Int64, vertices_colors[u])
end


function _constructR(tree, u, motify_frequency, vertices_colors)

	number_of_colors = size(motify_frequency)[2]
	cur_colors = zeros(Int64, number_of_colors)

	r = Array{Int64}	
	r = [ ]

	p = u

	while p != -1

		cur_colors[_getVericeColor(p, vertices_colors)] += 1

		if motify_frequency[_getVericeColor(p, vertices_colors)] - cur_colors[_getVericeColor(p, vertices_colors)] < 0
			break
		end

		push!(r, p)

		p = tree[p]
	end

	return r
end

########################################################################

edges_file = open("data/sample1/edges.csv")
vertices_colors_file = "data/sample1/vertices_colors.csv"
motify_frequency_file = "data/sample1/motify_frequency_description.csv"

vertices_colors = readcsv(vertices_colors_file)

motify_frequency = readcsv(motify_frequency_file)
number_of_colors = size(motify_frequency)[2]


vertices_by_color = [Int64[] for i = 1:number_of_colors]

for i = 1:size(vertices_colors)[2]
	push!(vertices_by_color[_getVericeColor(i, vertices_colors)], i)
end 


edges_file_lines = readlines(edges_file)
number_of_vertices = size(edges_file_lines)[1]
adjacency_list = Array{Array{Int64}}(number_of_vertices)

for i = 1:number_of_vertices	
	adjacency_list[i] = [parse(Int, ss) for ss in split(edges_file_lines[i])]
end 

close(edges_file)

tree = zeros(Int64, number_of_vertices)
_enraizar(adjacency_list, tree, 4, -1)


R = Array{Array{Int64}}(number_of_vertices)

for i in 1:number_of_vertices
	R[i] = _constructR(tree, i, motify_frequency, vertices_colors)
end


################################Formulation############################

edges_represented_by = [Tuple{Int64, Int64}[] for i = 1:number_of_vertices]
vertices_represented_by = [[] for i = 1: number_of_vertices]


m = Model(solver=CbcSolver())
@variable(m, x[1:number_of_vertices, 1:number_of_vertices], Bin)

@objective(m, Min, sum(x))

# Popular vertices_represented_by

for vertice = 1:number_of_vertices
	for representante in R[vertice]
		push!(vertices_represented_by[representante], vertice)
	end
end


for i = 1:number_of_vertices

	#Cada vertice tem no maximo um representante
	r = AffExpr()

	for j in R[i]
		r += x[i, j]
	end

	@constraint(m, r <= 1)

end




for i = 1:number_of_colors

	#color restrcition
	c = AffExpr()

	for vertice in vertices_by_color[i]
		for representante in R[vertice]
			#println("vertice ", vertice , " representadi por ", representante)
			c += x[vertice, representante]
		end
	end

	@constraint(m, c == motify_frequency[i])
end

#RENAME
egdes_pos_in_formulation = Tuple{String, JuMP.Variable}[]


for i = 1:number_of_vertices
	#para cada aresta
	for j in adjacency_list[i]
		if j > i 
			R_i_j = intersect(R[i], R[j])

			#para cada vertice na interseccao de R(i) e R(j)
			for representante in R_i_j

				key = "$(i)-$(j)-$(representante)"

				push!(
					egdes_pos_in_formulation, 
					( key, @variable(m, category = :Bin, basename = key) )
				)

				new_var = egdes_pos_in_formulation[end][2]

				@constraint(m, new_var <= x[i, representante])
				@constraint(m, new_var <= x[j, representante])

				push!(edges_represented_by[representante], (i, j))

			end
		end
	end
end

egdes_pos_dict = Dict(egdes_pos_in_formulation)


for representante in 1:number_of_vertices

	verticesExpr = AffExpr()
	edgesExpr = AffExpr()

	for u in vertices_represented_by[representante]
		verticesExpr += x[u, representante]
	end

	for v in edges_represented_by[representante]
		edgesExpr += egdes_pos_dict["$(v[1])-$(v[2])-$(representante)"]
	end

	@constraint(m, verticesExpr - edgesExpr <= 1)

end


####### Last constraint
for u = 1:number_of_vertices
	for v in R[u]
		@constraint(m, x[u, v] <= x[v, v])
	end
end



println("Model: ", m)
solve(m)

println("Objective value: ", getobjectivevalue(m))
println("x: ", getvalue(x))

for r in egdes_pos_dict
	println(r[1], " : ", getvalue(r[2]))
end
