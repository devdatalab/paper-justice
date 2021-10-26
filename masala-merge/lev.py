import pdb
import time
import io
import os

#!/usr/bin/python
# implementation of levenshtein for matching indian names
''' Calculates the Levenshtein distance of 2 strings'''

import csv
from optparse import OptionParser
import sys
from datetime import datetime

def parse_options():

    # PARSE COMMAND LINE
    parser = OptionParser()
    
    parser.add_option("-d", "--distance", dest="distance",
                      help="Maximum Masala-Levenshtein distance to calculate", metavar="DIST")
    
    parser.add_option("-1", "--file1", dest="file1",
                      help="First source csv file to match", metavar="FILE")
    
    parser.add_option("-2", "--file2", dest="file2",
                      help="Second source csv file to match", metavar="FILE")
    
    parser.add_option("-o", "--output_file", dest="outfile",
                      help="Output csv file", metavar="FILE")
    
    parser.add_option("-s", "--sorted", dest="sorted", action="store_true",
                      help="sort words in strings (can take 2x time)")

    (options, args) = parser.parse_args()
    
    if not options.outfile or not options.file1 or (options.file2 and not options.distance):
        parser.print_help()
        sys.exit()
    
    if options.file2:
        options.distance = float(options.distance)   # don't calculate distances greater than this.
        options.file2 = os.path.expanduser(options.file2)

    # expand username for all filenames
    options.outfile = os.path.expanduser(options.outfile)
    options.file1 = os.path.expanduser(options.file1)
    
    return options

# function to sort words in string. any 3-letter words or less at back of string are left unsorted
def sort_words(string):

    # split string on words
    word_list = string.split()

    # get # of words to sort -- don't want <= 3 letter words at end.
    count = 0
    sort_count = 0
    for word in word_list:

        # if word is longer than 3, sort at least this far
        # don't sort final words beginning with a digit either
        if len(word) > 3 and word[0] not in range(0,9):
            sort_count = count

        count += 1

    # sort the first sort_count words in the string
    new_string = " ".join(sorted(word_list[0:sort_count + 1]))

    # append unsorted words to the string if there are any
    if sort_count < (len(word_list) - 1):
        new_string += " " + " ".join(word_list[sort_count+1:])

    return new_string

# confirm that we got the command line right
# print options

# function to read a data file in the following format:
# ID, "string"
def read_id_string_data(filename):

    # open and read data file -- ignore unicode errors -- non-unicode characters will be removed
    f = io.open(filename, encoding='utf8', errors='ignore')

    csv = f.readlines()
    f.close()
    g = {}

    # loop over each csv line
    for line in csv:

        line = line.strip()

        # get comma position
        c1 = line.find(',')

        # get 2 words: group id and string to lev match
        group_id = line[0:c1]
        string = line[c1+2:-1]

        # create the group_id dictionary entry if it doesn't exist yet
        if group_id not in g:
            g[group_id] = []

        # and add the string to be matched to the dictionary
        g[group_id].append(string)

    # return dictionary
    return g

def print_matrix(m):
    print(' ')
    for row in m:
        print("")
        for item in row:
            sys.stdout.write("%5s," % str(item) )
    print(' ')


# specify single-letter pairs that have a low cost match.
# specify each one twice, i.e. both directions so can be a fast lookup
pair_1to1 = set(['UW', 'WU', 'DT', 'TD', 'AE', 'AI', 'AO', 'AU', 'EA', 'EI', 'EO', 'EU', 'IA', 'IE', 'IO', 'IU', 'OA', 'OE', 'OI', 'OU', 'UA', 'UE', 'UI', 'UO', 'SZ', 'ZS', 'BV', 'VB', 'OW', 'WO', 'YI', 'IY', 'RD', 'DR', 'CK', 'KC', 'CS', 'SC', 'GJ', 'JG', 'ZJ', 'JZ', 'XZ', 'ZX', 'XS', 'SX', 'XJ', 'JS', 'SZ', 'ZS', 'KQ', 'QK', 'WV', 'VW', 'BV', 'VB', 'PF', 'FP'])

