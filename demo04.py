#!/usr/bin/python3
# this program reads in an even number of lines from stdin, then prints out each line and the number of characters in that line by using a hash
import sys

a = sys.stdin.readlines()
if len(a) % 2 != 0: print("we want an even number of lines please enter one more"); b = sys.stdin.readline(); a.append(b)

lengths = []
#calculate lengths
for i in a:
    lengths.append(len(i))
my_dict = {};
# update hash to store lengths
for i in range(len(lengths)):
    str = "%s" % a[i]
    my_dict[str] = lengths[i]
# itterate over hash and print
for key in sorted(my_dict.keys()):
    print("%s has length %d" % (key, my_dict[key]))
