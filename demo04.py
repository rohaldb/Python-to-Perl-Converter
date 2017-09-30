#!/usr/local/bin/python3
# this program reads in an even number of lines from stdin, then prints out each line and the number of characters in that line
import sys

a = sys.stdin.readlines()
if len(a) % 2 != 0: print("we want an even number of lines please enter one more"); b = sys.stdin.readline(); a.append(b)

lengths = []
#calculate lengths
for i in a:
    lengths.append(len(i))
my_dict = {};
for i in range(len(lengths)):
    str = "%s" % a[i]
    my_dict[str] = lengths[i]

for key in my_dict.keys():
    print("%s has length %d" % (key, my_dict[key]))
