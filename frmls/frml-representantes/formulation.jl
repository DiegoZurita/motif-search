include("../commom.jl")
using Commom

using JuMP
using Cbc


function _enraizar(adj_list, parents, cur, p) 
	SEM_PAI = 0
	
	if parents[cur] != SEM_PAI
		return
	end

	parents[cur] = p

	for i in adj_list[cur]
		_enraizar(adj_list, parents, i, cur)
	end
end

function _getVericeColor(u, vertices_colors) 
	return round.(Int64, vertices_colors[u])
end

function _constructR(parents, u, motify_frequency, vertices_colors)

	number_of_colors = size(motify_frequency)[2]
	cur_colors = zeros(Int64, number_of_colors)

	r = Array{Int64}	
	r = [ ]

	p = u

	while p != -1

		cur_colors[_getVericeColor(p, vertices_colors)] += 1

		if cur_colors[_getVericeColor(p, vertices_colors)] > motify_frequency[_getVericeColor(p, vertices_colors)] 
			break
		end

		push!(r, p)

		p = parents[p]
	end

	return r
end

function ehRaiz(vertice, parents)
	return parents[vertice] == -1
end

function readInput(edges_file, vertices_colors_file, motify_frequency_file)

	input_data = Commom.parse_input(edges_file, vertices_colors_file, motify_frequency_file)

	##### Criar estrtura que agrupa vertices por cor
	vertices_by_color = [Int64[] for i = 1:input_data["number_of_colors"]]

	for i = 1:size(input_data["vertices_colors"])[2]
		push!(vertices_by_color[_getVericeColor(i, input_data["vertices_colors"])], i)
	end 

	##### Enraizar arvore
	parents = zeros(Int64, input_data["number_of_vertices"])
	_enraizar(input_data["adjacency_list"], parents, 2, -1)


	#### Construir R
	R = Array{Array{Int64}}(input_data["number_of_vertices"])

	for i in 1:input_data["number_of_vertices"]
		R[i] = _constructR(parents, i, input_data["motify_frequency"], input_data["vertices_colors"])
	end

	return Dict(
		"vertices_colors" => input_data["vertices_colors"],
		"motify_frequency" => input_data["motify_frequency"],
		"number_of_colors" => input_data["number_of_colors"],
		"number_of_vertices" => input_data["number_of_vertices"],
		"adjacency_list" => input_data["adjacency_list"],
		"vertices_by_color" => vertices_by_color,
		"parents" => parents,
		"R" => R
	)
end

