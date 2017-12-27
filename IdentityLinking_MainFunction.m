% Entity Matching POC

% Goal: identify pairs of accounts likely to belong to the same customer. 
% Methodology: 
% 

% TO DO: 
% - add txn features. loop through customers and aggregate txn info (e.g.,
% avg amount sent, number different devices etc.)
% - add info at session level (e.g., ip_address, device etc.): join on transaction_created_session_key
% kyc_status as extra check


% t.transaction_kount_geo_key? 

clear 
close all 
multiWaitbar('close all')
clc


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% to do: set up connection to db
% for now let's hardcode the file to load
% filename = '/Users/rossellab/Documents/Data Products Team/Identity Linking/dupe_accounts (1).csv';
% data = csvimport( filename); 
% clc

% Import the data
[~, ~, data] = xlsread('/Users/rossellab/Documents/MATLAB/IdentityLinking/LoadData/PromoDec.xlsx','Sheet1');
data = string(data);
data(ismissing(data)) = '';

% for now keep the fist 2000 rows for computation reasons. 
data = data(1:5000,:);


% keep only relevant features. for now chosen manually for MVP. 
% data_mvp = GetFeatures(data);
% header = data_mvp(1,:);
% data_mvp = data_mvp(2:end,:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Text Preprocessing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

header = data(1,:);
data(1,:) = [];
data_clean = preprocess_data(data);

% Find unique customer_keys
% key_idx = find(header == 'customer_key');
% [C,ia,ic] = unique(data_clean(:,key_idx));

% Loop through each customer_key
% To do: check: shouldn;t customer_key be unique? why are there some
% instances of equal customer_key but different last name? 
%S = cellfun(@(x) FeaturesSimilarity_cell(x, data_clean(1:1000,:), header), data_clean(1:1000,:));

% initialize match rows
alreadyMatched = [];
Match_rows = cell(1, size(data_clean,1));
multiWaitbar('Finding Matching Customers', 'value',0)
tic
for i = 1: size(data_clean,1) % for each customer
    cust = data_clean(i,:);
    % compute similarty score between customer i and all other customers
    SIM{i} = FeaturesSimilarity(cust, data_clean, header);
    [Match_rows{i}, SimScore{i} alreadyMatched] = FindMatch(SIM{i}, data_clean, alreadyMatched, header, i);
    multiWaitbar('Finding Matching Customers', 'value',i/size(data_clean,1))
end
toc


% show general statistics of matches: 

% number of unique dups found for each customer
Ndups = cellfun(@length,Match_rows);
% numebr of unique combs of matched customers
N_Matches =  sum(~cellfun(@isempty,Match_rows));
figure; 
histogram(Ndups)
title(['Histogram of number of dups per matched customer. Total number of matches: '...
    num2str(N_Matches) ' (Total # customers: ' num2str(size(data,1)) ')'] );


% create cellarray to export to xls
tic
export_cellarray = ['Similarity Score [0-1]' header];
for m = 1:numel(Match_rows) % for each customer potentially matched
    if ~isempty(Match_rows{m})
        this_cust = ['!MATCHED!' data(m,:)];
        export_cellarray = ...
            [export_cellarray; ...
            this_cust; ...
            SimScore{m} data(Match_rows{m},:) ...
            ];
        multiWaitbar('Creating Outoput', 'value',m/numel(Match_rows))
    end
end
toc
% export to xls the potentital matches

%new_header = [header 'flag'];
%A = cellstr([new_header; export_cellarray]);
toExport = cell2table(export_cellarray);
filename = ['IdentityMatch_1000_' strrep(date,'-','_') '.xlsx'];
writetable(toExport,filename) 


        
    







% initialize feature matrix: each row is a pair of customer{i,j} and each column 
% represents the distance between feature n between customer i and j. 
customers_comb = nchoosek(1:size(C,1),2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Feature Matrix of Similarities 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% F(i,j) = similarity of feature j for customer pair i

% Initialize feature matrix
FeatureMatrix = NaN(size(customers_comb,1), 2*size(data_clean,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate distance 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for now convert everything to a string
data_mvp_clean_str = cellfun(@num2str, data_clean, 'UniformOutput', 0);

% for now use a for loop; next version use cellfun or faster method
for i = 1:size(customers_comb,1) % for each pair of customers
    c = 1;
    for j = 1:size(data_mvp_clean_str,2) % for each column
        f1 = data_mvp_clean_str{customers_comb(i,1),j};
        f2 = data_mvp_clean_str{customers_comb(i,2),j};
        [FeatureMatrix(i,c) FeatureMatrix(i,c+1)] = FeaturesSimilarity(f1, f2, header{j});
        c = c + 2;
    end
    multiWaitbar( 'Computing Feature Matrix of Distances', 'value',i/size(customers_comb,1))
end
multiWaitbar( 'Computing Feature Matrix of Distances',  'close')






% plot histograms
figure
title_dist_str = {'Dice Coeff Distance'; 'Normalized Levensthein Distance'};
for n = 1:10
    subplot(5,2,n)
    hist(FeatureMatrix(:,n),100)
    title(horzcat(replace(header{ceil(n/2)},'_', ' '), ' - ' , title_dist_str{mod(n,2)+1}));
    xlabel('dist')
    grid
end

FeatureMatrix_Lev = FeatureMatrix(:,1:2:end);
FeatureMatrix_Dice = FeatureMatrix(:,2:2:end);

% plot overall scatterplot
figure
[~,ax] = plotmatrix(FeatureMatrix);
title('Scatter Plot - Levensthein AND Dice')
% figure out how to do this programmatically
ax(1,1).YLabel.String = [replace(replace(header{1},'_', ' '),'customer','') '-Lev']; 
ax(2,1).YLabel.String  = [replace(replace(header{1},'_', ' '),'customer','') '-Dice']; 
ax(3,1).YLabel.String  = [replace(replace(header{2},'_', ' '),'customer','') '-Lev'];
ax(4,1).YLabel.String  = [replace(replace(header{2},'_', ' '),'customer','') '-Dice'];
ax(5,1).YLabel.String  = [replace(replace(header{3},'_', ' '),'customer','') '-Lev']; 
ax(6,1).YLabel.String = [replace(replace(header{3},'_', ' '),'customer','') '-Dice'];
ax(7,1).YLabel.String = [replace(replace(header{4},'_', ' '),'customer','') '-Lev']; 
ax(8,1).YLabel.String  = [replace(replace(header{4},'_', ' '),'customer','') '-Dice']; 
ax(9,1).YLabel.String  = [replace(replace(header{5},'_', ' '),'customer','') '-Lev'];
ax(10,1).YLabel.String  = [replace(replace(header{5},'_', ' '),'customer','') '-Dice'];
ax(10,1).XLabel.String  = [replace(replace(header{1},'_', ' '),'customer','') '-Lev']; 
ax(10,2).XLabel.String  = [replace(replace(header{1},'_', ' '),'customer','') '-Dice'];
ax(10,3).XLabel.String  = [replace(replace(header{2},'_', ' '),'customer','') '-Lev']; 
ax(10,4).XLabel.String  = [replace(replace(header{2},'_', ' '),'customer','') '-Dice'];
ax(10,5).XLabel.String  = [replace(replace(header{3},'_', ' '),'customer','') '-Lev']; 
ax(10,6).XLabel.String  = [replace(replace(header{3},'_', ' '),'customer','') '-Dice'];
ax(10,7).XLabel.String  = [replace(replace(header{4},'_', ' '),'customer','') '-Lev']; 
ax(10,8).XLabel.String  = [replace(replace(header{4},'_', ' '),'customer','') '-Dice'];
ax(10,9).XLabel.String  = [replace(replace(header{5},'_', ' '),'customer','') '-Lev']; 
ax(10,10).XLabel.String  = [replace(replace(header{5},'_', ' '),'customer','') '-Dice'];


% plot scatterplot splitting by distances
figure
[~,ax] = plotmatrix(FeatureMatrix_Lev);
title('Scatter Plot - Levensthein Distance')
% figure out how to do this efficiently
ax(1,1).YLabel.String = replace(replace(header{1},'_', ' '),'customer',''); 
ax(2,1).YLabel.String  = replace(replace(header{2},'_', ' '),'customer',''); 
ax(3,1).YLabel.String  = replace(replace(header{3},'_', ' '),'customer',''); 
ax(4,1).YLabel.String  = replace(replace(header{4},'_', ' '),'customer',''); 
ax(5,1).YLabel.String  = replace(replace(header{5},'_', ' '),'customer',''); 
ax(5,1).XLabel.String = replace(replace(header{1},'_', ' '),'customer',''); 
ax(5,2).XLabel.String  = replace(replace(header{2},'_', ' '),'customer',''); 
ax(5,3).XLabel.String  = replace(replace(header{3},'_', ' '),'customer',''); 
ax(5,4).XLabel.String  = replace(replace(header{4},'_', ' '),'customer',''); 
ax(5,5).XLabel.String  = replace(replace(header{5},'_', ' '),'customer',''); 

% plot scatterplot
figure
[~,ax] = plotmatrix(FeatureMatrix_Dice);
title('Scatter Plot - Dice Coefficient')
% figure out how to do this efficiently
ax(1,1).YLabel.String = replace(replace(header{1},'_', ' '),'customer',''); 
ax(2,1).YLabel.String  = replace(replace(header{2},'_', ' '),'customer',''); 
ax(3,1).YLabel.String  = replace(replace(header{3},'_', ' '),'customer',''); 
ax(4,1).YLabel.String  = replace(replace(header{4},'_', ' '),'customer',''); 
ax(5,1).YLabel.String  = replace(replace(header{5},'_', ' '),'customer',''); 
ax(5,1).XLabel.String = replace(replace(header{1},'_', ' '),'customer',''); 
ax(5,2).XLabel.String  = replace(replace(header{2},'_', ' '),'customer',''); 
ax(5,3).XLabel.String  = replace(replace(header{3},'_', ' '),'customer',''); 
ax(5,4).XLabel.String  = replace(replace(header{4},'_', ' '),'customer',''); 
ax(5,5).XLabel.String  = replace(replace(header{5},'_', ' '),'customer',''); 


% plot bivariate histograms (flat view)
figure
k = 1;
for n = 1:size(FeatureMatrix_Lev,2)
    for i = 1:size(FeatureMatrix_Lev,2)
        subplot(5,5,k)
        h = histogram2(FeatureMatrix_Lev(:,n), FeatureMatrix_Lev(:,i),'DisplayStyle','tile');
        if i == 1
            ylabel(replace(replace(header{n},'_', ' '),'customer',''))
        elseif n == size(FeatureMatrix_Lev,2)
            xlabel(replace(replace(header{i},'_', ' '),'customer',''))
        end
        k = k +1;
    end
end

figure
k = 1;
for n = 1:size(FeatureMatrix_Dice,2)
    for i = 1:size(FeatureMatrix_Dice,2)
        subplot(5,5,k)
        h = histogram2(FeatureMatrix_Dice(:,n), FeatureMatrix_Dice(:,i),'DisplayStyle','tile');
        if i == 1
            ylabel(replace(replace(header{n},'_', ' '),'customer',''))
        elseif n == size(FeatureMatrix_Dice,2)
            xlabel(replace(replace(header{i},'_', ' '),'customer',''))
        end
        k = k +1;
    end
end

% find outliers: for now defined as 4 and 5std from mean. To do: better
% weighting and outlier definition
outliers_by_feature = find(FeatureMatrix > nanmean(FeatureMatrix,1) + 5*nanstd(FeatureMatrix));
% non-weigthed mean of horizontal sum
outliers_by_custpair = find(FeatureMatrix > nanmean(FeatureMatrix,2) + 4*nanstd(FeatureMatrix')');

outliers = union(outliers_by_feature, outliers_by_custpair,'rows');

r = 1;
for i = 1:length(outliers) % for each outlier
    [row col] = ind2sub(size(FeatureMatrix), outliers(i));
    cust_pair1(i,:) = customers_comb(row,:);
    Dups(r,:) = data_mvp_clean_str(customers_comb(row,1),:);
    Dups(r+1,:) = data_mvp_clean_str(customers_comb(row,2),:);
    Dups(r+2,:) = num2cell(FeatureMatrix(row,1:2:end));
    Dups(r+3,:) = num2cell(FeatureMatrix(row,2:2:end));
    r = r + 4;
end

Dups(1:10,:)

% write output to xls
xlswrite('PossibleEntityMatches.xls',Dups)

% for i = 1:length(outliers_by_custpair) % for each outlier
%     [row col] = ind2sub(size(FeatureMatrix), outliers_by_custpair(i));
%     cust_pair2(i,:) = customers_comb(row,:);
% end

 

% Angle between te two vectors
% CosTheta = dot(u,v)/(norm(u)*norm(v))

