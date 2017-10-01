#!/usr/bin/python3

# demo finding biggest number in list
a=[1,2,3,4,6,7,99,88,999]
max= 0
for i in a:
    if i > max:max=i
print(max)

# demo the print function in different ways
print("hey ben 1")
print("hey", "ben 2")
print("hey, %s" % "i am cool")
print("hey, %s" % "mini", "sorry i mean %s" % "ben")
print("hey, ben again", end='\n')
print("hey, ben a final, time", end='')
print("Am i ", end='inline?\n')
x=1
print(x+1, x+2, x+3, "tomato", end=' potato\n');
print(x)
print()
print(x+1, end='')
print("%s %s %d" % ("ben", "is", 8), "years old");
print(x, "split, %s" % "example", "years old");
print(x, "split, %d" % 9, "years old");
