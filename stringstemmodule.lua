--!strict


--[[
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
]]

local StringStem = {}


type Rule = {[number]: {[number]: string}}


-- List of S1 -> S2 rules.

local step_1a_rules: Rule = {
	{"sses$", "ss"},
	{"ies$", "i"},
	{"ss$", "ss"},
	{"s$", ""},
}

local step_1b_1_rules: Rule = {
	{"eed$", "ee"},
	{"ed$", ""},
	{"ing$", ""},
}

local step_1b_extra_rules: Rule = {
	{"at$", "ate"},
	{"bl$", "ble"},
	{"iz$", "ize"},
}

local step_1c_rules: Rule = {
	{"y$", "i"},
}

local step_2_rules = {
	{"ational$", "ate"},
	{"tional$", "tion"},
	{"enci$", "ence"},
	{"anci$", "ance"},
	{"izer$", "ize"},
	{"bli$", "ble"},
	{"alli$", "al"},
	{"entli$", "ent"},
	{"eli$", "e"},
	{"ousli$", "ous"},
	{"ization$", "ize"},
	{"ation$", "ate"},
	{"ator$", "ate"},
	{"alism$", "al"},
	{"iveness$", "ive"},
	{"fulness$", "ful"},
	{"ousness$", "ous"},
	{"aliti$", "al"},
	{"iviti", "ive"},
	{"biliti$", "ble"},
	{"logi$", "log"},
}

local step_3_rules: Rule = {
	{"icate$", "ic"},
	{"ative$", ""},
	{"alize$", "al"},
	{"iciti$", "ic"},
	{"ical$", "ic"},
	{"ful$", ""},
	{"ness$", ""},
}

local step_4_rules: Rule = {
	{"al$", ""},
	{"ance$", ""},
	{"ence$", ""},
	{"er$", ""},
	{"ic$", ""},
	{"able$", ""},
	{"ible$", ""},
	{"ant$", ""},
	{"ement$", ""},
	{"ment$", ""},
	{"ent$", ""},
	{"ion$", ""},
	{"ou$", ""},
	{"ism$", ""},
	{"ate$", ""},
	{"iti$", ""},
	{"ous$", ""},
	{"ive$", ""},
	{"ize$", ""},
}

local step_5a_rules: Rule = {
	{"e$", ""},
}


------------------ The algorithms utility functions: ------------------


