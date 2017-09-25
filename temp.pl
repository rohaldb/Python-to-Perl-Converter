#!/usr/bin/perl -w

$a = 3;
$b = 2;
$a += $b;
print "$a\n";
$a = 3;
$a **= $b;
print "$a\n";
$a = 3;
$a %= $b;
print "$a\n";
$b //= $a;
print "$b\n";
