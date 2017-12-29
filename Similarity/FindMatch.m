function [Match_rows, SimScore, SimScore_fuzzy, alreadyMatched] = FindMatch(SIM, data_clean, alreadyMatched, header, i, threshold)

% FindMatch finds rows which overall similarity score is > threshold

% Initialization
SimScore = [];
MatchRows = [];

% replace nan in SIM with 0
SIM(isnan(SIM)) = 0;

% Calculate the weights for each feature as its prior prob
weights = zeros(1,size(data_clean,2));
exclusions = {'customer_key', 'corridor_key', 'kyc_status', 'inferred_source', ...
    't.transaction_fee_discount -- different from 0 when discount?','r.delivery_type', ...
    'r.sum_all_promo_discount', 'r.remitly_fraud_model_score'};
for w = 1:size(SIM,2)
    if ismember(header{w},exclusions) == 0
         weights(w) = 1 - sum(ismember(data_clean(:,w),data_clean{i,w}))/size(data_clean,1);
    end
end

% apply log to weight more high similarity values
SIM_log10 = abs(log10(1+SIM));
SIM_log10(isinf(SIM_log10)) = 1;
SIM_log10_sum = SIM + SIM_log10;
similarities = (SIM_log10_sum*weights')/sum(weights);

% enforce "hard links", i.e., if any of these is == 1 then replace simscore with
% 1
[rows,col] = find(SIM(:,...
    [find(strcmpi(header,'email')==1),...
    find(strcmpi(header,'r.device_1')==1),...
    find(strcmpi(header,'mobile_number')==1)]) == 1);
similarities_fuzzy = similarities;
similarities(unique(rows)) = 1;

% find potential matching customers (this includes similarities > threshold
% and perfect match of features as email, device and mobile number
Match_rows = find(similarities > threshold);
SimScore = similarities(Match_rows);
SimScore_fuzzy = similarities_fuzzy(Match_rows);

% replace scores > 1 to 1
SimScore(SimScore > 1) = 1;

% remove the customer himself
todel = find(Match_rows == i);
Match_rows(todel) = [];
SimScore(todel) = [];
SimScore_fuzzy(todel) = [];
% remove already matched
if ~isempty(alreadyMatched) && ~isempty(Match_rows)
    todel = ismember([Match_rows repmat(i,length(Match_rows),1)], alreadyMatched,'rows');
    Match_rows(todel) = [];
    SimScore(todel) = [];
    SimScore_fuzzy(todel) = [];
end
% update alreadyMatched
alreadyMatched = [alreadyMatched; repmat(i,length(Match_rows),1) Match_rows];


% HEADER: 
% "customer_key"    "first_name"    "last_name"    "signup_date_key"    "city"    "zip"    "state"
% "corridor_key"    "kyc_status"    "date_of_birth_dat?"    "inferred_source"    "mobile_number"    "email"
% "geo_location_coun?"    "address_line_1"    "address_line_2"    "address_city"    "address_state"
% "normalized_addres?"    "t.transaction_fee?"    "t.transaction_kou?"    "t.transaction_kou?"
% "rec.receiver_key"    "rec.receiver_mobi?"    "rec.receiver_firs?"    "rec.receiver_last?"
% "r.delivery_type"    "r.device_1"    "r.l4ssn"    "r.rec_name -- rec?"    "r.sum_all_promo_d?",  "r.remitly_fraud_m?"


% EDA
% plot to check
% n = 50;
% figure; 
% plot(Combined_sim(1:n),'-bo'); hold on
% plot(Combined_sim_log10_sum(1:n),'-mx'); hold on
% legend('original similarity score','log10(1+sim-matrix) + sim-matrix')
% title('log transform of similarity scores')
% xlabel('n')
% ylabel('similarity score')
% grid
% 

% look at the hist of the weigths. exclude features that we are not comparing or that we are comparing using
% boolean comp.
% exclusions = {'customer_key', 'corridor_key', 'kyc_status', 'inferred_source', ...
%     't.transaction_fee_discount -- different from 0 when discount?','r.delivery_type', ...
%     'r.sum_all_promo_discount', 'r.remitly_fraud_model_score'};
% exclusions_bool = {'signup_date_key', 'state', 'date_of_birth_date_key', 'mobile_number',...
%     'geo_location_country','address_line_2', 'address_state', 't.transaction_kount_geo_key', ...
%     't.transaction_kount_device_key', 'rec.receiver_key', 'rec.receiver_mobile_number',...
%     'r.device_1','r.l4ssn', 'r.rec_name -- receiver "first name last name"' };
% excl = [exclusions exclusions_bool];    
% idx = find(ismember(header, excl) == 0);
% figure
% title('Histogram of feature similarities for a given customer and log similarities')
% for w = 1:length(idx)
%     subplot(4, 3, w)
%     histogram(SIM(:,idx(w)),'FaceColor','b', 'FaceAlpha',0.4); 
%     hold on; 
%     histogram(SIM_log10_sum(:,idx(w)),'FaceColor','m','FaceAlpha',0.4);
%     title(strrep(header{idx(w)},'_',' '))
%     grid
% end

% just to check
% n = 10;
% d = [cellstr(num2str(Combined_sim_log10_sum(1:n,:))) data_clean(1:n,:)];
% A = cell(n*2,length(header)+1);
% A(1:2:end,:) = d;
% A(2:2:end,2:end) = num2cell(SIM(1:n,:));
% sample = ['weights' header; 'NaN' num2cell(weights);'1' cust];
% sample = [cellstr(sample); A ];