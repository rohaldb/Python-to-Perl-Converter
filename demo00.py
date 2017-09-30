#!/usr/local/bin/python3
x=5
y  =   1.5
k   = 2
sumvar = x   +   y
tot = 0
print(x+y)
print("above should be same as below")
print  (sumvar )
if (x  +  k == 7) : print ("1"); tot += 1
if (x  /  k == 2.5) : print ("2"); tot += 1
if (y  -  k == -0.5)  : print("3"); tot += 1
if (y * k == 3) : print("4"); tot += 1
if (x//y == 3) : print("5"); tot += 1
if (x % k == 1) : print("6"); tot += 1
if (x ** k == 25) : print("7"); tot += 1

if not tot ==  7 : print  ("error encountered")

x*=16
x/=8
x-=6
x+=2

x += 12//7
print(x);
print("above should be 7.0");
