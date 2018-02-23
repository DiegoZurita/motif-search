import re

file = open("motify/DM_Fly_Complexes_GO.txt", "r")

files_lines = file.readlines()
count = 0

for lines in files_lines:
	motify_parse = re.split(r'\t+', lines)
	if len(motify_parse) < 2:
		continue
	motify_description = motify_parse[1].split()

	if len(motify_description) >= 30:
		print lines
		count = count + 1
print count