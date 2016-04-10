import random

output = ''
for k in range(10):
	i = random.randrange(256)
	output += '{0:08b}'.format(i) + " "
	output += '{0:08b}'.format(i) + '\n'
f = open("adcc_tracefile.txt", 'w')
f.write(output)
f.close()

