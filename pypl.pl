#!/usr/bin/perl -w

# written by ben rohald 2017
use strict;

our @variables;
our $global_indentation = 0;

while (my $line = <>) {
  my $temp_line = $line;
  $temp_line =~ /^(\s*).*/;
  my $local_indentation = length($1)/4;
  if ($local_indentation < $global_indentation) {
    closeAllBrackets($local_indentation);
  }
  patternMatch($line);
  # close all unclosed brackets if end of file
  closeAllBrackets(0) if (eof || eof());
}

sub countIndentations {
  # my $temp_line = $_[0];
  # $temp_line =~ /^(\s*).*/;
  # my $local_indentation = length($1)/4;
  # print "$local_indentation , $global_indentation ??\n";
  # if ($local_indentation < $global_indentation || eof()) {
  #   print "entered here\n";
  #   closeAllBrackets($local_indentation);
  # }
  # print "ben\n";
  # my $count = $_[0] =~ tr/ //;
  # print "count = $count\n";
  # $count /= 4;
  # print "new count = $count\n";
  # return $count;
}

sub patternMatch {
    my $line = $_[0];
    #$line = spaceOperators($line);

    if ($line =~ /^#!/ && $. == 1) {
        # translate #! line
        print "#!/usr/bin/perl -w\n";
    } elsif ($line =~ /^\s*(#|$)/) {
        # Blank & comment lines can be passed unchanged
        print $line;
    } elsif ($line =~ /^\s*import\s+sys\s*$/) {
        return;
    } elsif ($line =~ /^\s*for\s+(\w+)\s+in\s+range\s*\((.*)\)\s*:/) {
        #for loop with range
        forStatement($1,$2);
    } elsif ($line =~ /\s*while\s*(.*?)\s*:\s*(.*)/) {
        #while statement, be it inline or multiline
        conditionalStatement($1,$2, "while");
    } elsif ($line =~ /\s*if\s*(.*?)\s*:\s*(.*)/) {
        #while statement, be it inline or multiline
        conditionalStatement($1,$2, "if");
    } elsif ($line =~ /^\s*print\s*\(\s*("{0,1})(.*?)"{0,1}\s*\)/ || $line =~ /^\s*sys.stdout.write\s*\(\s*("{0,1})(.*?)"{0,1}\s*\)/) {
        #printing
        printStatment($1,$2);
    } elsif ($line =~ /^\s*(\w+)\s*(\+=|=|-=|\*=|\/=)\s*(.*)/) {
        #assignment of a variable
        printIndentation();
        variableAssignment($1,$2,$3);
    } else {
        # Lines we can't translate are turned into comments
        printIndentation();
        print "#$line\n";
    }
}

sub forStatement {
  #for range loop
  my $var = $_[0]; my $range = $_[1];
  push @variables, $var;
  if ($range =~ /(\d+)\s*,\s*(\d+)/) {
    print "foreach $var ($1..$2) {\n";
  } elsif ($range =~ /^\s*(\d+)\s*$/) {
    print "foreach $var (0..$1) {\n";
  } else {
    print "problem with range\n";
  }
  $global_indentation++;
}

sub sanitizeOperators {
  my $line = $_[0];
  #while we have an invalid // operator, swap it
  while ($line =~ /((\w+)\s*\/\/\s*(\w+))/) {
    my $full = $1; my $divisor1 = $2; my $divisor2 = $3;
    $line =~ s/$full/int($divisor1\/$divisor2)/g;
  }
  # if line starts with not, add brackting format
  if ($line =~ /(\bnot\b\s*(.*))/) {
    $line = "not($2)";
  }
  return $line;
}

#used to handle if and while statments
sub conditionalStatement {
  #in the format if/while(condition): optional_inline; optional_inline
  #type = while vs if
  my ($condition, $optional_inline, $type) = @_;

  $condition = sanitizeOperators($condition);
  printIndentation();
  $condition = insertDollars($condition);
  print "$type ($condition) {\n";
  $global_indentation++;

  if (!$optional_inline) {
    #just a if/while statement
    $condition = insertDollars($condition);
  } else {
    #may have multiple inline statements, split them up and handle each appropriately
    my @statements = split '\s*;\s*', $optional_inline;
    foreach my $statement (@statements) {
        patternMatch($statement);
    }
    $global_indentation--;
    printIndentation(); print "}\n";
  }
}

sub printStatment {
    my ($quotation,$print_content) = @_;
    printIndentation();
    if ($quotation) {
        # printing a string
        print "print \"$print_content\\n\";\n";
    } else {
        #print contains variables
        my $print_content = insertDollars($print_content);

        if ($print_content =~ /\+|-|\*|\/|%/){
            #printing an expression
            print "print $print_content, \"\\n\";\n";
        } else {
            #printing a variable
            print "print \"$print_content\\n\";\n";
        }
    }
}

sub variableAssignment {
    my ($lhs,$operator, $rhs) = @_;
    #check if first declaration or updating
    my $exists = 0;
    foreach my $var (@variables) {
      $exists = 1 if ($var eq $lhs);
    }
    push @variables, $lhs unless ($exists);
    if ($rhs =~ /sys.stdin.readline\(\)/) {$rhs = "<STDIN>\n";}
    $rhs = insertDollars($rhs);
    print "\$$lhs $operator $rhs;\n";
}

# inserts $before known variables in a string param
sub insertDollars {
    my $str = $_[0];
    foreach my $var (our @variables) {
        $str =~ s/\b$var\b/\$$var/g;
    }
    return $str;
}

sub printIndentation {
   foreach (1..$global_indentation) {
      print "    ";
   }
}

sub closeAllBrackets {
  my $local_indentation = $_[0];
  while ($global_indentation != $local_indentation) {
    $global_indentation--;
    printIndentation();
    print "}\n";
  }
}

sub spaceOperators {
    my $line = $_[0];
    #provide appropriate spacing
    $line =~ s/\+/ + /g;
    $line =~ s/-/ - /g;
    $line =~ s/\*/ * /g;
    $line =~ s/\// \/ /g;
    $line =~ s/\/\// \/\/ /g;
    $line =~ s/\* \*/ \*\* /g;
    $line =~ s/%/ % /g;
    $line =~ s/  */ /g;
    $line =~ s/\* \*/\*\*/g;
    $line =~ s/\/ \//\/\//g;
    $line =~ s/\+ =/\+=/g;
    $line =~ s/- =/-=/g;
    $line =~ s/\* =/\*=/g;
    $line =~ s/\/ =/\/=/g;
    return $line;
}
