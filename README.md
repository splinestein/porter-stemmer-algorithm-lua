# Porter-Stemmer-Algorithm-Lua


## Removes the commoner morphological and inflexional endings from words in English. Its main use is as part of a term normalisation process that is usually done when setting up Information Retrieval systems.

### This is my implementation of the Porter Stemmer Algorithm in Lua according to the documentations.
* Link to module: https://www.roblox.com/library/12135154878/StringStem
* Open sourced here: https://github.com/splinestein/porter-stemmer-algorithm-lua/blob/main/stringstemmodule.lua
* DevForum thread: Coming soon.


### How do you use it?

1) Get the module and put it into ReplicatedStorage.
2) In your script require it with: ```local StringStem = require(game:GetService("ReplicatedStorage"):FindFirstChild("StringStem"))```
3) You will have to tokenize your sentence so every letter is lowercased in a table:  ```print(StringStem.stem({'electrical', 'agreed', 'plastering'}))```


### "Why is the stemmer sometimes not producing proper words?"

"It is often taken to be a crude error that a stemming algorithm does not leave a real word after removing the stem. But the purpose of stemming is to bring variant forms of a word together, not to map a word onto its ‘paradigm’ form."

And connected with this,

### "Why are there errors?"

"The question normally comes in the form, why should word X be stemmed to x1, when one would have expected it to be stemmed to x2? It is important to remember that the stemming algorithm cannot achieve perfection. On balance it will (or may) improve IR performance, but in individual cases it may sometimes make what are, or what seem to be, errors. Of course, this is a different matter from suggesting an additional rule that might be included in the stemmer to improve its performance."


```
Scripting and implementation by splinestein.

Scripted according to the documentation in the 1980 tartarus paper
also taking into account later modernized rule revisions.

-- Porter Stemmer Algorithm. --

"Is a process for removing the commoner morphological and inflexional endings from words in English."
"Its main use is as part of a term normalisation process that is usually done when setting up Information Retrieval systems."

For example the 'full-text search' text retreival technique uses
the process of stemming when constructing search queries for fast data retreival.

New in step_2:
  * new: (m > 0) logi -> log

Replaced in step_2:
  * original:  (m > 0) abli -> able 
  * new:  (m > 0) bli -> ble

Can stem 10,000 words in approximately 83 ms locally on a Ryzen 9 3900X.

----

splinestein documentation:

I've decided to write a simplified documentation since the original documentation
leaves out a lot and is quite complicated to get a hang of.

Stemming is just a way to convert a word like "Helping" to it's root form: "Help".

Examples:

1)   conditional  ->  condition
2)   conflated  ->  conflate
3)   relational  ->  relate
4)   agreed  ->  agree
5)   pony  ->  poni
6)   predication  ->  predic
7)   cease  ->  ceas
8)   electric  ->  electr

IMPORTANT TO NOTE! The algorithm intentionally converts some of the words into weird ones:

Documentation states:

"It is often taken to be a crude error that a stemming algorithm does not leave a real word after removing the stem. 
But the purpose of stemming is to bring variant forms of a word together, not to map a word onto its ‘paradigm’ form."

"The question normally comes in the form, why should word X be stemmed to x1, 
when one would have expected it to be stemmed to x2?"

"It is important to remember that the stemming algorithm cannot achieve perfection.
On balance it will (or may) improve IR performance, but in individual cases it may sometimes make what are, 
or what seem to be, errors. Of course, this is a different matter from suggesting 
an additional rule that might be included in the stemmer to improve its performance."

Some of these rules can look like this:

Examples:

1)   AT -> ATE
2)   (m>0) EED -> EE
3)   (*d and not (*L or *S or *Z)) -> single letter
4)   (m=1 and *o) -> E

The first example has suffix 1 converted to suffix 2. 
In the documentation it's called: S1 -> S2
This means that it checks if word ends with AT and if it does it changes
AT to ATE.

The second example has a condition m, known as "measure" 
which in this case must be greater than 0, then S1 -> S2 conversion is done.

This means that before you convert the S1 to S2 you must check if the
condition is met. To do this, the program checks if the word ends with EED,
if it does it removes EED from the word and we get something known as a "stem".
The stem is checked against the condition.

The way the measure check for the "stem" is done is by first of all converting the
"stem" into letters of vowels and consonant with 1 specific extra rule:

If the letter y (or multiple y's) is / are present in the word it's treated as 
a vowel ONLY IF the letter before the y is a consonant.

To visualize what I mean:

1) word = 'TREE' the output will be: 'CCVV'.
2) word = 'REPLACEMENT' the output will be: 'CVCCVCVCVCC'.
3) word = 'SYZYGY' the output will be: 'CVCVCV'. (letter Y is treated as a vowel here.)
4) word = 'ABAYA' the output will be: 'VCVCV'. (letter Y is treated as a consonant here.)

After this is done, we have another function that 
with the notation of [C](VC){m}[V] that calculates how many occurrences of "VC" it found in the cv string.

Now if the condition is met it will add S2 to the stem. (This rule applies to everything).

Example 3 has some interesting new conditions...

*S  - the stem ends with S (and similarly for the other letters).

*v* - the stem contains a vowel.

*d  - the stem ends with a double consonant (e.g. -TT, -SS).

*o  - the stem ends cvc, where the second c is not W, X or Y (e.g.
       -WIL, -HOP).

I think it's worth mentioning that you shouldn't confuse the * especially in 
*v* to check for stuff inbetween the first and last letters in the stem, 
because *v* means it covers the entire stem. So just keep it simple and check
the entire stem.

So the condition here: (*d and not (*L or *S or *Z)) -> single letter

does the condition of checking *d and not ending with letters L or S or Z...
if the condition is met it removes the last letter in the stem and returns.

Example 4 should be easy to understand now.
It adds letter E to the stem if the condition is met.


All in all the Porter Stemmer Algorithm has 5 different steps to stem a word.

These steps sometime include 'extra' steps to process words based on some of the
rules / conditions.

For example in Step 1b it does an extra check (check the tartarus documentation for that).

The rules are iterated through per individual step. Just because a word gets stemmed in step 1
does not mean it won't get stemmed later in say step 4. That is why the program must take the
word through all the 5 steps and only then return back to the user.

For example the word agreed converts to agree and then later to agre, this is completely normal. 
```
