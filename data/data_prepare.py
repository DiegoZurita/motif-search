
# coding: utf-8


import random
from numpy.random import choice
import re
import os


parent = dict()
rank = dict()

order_type = {"reverse": 1, "random": 2}

def make_set(vertice):
    parent[vertice] = vertice
    rank[vertice] = 0

def find(vertice):
    if parent[vertice] != vertice:
        parent[vertice] = find(parent[vertice])
    return parent[vertice]

def union(vertice1, vertice2):
    root1 = find(vertice1)
    root2 = find(vertice2)
    if root1 != root2:
        if rank[root1] > rank[root2]:
            parent[root2] = root1
	else:
	    parent[root1] = root2
	if rank[root1] == rank[root2]: rank[root2] += 1

def kruskal(graph, edges_order_type): 
    
    if edges_order_type == order_type["reverse"]:
        edges = list(graph['edges'])
        edges.sort()
        edges.reverse()
    elif edges_order_type == order_type["random"]:
        edges = list(graph['edges'])
        random.shuffle(edges)
    
    for vertice in graph['vertices']:
        make_set(vertice)
        minimum_spanning_tree = set()
        #print edges
    for edge in edges:
        weight, vertice1, vertice2 = edge
        if find(vertice1) != find(vertice2):
            union(vertice1, vertice2)
            minimum_spanning_tree.add(edge)
    
    return sorted(minimum_spanning_tree)


def ler_rede(rede): 
    file_ = open(rede, "r")
    rows = file_.readlines()

    edges = []

    #store value in format vertice_name => color
    vertices_colors = dict()
    vertice_color = 0

    for row in rows:
        data = row.split()

        start_vertice = data[0]
        weight = float(data[1])
        end_vertice = data[2]

        edges.append((weight, start_vertice, end_vertice))

        vertices_colors[start_vertice] = vertice_color
        vertice_color += 1 

        vertices_colors[end_vertice] = vertice_color
        vertice_color += 1

    vertices = list(vertices_colors.keys())
    print len(vertices), " vertices"
    print len(edges), " edges"
    return {"vertices": vertices, "edges": edges, "vertices_colors": vertices_colors}



def create_vertices_id(vertices):
    vertices_id = dict()

    counter = 0

    for vertice_ in vertices:
        vertices_id[vertice_] = counter
        counter = counter + 1
    return vertices_id



def trocar_cores(edges, vertices_colors):
    for edge in edges:
        weight = edge[0]
        start = edge[1]
        end = edge[2]

        #probabilidade de pegar a cor do primeiro
        should_change_color = choice(a = [True, False], p = [weight, 1 - weight])

        if should_change_color:

            should_get_first_color = choice(a = [True, False], p = [0.5, 0.5])

            if should_get_first_color:
                vertices_colors[end] = vertices_colors[start]
            else: 
                vertices_colors[start] = vertices_colors[end]



def rerotular(vertices_colors):
    color = dict()
    color_count = 0

    for vertice, vertice_color in vertices_colors.iteritems():
        if vertice_color not in color:
            color[vertice_color] = color_count
            color_count = color_count + 1    


        vertices_colors[vertice] = color[vertice_color]

    color_count = color_count + 1
    print color_count, " cores ao total"
    
    return color_count

def create_adjacency_list(graph, order_type_, vertices_id):
    edges_selected = kruskal(graph, order_type_)
    
    
    if order_type_ == order_type["reverse"]:
        print len(edges_selected), " edges selecionadas pelo algoritmo para o tipo reverse"
    elif order_type_ == order_type["random"]:
        print len(edges_selected), " edges selecionadas pelo algoritmo para o tipo random"
    

    number_of_vertices = len(graph["vertices"])

    adjacency_list = [[] for i in xrange(number_of_vertices)]

    for edge in edges_selected:
        start_vertice = edge[1]
        end_vertice = edge[2]

        adjacency_list[vertices_id[start_vertice]].append(str(vertices_id[end_vertice] + 1))
        adjacency_list[vertices_id[end_vertice]].append(str(vertices_id[start_vertice] + 1))
        
    return adjacency_list    


