--!strict


-- Scripted by splinestein. My own implementation of the Porter Stemmer Algorithm.


local StringStem = {}


type Rule = {[number]: {[number]: string}}


------------------------------------------------------


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

------------------------------------------------------


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


function StringStem.cv_measure(cv: string) : number
	-- Notation: [C](VC){m}[V]
	local _, count = cv:gsub("VC", "")
	
	return count
end


--[[ 
	Return stem & the modified word.
	
	So how the logic works throughout is as follows:
	
	If S1 is found in the word it removes S1 from the word.
	After that you have the so called "stem".
	
	After that the "stem" is ALWAYS compared to the condition like *v* or
	(m > 1) and only IF the condition is true, S2 gets added to the stem that we have.
	
	By the way... m means measure and the measure are the letters into consonant and vowel
	representation (cv_map)... and measure check checks how many 'VC' occurrences we find.
	
	So we do that check against the stem, not the whole word or the final (modified) result, just the stem.
]]

function StringStem.return_stem(word: string, s1_s2: Rule) : (string, string, boolean)
	for _, rule in ipairs(s1_s2) do
		if word:find(rule[1]) then
			return word:gsub(rule[1], ''), word:gsub(rule[1], rule[2]), true
		end
	end

	return word, word, false
end


------------------------------------------------------


function StringStem.step_1a(word: string) : string
	local _, step_1a_new_word, changed = StringStem.return_stem(word, step_1a_rules)
	
	if changed then
		return step_1a_new_word
	end
	
	return word
end


function StringStem.step_1b(word: string) : string
	local stem, stem_s2_added, changed = StringStem.return_stem(word, step_1b_1_rules)
	
	if changed then
		-- Okay we know that 1 of the rules got applied.
		local stem_cv = StringStem.cv_map(stem)
		local cond = word:find('eed$')
		local measure = StringStem.cv_measure(stem_cv)
		
		if cond and measure > 0 then
			return stem_s2_added
		elseif not cond and stem_cv:find("[V]") then
			return StringStem.step_1b_extra(stem, stem_cv, measure)
		end
	end
	
	return word
end



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


function StringStem.step_1c(word: string) : string
	local stem, stem_s2_added, changed = StringStem.return_stem(word, step_1c_rules)
	
	if changed and StringStem.cv_map(stem):find("[V]") then
		return stem_s2_added
	end

	return word
end


------------------------------------------------------


function StringStem.handle(word: string) : string
	local step_1a = StringStem.step_1a(word)
	local step_1b = StringStem.step_1b(step_1a)
	local step_1c = StringStem.step_1c(step_1b)
	
	return step_1c
end



return StringStem
