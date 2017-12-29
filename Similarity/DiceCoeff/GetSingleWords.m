function words = GetSingleWords(s)

% extracts single words in a string

space_s = [0 regexp(s,'\s') length(s)+1];
words = cell(1,length(space_s) - 1);
for w = 1:length(space_s)-1
  words{w} = s(space_s(w)+1:space_s(w+1)-1);
end
