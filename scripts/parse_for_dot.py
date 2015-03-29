#!/user/bin/env python


#Created by David Streett
#Used to create family tree charts of creatures
#output expected
#creature inheritence
#then #s with creatures location (old code)

import os
import sys


def main():

    f = open(sys.argv[1], "r");
    
    #stict is imposed to keep each generation in its own row    
    print " strict graph { "
    print 'graph [ranksep="3"]'

    for e in f.readlines():
        if (e[0] != '#'):
            l = e.split('.');
            for x in range(0, len(l)-1):
                print l[x] + " -- " +  l[x+1]

            if (len(l) - 1 == 0):
                print l[0]
        else:
            if (e[1] == 'G'):
                generation = int(e.split('\t')[1])
            else:
                image_node(e, generation);

    print " } "

def image_node(e, gen):
    
    #removes pound sign and new line
    e = e[1::]
    e = e[:-1];

    #in l it contains creature number, x location, y location
    #x and y locations aren't used any more
    l = e.split("\t");
    image = "c" + str(l[0]) + ".png"

    #might need to change the path to something else c[0-9]+.png
    os.system("./convert " + "../" + image + " -resize 100X100 " + image)

    print str(l[0]) + ' [label="",shape=none, image="' + image + '"]'
    
main()
