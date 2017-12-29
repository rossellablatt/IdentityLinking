function NormalizedLevensthein = ComputeLevDist(key, TargetList)

% Compute Levensthein distance between string key and cellstr TargetList
% using cellfun to speedup computation

Nk = numel(key); 
NormalizedLevensthein = cellfun(@(x) ComputeLevDamDistance(x, key, Nk), TargetList);