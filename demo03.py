#!/usr/bin/python3
# demo finding the biggest number in a list of lists
a = [[1],[6],[2,9,3]]
my_max = 0
i = 0
while i < len(a):
    for i in a[i] :
        if i > my_max: my_max = i;
    i+=1

print("biggest in all lists is %d" % my_max)

# demo arrray operations
a=[]
b=[]
a = [1,2,3]
b.append(4)
b.append(5)
b.append(6)
if b.pop(0) == 4 :
    print("You should see me");
    if a.pop() == 3 :
        print("You should also see  me")
        a[1] = 100
        if a[1] == 100 :
            print("keep on going")
            if len(a) == len(b) : print("If you see me youve passed the array operations"); print(int(12/5), " <- should equal 2")

# demo reading lines in from sys.stdin and readlines()
import sys

print("please enter some data through readlines");
new = sys.stdin.readlines()

z = len(new)
print("the number of lines you entered was %d" % z , end='\n and i should be on a new line\n')

print("please enter some more data")
for line in sys.stdin: print(line);

# demo hash operations
hash = {'Name': 'Zara', 'Age': 7, 'Class': 'First'}
hash['Age'] = 8; # update existing entry
hash['School'] = "St Caths"; # Add new entry

for i in sorted(hash.keys()):
    print(i)
    print(hash[i])
