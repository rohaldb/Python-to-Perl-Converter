#!/usr/local/bin/python3
count = 0
for i in range(2, 100):
    k = i // 2
    j = 2
    for j in range(2, k + 1):
        k = i % j
        if k == 0:
            count = count - 1
            break
        k = i // 2
    count = count + 1
print(count)
