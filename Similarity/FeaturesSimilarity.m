function SIM = FeaturesSimilarity(cust, data, header)

% Compute similarity of each feature between customer cust and all other
% customers
% to do: move code to find indexes outside of function (no need to recompute every
% time)

% 3 types of distances are considered: boolean comparison, levensthein and dice

% initialize similarity matrix
SIM = zeros(size(data));

% BOOLEAN COMPARISON
% for these features we are interested in a boolean comparison (either they
% match or not. the distance for these features is not meaningful)
bool_features = {'date_of_birth_date_key', 'mobile_number', ...
    't.transaction_kount_geo_key', 't.transaction_kount_device_key',...
    'rec.receiver_key', 'rec.receiver_mobile_number', ...
    'r.device_1', 'r.l4ssn'};
Match_bool = cellfun(@(x) ismember(x,  bool_features), header, 'UniformOutput', 0);
bool_idx = find(cell2mat(Match_bool));
% remove col if values empty
todel = find(cellfun(@isempty, cust(bool_idx)) == 1);
bool_idx(todel) = [];
sim_bool = cellfun(@(x) strcmpi(x,data(:,bool_idx)),cust(bool_idx),'uniformoutput',0);
matSize = size(sim_bool{1},1);
B = reshape(cell2mat(sim_bool),matSize,[],length(bool_idx));
C = sum(B,3);
SIM(:,bool_idx) = C;

% LEVENSTHEIN: appropriate for strings composed of one word only
lev_features = { 'first_name','last_name', 'city', 'zip', 'state','address_city','address_state',...
    'rec.receiver_first_name', 'rec.receiver_last_name'};
Match_lev = cellfun(@(x) ismember(x,  lev_features), header, 'UniformOutput', 0);
lev_idx = find(cell2mat(Match_lev));
for c = 1:length(lev_idx) % for each column
    key = cust{lev_idx(c)};
    TargetList = data(:,lev_idx(c));
    s = cellfun(@(x) ComputeLevDist(x, TargetList), cellstr(key),'uniformoutput',0);
    SIM(:,lev_idx(c)) = cell2mat(s);
end

% DICE: appropriate for strings composed of multiple words    
dice_features = { 'email','address_line_1', 'address_line_2', 'normalized_address_line_1','r.rec_name -- receiver "first name last name'};
Match_dice = cellfun(@(x) ismember(x,  dice_features), header, 'UniformOutput', 0);
dice_idx = find(cell2mat(Match_dice));
% remove email provider from email address
idx_email = find(strcmpi(header,'email')==1);
% keep only characters before @
data(:,idx_email) = strtok(data(:,idx_email),'@');
cust(:,idx_email) = strtok(cust(:,idx_email),'@');
for c = 1:length(dice_idx) % for each column
    key = cust{dice_idx(c)};
    TargetList = data(:,dice_idx(c));
    SIM(:,dice_idx(c)) = ComputeDiceDistance(key, TargetList);
end