#cria arquivos de vertices
def create_vertices_file(vertices_colors, folder):
    vertices_colors_file = file(folder + "/vertices_colors.csv", "w+")

    vertices_color_content = []

    for vertice, vertice_color in vertices_colors.iteritems():
        vertices_color_content.append(str(vertice_color + 1))

    vertices_colors_file.write(",".join(vertices_color_content))
    vertices_colors_file.close()


def create_edges_file(adjacency_list, number_of_vertices_, type_, folder):
    edges_file = file(folder + "/edges/" + type_ + "-edges.csv", "w+")
    
    vertices_range = xrange(number_of_vertices_)

    adjacency_list_text = [[] for i in vertices_range]

    for i in vertices_range:
        adjacency_list_text[i] = " ".join(str(v) for v in adjacency_list[i])

    edges_file.write("\n".join(adjacency_list_text))
    edges_file.close()    


def create_motifys_files(source, number_of_colors, vertices_colors, folder):
           
    motify_file = open(source, "r")
    motify_lines = motify_file.readlines()
    
    for i in xrange(len(motify_lines)):    
        counter = 0

        motify_sample = motify_lines[i]

        motify_parse = re.split(r'\t+', motify_sample)
        motify_description = motify_parse[1].split()

        i_str = str(i + 1)

        color_frequency = ["0"] * number_of_colors
        total_color = 0

        for vertice_ in motify_description:

            if vertice_ in vertices_colors: 
                color = vertices_colors[vertice_]

                frequency = int(color_frequency[color])

                if frequency == 0:
                    total_color = total_color + 1

                color_frequency[color] = str(frequency + 1)
            else:
                counter = counter + 1

        total_vertices = len(motify_description) - counter
        motify_frequency_file = open(folder + "/motify/motify-" + i_str + "-" + str(total_vertices) + "-" + str(total_color) + ".csv", "w+")

        motify_frequency_file.write(",".join(color_frequency))
        motify_frequency_file.close()


def create_instance(config):
    
    print "Criando instancia para a rede: ", config["rede"], " motify: ", config["motify"], " na pasta ", config["folder"]
    
    if not os.path.exists(config["folder"]):
        os.makedirs(config["folder"])
        os.makedirs(config["folder"] + "/motify")
        os.makedirs(config["folder"] + "/edges")
    
    rede = ler_rede(config["rede"])
    vertices_id = create_vertices_id(rede["vertices"])
    trocar_cores(rede["edges"], rede["vertices_colors"])
    color_count = rerotular(rede["vertices_colors"])


    #cria lista de adjacencia
    graph = {
        'vertices': rede["vertices"],
        'edges': set(rede["edges"])
    }

    adjacency_list_random = create_adjacency_list(graph, order_type["random"], vertices_id)
    adjacency_list_reverse = create_adjacency_list(graph, order_type["reverse"], vertices_id)

    #criar arquivo de lista de adjacencia
    number_of_vertices  = len(vertices_id)
    create_edges_file(adjacency_list_random, number_of_vertices, "random", config["folder"])
    create_edges_file(adjacency_list_reverse, number_of_vertices, "reverse", config["folder"])

    #create motify files
    vertices_colors = rede["vertices_colors"]
    create_motifys_files(config["motify"], color_count, vertices_colors, config["folder"])

    #create vertices colors file 
    create_vertices_file(vertices_colors, config["folder"])


def main():
    configs = [
        {
            "rede": "redes/test.txt",
            "motify": "motify/test_motify.txt",
            "folder": os.path.join(os.pardir, "instancias/teste")
        },
        {
            "rede": "redes/SC_Torque.sif",
            "motify": "motify/SC_Yeast_Complexes_SGD_filtrado.txt",
            "folder": os.path.join(os.pardir, "instancias/SC")
        }
#         {
#             "rede": "redes/HomoSapiens_Torque.sif",
#             "motify": "motify/HS_Human_Complexes_CORUM_filtrado.txt",
#             "folder": os.path.join(os.pardir, "instancias/HS")
#         }
#         {
#             "rede": "redes/DM_Torque.sif",
#             "folder": os.path.join(os.pardir, "instancias/DM"),
#             "motify": "motify/DM_Fly_Complexes_GO_filtrado.txt"
#         }
    ]

    for config in configs:
        create_instance(config)
        print "\n\n"


main()
