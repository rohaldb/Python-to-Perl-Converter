#!/usr/local/bin/python3
a = 65
b = 19
print(a)
print(b)
c = a & b
print(c)
c = a | b
print(c)
c = a ^ b
print(c)
c = a << 2
print(c)
c = a >> 2
print(c)

import sys

a = int(sys.stdin.readline())
if a < 3 :
    print("why so small?")
elif        a <       10 and a >= 3:
    print("decent size")
else :
    print("nice and big. lets print the times table of your number")
    for i in range(0,10):
        print(i*a);

x=0
while (x < 10) :
    x   +=   1;
    if x == 5:
        continue;
    if x == 7 :
        break;
    print(x);

y = int(12/5);
print(y)
sys.stdout.write("hopefully there are no errors by now");
print();