-- The function cv_map converts the word into a list of consonants and vowels.
function StringStem.cv_map(word: string) : string
	local cv = ''

	for i = 1, #word do
		local c = word:sub(i, i)
		if c:find('[aeiou]') or c == 'y' and cv:sub(#cv, #cv) == 'C' then
			cv ..= 'V'
		else
			cv ..= 'C'
		end
	end

	return cv
end


--[[
	The function cv_measure counts how many 'VC' occurrences we found in the consonant-vowel string. 
	Notation: [C](VC){m}[V] 
]]
function StringStem.cv_measure(cv: string) : number
	local _, count = cv:gsub("VC", "")
	
	return count
end


--[[ 
	The function return_stem goes through all the rules and returns if S1 was found.
	It returns the so called 'stem' of the word, as in it removes the S1 from the word.
	The second return value is the final word; S1 -> S2 conversion.
	The third return value is a bool used to determine if the rule was met, otherwise
	you'd have to ~= the stem with the original word.
]]
function StringStem.return_stem(word: string, s1_s2: Rule) : (string, string, boolean)
	for _, rule in ipairs(s1_s2) do
		if word:find(rule[1]) then
			return word:gsub(rule[1], ''), word:gsub(rule[1], rule[2]), true
		end
	end

	return word, word, false
end


-- A utility function shared by a lot of steps that returns a lot of the core data needed for condition checking.
function StringStem.multi_data(word: string) : (number, string, number)
	local cv = StringStem.cv_map(word)
	local measure = StringStem.cv_measure(cv)
	
	return #word, cv, measure
end


------------------ The algorithms step functions: ------------------


--[[
    SSES -> SS                         classes  ->  class
    IES  -> I                          ponies   ->  poni
                                       ties     ->  ti
    SS   -> SS                         boss     ->  boss
    S    ->                            cats     ->  cat
]]
function StringStem.step_1a(word: string) : string
	local _, step_1a_new_word, changed = StringStem.return_stem(word, step_1a_rules)
	
	if changed then
		return step_1a_new_word
	end
	
	return word
end

--[[
    (m>0) EED -> EE                    feed      ->  feed
                                       agreed    ->  agree
    (*v*) ED  ->                       plastered ->  plaster
                                       sled      ->  sled
    (*v*) ING ->                       motoring  ->  motor
                                       sing      ->  sing
]]
function StringStem.step_1b(word: string) : string
	local stem, stem_s2_added, changed = StringStem.return_stem(word, step_1b_1_rules)
	
	if changed then
		local _, stem_cv, measure = StringStem.multi_data(stem)
		local cond = word:find('eed$')
		
		if cond and measure > 0 then
			return stem_s2_added
		elseif not cond and stem_cv:find("[V]") then
			return StringStem.step_1b_extra(stem, stem_cv, measure)
		end
	end
	
	return word
end


--[[
	If the second or third of the rules in Step 1b is successful, the following
	is done:

	    AT -> ATE                       conflat(ed)  ->  conflate
	    BL -> BLE                       troubl(ed)   ->  trouble
	    IZ -> IZE                       siz(ed)      ->  size
	    (*d and not (*L or *S or *Z))
	       -> single letter
	                                    hopp(ing)    ->  hop
	                                    tann(ed)     ->  tan
	                                    fall(ing)    ->  fall
	                                    hiss(ing)    ->  hiss
	                                    fizz(ed)     ->  fizz
	    (m=1 and *o) -> E               fail(ing)    ->  fail
	                                    fil(ing)     ->  file
]]
function StringStem.step_1b_extra(word: string, cv: string, measure: number) : string
	local _, stem_s2_added, changed = StringStem.return_stem(word, step_1b_extra_rules)

	if changed then
		return stem_s2_added
	else
		local word_len = #word

		if cv:find("CC$") and not word:find("[lsz]$") then
			return word:sub(1, word_len - 1)
		elseif measure == 1 and cv:find("CVC$") and not word:sub(word_len, word_len):find("[wxy]") then
			word ..= 'e'
			return word
		end
	end

	return word
end

--[[
	Step 1c
	    (*v*) Y -> I                    happy        ->  happi
	                                    sky          ->  sky
]]
function StringStem.step_1c(word: string) : string
	local stem, stem_s2_added, changed = StringStem.return_stem(word, step_1c_rules)
	
	if changed and StringStem.cv_map(stem):find("[V]") then
		return stem_s2_added
	end

	return word
end


--[[
	Step 2

	    (m>0) ATIONAL ->  ATE           relational     ->  relate
	    (m>0) TIONAL  ->  TION          conditional    ->  condition
	                                    rational       ->  rational
	    (m>0) ENCI    ->  ENCE          valenci        ->  valence
	    (m>0) ANCI    ->  ANCE          hesitanci      ->  hesitance
	    (m>0) IZER    ->  IZE           digitizer      ->  digitize
	    (m>0) ABLI    ->  ABLE          conformabli    ->  conformable
	    (m>0) ALLI    ->  AL            radicalli      ->  radical
	    (m>0) ENTLI   ->  ENT           differentli    ->  different
	    (m>0) ELI     ->  E             vileli         ->  vile
	    (m>0) OUSLI   ->  OUS           analogousli    ->  analogous
	    (m>0) IZATION ->  IZE           actualization  ->  actualize
	    (m>0) ATION   ->  ATE           predication    ->  predicate
	    (m>0) ATOR    ->  ATE           operator       ->  operate
	    (m>0) ALISM   ->  AL            feudalism      ->  feudal
	    (m>0) IVENESS ->  IVE           decisiveness   ->  decisive
	    (m>0) FULNESS ->  FUL           hopefulness    ->  hopeful
	    (m>0) OUSNESS ->  OUS           callousness    ->  callous
	    (m>0) ALITI   ->  AL            formaliti      ->  formal
	    (m>0) IVITI   ->  IVE           sensitiviti    ->  sensitive
	    (m>0) BILITI  ->  BLE           sensibiliti    ->  sensible
]]
function StringStem.step_2(word: string) : string
	local stem, stem_s2_added, changed = StringStem.return_stem(word, step_2_rules)
	
	if changed then
		if StringStem.cv_measure(StringStem.cv_map(stem)) > 0 then
			return stem_s2_added
		end
	end

	return word
end


--[[
	Step 3

	    (m>0) ICATE ->  IC              triplicate     ->  triplic
	    (m>0) ATIVE ->                  formative      ->  form
	    (m>0) ALIZE ->  AL              formalize      ->  formal
	    (m>0) ICITI ->  IC              electriciti    ->  electric
	    (m>0) ICAL  ->  IC              electrical     ->  electric
	    (m>0) FUL   ->                  hopeful        ->  hope
	    (m>0) NESS  ->                  goodness       ->  good
]]
function StringStem.step_3(word: string) : string
	local stem, stem_s2_added, changed = StringStem.return_stem(word, step_3_rules)

	if changed then
		if StringStem.cv_measure(StringStem.cv_map(stem)) > 0 then
			return stem_s2_added
		end
	end

	return word
end

--[[
Step 4

    (m>1) AL    ->                  revival        ->  reviv
    (m>1) ANCE  ->                  allowance      ->  allow
    (m>1) ENCE  ->                  inference      ->  infer
    (m>1) ER    ->                  airliner       ->  airlin
    (m>1) IC    ->                  gyroscopic     ->  gyroscop
    (m>1) ABLE  ->                  adjustable     ->  adjust
    (m>1) IBLE  ->                  defensible     ->  defens
    (m>1) ANT   ->                  irritant       ->  irrit
    (m>1) EMENT ->                  replacement    ->  replac
    (m>1) MENT  ->                  adjustment     ->  adjust
    (m>1) ENT   ->                  dependent      ->  depend
    (m>1 and (*S or *T)) ION ->     adoption       ->  adopt
    (m>1) OU    ->                  homologou      ->  homolog
    (m>1) ISM   ->                  communism      ->  commun
    (m>1) ATE   ->                  activate       ->  activ
    (m>1) ITI   ->                  angulariti     ->  angular
    (m>1) OUS   ->                  homologous     ->  homolog
    (m>1) IVE   ->                  effective      ->  effect
    (m>1) IZE   ->                  bowdlerize     ->  bowdler
]]
function StringStem.step_4(word: string) : string
	local stem, stem_s2_added, changed = StringStem.return_stem(word, step_4_rules)

	if changed then
		local stem_len, _, measure = StringStem.multi_data(stem)
		local cond = word:find('ion$')
		
		if measure > 1 and cond and stem:sub(stem_len, stem_len):find("[st]") then
			return stem_s2_added
		elseif measure > 1 and not cond then
			return stem_s2_added
		end
	end

	return word
end



--[[
	The suffixes are now removed. All that remains is a little tidying up.

	Step 5a

	    (m>1) E     ->                  probate        ->  probat
	                                    rate           ->  rate
	    (m=1 and not *o) E ->           cease          ->  ceas
]]
function StringStem.step_5a(word: string) : string
	local stem, stem_s2_added, changed = StringStem.return_stem(word, step_5a_rules)
	local stem_len, cv, measure = StringStem.multi_data(stem)

	if changed then
		if measure == 1 and not cv:find("CVC$") then
			return stem_s2_added
		elseif measure > 1 then
			return stem_s2_added
		end
	end

	return word
end

--[[
	Step 5b

	    (m > 1 and *d and *L) -> single letter
	                                    controll       ->  control
	                                    roll           ->  roll
]]
function StringStem.step_5b(word: string) : string
	local word_len, cv, measure = StringStem.multi_data(word)
	
	if measure > 1 and cv:find("CC$") and word:sub(word_len, word_len) == 'l' then
		return word:sub(1, word_len - 1)
	end
	
	return word
end


------------------ The main handle function: ------------------


function StringStem.stem(word: string) : string
	-- Short words are ignored as per documentation.
	if #word > 2 then
		word = StringStem.step_1a(word)
		word = StringStem.step_1b(word)
		word = StringStem.step_1c(word)
		word = StringStem.step_2(word)
		word = StringStem.step_3(word)
		word = StringStem.step_4(word)
		word = StringStem.step_5a(word)
		word = StringStem.step_5b(word)
	end
	
	return word
end


return StringStem
