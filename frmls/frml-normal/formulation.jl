include("../commom.jl")
using Commom

using JuMP
using Cbc

function create_model(input_data, relex)
	m = Model(solver=CbcSolver())

	number_of_colors = input_data["number_of_colors"]
	adjacency_list = input_data["adjacency_list"]
	vertices_color_data = input_data["vertices_colors"]
	motify_frequency_description_data = input_data["motify_frequency"]
	number_of_vertices = input_data["number_of_vertices"]


	###### creating expressions to each color in problem
	colors_contraints_exprexions = Array{JuMP.GenericAffExpr, 1}(number_of_colors)

	for i = 1:number_of_colors
		colors_contraints_exprexions[i] = AffExpr()	
	end


	is_vertice_in_problem = Array{Bool}(number_of_vertices)


	#Vertices
	if relex
		@variable(m, 0 <= x[1:number_of_vertices] <= 1)
	else
		@variable(m, x[1:number_of_vertices], Bin)
	end



	#Edges
	edges_pos_in_formulation = Tuple{String, JuMP.Variable}[]
	edges_sum_expr = AffExpr()

	for i in 1:number_of_vertices
		for j in adjacency_list[i]
			if j > i 
				key = "$(i) $(j)"

				if relex
					push!(
						edges_pos_in_formulation,
						( key, @variable(m, basename = key, lowerbound = 0, upperbound = 1) )
					)
				else
					push!(
						edges_pos_in_formulation,
						( key, @variable(m, category = :Bin, basename = key) )			
					)
				end

				new_var = edges_pos_in_formulation[end][2]
				edges_sum_expr += new_var
			end
		end
	end

	egdes_pos_dict = Dict(edges_pos_in_formulation)

	@objective(m, Min, sum(x) - edges_sum_expr)


	for i = 1:number_of_vertices
		vertice_color = round.(Int64, vertices_color_data[i])

		colors_contraints_exprexions[vertice_color] += x[i]
	end


	for i = 1:number_of_colors
		@constraint(m, colors_contraints_exprexions[i] == motify_frequency_description_data[i])
	end


	number_of_edges = 0
	for edge_tuple in egdes_pos_dict
		edge = split(edge_tuple[1])

		start_vertice = parse(Int, edge[1])
		end_vertice = parse(Int, edge[2])


		@constraint(m, edge_tuple[2] <= x[start_vertice])
		@constraint(m, edge_tuple[2] <= x[end_vertice])
		number_of_edges = number_of_edges + 1
	end


	return Dict(
		"model" => m,
		"vertices_vars"=> x,
		"edges_vars"=> egdes_pos_dict,
		"number_of_edges" => number_of_edges
	)
end

function export_mps(files, ehRelaxado)

	input_data = Commom.parse_input(files["edges"], files["vertices_colors"], files["motify"])
	println("Criando modelo ..")
	model_data = create_model(input_data, ehRelaxado)

	model = model_data["model"]	

	println("Criando mps ..")

	if ehRelaxado
		Commom.create_mps(
			model, 
			"../../mps/frml-normal-relaxada-$(files["output"]).mps"
		)
	else
		Commom.create_mps(
			model, 
			"../../mps/frml-normal-inteiro-$(files["output"]).mps"
		)
	end

	#Commom.resolver_modelo(model)
	#Commom.exibir_resultado(model)

end

function main()


	all_files = Commom.get_instences(ARGS[1])

	println("Formulação normal")


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