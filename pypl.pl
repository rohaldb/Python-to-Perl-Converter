#!/usr/bin/perl -w

# written by ben rohald 2017
use strict;

# arrays of variable names grouped by type
our @scalars;
our @lists;
our @dicts;
# represents how indented we should be. Different to local indentation which is how indented a line is. If they differ, we know we have to deal with closing conditionals
our $global_indentation = 0;

# read lines in
while (my $line = <>) {

  # calcualte how indented this line is:
  my $temp_line = $line;
  $temp_line =~ /^(\s*).*/;
  my $local_indentation = length($1)/4; #divide by 4 since 4 spaces = 1 indent

  # by comparing local and global indentation, do we have conditional statments that need to be closed?

  # if we have an empty line, dont close all brackets
  $local_indentation = 0 if ($line =~ /^\s*$/);
  # if we are less indented than we expected to be, close brackets
  closeAllBrackets($local_indentation) if ($local_indentation < $global_indentation);

  # Do we have multiple inline statements? If so, split them up.
  # if the line starts with a for, if or while, then ignore inline statements as they are handles later and slightly differently
  if (not($line =~ /^\s*(for|if|while)/) and $line =~ /.*;.*/) {
    handleOptionalInline($line);
  } else {
    # otherwise, pattern match the line and proceed
    patternMatch($line);
  }

  # close all unclosed brackets if end of file
  closeAllBrackets(0) if (eof || eof());
}

