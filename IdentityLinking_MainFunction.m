% Entity Matching POC

% Goal: identify pairs of accounts that likely belong to the same customer. 

% Methodology: 
% 1. Load Promo data
% 2. Preprocessing: 
    % a. remove trailing space
    % b. lowercase everything
% 3. Compute Similarities: 
    % a. Boolean distance
    % b. Levensthein distance
    % c. Dice Coefficient
% 4. Compute weigth to assign to each feature based on feature value
% frequency
% 5. Weight each customer/feature similarity by the weight for that feature and customer
% 6. Find rows with similarity score > threshold
% 7. Export results


% Author: Rossella Blatt
% Date: 12/28/2017 

clear 
close all 
clc
multiWaitbar('close all')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% to do: set up connection to db
% for now let's hardcode the file to load

% Import the data: importing december promo data  
[~, ~, data] = xlsread('/Users/rossellab/Documents/Data Products Team/MATLAB/ok/LoadData/PromoDec.xlsx','Sheet1');
data = string(data);
data(ismissing(data)) = '';

% for speed reasons let's limit the analysis to the first 5000 rows. 
% To do: use parallelization
data = data(1:5000,:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Text Preprocessing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

header = data(1,:);
data(1,:) = [];
data_clean = preprocess_data(data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute Similarities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialization
Match_rows = cell(1, size(data_clean,1));
alreadyMatched = [];
multiWaitbar('Finding Matching Customers', 'value',0)
% define threshold for similarity
threshold = 0.6; 
tic
for i = 1: size(data_clean,1) % for each customer
    cust = data_clean(i,:);
    % compute similarty scores for each feature between customer i and all other customers
    SIM{i} = FeaturesSimilarity(cust, data_clean, header);
    % compute similarty score between customer i and all other customers
    % and retrieve rows > threshold
    [Match_rows{i}, SimScore{i}, SimScore_fuzzy{i}, alreadyMatched] = FindMatch(SIM{i}, data_clean, alreadyMatched, header, i, threshold);
    multiWaitbar('Finding Matching Customers', 'value',i/size(data_clean,1))
end
toc

% create cellarray to export to xls
tic
% export_cellarray = ['Similarity Score [0-1]' header];
export_cellarray = ['Match {0,1}' 'Fuzzy Similarity Score [0-1]' header];
for m = 1:numel(Match_rows) % for each customer potentially matched
    if ~isempty(Match_rows{m})
        this_cust = ['!MATCHED!' '1' data(m,:)];
        export_cellarray = ...
            [export_cellarray; ...
            this_cust; ...
            SimScore{m} SimScore_fuzzy{m} data(Match_rows{m},:) ...
            ];
        multiWaitbar('Creating Outoput', 'value',m/numel(Match_rows))
    end
end
toc

% export potentital matches to xls
toExport = cell2table(cellstr(export_cellarray));
filename = ['IdentityMatch_ ' num2str(size(data_clean,1)) '_' strrep(date,'-','_') '.xlsx'];
writetable(toExport,filename) 

% 
% 
% % show general statistics of matches: 
% % number of unique dups found for each customer
% Ndups = cellfun(@length,Match_rows);
% % numebr of unique combs of matched customers
% N_Matches =  sum(~cellfun(@isempty,Match_rows));
% figure; 
% histogram(Ndups)
% title(['Histogram of number of dups per matched customer. Total number of matches: '...
%     num2str(N_Matches) ' (Total # customers: ' num2str(size(data,1)) ')'] );



