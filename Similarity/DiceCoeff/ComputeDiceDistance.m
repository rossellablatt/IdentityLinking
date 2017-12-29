function DiceCoefficient = ComputeDiceDistance(key, TargetList)

% Compute Sørensen-Dice coefficient, which computes the intersection of
% n-grams between strings. 

% Extract individual words from key string
words1 = GetSingleWords(key);
% for each word, find all bigrams
bigrams1 = cellfun(@GetBigrams, words1, 'UniformOutput',0);
% put them together into one string
big_key = [];
for b = 1:numel(bigrams1)
    big_key = [big_key, bigrams1{b}];
end
N_big_key = numel(big_key);
% Compute Sørensen?Dice coefficient
DiceCoefficient = cellfun(@(x)  FastDiceCoefficient(x, big_key, N_big_key),TargetList);

