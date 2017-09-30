#!/usr/bin/perl -w
# put your test script here

# finds the biggest number in a list of lists
@a = ((1),(6),(2,9,3));
$my_max = 0;
$i = 0;
while ($i < scalar(@a)) {
    foreach $i ($a[$i]) { 
        if ($i > $my_max) {
            $my_max = $i;
        }
    }
    $i += 1;
}

print("biggest in all lists is $my_max", "\n");

#arrray operations
@a = (1,2,3);
push(@b, 4);
push(@b, 5);
push(@b, 6);
if (splice(@b, 0, 1) == 4) {
    print("You should see me", "\n");
        if (pop(@a) == 3) {
        print("You should also see  me", "\n");
        $a[1] = 100;
        if ($a[1] == 100) {
            print("keep on going", "\n");
            if (scalar(@a) == scalar(@b)) {
                print("If you see me youve passed the array operations", "\n");
                print(int(12/5), " ", " <- should equal 2", "\n");
            }
        }
    }
}

# reading in from std

print("please enter some data through readlines", "\n");
foreach $line (<STDIN>) { 
    push(@new, $line);
}

$z = scalar(@new);
print("the number of lines you entered was $z", "\n and i should be on a new line\n");

foreach $line (<STDIN>) { 
    print($line, "\n");
}

# hash operations
%hash = ('Name', 'Zara', 'Age', 7, 'Class', 'First');
$hash{'Age'} = 8; # update existing entry;
$hash{'School'} = "St Caths";

foreach $i (sort(keys %hash)) { 
    print($i, "\n");
    print($hash{$i}, "\n");
}
