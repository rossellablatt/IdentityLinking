function bigram = GetBigrams(s)

% compute bigrams of a string

bigram{1} = s(1:end);
for i = 1:length(s)-1
    bigram{i} = s(i:i+1);
end