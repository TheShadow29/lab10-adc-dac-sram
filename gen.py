#########adc tracefile###############
# import random

# output = ''
# for k in range(10):
# 	i = random.randrange(256)
# 	output += '{0:08b}'.format(i) + " "
# 	output += '{0:08b}'.format(i) + '\n'
# f = open("adcc_tracefile.txt", 'w')
# f.write(output)
# f.close()

##############smc tracefile#################
import random
data = {}
output = ''
for k in range(10):
	rw = int(random.random()* 2)
	addr = 0
	number = 0
	if len(data) == 0:
		rw = 1
	if rw == 1:
		addr = random.randrange(0,8192)
		number = random.randrange(0,256)
		data[addr] = number;
	else:
		addr = random.choice(data.keys())
		number = data[addr]
	output += '{0:01b}'.format(rw) + " "
	output += '{0:013b}'.format(addr) + " "
	output += '{0:08b}'.format(number) + '\n'
f = open("smcc_tracefile.txt", 'w')
f.write(output)
f.close()