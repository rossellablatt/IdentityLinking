function DiceCoefficient = FastDiceCoefficient(  Target, big_key, N_big_key)

% Extract individual words from target string
words2 = GetSingleWords(Target);
% for each word, find all bigrams
bigrams2 = cellfun(@GetBigrams, words2, 'UniformOutput',0);
% put them together into one cell
big2 = [];
for b = 1:numel(bigrams2)
    big2 = [big2, bigrams2{b}];
end
% Compute Dice Coefficient
DiceCoefficient = sum([ismember(big2,big_key), ismember(big_key,big2)])/(N_big_key + numel(big2));