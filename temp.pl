#!/usr/bin/perl -w
$x = 1;
$y = 0;
if ($x or $y) {
	print "or\n";
}
if ($x and $x) {
	print "and\n";
}
if (not($y)) {
	print "not\n";
}
