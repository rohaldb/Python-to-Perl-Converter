#!/usr/bin/python3

# demo inline loops and if statements. Also test operators
x=10
y = 7
while x%2 == 0 or x == 9 :  print(x); x-=1;
#x should be 8 at this point
if not x == y : print(y); y += 1;

if y == x and y < 9 : print("we're on track baby"); x+=3; y += 6;
z = 12
if x < y and (y-1) == z and x != y and y > (x) and (y-1) >= z and x <= (y-3) : print("if you see me you've beaten this boss");
