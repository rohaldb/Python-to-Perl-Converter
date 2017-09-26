#!/usr/bin/perl -w

foreach $line (<STDIN>) { 
    push @lines, $line;
}

$i = scalar(@lines) - 1;
while ($i >= 0) {
    print($lines[$i], "\n");
    $i = $i - 1;
}
