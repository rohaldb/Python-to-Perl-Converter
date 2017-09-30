#!/usr/bin/perl -w
# put your test script here

@a = ("hey","ben",(3,4));
foreach $i (@a) {
  print(length($i));
}
