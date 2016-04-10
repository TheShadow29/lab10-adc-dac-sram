import random

def toBinary (a, size):
	s = ''
	for i in range(size):
		s = str(a%2) + s
		a = a / 2
	return s
	
def getRandom (lower, higher):
	hilorange = higher - lower
	return (int)(random.random()*hilorange) + lower
	
f = open ('adc_sim.txt', 'w')
f.seek (0)
f.truncate()

for caseNum in range (0,1000):
	num = toBinary( getRandom(0,255),8 )
	f.write(num + " " + num + "\n")

f.close();
