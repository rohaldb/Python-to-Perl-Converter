#!/usr/bin/perl -w

# demo finding biggest number in list
@a = (1,2,3,4,6,7,99,88,999);
$max = 0;
foreach $i (@a) {
    if ($i > $max) {
        $max = $i;
    }
}
print($max, "\n");

# demo the print function in different ways
print("hey ben 1", "\n");
print("hey", " ",  "ben 2", "\n");
print("hey, i am cool", "\n");
print("hey, mini", " ", "sorry i mean ben", "\n");
print("hey, ben again", "\n");
print("hey, ben a final, time", "");
print("Am i ", "inline?\n");
$x = 1;
print($x+1, " ",  $x+2, " ",  $x+3, " ",  "tomato", " potato\n");
print($x, "\n");
print "\n";
print($x+1, "");
print("ben is 8", " ",  "years old", "\n");
print($x, " ", "split, example", " ",  "years old", "\n");
print($x, " ", "split, 9", " ",  "years old", "\n");
