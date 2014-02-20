import sys

i = 0
for i in range(1, len(sys.argv)):
	print "%d. %s" % (i, sys.argv[i])
	fp = open('c:\\scripts\\python\\' + sys.argv[i], 'w')
	fp.write('testing')
	fp.close()
	i += 1
