#!/usr/bin/perl -w


push @a, 1;
push @a,  2 ;
push @a, 3;
push @a, 4;
pop(@a);
splice @a, 0, 1;
print "@a\n";
