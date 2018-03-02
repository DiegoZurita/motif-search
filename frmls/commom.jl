module Commom

using JuMP
import YAML

export create_mps
export resolver_modelo
export exibir_model
export get_instences
export exibir_resultado
export parse_input
export obter_resultado


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

function obter_resultado(model)
	return getobjectivevalue(model)
end

function create_mps(model, name)
	writeMPS(model, name)
end

function resolver_modelo(model)
	solve(model)
end

function get_instences(ROOT_FOLDER,parametros_path)

	listas_parametros = readlines("$(ROOT_FOLDER)/$(parametros_path)")


	files_dict = []


	for listas_parametro in listas_parametros

		parametros = split(listas_parametro)

		lista_de_adajacencia = replace(parametros[1], "ROOT", ROOT_FOLDER)
		cores_do_vertice = replace(parametros[2], "ROOT", ROOT_FOLDER)
		motify = replace(parametros[3], "ROOT", ROOT_FOLDER)
		output = parametros[4]


		push!(
			files_dict,
			Dict(
				"edges" => lista_de_adajacencia,
				"motify" => motify,
				"vertices_colors" => cores_do_vertice,
				"edges_file_name" => lista_de_adajacencia,
				"motify_file_name" => motify,
				"output" => output,
			)
		)
	end

	return files_dict
end

end