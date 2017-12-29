function data_mvp_clean = preprocess_data(data_mvp)

% find idx of columns with chars
idx_char = sum(cellfun(@ischar,data_mvp)) > 1;

% remove trailing space
data_mvp_clean = cellfun(@strtrim, data_mvp(:,idx_char), 'uni', false);

% lower case
data_mvp_clean = cellfun(@lower, data_mvp_clean, 'uni', false);

% Missing values: TBD how to handle

