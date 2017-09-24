#!/usr/local/bin/python3
import sys
x = 1
while x < 10:
    y = 1
    while y <= x:
        sys.stdout.write("*")
        y = y + 1
    print()
    x = x + 1