# given the current line, matches the line with a method to handle it
sub patternMatch {
    my $line = $_[0];
    if ($line =~ /^#!/ && $. == 1) {
        # translate #! line
        print "#!/usr/bin/perl -w\n";
    } elsif ($line =~ /^\s*(#|$)/) {
        # Blank & comment lines can be passed unchanged
        print $line;
    } elsif ($line =~ /^\s*import\s*.*\s*;{0,1}$/) {
        # ignore import lines
        return;
    } elsif ($line =~ /^\s*for\s+(\w+)\s+in\s+(.*?)\s*:\s*(.*)$/) {
        #for loop. Captures for (x) in (y) : (z)
        forStatement($1,$2, $3);
    } elsif ($line =~ /\s*while\s*(.*?)\s*:\s*(.*)/) {
        #while loop. Captures while (x) : (y)
        conditionalStatement($1,$2, "while");
    } elsif ($line =~ /\s*\bif\b\s*(.*?)\s*:\s*(.*)/) {
        #if statement. Captures if (x):(y)
        conditionalStatement($1,$2, "if");
    } elsif ($line =~ /\s*elif\s*(.*?)\s*:\s*;{0,1}\s*$/) {
        #elseif statement. Captures elif (x):(y)
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
        # print statement. Captures print((x))
        # 0 passed to printStatement means matched on print statement
        printStatement($1,0);
    } elsif ($line =~ /^\s*sys.stdout.write\s*\((.*?)\)\s*;{0,1}\s*$/) {
        # print statement. Captures sys.stdout((x))
        # 0 passed to printStatement means matched on sys.stdout
        printStatement($1, 1);
    }  elsif ($line =~ /^\s*(\w+(?:\[['"]{0,1}\w+['"]{0,1}\]){0,1})\s*(\+=|=|-=|\*=|\/=|%=|\*\*=|\/\/=)\s*(.*?);{0,1}\s*$/) {
        #assignment of a variable. captures (x) (=/+= etc) (y)
        printIndentation();
        variableAssignment($1,$2,$3);
    } elsif ($line =~ /\s*(.*)\.(\w+)\((.*)\)\s*;{0,1}\s*$/) {
        # method being called on a list. can be either push or pop. Check which it is and call appropriate sub
        my $array_ref = $1; my $method = $2; my $var = $3;
        if ($method =~ /append/) {
          print appendStatement($array_ref, $var), ";\n";
        } elsif ($method =~ /pop/) {
          print popStatement($array_ref, $var), ";\n";
        }
    } else {
        # Lines we can't translate are turned into comments
        printIndentation();
        print "#$line\n";
    }
}

# checks what kind of for statment we have and calls appropriate method
sub forStatement {
  my ($var, $expr, $optional_inline) = @_;
  # check which kind of statement we have
  if ($expr =~ /sys\.stdin/) {
    # stdin
    forStdinStatement($var,$optional_inline);
  } elsif ($expr =~ /range\s*\((.*)\)/) {
    # range
    forRangeStatement($var,$1,$optional_inline);
  } else {
    # can be any expression, such as @array or $dict.keys
    generalForStatement($var, $expr, $optional_inline);
  }
}

# handles for statements where conditional is not a range or a sys.stdin
# eg. for i in (array/keys dict / sorted array) etc
sub generalForStatement {
  my ($var, $expr, $optional_inline) = @_;
  # store the variable
  pushOnto(\@scalars, $var);
  $expr = sanitizeExpression($expr);
  $var = sanitizeExpression($var);
  printIndentation();
  print "foreach $var ($expr) { \n";
  $global_indentation++;

  # if we had inline statements, need to fix indentation and close parenthesis
  if (handleOptionalInline($optional_inline)) {
    $global_indentation--;
    # end by closing the parenthesis
    printIndentation(); print "}\n";
  }
}

# given a python expression, sanitizes it through a range of sub methods
sub sanitizeExpression {
  my $expr = $_[0];
  # 1. replaces invalid operators with valid ones: sanitizeOperators
  # 2. check if we need to fix braces on scalar assignment in dict or list: sanitizeBraces
  # 3. replaces variables,lists and dicts with prefixes: sanitizePrefix
  # 4. replaces method definitions with appropriate syntax: sanitize methods
  # 5. look for instances where we need to sub varibales into string eg. a = "%d" % (7): sanitizeSubstitutions
  $expr = sanitizeSubstitutions(sanitizeMethods(sanitizePrefix(sanitizeBraces(sanitizeOperators($expr)))));
  return $expr;
}

# given an expression, substitutes all instances of invalid methods with appropriate syntax
sub sanitizeMethods() {
  my $expr = $_[0];
  # replace len(@array) with scalar(@array)
  $expr =~ s/len\(@/scalar\(@/g;
  # replace len($scalar) with length($scalar)
  $expr =~ s/len\(/length\(/g;
  #replace sorted(array) w sort(array)
  $expr =~ s/sorted\(/sort\(/g;
  # replace hash.keys() w keys %hash
  $expr =~ s/(%\w+)\.keys\(\)/keys $1/g;
  # replace array.pop w pop(array)
  if ($expr =~ /@(\w+)\.pop\((.*)\)/) {
    my $temp = popStatement($1, $2);
    $expr =~ s/@(\w+)\.pop\((.*)\)/$temp/;
  }
  # replace array.append w push(array)
  if ($expr =~ /@(\w+)\.append\((.*)\)/) {
    my $temp = appendStatement($1, $2);
    $expr =~ s/@(\w+)\.append\((.*)\)/$temp/;
  }
  return $expr;
}

# handles the pop method
sub popStatement {
  my ($array_ref, $var) = @_;
  #add the list to our array of known lists (even though if we are popping, its likely we've seen it before)
  pushOnto(\@lists, $array_ref);
  printIndentation();
  $array_ref = sanitizeExpression($array_ref);
  # check if we have a variable indicating index eg. pop(x) or popping final elem
  if ($var eq '') {
    return "pop($array_ref)"
  } else {
    # clean up whatever is being pushed as it could be an expression
    $var = sanitizeExpression($var);
    # there is no pop at index in perl, so we must splice the array
    return "splice($array_ref, $var, 1)";
  }
}

# handles the append method
sub appendStatement {
  my ($array_ref, $var) = @_;
  #add the list to our array of known lists
  pushOnto(\@lists, $array_ref);
  # clean up whatever is being pushed as it could be an expression
  $var = sanitizeExpression($var);
  $array_ref = sanitizeExpression($array_ref);
  printIndentation();
  return "push($array_ref, $var)";
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

# handles for var in sy.stdin
sub forStdinStatement {
  my ($var, $optional_inline) = @_;
  # store the variable
  pushOnto(\@scalars,$var);
  $global_indentation += 1;
  print "foreach \$$var (<STDIN>) { \n";

  # if we had inline statements, need to fix indentation and close parenthesis
  if (handleOptionalInline($optional_inline)) {
    $global_indentation--;
    # end by closing the parenthesis
    printIndentation(); print "}\n";
  }
}

# checks if param is a set of inline statements and handles each appropriately
sub handleOptionalInline {
  my $optional_inline = $_[0];
  # if we have an inline statement such as if(condition):statement; statement;...
  if ($optional_inline) {
    #split them up and handle each
    my @statements = split '\s*;\s*', $optional_inline;
    foreach my $statement (@statements) {
        patternMatch($statement);
    }
    # indicate that we did in fact have inline statements
    return 1;
  }
  # indicate that we didnt have inline statements
  return 0;
}

# handles for var in range()
sub forRangeStatement {
  #for range loop
  my ($var, $range, $optional_inline) = @_;
  # store the variable
  pushOnto(\@scalars,$var);
  printIndentation();
  # check whether it is a range(x) or a range(x, y)
  if ($range =~ /(.+)\s*,\s*(.+)/) {
    # bounds can be expressions, evaluate and print
    my $lower = sanitizeExpression($1);
    my $upper = sanitizeExpression($2);
    print "foreach \$$var ($lower..$upper - 1) {\n";
  } elsif ($range =~ /^\s*(.+)\s*$/) {
    # bound can be expression, evaluate it and print
    my $upper = sanitizeExpression($1);
    print "foreach \$$var (0..$upper - 1) {\n";
  }
  $global_indentation++;
  # if we had inline statements, need to fix indentation and close parenthesis
  if (handleOptionalInline($optional_inline)) {
    $global_indentation--;
    # end by closing the parenthesis
    printIndentation(); print "}\n";
  }
}

# applied to an expression. replaces a//b with int(a/b)
sub sanitizeOperators {
  my $expr = $_[0];
  #while we have an invalid // operator, swap it
  while ($expr =~ /((\w+)\s*\/\/\s*(\w+))/) {
    my $full = $1; my $divisor1 = $2; my $divisor2 = $3;
    $expr =~ s/$full/int($divisor1\/$divisor2)/g;
  }
  return $expr;
}

#used to handle if and while statments
sub conditionalStatement {
  #loops are in the format if/while(condition): optional_inline; optional_inline ...
  #type is either "while" or "if"
  my ($condition, $optional_inline, $type) = @_;

  printIndentation();

  $condition = sanitizeExpression($condition);
  # print if (condition) or while(condition)
  print "$type ($condition) {\n";
  $global_indentation++;

  # if we had inline statements, need to fix indentation and close parenthesis
  if (handleOptionalInline($optional_inline)) {
    $global_indentation--;
    # end by closing the parenthesis
    printIndentation(); print "}\n";
  }
}

# prints any expression
sub printStatement {
    # prints any expression. first param is content, second indicates if function is being called from match on print, or match on std.out
    my ($print_content, $stdout) = @_;
    printIndentation();
    # if printing nothing. eg print(), print new line and return
    if ($print_content =~ /^\s*$/) {
      print "print \"\\n\";\n";
      return;
    }
    # check if there is a custom end. eg print(..., end = '')
    my $end_exists = endOfPrintExists($print_content);
    # get the custom end regardless of whether it exists.
    my $end = getEndOfPrint($print_content);
    # set end to new line unless there is another one specified, or unless the params tell us we are in sys.stdout
    $end = "\\n" unless ($end_exists or $stdout);
    # cut the end off (if it exists).
    $print_content =~ s/\s*,\s*end.*//g;

    # break the print up in the right way
    # to see how this works, see recursiveSplit()
    my @sub_prints = recursiveSplit($print_content);

    # print each part of the print statement
    my $counter = 0;
    print "print(";
    foreach my $print (@sub_prints) {
      # only put commas and spaces after the first element
      print ", \" \", " unless ($counter == 0);
      # print this part of the print statement
      my $subPrint = sanitizeExpression($print);
      print($subPrint);
      $counter++;
    }
    print ", \"$end\");\n";
}

# since a print statement can be in a complex form like print("%s %s %d" % ("ben", "is", 8), "years old");
# we want to split it up into multiple statements, and handle each individually.
# however performing the split is hard since commas can exist inside ("ben", "is", 8) or inside the string itself
# this function recrusively goes through character by character and splits appropriately, by marking when we are inside a set of brackets or quotes
#example input: "hey there, %s and %s" % ("ben", "michael"), "(nice day), isnt it?"
#example output: ["hey there, %s" % ("ben"), "(nice day), isnt it?"]
sub recursiveSplit {
  # the array to itterate over
  my @char_array = split //, $_[0];
  # booleans if we are able to split or not
  my $inside_parenthesis = 0;
  my $inside_quotes = 0;
  # index used to split the array
  my $index = 0;
  # return value initialized
  my @return_array;
  # used to return the initial strring at the end if nothing was split
  my $found_match = 0;
  foreach my $char (@char_array) {
    # if we have entered a set of parenthesis, cant split
    if ($char eq '(' and $inside_parenthesis == 0) {$inside_parenthesis = 1;}
    # if we have exited a set of parenthesis, can split
    elsif ($char eq ')' and $inside_parenthesis == 1)  {$inside_parenthesis = 0;}
    # if we have entered a set of quotes, cant split
    elsif ($char eq "\"" and $inside_quotes == 0) {$inside_quotes = 1;}
    # if we have exited a set of quotes, can split
    elsif ($char eq "\"" and $inside_quotes == 1)  {$inside_quotes = 0;}

    # if we find a comma and are able to split, do so
    elsif ($char eq ',' and $inside_parenthesis == 0 and $inside_quotes == 0) {
      # mark that we have split
      $found_match = 1;
      # push the begining of the string until the current index onto the return array (minus the comma)
      push @return_array, (join "", (@char_array[0..$index-1]));
      # recursively call the split on the rest of the string, and push onto the return array
      push @return_array, recursiveSplit(join "", @char_array[$index+1..$#char_array]);
      # once we have matched, break
      last;
    }
    $index++;
  }
  # if no split performed, return original string
  return $_[0] unless ($found_match == 1);
  # otherwise return the split
  return @return_array;
}

# checks if the content is of the form " %x " % (var) and subs variables in if so
sub sanitizeSubstitutions {
  my ($print_content) = $_[0];
  # check if we are printing a string
  if ($print_content =~ /^\s*"(.*?)"(.*)/ or $print_content =~ /^\s*'(.*?)'(.*)/) {
      my ($string, $remaining) = ($1, $2);
      # remaining will be in form % (x,y,z), % x, or empty
      # we now assume that there is a % with variables to substitute
      # remove braces surrounding variables (if there are)
      $remaining =~ s/[\(\)]//g;
      # remove % and spacing
      $remaining =~ s/^\s*%\s*//g;
      # if remaining is not empty, we know there are no variables to subsitute
      if ($remaining) {
        # split the variables into a list to be used for subsituton
        my @vars_to_sub = split /\s*,\s*/, $remaining;
        # substitute variables before printing
        $string = subVarsIntoString($string, @vars_to_sub);
      }
      return "\"$string\"";
      # print "\"$string\"";
  } else {
    return $print_content;
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

# performs substitution of variables in array into string. Used for formatting prints such as "%s %d" % ("hey", 5)
sub subVarsIntoString {
  my ($string, @vars_to_sub) = @_;
  # currently doesnt support format matching. simply replaces %anything with variable
  while ($string =~ /(%\w)/) {
    my $symbol = $1;
    # get variable
    my $variable = shift(@vars_to_sub);
    # cut leading and trailing quotes if case string
    $variable =~ s/^['"]//; $variable =~ s/['"]$//;
    # perform swap
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

# handles all assignment statements
sub variableAssignment {
    my ($lhs,$operator, $rhs) = @_;

    $rhs = sanitizeExpression($rhs);
    # if we are assigning to sys.stdin.readlines()
    if ($rhs =~ /sys.stdin.readlines()/){
      readLinesStatement($lhs);
      return;
    }

    # the type of the lhs depends on what is on the rhs. We now go through all the cases

    # declaring a dict
    if ($rhs =~ /^\s*\{(.*)\}\s*$/) {
      # store the dict
      pushOnto(\@dicts, $lhs);
      # change inner and outer braces
      $rhs =~ s/^\s*\{/\(/;$rhs =~ s/\}\s*$/\)/;
      # replace colons with commas
      $rhs =~ tr/:/,/;
      $lhs = sanitizeExpression($lhs);
      print "$lhs $operator $rhs;\n";
    } elsif ($rhs =~ /^\s*\[(.*)\]\s*$/) {
      # if we are declaring a list by providing elements eg [1,2,3]
      # dont print declaration of empty list
      return unless $1;
      # store the list
      pushOnto(\@lists, $lhs);
      # change inner and outer braces
      $rhs =~ s/\[/\(/g;$rhs =~ s/\]/\)/g;
      $lhs = sanitizeExpression($lhs);
      print "$lhs $operator $rhs;\n";
    } elsif ($rhs =~ /sort\(/) {
      # we are declaring a list since rhs returns array
      pushOnto(\@lists, $lhs);
      $lhs = sanitizeExpression($lhs);
      print "$lhs $operator $rhs;\n";
    } else {
      # assigning scalar value
      my $prefix = "\$";

      # check if we are dealing with scalar assignment to hash or array eg. $array[1] = x
      unless ($lhs =~ /(\w+)\[['"]{0,1}\w+['"]{0,1}\]/) {
        pushOnto(\@scalars,$lhs);
      }

      # if stdin, replace rhs with <STDIN>
      if ($rhs =~ /sys.stdin.readline\(\)/) {
        $rhs = "<STDIN>";
      }

      $lhs = sanitizeExpression($lhs);
      print "$lhs $operator $rhs;\n";
    }
}

# replaces hash[x] w hash{x}
sub sanitizeBraces {
  my $expr = $_[0];
  foreach my $dict (@dicts) {
    $expr =~ s/$dict\[(['"]{0,1}\w+['"]{0,1})\]/$dict\{$1\}/g;
  }
  return $expr;
}

# inserts appropriate prefix before known variables in an expression
sub sanitizePrefix {
    my $expr = $_[0];
    # prefix scalars with $
    foreach my $var (@scalars) {
      $expr =~ s/\b$var\b/\$$var/g;
    }
    # prefix indexed arrays with either $/@
    foreach my $var (@lists) {
      # if the sed for a $ doesnt match, must be @
      if (not($expr =~ s/\b$var\[/\$$var\[/g)) {
        $expr =~ s/\b$var\b/\@$var/g;
      }
    }
    # prefix indexed dicts with either $/%
    foreach my $var (@dicts) {
      # if the sed for a $ doesnt match, must be %
      if (not($expr =~ s/\b$var\{/\$$var\{/g)) {
        $expr =~ s/\b$var\b/%$var/g;
      }
    }
    return $expr;
}

#checks if an elem belongs to a list (string names)
sub belongsTo {
  my ($array_ref, $var1) = @_;
  #check if it already exists on the list
  my $exists = 0;
  foreach my $var2 (@$array_ref) {
    $exists = 1 if ($var2 eq $var1);
  }
  return $exists;
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
  # while current indentation does not match where it should be
  while ($global_indentation != $local_indentation) {
    # decrease indentation and print closing brace
    $global_indentation--;
    printIndentation();
    print "}\n";
  }
}
