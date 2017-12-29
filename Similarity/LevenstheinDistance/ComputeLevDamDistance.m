function NormalizedLevensthein = ComputeLevDamDistance(Target, key, Nk)

% ComputeLevDamDistance computes the Levensthein distance between string
% key and string Target.  
% The distance is the number of deletions, insertions, or substitutions 
% required to transform key into target.
% The distance is then normalized with the max total length of the two strings

Nt = numel(Target);

% initialize distance matrix
d = zeros(Nt+1,Nk+1);

% create matrix of transformation
d(1,:) = 0:Nk;
d(:,1) = 0:Nt;
for i=2:Nt+1
    for j=2:Nk+1
        if key(j-1) == Target(i-1)
            cost = 0;
        else
            cost = 1;
        end
        d(i,j)=min([ ...
        d(i, j-1) + 1, ...     % deletion
        d(i-1, j) + 1, ...     % insertion
        d(i-1,j-1) + cost ... % substitution
        ]);
        if (i-1)>1 && (j-1)>1 &&  i-1 <= Nk && j-1 <= Nt && key((i-1))==Target((j-1)-1) && key((i-1)-1) == Target(j-1)
            % transposition
            d(i,j) = min([d(i,j), d(i-1,j-1)]);
        end
    end
end
  
% normalize the distance and transform in similarity
NormalizedLevensthein = 1 - (d(Nt+1,Nk+1)/max(Nt, Nk));