# 2to2 lists mean cheap processing of character transposition
pair_2to2 = set(['EV', 'EO', 'CK', 'KC', 'KQ', 'QK', 'PF', 'FP', 'GJ', 'JG', 'BV', 'VB', 'VW', 'WV', 'BW', 'WB', 'JZ', 'ZJ', 'XZ', 'ZX', 'XS', 'SX', 'ZS', 'SZ', 'SC', 'CS', 'YU', 'UY', 'AU', 'UA', 'EU', 'UE', 'IU', 'UI', 'IO', 'OI'])

# 2to1
pair_2to1_list = ['O-OW', 'U-UW', 'U-OO', 'E-IY', 'I-IY', 'X-KS', 'E-EE' , 'O-OO', 'S-SC' , 'X-XC', 'I-EE', 'A-YA']

# dictionary for cheap single letter omissions. spaces are free, but non-zero to avoid duplication problems.
pair_1to0 = {'A':0.2, 'H':0.2, 'N':0.45, ' ': 0.01, '(': 0.01, ')': 0.01 }

cost_swap = 0.45
cost_1to1 = 0.45
cost_2to2 = 0.2
cost_2to1 = 0.2
cost_double_letter = 0.1

# specify additional penalty for mismatched digits. (so village1 doesn't match village2)
digit_cost = 1.5

# other potential rules
# - N + consonant -> consonant
# - first letter wrong = cost 1.5

# N+consonant -> consonant: .25
# nb nc nd nf ng nh -> 0.8?

# INSERT / DELETE COSTS
# W/Y -> 0.5


# initialize 2 to 1 matching dictionary
# format is [single-letter] -> [first of double-letter] -> [list of second of double-letter]
pair_2to1 = {}

# convert 2-to-1 list into a dictionary:
for item in pair_2to1_list:

    if item[0] not in pair_2to1:
        pair_2to1[item[0]] = {}

    if item[2] not in pair_2to1[item[0]]:
        pair_2to1[item[0]][item[2]] = []

    if item[3] not in pair_2to1[item[0]][item[2]]:
        pair_2to1[item[0]][item[2]].append(item[3])


#
def update_matrix(matrix, row, col, value):
    if row >= len(matrix) or col >= len(matrix[0]): return
    if matrix[row][col] > value: matrix[row][col] = value

# internet levensthein
def levenshtein(str1, str2):

    # if one string is empty, return the length of the other string
    if not str1.strip(): return len(str2)
    if not str2.strip(): return len(str1)
    
    s1 = str1 + " "
    s2 = str2 + " "

    l1 = len(s1)
    l2 = len(s2)

    # initialize matrix with worst case.
    matrix = [list(range(l1 + 1))] * (l2 + 1)
    for c2 in range(l2 + 1):
        matrix[c2] = list(range(c2,c2 + l1 + 1))
    
    # loop over each row
    for c2 in range(0,l2):

        # store minimum distance in this row
        min_dist = options.distance

        # loop over each column
        for c1 in range(0,l1):

            # update minimum distance if this is lower than current minimum
            if matrix[c2][c1] < min_dist: min_dist = matrix[c2][c1]

            # adjust right step, down step (characters dropped), and right-down step (character substitution)
            update_matrix(matrix, c2+1, c1, matrix[c2][c1] + 1)
            update_matrix(matrix, c2, c1+1, matrix[c2][c1] + 1)
            update_matrix(matrix, c2+1, c1+1, matrix[c2][c1] + 1)

            # if this position is a match
            if s1[c1] == s2[c2]:

                # set down-right cell to minimum of (right + 1, down + 1, this cell)
                update_matrix(matrix, c2+1, c1+1, matrix[c2][c1])

            # cheaper right step if c1 is in pair_1to0
            if s1[c1] in pair_1to0:
                update_matrix(matrix, c2, c1+1, matrix[c2][c1] + pair_1to0[s1[c1]])

            # cheaper down step if c2 is in pair_1to0
            if s2[c2] in pair_1to0:
                update_matrix(matrix, c2+1, c1, matrix[c2][c1] + pair_1to0[s2[c2]])

            # if the letters are close
            if (s1[c1] + s2[c2]) in pair_1to1:

                # pay 1to1 cost in right-down cell.
                update_matrix(matrix, c2+1, c1+1, matrix[c2][c1] + cost_1to1)

            # tricky part, if we find a match in the 2to1 list, adjust a knight's move number.
            # this is separate from the other if block, since it doesn't affect the diagonal square.
            if c1 < (l1-0) and c2 < (l2-1) and s1[c1] in pair_2to1 and s2[c2] in pair_2to1[s1[c1]] and s2[c2+1] in pair_2to1[s1[c1]][s2[c2]]:

                # jump to 1 step right, 2 steps down
                update_matrix(matrix, c2+2, c1+1, matrix[c2][c1] + cost_2to1)

            # now check for a matching pair_ going the other way
            if c2 < (l2-0) and c1 < (l1-1) and s2[c2] in pair_2to1 and s1[c1] in pair_2to1[s2[c2]] and s1[c1+1] in pair_2to1[s2[c2]][s1[c1]]:

                # jump to 1 step down, 2 steps right
                update_matrix(matrix, c2+1, c1+2, matrix[c2][c1] + cost_2to1)

            # check for character position swap, and adjust +2,+2 matrix location
            if c2 < (l2-1) and c1 < (l1-1) and ((s1[c1] + s1[c1 + 1]) == (s2[c2+1] + s2[c2])):

                # if in cheap list, do it cheaply
                if (s1[c1] + s1[c1 + 1]) in pair_2to2:
                    update_matrix(matrix, c2+2, c1+2, matrix[c2][c1] + cost_2to2)

                else:
                    update_matrix(matrix, c2+2, c1+2, matrix[c2][c1] + cost_swap)

            # if single letter matches a double letter, low cost knight's move (1 right 2 down)
            if c1 < (l1-0) and c2 < (l2-1) and s1[c1] == s2[c2] and s1[c1] == s2[c2+1]:
                update_matrix(matrix, c2+2, c1+1, matrix[c2][c1] + cost_double_letter)

            # ditto, 1 down 2 right
            if c1 < (l1-1) and c2 < (l2-0) and s1[c1] == s2[c2] and s1[c1+1] == s2[c2]:
                update_matrix(matrix, c2+1, c1+2, matrix[c2][c1] + cost_double_letter)

        # if the lowest distance is too large, exit
        if min_dist >= options.distance: return options.distance

    return matrix[l2][l1]


