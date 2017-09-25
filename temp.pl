#!/usr/bin/perl -w
$a = 65;
$b = 19;
print "$a\n";
print "$b\n";
$c = $a & $b;
print "$c\n";
$c = $a | $b;
print "$c\n";
$c = $a ^ $b;
print "$c\n";
$c = $a << 2;
print "$c\n";
$c = $a >> 2;
print "$c\n";


$a = <STDIN>;
if ($a < 3) {
    print "why so small?\n";
}
elsif ($a <       10 and $a >= 3) { 
    print "decent size\n";
}
else { 
    print "nice and big. lets print the times table of your number\n";
    foreach $i (0..10 - 1) {
        print $i*$a, "\n";

    }
}
$x = 0;
while (($x < 10)) {
    $x += 1;
    if ($x == 5) {
        next;
    }
    if ($x == 7) {
        last;
    }
    print "$x\n";

}
$y = int(12/5);
print "$y\n";
print "hopefully there are no errors by now";
print "\n";
