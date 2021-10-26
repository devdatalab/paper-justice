# masala-merge
Stata/Python code for fuzzy matching of latin script location names in Hindi.

# Requirements

Python 3.2 (may work with other versions)

`$tmp` and `$MASALA_PATH` must be defined. `$tmp` is a folder for
storage of temporary files. `$MASALA_PATH` is the path containing
`lev.py`, included in this package.

# Stata usage (fix_spelling)

`fix_spelling` will magically correct spelling errors in a list of
words, given a master list of correct words.  For example, suppose you
have a dataset with district names, you have a master list of district
names (with state identifiers), and you want to modify your current
district names to match the master key. The following
command will "fix" your misspelled district names:

```
fix_spelling district_name, src(master_district_key.dta) group(state_id) replace
```

`state_id` is a group variable -- districts in state 1 in the open
file will only be fixed based on districts in state 1 in the key
file. With this format, `district_name` and `state_id` both need to
appear in both files. If the variables have different names in the
different datasets, use `targetfield()` and `targetgroup()` to specify
the field and group variables in the using data.

Additional options:

- `gen(varname)` can be used instead of replace
- `targetfield()` and `targetgroup()` can be used if the group or merge
  variable have different names in the master dataset.
- If `keepall` is specified, your dataset will add rows from the
  target list that didn't match anything in your data

Example:

```
. fix_spelling pc01_district_name, src($keys/pc01_district_key) replace group(pc01_state_name) 

[...]

+--------------------------------------------------------------------------------------
| Spelling fixes and levenshtein distances:
+--------------------------------------------------------------------------------------

      +-------------------------------------------+
      | pc01_distri~e         __000000   __0000~t |
      |-------------------------------------------|
  80. |   karimanagar       karimnagar         .2 |
 155. |  mahabubnagar      mahbubnagar         .2 |
 422. |         buxor            buxar        .45 |
 462. |     jahanabad        jehanabad        .45 |
 480. |     khagari a         khagaria        .01 |
      |-------------------------------------------|
 544. |        purnea           purnia        .45 |
 624. |     ahmedabad        ahmadabad        .45 |
 700. |   banaskantha     banas kantha        .01 |
 757. |         dahod            dohad         .8 |
 888. |    panchmahal     panch mahals       1.01 |
      |-------------------------------------------|
 932. |   sabarkantha     sabar kantha        .01 |
 991. |       vadodra         vadodara         .2 |
1490. |         angul           anugul          1 |
1546. |         boudh            baudh        .45 |
1569. |       deogarh         debagarh        1.2 |
      |-------------------------------------------|
1609. | jagatsinghpur   jagatsinghapur         .2 |
1617. |        jajpur          jajapur         .2 |
1674. |        khurda          khordha        .65 |
1722. |   nabarangpur     nabarangapur         .2 |
1922. |    puducherry      pondicherry       1.35 |
      +-------------------------------------------+
```

# Stata usage (masala_merge)

`masala_merge` is the underlying program used by `fix_spelling` and
has more customizable behavior.

Given datasets that already align on state, district and subdistrict
identifiers, the following command will run a fuzzy merge on village
names:

```
masala_merge state_id district_id subdistrict_id using match_data.dta, S1(village_name) OUTfile($tmp/foo)
```

Only one field can be fuzzy matched at a time.

The outfile is a temporary file that will be generated with the full
set of matches. `masala_merge` will create a dataset that
automatically picks the matches that it thinks are best and rejects
the matches that are too ambiguous.

For example, if a match with modified levenshtein distance 0.4 will be
rejected if there is an another possible match with 

Some Additional options:
```
fuzziness(real): Default is 1. Higher numbers generate merges with more
           tolerance for differences. But even 0 will allow some
	   fuzziness.

quietly: Suppress output

keepusing(string): Works like keepusing() in standard merge command

sortwords: Will sort words before running merge
```

# Customizing `masala_merge`

Masala_merge runs a Levenshtein "edit distance" algorithm that counts
the number of insertions, deletions and character changes that are
required to get from one string to another. We have modified the
Levenshtein algorithm to use smaller penalties for very common
alternate spellings in Hindi. For instance "laxmi" and "lakshmi" have
a Levenshtein distance of 3, but a Masala Levenshtein distance of only
0.4.

The low cost character changes are described in a list in `lev.py`. If
you would like to modify this for other languages with other common
spelling inconsistencies, you only need to modify these lists and the
costs associated with each kind of change.
