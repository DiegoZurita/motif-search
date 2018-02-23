
# coding: utf-8

# In[41]:

import random
from numpy.random import choice
import re


# In[42]:

parent = dict()
rank = dict()

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

def kruskal(graph):
    edges = list(graph['edges'])
    
    #random.shuffle(edges)
    edges.sort()
    #edges.reverse()
    # print edges
    
    for vertice in graph['vertices']:
        make_set(vertice)
        minimum_spanning_tree = set()

    for edge in edges:
        weight, vertice1, vertice2 = edge
        if find(vertice1) != find(vertice2):
            union(vertice1, vertice2)
            minimum_spanning_tree.add(edge)
            
    return  (minimum_spanning_tree)


# In[43]:

file_ = open("redes/HomoSapiens_Torque.sif", "r")
#file_ = open("test.txt", "r")
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


# In[44]:

vertices_id = dict()

counter = 0

for vertice_ in vertices:
    vertices_id[vertice_] = counter
    counter = counter + 1


# In[45]:

#Trocar as cores
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


# In[46]:

#rerotular
color = dict()
color_count = 0

for vertice, vertice_color in vertices_colors.iteritems():
    if vertice_color not in color:
        color[vertice_color] = color_count
        color_count = color_count + 1    
           
            
    vertices_colors[vertice] = color[vertice_color]
    
color_count = color_count + 1
print color_count


# In[47]:

#cria arquivos de vertices

vertices_colors_file = file("instance1/vertices_colors.csv", "w+")

vertices_color_content = []

for vertice, vertice_color in vertices_colors.iteritems():
    vertices_color_content.append(str(vertice_color))
    
vertices_colors_file.write(",".join(vertices_color_content))


# In[48]:

#cria arquivo de motify


motify_frequency_file = file("instance1/motify_frequency.csv", "w+")

motify_sample = "ITGAV-ITGB5-CYR61 complex	3491 3685 3693"
#motify_sample = "ITGAV-ITGB5-CYR61 complex	A B"



motify_parse = re.split(r'\t+', motify_sample)
motify_description = motify_parse[1].split()

color_frequency = ["0"] * color_count

for vertice_ in motify_description:
    color = vertices_colors[vertice_]
    temp_val = int(color_frequency[color])
    color_frequency[color] = str(temp_val + 1)
    
motify_frequency_file.write(",".join(color_frequency))


# In[49]:

#cria lista de adjacencia
graph = {
    'vertices': vertices,
    'edges': set(edges)
}

edges_selected = kruskal(graph)

number_of_vertices = len(graph["vertices"])

adjacency_list = [[] for i in xrange(number_of_vertices)]

for edge in edges_selected:
    start_vertice = edge[1]
    end_vertice = edge[2]
    
    adjacency_list[vertices_id[start_vertice]].append(end_vertice)
    adjacency_list[vertices_id[end_vertice]].append(start_vertice)


# In[50]:

#criar arquivo de lista de adjacencia
edges_file = file("instance1/edges.csv", "w+")

adjacency_list_text = [[] for i in xrange(number_of_vertices)]

for i in xrange(number_of_vertices):
    adjacency_list_text[i] = " ".join(str(v) for v in adjacency_list[i])
    
edges_file.write("\n".join(adjacency_list_text))


# In[ ]:



