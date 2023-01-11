--!strict


local StringStem = {}


type Rule = {[number]: {[number]: string}}


local step_1a_rules: Rule = {
	{"sses$", "ss"},
	{"ies$", "i"},
	{"ss$", "ss"},
	{"s$", ""},
}


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


function StringStem.return_stem(word: string, s1_s2: Rule) : string
	for _, rule in ipairs(s1_s2) do
		if word:find(rule[1]) then
			return word:gsub(rule[1], rule[2])
		end
	end

	return word
end


function StringStem.handle(word: string) : string
	local step_1a = StringStem.return_stem(word, step_1a_rules)
	
	return word, step_1a
end



return StringStem
