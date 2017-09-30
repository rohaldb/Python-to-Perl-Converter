#!/usr/bin/python3
# put your test script here

a=[]
b=[]
a = [1,2,3]
b.append(4)
b.append(5)
b.append(6)
if b.pop(0) == 4 : print("You should see me");
if a.pop() == 3 :
    print("You should also see  me")
a[1] = 100
if a[1] == 100 : print("keep on going")

if len(a) != len(b) : print("almost there")

import sys

a = sys.stdin.readlines()

print("the number of lines you entered was %d" % len(a) , end='\ni should be on a new line\n')

for line in sys.stdin: print(line);

hash = {'Name': 'Zara', 'Age': 7, 'Class': 'First'}
hash['Age'] = 8; # update existing entry
hash['School'] = "St Caths"; # Add new entry

for i in sorted(hash.keys()):
    print(i)
    print(hash[i])
