#!/usr/local/bin/python3
import sys

lines = []
for line in sys.stdin:
    lines.append(line)

i = len(lines) - 1
while i >= 0:
    print(lines[i])
    i = i - 1
