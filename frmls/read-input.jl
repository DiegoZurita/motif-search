instancias_folder = "../instancias"

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
					"colors" => "$(instancias_folder)/$(instancia_dir)/vertices_colors.csv"
				)
			)
		end
	end
end	


println(files_dict)