#!/usr/local/bin/python3
# put your test script here

#need to be able to translate length differently depending on parameter type
@a = (1,(2),(1,2,3));
$my_max = 0;
foreach @a (@a) {
    if (len(@a) > $my_max) {
        $my_max = scalar(@a);
    }
}
