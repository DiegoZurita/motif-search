module Commom

using JuMP

export create_mps
export resolver_modelo
export exibir_model
export get_instences
export exibir_resultado
export parse_input


function parse_input(edges_file, vertices_colors_file, motify_frequency_file)
    edges_file = open(edges_file)
	vertices_colors = readcsv(vertices_colors_file)
    motify_frequency = readcsv(motify_frequency_file)
    
    number_of_colors = size(motify_frequency)[2]

    #### criar lista de adjacencia
	edges_file_lines = readlines(edges_file)
	number_of_vertices = size(edges_file_lines)[1]
	adjacency_list = Array{Array{Int64}}(number_of_vertices)

	for i = 1:number_of_vertices	
		adjacency_list[i] = [parse(Int, ss) for ss in split(edges_file_lines[i])]
	end 

    close(edges_file)
    
    return Dict(
        "number_of_colors" => number_of_colors,
		"vertices_colors" => vertices_colors, 
		"motify_frequency" => motify_frequency,
		"number_of_vertices" => number_of_vertices,
		"adjacency_list" => adjacency_list,
    )
end

function exibir_resultado(model)
	println("Objective value: ", getobjectivevalue(model))
end

function exibir_model(model)
	println("Model: ", model)
end

function create_mps(model, name)
	writeMPS(model, name)
end

function resolver_modelo(model)
	solve(model)
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

end