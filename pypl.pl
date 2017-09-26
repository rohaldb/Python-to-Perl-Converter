#!/usr/bin/perl -w

# written by ben rohald 2017
use strict;

our @variables;
our @lists;
our $global_indentation = 0;

while (my $line = <>) {
  my $temp_line = $line;
  $temp_line =~ /^(\s*).*/;
  my $local_indentation = length($1)/4;
  # if we have an empty line, dont close all brackets
  $local_indentation = 0 if ($line =~ /^\s*$/);
  # print "the indentation of $line is $local_indentation\n";
  if ($local_indentation < $global_indentation) {
    closeAllBrackets($local_indentation);
  }
  patternMatch($line);
  # close all unclosed brackets if end of file
  closeAllBrackets(0) if (eof || eof());
}

# given the current line, matches the line with a method to handle it
sub patternMatch {
    my $line = $_[0];
    #$line = spaceOperators($line);

    if ($line =~ /^#!/ && $. == 1) {
        # translate #! line
        print "#!/usr/bin/perl -w\n";
    } elsif ($line =~ /^\s*(#|$)/) {
        # Blank & comment lines can be passed unchanged
        print $line;
    } elsif ($line =~ /^\s*import\s+sys\s*;{0,1}$/) {
        return;
    } elsif ($line =~ /^\s*for\s+(\w+)\s+in\s+range\s*\((.*)\)\s*:\s*(.*)$/) {
        #for loop with range
        forRangeStatement($1,$2,$3);
    } elsif ($line =~ /^\s*for\s+(\w+)\s+in\s+sys\.stdin\s*:\s*(.*)$/) {
        #for loop over stdin
        forStdinStatement($1,$2);
    } elsif ($line =~ /\s*while\s*(.*?)\s*:\s*(.*)/) {
        #while statement, be it inline or multiline
        conditionalStatement($1,$2, "while");
    } elsif ($line =~ /\s*\bif\b\s*(.*?)\s*:\s*(.*)/) {
        #if statement, be it inline or multiline
        conditionalStatement($1,$2, "if");
    } elsif ($line =~ /\s*elif\s*(.*?)\s*:\s*;{0,1}\s*$/) {
        #elseif statement
        elseIfStatement($1);
    } elsif ($line =~ /\s*else\s*:\s*$/) {
        #else statement to end conditional
        elseStatement();
    } elsif ($line =~ /^\s*break\s*;{0,1}\s*$/) {
        #break statement
        breakStatement($line);
    } elsif ($line =~ /^\s*continue\s*;{0,1}\s*$/) {
        #continue statement
        continueStatement($line);
    } elsif ($line =~ /^\s*print\s*\(\s*(.*?)\s*\)\s*;{0,1}\s*$/) {
        #printing. 0 means called from print
        printStatment($1,0);
    } elsif ($line =~ /^\s*sys.stdout.write\s*\((.*?)\)\s*;{0,1}\s*$/) {
        #printing. 1 means called from sys.stdout
        printStatment($1, 1);
    }  elsif ($line =~ /^\s*(\w+)\s*(\+=|=|-=|\*=|\/=|%=|\*\*=|\/\/=)\s*(.*?);{0,1}\s*$/) {
        #assignment of a variable
        printIndentation();
        variableAssignment($1,$2,$3);
    } elsif ($line =~ /\s*(\w+)\.(\w+)\((.*)\)\s*;{0,1}\s*$/) {
        # method being called on a list. can be either push or pop. Check which it is and call appropriate sub
        my $array_ref = $1; my $method = $2; my $var = $3;
        appendStatement($array_ref, $var) if ($method =~ /append/);
        popStatement($array_ref, $var) if ($method =~ /pop/);
    } else {
        # Lines we can't translate are turned into comments
        printIndentation();
        print "#$line\n";
    }
}

# given a python expression, sanitizes it through subs
sub sanitizeExpression {
  my $expr = $_[0];
  # 1. replaces invalid operators with valid ones
  # 2. replaces variables and lists with prefixes
  # 3. replaces method definitions with appropriate syntax
  $expr = sanitizeMethods(prefixVariables(sanitizeOperators($expr)));
  return $expr;
}

# given an expression, substitutes all instances of lenth with appropriate syntax
sub sanitizeMethods() {
  my $expr = $_[0];
  # replace len(@array) with scalar(@array)
  $expr =~ s/len\(@/scalar\(@/g;
  # replace len($scalar) with length($scalar)
  $expr =~ s/len\(/length\(/g;
  #replace sorted(array) w sort(array)
  $expr =~ s/sorted\(/sort\(/g;
  return $expr;
}

sub popStatement {
  my ($array_ref, $var) = @_;
  #add the list to our array of known lists (even though if we are popping, its likely we've seen it before)
  pushOnto(\@lists, $array_ref);
  printIndentation();
  # check if we have a variable indicating index eg. pop(x) or popping final elem
  if ($var eq '') {
    print "pop(\@$array_ref);\n";
  } else {
    # clean up whatever is being pushed as it could be an expression
    $var = sanitizeExpression($var);
    print "splice \@$array_ref, $var, 1;\n";
  }
}

sub appendStatement {
  my ($array_ref, $var) = @_;
  #add the list to our array of known lists
  pushOnto(\@lists, $array_ref);
  # clean up whatever is being pushed as it could be an expression
  $var = sanitizeExpression($var);
  printIndentation();
  print "push \@$array_ref, $var;\n";
}

sub elseIfStatement {
  my $condition = sanitizeExpression($_[0]);
  printIndentation();
  print "elsif ($condition) { \n";
  $global_indentation++;
}

sub elseStatement {
  printIndentation();
  print "else { \n";
  $global_indentation++;
}

sub breakStatement {
  my $line = $_[0];
  printIndentation();
  print "last;\n";
}

sub continueStatement {
  my $line = $_[0];
  printIndentation();
  print "next;\n";
}

#pushes the variable parameter onto the list parameter
sub pushOnto {
  my ($array_ref, $new_var) = @_;
  #check if it already exists on the list
  my $exists = 0;
  foreach my $var (@$array_ref) {
    $exists = 1 if ($var eq $new_var);
  }
  push @$array_ref, $new_var unless ($exists);
}

sub forStdinStatement {
  my ($var, $optional_inline) = @_;
  # store the variable
  pushOnto(\@variables,$var);
  $global_indentation += 1;
  print "foreach \$$var (<STDIN>) { \n";
  handleOptionalInline($optional_inline);
}

sub handleOptionalInline {
  my $optional_inline = $_[0];
  # if we have an inline statement such as if(condition):statement; statement;...
  if ($optional_inline) {
    #split them up and handle each appropriately
    my @statements = split '\s*;\s*', $optional_inline;
    foreach my $statement (@statements) {
        patternMatch($statement);
    }
    $global_indentation--;
    # end by closing the parenthesis
    printIndentation();
    print "}\n";
  }
}

sub forRangeStatement {
  #for range loop
  my ($var, $range, $optional_inline) = @_;
  # store the variable
  pushOnto(\@variables,$var);
  printIndentation();
  # check whether it is a range(x) or a range(x, y)
  if ($range =~ /(.+)\s*,\s*(.+)/) {
    # bounds can be expressions, evaluate and print
    my $lower = sanitizeExpression($1);
    my $upper = sanitizeExpression($2);
    print "foreach \$$var ($lower..$upper - 1) {\n";
  } elsif ($range =~ /^\s*(\d+)\s*$/) {
    # bound can be expression, evaluate it and print
    my $upper = sanitizeExpression($1);
    print "foreach \$$var (0..$upper - 1) {\n";
  }
  $global_indentation++;
  handleOptionalInline($optional_inline);
}

# applied to an expression. replaces a//b with int(a/b)
sub sanitizeOperators {
  my $expr = $_[0];
  #while we have an invalid // operator, swap it
  while ($expr =~ /((\w+)\s*\/\/\s*(\w+))/) {
    my $full = $1; my $divisor1 = $2; my $divisor2 = $3;
    $expr =~ s/$full/int($divisor1\/$divisor2)/g;
  }
  # if line starts with not, add brackting format
  # if ($expr =~ /(\bnot\b\s*(.*))/) {
  #   $expr = "not($2)";
  # }
  return $expr;
}

#used to handle if and while statments
sub conditionalStatement {
  #loops are in the format if/while(condition): optional_inline; optional_inline ...
  #type is either while or if
  my ($condition, $optional_inline, $type) = @_;

  printIndentation();

  $condition = sanitizeExpression($condition);
  # print if (condition) or while(condition)
  print "$type ($condition) {\n";
  $global_indentation++;

  handleOptionalInline($optional_inline);
}

# prints any expression
sub printStatment {
    # prints any expression. first param is content, second indicates if function is being called from match on print, or match on std.out
    my ($print_content, $stdout) = @_;
    printIndentation();
    # if printing nothing. eg print(), print new line and return
    if ($print_content =~ /^\s*$/) {
      print "print \"\\n\";\n";
      return;
    }
    # check if there is a custom end
    my $end_exists = endOfPrintExists($print_content);
    # get the custom end regardless of whether it exists.
    my $end = getEndOfPrint($print_content);
    # set end to new line unless there is another one specified, or unless the params tell us we are in sys.stdout
    $end = "\\n" unless ($end_exists or $stdout);

    if ($print_content =~ /^"(.*?)"(.*)/ or $print_content =~ /^'(.*?)'(.*)/) {
        my ($string, $remaining) = ($1, $2);
        # if we enter here, we are printing a string
        # we now assume that there is a % with variables to substitute
        if ($end_exists) {
          # cut the end off (if it exists). format after operation: ' % (x,y,z)'
          $remaining =~ s/\s*,\s*end.*//g;
          # remove encasing brackets. format after operation: ' % x,y,z'
          $remaining =~ s/[\(\)]//g;
          # at this point, remaining should be in the same format as if ther was no end
        }
        # format after operation: % x,y,z
        $remaining =~ s/^\s*%\s*//g;
        # if remaining is not empty, we know there are no variables to subsitute
        if ($remaining) {
          # split the variables into a list to be used for subsituton
          my @variables = split /\s*,\s*/, $remaining;
          # substitute variables before printing
          $string = subVarsIntoString($string, @variables);
        }
        print "print \"$string$end\";\n";
    } else {
        # if we enter here, we are printing an expression
        $print_content =~ s/\s*,\s*end.*//g;
        $print_content = sanitizeExpression($print_content);
        print "print($print_content, \"$end\");\n";
    }
}

# returns boolean depending on if end='' exists
sub endOfPrintExists {
  return $_[0] =~ /end\s*=\s*['"](.*)['"]/;
}

# returns str val of custom end to print statement
sub getEndOfPrint {
  my $content = $_[0];
  if ($content =~ /end\s*=\s*['"](.*)['"]/) {
    return escapeAllSpecialCharacters($1);
  } else {
    return '';
  }
}

sub subVarsIntoString {
  my ($string, @variables) = @_;
  while ($string =~ /(%\w)/) {
    my $symbol = $1;
    my $variable = shift(@variables);
    # cut leading and trailing quotes if case string
    $variable =~ s/^['"]//; $variable =~ s/['"]$//;
    $string =~ s/$symbol/$variable/;
  }
  return $string;
}

# escapes all special chars from string
sub escapeAllSpecialCharacters {
  my $string = $_[0];
  $string =~ s/\.\^\$\*\+\-\?\(\)\[\]\{\}\\\|/\\$1/g;
  return $string;
}

# converts param = sys.stdin.readlines() to a while loop
sub readLinesStatement {
  my $variable = $_[0];
  #pass back into pattern match a python string that will be converted to an equivalent statement with a  loop
  patternMatch("for line in sys.stdin: $variable.append(line)");
}

sub variableAssignment {
    my ($lhs,$operator, $rhs) = @_;
    $rhs = sanitizeExpression($rhs);

    # if we are assigning to sys.stdin.readlines()
    if ($rhs =~ /sys.stdin.readlines()/){
      readLinesStatement($lhs);
      return;
    }

    # if we are declaring a list by providing elements eg [1,2,3]
    if ($rhs =~ /^\s*\[(.*)\]\s*$/) {
      return unless $1;
      # store the list
      pushOnto(\@lists, $lhs);
      $rhs =~ tr/\[/\(/; $rhs =~ tr/\]/\)/;
      print "\@$lhs $operator $rhs;\n";
    } elsif ($rhs =~ /sort\(/) {
      # we are declaring an array since rhs returns array
      pushOnto(\@lists, $lhs);
      print "\@$lhs $operator $rhs;\n";
    } else {
      # we are declaring a variable
      # add the variable to our list of variables
      pushOnto(\@variables,$lhs);
      # if stdin, replace rhs with <STDIN>
      if ($rhs =~ /sys.stdin.readline\(\)/) {
        $rhs = "<STDIN>";
      }
      print "\$$lhs $operator $rhs;\n";
    }
}

# inserts appropriate prefix before known variables in an expression
sub prefixVariables {
    my $expr = $_[0];
    # prefix scalars with $
    foreach my $var (@variables) {
      $expr =~ s/\b$var\b/\$$var/g;
    }
    # prefix indexed arrays with either $/@
    foreach my $var (@lists) {
      # if the sed for a $ doesnt match, must be @
      if (not($expr =~ s/\b$var\[/\$$var\[/g)) {
        $expr =~ s/\b$var\b/\@$var/g;
      }
    }
    return $expr;
}

# prints the required indentation for a line
sub printIndentation {
   foreach (1..$global_indentation) {
      print "    ";
   }
}

# given the current lines indentation, closes the appropriate amount of brackets
sub closeAllBrackets {
  my $local_indentation = $_[0];
  while ($global_indentation != $local_indentation) {
    $global_indentation--;
    printIndentation();
    print "}\n";
  }
}

# sub spaceOperators {
#     my $line = $_[0];
#     #provide appropriate spacing
#     $line =~ s/\+/ + /g;
#     $line =~ s/-/ - /g;
#     $line =~ s/\*/ * /g;
#     $line =~ s/\// \/ /g;
#     $line =~ s/\/\// \/\/ /g;
#     $line =~ s/\* \*/ \*\* /g;
#     $line =~ s/%/ % /g;
#     $line =~ s/  */ /g;
#     $line =~ s/\* \*/\*\*/g;
#     $line =~ s/\/ \//\/\//g;
#     $line =~ s/\+ =/\+=/g;
#     $line =~ s/- =/-=/g;
#     $line =~ s/\* =/\*=/g;
#     $line =~ s/\/ =/\/=/g;
#     return $line;
# }