function create_model(data, relex)

	vertices_colors = data["vertices_colors"]
	motify_frequency = data["motify_frequency"]
	number_of_colors = data["number_of_colors"]
	vertices_by_color = data["vertices_by_color"]
	number_of_vertices = data["number_of_vertices"]
	adjacency_list = data["adjacency_list"]
	R = data["R"]


	edges_represented_by = [Tuple{Int64, Int64}[] for i = 1:number_of_vertices]
	vertices_represented_by = [[] for i = 1: number_of_vertices]


	m = Model(solver=CbcSolver())

	vertices_pos_in_formulation = Tuple{String, JuMP.Variable}[]

	number_of_vertices_vars = 0

	for u in 1:number_of_vertices
		for v in R[u]
			key = "$(u)-$(v)"
			if relex
				push!(
					vertices_pos_in_formulation, 
					( key, @variable(m, basename = key, lowerbound = 0, upperbound = 1) )
				)
			else
				push!(
					vertices_pos_in_formulation, 
					( key, @variable(m, category = :Bin, basename = key) )
				)
			end

			new_var = vertices_pos_in_formulation[end][2]

			number_of_vertices_vars = number_of_vertices_vars + 1

			setname(new_var, key)
		end
	end

	vertices_pos_dict = Dict(vertices_pos_in_formulation)


	objectiveExpr = AffExpr()

	for i in 1:number_of_vertices
		if haskey(vertices_pos_dict, "$(i)-$(i)")
			objectiveExpr += vertices_pos_dict["$(i)-$(i)"]
		end
	end

	@objective(m, Min, objectiveExpr)

	# Popular vertices_represented_by
	for vertice = 1:number_of_vertices
		for representante in R[vertice]
			push!(vertices_represented_by[representante], vertice)
		end
	end


	### Restricao 1 
	for i = 1:number_of_vertices

		#Cada vertice tem no maximo um representante
		r = AffExpr()

		for j in R[i]
			r += vertices_pos_dict["$(i)-$(j)"]
		end

		@constraint(m, r <= 1)

	end

	### Restricao 2
	for u = 1:number_of_vertices
		for v in R[u]
			@constraint(m, vertices_pos_dict["$(u)-$(v)"] <= vertices_pos_dict["$(v)-$(v)"])
		end
	end



	### Restricao 3

	vertice_var_que_tem_cor_no_motify = 0

	for i = 1:number_of_colors

		#color restrcition
		c = AffExpr()

		for vertice in vertices_by_color[i]
			for representante in R[vertice]
				#println("vertice ", vertice , " representadi por ", representante)

				
				if motify_frequency[i] == 1
					vertice_var_que_tem_cor_no_motify = vertice_var_que_tem_cor_no_motify + 1
				end


				c += vertices_pos_dict["$(vertice)-$(representante)"]
			end
		end

		@constraint(m, c == motify_frequency[i])
	end



	### Restricao 4
	egdes_pos_in_formulation = Tuple{String, JuMP.Variable}[]

	number_of_edges_vars = 0

	for i = 1:number_of_vertices
		#para cada aresta
		for j in adjacency_list[i]
			if j > i 
				R_i_j = intersect(R[i], R[j])

				#para cada vertice na interseccao de R(i) e R(j)
				for representante in R_i_j

					key = "$(i)-$(j)-$(representante)"

					if relex
						push!(
							egdes_pos_in_formulation, 
							( key, @variable(m, basename = key, lowerbound = 0, upperbound = 1) )
						)
					else
						push!(
							egdes_pos_in_formulation, 
							( key, @variable(m, category = :Bin, basename = key) )
						)
					end

					new_var = egdes_pos_in_formulation[end][2]

					setname(new_var, key)	

					@constraint(m, new_var <= vertices_pos_dict["$(i)-$(representante)"])
					@constraint(m, new_var <= vertices_pos_dict["$(j)-$(representante)"])

					push!(edges_represented_by[representante], (i, j))

					number_of_edges_vars = number_of_edges_vars + 1
				end
			end
		end
	end

	egdes_pos_dict = Dict(egdes_pos_in_formulation)

	### Restricao 4
	for representante in 1:number_of_vertices

		expr = AffExpr()

		for u in vertices_represented_by[representante]
			expr += vertices_pos_dict["$(u)-$(representante)"]
		end

		for v in edges_represented_by[representante]
			expr -= egdes_pos_dict["$(v[1])-$(v[2])-$(representante)"]
		end

		@constraint(m, expr <= 1)

	end

	return Dict(
		"model" => m,
		"edges_vars" => egdes_pos_dict,
		"vertices_vars" => vertices_pos_dict,
		"number_of_edges_vars" => number_of_edges_vars,
		"number_of_vertices_vars" => number_of_vertices_vars,
		"vertice_var_que_tem_cor_no_motify" => vertice_var_que_tem_cor_no_motify
	)
end

function export_mps(files, ehRelaxado)
	read_data_result = readInput(files["edges"], files["vertices_colors"], files["motify"])
	println("Criando modelo ..")
	model_data = create_model(read_data_result, ehRelaxado)

	m = model_data["model"]

	println("Criando mps ..")

	if ehRelaxado
		Commom.create_mps(
			m, 
			"../../mps/frml-representantes-relaxada-$(files["output"]).mps"
		)
	else
		Commom.create_mps(
			m, 
			"../../mps/frml-representantes-inteiro-$(files["output"]).mps"
		)
	end

	#Commom.resolver_modelo(m)	
	#Commom.exibir_resultado(m)
end 

function main()



	all_files = Commom.get_instences(ARGS[1])

	println("Formulação representantes")

	for files in all_files	
		println("motify: ", files["motify_file_name"])
		println("edges: ", files["edges_file_name"])

		println("Para o modelo inteiro")
		export_mps(files, false)

		println("Para o modelo relaxado")
		export_mps(files, true)

		println()
	end
end


main()