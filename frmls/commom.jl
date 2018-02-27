module Commom

using JuMP
import YAML

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

function get_instences(yml_path)

	data = YAML.load(open(yml_path))

	return Dict(
		"edges" => data["arvore"],
		"motify" => data["motify"],
		"vertices_colors" => data["cores_dos_vertices"],
		"edges_file_name" => data["arvore"],
		"motify_file_name" => data["motify"],
		"output" => data["output"],
	)
end

end