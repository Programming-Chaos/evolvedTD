#!/usr/bin/env bash


#start processing and pipe all output to text file
processing > output_text_for_python_parser.txt


#if errors were thrown clean up the top part of the text file
#once that is finished and you have stoped the program
python ./parse_for_dot.py output_test_for_python_parser.txt > dot_language_for_tree.dot


#now just execute dot (aka graphwiz)
#-T (then type) [we are outputing to png file (could be ps, pdf, gif . . . )
./dot -Tpng dot_language_for_tree.dot -o tree_of_creatures.png


#Let me know if you have any questions or there is a bug somewhere in the code
