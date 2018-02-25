using JuMP
using Cbc




function read_input(motify_frequency_description_file, vertices_color_file, edges_file)

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


	return Dict(
		"motify_frequency_description_data" => motify_frequency_description_data,
		"number_of_colors" => number_of_colors,
		"vertices_color_data" => vertices_color_data,
		"number_of_vertices" => number_of_vertices,
		"adjacency_list" => adjacency_list
	)

end

function create_model(input_data, relex)
	m = Model(solver=CbcSolver())

	number_of_colors = input_data["number_of_colors"]
	adjacency_list = input_data["adjacency_list"]
	vertices_color_data = input_data["vertices_color_data"]
	motify_frequency_description_data = input_data["motify_frequency_description_data"]
	number_of_vertices = input_data["number_of_vertices"]


	###### creating expressions to each color in problem
	colors_contraints_exprexions = Array{JuMP.GenericAffExpr, 1}(number_of_colors)

	for i = 1:number_of_colors
		colors_contraints_exprexions[i] = AffExpr()	
	end


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


	return Dict(
		"model" => m,
		"vertices_vars"=> x,
		"edges_vars"=> egdes_pos_dict
	)
end


function exibir_modelo(model)
	println(model)
end

function criar_mps(model, file_name)
	writeMPS(model, file_name)
end


function resolver_modelo(model)
	solve(model)
end


function exibir_resultado(model_data)
	model = model_data["model"]

	#exibir_modelo(model)
	println("Objective value: ", getobjectivevalue(model))

	vertices_vars = model_data["vertices_vars"]

	edges_counter = 0

	vertices_counter = 0

	for edge_tuple in model_data["edges_vars"]
		edge = split(edge_tuple[1])

		start_vertice = parse(Int, edge[1])
		end_vertice = parse(Int, edge[2])

		#Aresta selecionada
		if getvalue(edge_tuple[2]) == 1
			edges_counter = edges_counter + 1
		end
	end

	for vertices_var in vertices_vars
		if getvalue(vertices_var) == 1 
			vertices_counter = vertices_counter + 1
		end
	end
end


function get_instences(instancias_folder)
	instancia_dirs = readdir(instancias_folder)

	files_dict = []

	for instancia_dir in instancia_dirs

		edges_folder_path = "$(instancias_folder)/$(instancia_dir)/edges"
		motify_folder_path = "$(instancias_folder)/$(instancia_dir)/motify"

		motifys_files_path = readdir(motify_folder_path)

		for edge_file_path in readdir(edges_folder_path)

			for motify_file_path in motifys_files_path

				push!(
					files_dict,
					Dict(
						"edges" => "$(edges_folder_path)/$(edge_file_path)",
						"motify" => "$(motify_folder_path)/$(motify_file_path)",
						"vertices_colors" => "$(instancias_folder)/$(instancia_dir)/vertices_colors.csv",
						"edges_file_name" => edge_file_path,
						"motify_file_name" => motify_file_path
					)
				)
			end
		end
	end	

	return files_dict
end


function export_mps(files, ehRelaxado)

	input_data = read_input(files["motify"], files["vertices_colors"], files["edges"])

	model_data = create_model(input_data, ehRelaxado)

	model = model_data["model"]

	resolver_modelo(model)

	if ehRelaxado
		criar_mps(model, "../../mps/frml_normal-relaxado-$(files["motify_file_name"])-$(files["edges_file_name"]).mps")
	else
		criar_mps(model, "../../mps/frml_normal-inteira-$(files["motify_file_name"])-$(files["edges_file_name"]).mps")
	end

	exibir_resultado(model_data)

end


function main()


	instences = get_instences("../../instancias")

	files = instences[1]

	for files in instences

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