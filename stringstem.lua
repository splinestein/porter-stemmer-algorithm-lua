--!strict


--[[
Scripted by splinestein into Lua according to the 
Porter Stemmer algorithm documentation in the 1979 tartarus paper
also taking into account later modernized rule revisions:

New in step_2:
	* new: (m > 0) logi -> log

Replaced in step_2:
	* original:  (m > 0) abli -> able 
	* new:  (m > 0) bli -> ble
]]

--[[
	First of all. Porter Stemmer Algorithm wants build up a string of the word
	where each letter is replaced by a vowel V or a consonant C.

	This has specific rules according to the documentation where
	if the letter y (or multiple y's) is / are present in the word it's treated as 
	a vowel ONLY IF the letter before y is a consonant.
	
	To visualize what I mean:
	
	1) word = 'TREE' the output will be: 'CCVV'.
	2) word = 'REPLACEMENT' the output will be: 'CVCCVCVCVCC'.
	3) word = 'SYZYGY' the output will be: 'CVCVCV'. (letter Y is treated as a vowel here.)
	4) word = 'ABAYA' the output will be: 'VCVCV'. (letter Y is treated as a consonant here.)

	After this, according to the documentation we should find
	how many 'VC' occurances we can find in those final processed strings.
	This however is handled in another function and I'll explain more about that there.
]]

local function consonant_vowel_mapper(word: string) : string
	local CV_string = ''
	local prev_consonant = false
	
	for i = 1, #word do
		local c = word:sub(i, i)
		if c:find("[aeiouAEIOU]") then
			CV_string ..= 'V'
			prev_consonant = false
		elseif c:find("[yY]") then
			if prev_consonant == false then
				CV_string ..= 'C'
			else
				CV_string ..= 'V'
			end
		else
			CV_string ..= 'C'
			prev_consonant = true
		end
	end
	
	return CV_string
end


--[[
	Porter Stemmer Algorithm documentation tells us we should count the "VC"
	occurrences after we have the 'consonant vowel' string, for example: 

	CVCCVC -> 2 "VC" occurrences.
	CVCCVCVCVCC -> 4 "VC" occurrences.

	We want to measure how many "VC" occurrences we can find so we
	can apply it to the conditions presented in the suffix rules. 
]]

local function CV_measure(cv: string) : number
	-- Notation: [C](VC){m}[V]
	
	local _, count = string.gsub(cv, "VC", "")
	return count
end


--[[
	Step 1a does not have any special 'stem' conditions.
	What is meant by 'stem' is everything before the S1 suffix.
	
	S1 -> S2 (Suffix 1 is converted to Suffix 2 as in: SSES -> SS).
	In the other steps we have conditions like: (m > 1) S1 -> S2

	SSES -> SS                         caresses  ->  caress
    IES  -> I                          ponies    ->  poni
                                       ties      ->  ti
    SS   -> SS                         caress    ->  caress
    S    ->                            cats      ->  cat
]]

local function step_1a(word: string) : string	
	local s1_s2 = {
		{"sses$", "ss"},
		{"ies$", "i"},
		{"ss$", "ss"},
		{"s$", ""},
	}
	
	for _, rule in ipairs(s1_s2) do
		if word:find(rule[1]) then
			word = word:gsub(rule[1], rule[2])
			return word
		end
	end

	return word
end


-- Extra step if *v* stem conversion works.
local function vowel_cond_extra(stem: string, new_cv: string) : string
	
	-- We have to measure the stem now:
	local measure = CV_measure(new_cv)
	
	local s1_s2 = {
		{"at$", "ate"},
		{"bl$", "ble"},
		{"iz$", "ize"},
	}

	for _, rule in ipairs(s1_s2) do
		if stem:find(rule[1]) then
			return stem:gsub(rule[1], rule[2])
		end
	end

	if new_cv:find("CC$") and not stem:find("l$") and not stem:find("s$") and not stem:find("z$") then
		-- (*d and not (*L or *S or *Z)) -> single letter
		return stem:sub(1, #stem - 1)
	elseif measure == 1 and new_cv:find("CVC$") and stem:sub(#stem, #stem) ~= 'w' 
		and stem:sub(#stem, #stem) ~= 'x' and stem:sub(#stem, #stem) ~= 'y' then
		-- (m=1 and *o) -> E
		stem ..= 'e'
		return stem
	end

	return stem
end


-- Shared conditional argument function.
local function stem_arg_parse(word: string, s1: string, s2: string, cv: string) : ( string, string )
	return word:gsub(s1, s2), cv:sub(1, #cv - (#s1 - 1))
end


-- Does the *v* stem check, meaning "*v* - the stem contains a vowel."
local function stem_vowel_finder(word: string, s1: string, s2: string, cv: string, which_step) : string
	local stem_of_word, cv = stem_arg_parse(word, s1, s2, cv)
	
	if cv:find("[V]") then
		if which_step == '1b' then
			return vowel_cond_extra(stem_of_word, cv)
		else
			-- Else 1c with: (*v*) Y -> I
			return word:gsub(s1, s2)
		end
	end

	return word
end


--[[ 
	Does the ( m > 0 ) conditional check where 0 is measure.

	If there is a measure check before S1 it means it will 
	check what the length of the stem is if for example: EED was taken from it.
]]
local function stem_measure_checker(word: string, s1: string, s2: string, cv: string, measure : number) : string
	local _, cv = stem_arg_parse(word, s1, s2, cv)
	
	if CV_measure(cv) > measure then
		return word:gsub(s1, s2)
	end

	return word
end


local function step_1b(word: string) : string	
	local cv = consonant_vowel_mapper(word)
	
	if word:find("eed$") then
		-- (m > 0) EED -> EE
		return stem_measure_checker(word, "eed$", 'ee', cv, 0)
	elseif word:find("ed$") then
		-- (*v*) ED  ->
		return stem_vowel_finder(word, "ed$", "", cv, '1b')
	elseif word:find("ing$") then
		-- (*v*) ING ->
		return stem_vowel_finder(word, "ing$", "", cv, '1b')
	end

	return word
end


local function step_1c(word: string) : string
	-- (*v*) Y -> I
	local cv = consonant_vowel_mapper(word)

	return stem_vowel_finder(word, 'y$', 'i', cv, '1c')
end


-- Tests:
local stem_test = {
	'caresses',
	'ponies',
	'ties',
	'caress',
	'cats',
	'tree',
	'trees',
	'feed',
	'bleed',
	'creed',
	'speed',
	'agreed',
	'plastered',
	'bled',
	'motoring',
	'sing',
	'conflated',
	'troubled',
	'sized',
	'hopping',
	'tanned',
	'hissing',
	'fizzed',
	'failing',
	'filing',
	'happy',
	'sky',
}

for _, word in ipairs(stem_test) do
	local word_to_stem = word

	local word_step_1a = step_1a(word_to_stem)
	local word_step_1b = step_1b(word_step_1a)
	local word_step_1c = step_1c(word_step_1b)

	print(word_step_1c, CV_measure(consonant_vowel_mapper(word_to_stem)))
end