# possible modifications
# 1:1 substitutions:

#  x replacement is diagonal. so each time, could test for a close
#    letter and pay a smaller diagonal cost

#  x replacing 1 letter for two, use a knight's move.

#  x 2-for-2?  same strategy should work

#  x add character swap as single operation

# x save time by quitting if minimum distance in a row is > X.

# KENISTON'S RULES

  # TRANSPOSITION COSTS
  # swap two vowels in valid vowel pair list [au, eu, iu, io] : cost is 0.15
  # swap vowel with consonant: cost is 0.25
  # swap vowel with R: 0.15
  # swap two consonants: 0.35
  
  # INSERT / DELETE COSTS
  # W/Y -> 0.5
  
  # SUBSTITUTION COSTS
  # base cost: 1
  # vowels in valid list: 0.25
  # # -> ! and vice versa? : 0.05
  # "YI" "IY" "RD" "DR" "CK" "KC" "CS" "SC" "GJ" "JG" "ZJ" "JZ" "XZ" "ZX" "XS" "SX" "XJ" "JS" "SZ" "ZS" "KQ" "QK" "WV" "VW" "BV" "VB" "PF" "FP" : 0.25
  # "KQ" "QK" "WV" "VW" "BV" "VB" "PF" "FP" : 0.15
  
  # another substituion or translation list:
  # "CK" "KC" "KQ" "QK" "PF" "FP" "GJ" "JG" "BV" "VB" "VW" "WV" "BW" "WB" "JZ" "ZJ" "XZ" "ZX" "XS" "SX" "ZS" "SZ" "SC" "CS" "YU" "UY"
  
  # char list + H
  # N + consonant = consonant
  
  # INSERT / DELETE COSTS
  # W/Y -> 0.5


###############################################################################

#calculates additional cost of comparison between two string.
#returns additional cost
def digit_compare(string1, string2):

    first_digits = "" #empty string for digits found in first
    second_digits = "" #empty string for digits found in second

    # compares all letters and digits in first and separates the digits into first_digits
    for i in string1:

        # if this is a digit (ascii value between 48 and 57)
        if ord(i) >= 48 and ord(i) <= 57:
            first_digits += i

    # repeat process for string2
    for i in string2:
        if ord(i) >= 48 and ord(i) <= 57:
            second_digits += i

    # run levenshtein again on just the digit strings
    digit_penalty = digit_cost * levenshtein(first_digits, second_digits)

    # return digit penalty
    return digit_penalty

###############################################################################
# many-to-many merge on two files, each a list of unique ids and strings
#              Produces a new file with file1, file2, lev_dist
def two_file_match(options):

    # print start timestamp
    print(datetime.now())
    sys.stdout.write("Reading data files...")

    print([options.file1, options.file2])

    dict1 = read_id_string_data(options.file1)
    dict2 = read_id_string_data(options.file2)

    print("Calculating edit distances... ")

    # open output file
    foutput = open(options.outfile, 'w')
    if not foutput:
        print("Could not open output file")
        die()

    # put some things in place for time estimation
    start_time = time.time()

    # calculate total number of comparisons to be done
    total_comps = 0
    for group_id in sorted(dict1.keys()):
        if group_id in dict2:
            total_comps += len(dict1[group_id]) * len(dict2[group_id])
    finished_comps = 0

    # loop over each group
    count = len(dict1.keys())
    i = 0

    for group_id in sorted(dict1.keys()):

        # update counter
        i += 1

        time_passed = time.time() - start_time
        time_est = float(time_passed / (finished_comps + 1)) * float((total_comps - finished_comps))

        # verify this group appears in both datasets
        if group_id not in dict2: continue

        # count the total number of comparisons to be done
        comps = len(dict1[group_id]) * len(dict2[group_id])

        print("%8.2f min: Group %4d/%d (%6d comparisons, %6.1f minutes remaining)" % (float(time_passed)/60, i, count, comps, float(time_est)/60))

        for word1 in dict1[group_id]:
            for word2 in dict2[group_id]:

                # calculate lev distance
                lev_dist = levenshtein(word1.strip().upper(), word2.strip().upper())

                # double cost of first letter mismatch
                if word1[0] != word2[0]:
                    lev_dist += levenshtein(word1[0].upper(), word2[0].upper())

                # raise cost for digit substitutions
                lev_dist += digit_compare(word1, word2)

                # if sorted flag, repeat with sorted words
                if options.sorted:
                    sorted1 = sort_words(word1)
                    sorted2 = sort_words(word2)

                    # only go to levenshtein if words are different
                    if sorted1 != word1 or sorted2 != word2:

                        # now repeat what we did above
                        sorted_lev_dist = levenshtein(sorted1.strip().upper(), sorted2.strip().upper())
                        if sorted1[0] != sorted2[0]:
                            sorted_lev_dist += levenshtein(sorted1[0].upper(), sorted2[0].upper())
                        sorted_lev_dist += digit_compare(sorted1, sorted2)

                        lev_dist = min(sorted_lev_dist, lev_dist)

                # add a line to outfile with the distance
                # print('"%s", "%s", %d' % (word1, word2, lev_dist) )
                if lev_dist < options.distance:
                    foutput.write('"%s", "%s", "%s", %5.2f\n' % (group_id, word1, word2, lev_dist) )

        # record how many comparisons are finished
        finished_comps += comps

    foutput.close()

    # print end timestamp
    print(datetime.now())

###############################################################################
# read a list of word pairs and produce an output file with edit distances
def lev_calc(options):

    f = io.open(options.file1, 'rt', encoding='utf8', errors='ignore')
    if not f:
        print("ERROR: COULD NOT OPEN INPUT FILE")
        die()

    output_list = []
    reader = csv.reader(f)

    for row in reader:
        group = row[0]
        lev_dist = levenshtein(row[1].strip().upper(), row[2].strip().upper())
        output_list.append([group, row[1], row[2], str(lev_dist)])

    # open output file
    foutput = open(options.outfile, 'w')
    if not foutput:
        print("Could not open output file")
        die()

    # write the matrix to a csv file
    foutput.write("_row_number, _masala_word1, _masala_word2, _masala_dist\n")
    for row in output_list:
        foutput.write( '"' + '","'.join(row) + '"\n' )
        # sys.stdout.write( '"' + '","'.join(row) + '"\n' )

    foutput.close()

##########
# MAIN  ##
##########

options = parse_options()

# run two file match if two files submitted
if options.file2:
    two_file_match(options)

else:
    options.distance = 1000
    lev_calc(options)
