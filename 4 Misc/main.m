
%% ####################### Master Thesis Code ########################## %%
% #################### Max Haberl 5407084 2021/22 ####################### %
% ################ Chair of Econometrics, Statistics #################### %
% #################### and Empirical Economics ########################## %
% ############# Supervised by: Prof. Dr. Joachim Grammig ################ %
% ======================================================================= %

% For replication of results please adapt working directory path and paths
% pointing to data sets. Simply adapt the paths according to your system
% path. Many blocks of code are disabled, as they are not necessary for the
% replication of results

clc;
clear;
rng(42);

addpath('C:\Users\maxem\Documents\Uni\Master\MA\MA\data\01_brokerData\robinhood\robintrack-popularity-history\tmp\popularity_export');
addpath("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\market_volume_data_cboe");
%addpath(genpath('C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\Robinhood'));

datetime.setDefaultFormats('default','dd/MM/yyyy');
%% Daily Data - Robinhood ################################################# 
% daily, aggregated intraday, specific stock information, users holding! 
% ONLY NECESSARY IF RH DATA IS NON_AGGREGATED TO DAILY!!! (takes ~hours)

% ds = tabularTextDatastore('C:\Users\maxem\Documents\Uni\Master\MA\MA\data\01_brokerData\robinhood\robintrack-popularity-history\tmp\popularity_export');
% N = length(ds.Files);
% rhood_cell = cell(N,1);
% for i = 8298:N
%     temp = ds.Files{i,1};
% 
%     rhood_cell{i} = readcell(temp, 'Range', 2);
%     temp = rhood_cell{i,1};
%     temp = cell2table(temp);
%     grouped_df = groupsummary(temp, 1, 'day', 'max'); %can be altered to "max" per dasy instead of "mean" per day
%     % statistics
%     
%     name = "output\RobinhoodMax\" + regexp(ds.Files{i,1},"[\w]*(?=\.\w)", 'match');
%     writetable(grouped_df, name)
%     disp(i);
%     if rem(i,10) == 0
%         disp(i);
%     end
% end
%% Weekly Data - Charles Schwab ###########################################
% weekly, non-stock specific, average daily client trades!
% charlesSchwab_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\01_brokerData\schwab\Schwab_ClientTradingActivity_weekly_readable.xlsx");

%% Monthly Data - InteractiveBrokers ######################################
% interactiveBrokers_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\01_brokerData\interactiveBrokers\InteractiveBrokers_ClientAccounts_Monthly.xlsx");

%% Historical Security and Exchange Quotes and Trading Data ###############
% from SEC market reports (1,9 GB of text, takes some time)
% 
% 
% Sp500ticks = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\control_variables\SP500codes.csv", 'ReadVariableNames', 0); % can be imported later as well
% Sp500ticks.Properties.VariableNames{1} = 'ticker';
% Sp500ticks = table2array(Sp500ticks);
% %%
% sec_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\sec_metrics\sec_df_historical_sparse.csv");
% % narrow down to SP500 universe 
% sec_sp500_df = sec_df(ismember(table2cell(sec_df(:,4)), Sp500ticks),:);
% %
% sec_sp500_df.Date = datetime(sec_sp500_df.Date, 'ConvertFrom', 'yyyymmdd');
% sec_sp500_df = table2timetable(sec_sp500_df, 'RowTimes', 'Date');
% sec_sp500_df = sortrows(sec_sp500_df, 'Date', 'ascend');
% sec_sp500_df = removevars(sec_sp500_df, 'Var1');

%% Historical Market Volume Data - CBOE ###################################
% make sure that all csv files from CBOE are as is, ending on ".csv" and
% are jointly stored in one folder

ds = tabularTextDatastore("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\market_volume_data_cboe");
N = length(ds.Files);
marketVolume_cell = cell(N,1);

for i = 1:N
    if i == 1
        temp = ds.Files{1,1};
        marketVolume_cell{1} = readcell(temp, 'Range', 2);
        temp = marketVolume_cell{1,1};
        marketVolume_df = cell2table(temp, 'VariableNames', {'Day', 'Market Participant', 'Tape A Shares', 'Tape B Shares', 'Tape C Shares', 'Total Shares', 'Tape A Notional', 'Tape B Notional' ,'Tape C Notional', 'Total Notional', 'Tape A Trade Count', 'Tape B Trade Count', 'Tape C Trade Count', 'Total Trade Count'});
        
    else 
        temp = ds.Files{i,1};
        marketVolume_cell{i} = readcell(temp, 'Range', 2);
        temp = marketVolume_cell{i,1};
        marketVolume_df = cat(1, marketVolume_df, temp);
    end
end

marketVolume_df = sortrows(marketVolume_df,'Day','descend');

%% VIX index - CBOE #######################################################
volaIndex_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\vix_index_cboe\VIX_History.csv");

%% Closing Price Data - Alpha Vantage #####################################
prices_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\control_variables\closing_sp500.csv");
prices_df.Properties.VariableNames{1} = 'Date';
prices_df = sortrows(prices_df, 'Date', 'ascend');
prices_df = table2timetable(prices_df, 'RowTimes','Date');
prices_df_weekly = convert2weekly(prices_df, 'Aggregation', 'lastvalue');

volumes_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\control_variables\volumes_sp500.csv");
volumes_df.Properties.VariableNames{1} = 'Date';
volumes_df = sortrows(volumes_df, 'Date', 'ascend');
volumes_df = table2timetable(volumes_df, 'RowTimes', 'Date');


returns_df = tick2ret(prices_df);
logReturns_df = tick2ret(prices_df, 'Continuous');
%%
logReturns_weekly_df = convert2weekly(logReturns_df, 'Aggregation', 'sum'); % sum due to log ret, takes some time as loop only
%% Excess Market Return Data - Fama French 3 Factor########################
factors_daily_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\fama_french\F-F_Research_Data_Factors_daily_CSV\F-F_Research_Data_Factors_daily.CSV");
factors_weekly_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\fama_french\F-F_Research_Data_Factors_weekly_CSV\F-F_Research_Data_Factors_weekly.csv");
factors_monthly_df = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\fama_french\F-F_Research_Data_Factors_CSV\F-F_Research_Data_Factors.CSV");

factors_monthly_df.Var1 = factors_monthly_df.Var1*100+1; % necessary as any day is required for further processing
factors_daily_df.Var1 = datetime(factors_daily_df.Var1, 'ConvertFrom', 'yyyymmdd');
factors_weekly_df.Var1 = datetime(factors_weekly_df.Var1, 'ConvertFrom', 'yyyymmdd');
factors_monthly_df.Var1 = datetime(factors_monthly_df.Var1, 'ConvertFrom', 'yyyymmdd');

factors_daily_df = table2timetable(factors_daily_df, 'RowTimes', 'Var1');

%% Market Cap & Book Value data ###########################################
% Book Value

% % daily volume data
% volumes_daily = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\control_variables\volumes_all.csv",'ReadVariableNames',1,'TreatAsMissing',"" );
% volumes_daily = rmmissing(volumes_daily, 2, "MinNumMissing", height(volumes_daily));
% 
% % total assets as reported quarterly
% assets_quarterly = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\control_variables\assets_all.csv",'ReadVariableNames',1,'TreatAsMissing','' );
% assets_quarterly = rmmissing(assets_quarterly, 2, "MinNumMissing", height(assets_quarterly));
% assets_quarterly = sortrows(assets_quarterly,1,'descend');
% assets_quarterly = addvars(assets_quarterly, year(assets_quarterly{:,1}),quarter(assets_quarterly{:,1}), 'After',1, 'NewVariableNames', {'year', 'quarter'});
% 
% id1 = [1:2:41];
% id2 = [2:2:40];
% assets_quarterly_1 = assets_quarterly(id1,:);
% assets_quarterly_2 = assets_quarterly(id2,:);
% 
% assets_quarterly_1 = rmmissing(assets_quarterly_1,2, 'MinNumMissing', height(assets_quarterly_1));
% assets_quarterly_2 = rmmissing(assets_quarterly_2,2, 'MinNumMissing', height(assets_quarterly_2));
% 
% for i = 4:width(assets_quarterly_2)
%     var = [assets_quarterly_2{:,i}; NaN];
%     name = assets_quarterly_2.Properties.VariableNames{i};
%     assets_quarterly_1 = addvars(assets_quarterly_1,var, 'NewVariableNames', name);
% end
% 
% assets_quarterly = assets_quarterly_1;
% % assets_quarterly = table2timetable(assets_quarterly, "RowTimes", 1);
% % assets_quarterly = addvars(assets_quarterly, year(assets_quarterly));
% 
% % total liabilties as reported quarterly
% liab_quarterly = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\control_variables\liabilities_all.csv",'ReadVariableNames',1,'TreatAsMissing',"" );
% liab_quarterly = rmmissing(liab_quarterly, 2, "MinNumMissing", height(liab_quarterly));
% liab_quarterly = sortrows(liab_quarterly,1,'descend');
% liab_quarterly = addvars(liab_quarterly, year(liab_quarterly{:,1}),quarter(liab_quarterly{:,1}), 'After',1, 'NewVariableNames', {'year', 'quarter'});
% id1 = [1:2:41];
% id2 = [2:2:40];
% liab_quarterly_1 = liab_quarterly(id1,:);
% liab_quarterly_2 = liab_quarterly(id2,:);
% 
% liab_quarterly_1 = rmmissing(liab_quarterly_1,2, 'MinNumMissing', height(liab_quarterly_1));
% liab_quarterly_2 = rmmissing(liab_quarterly_2,2, 'MinNumMissing', height(liab_quarterly_2));
% 
% for i = 4:width(liab_quarterly_2)
%     var = [liab_quarterly_2{:,i}; NaN];
%     name = liab_quarterly_2.Properties.VariableNames{i};
%     liab_quarterly_1 = addvars(liab_quarterly_1,var, 'NewVariableNames', name);
% end
% 
% liab_quarterly = liab_quarterly_1;
% % liab_quarterly = table2timetable(liab_quarterly, "RowTimes", 1);
% 
% %%
% book_value = assets_quarterly(:,1:3);
% count = 0;
% for i = 4:width(assets_quarterly)
%     name = assets_quarterly.Properties.VariableNames{i};
%     assets = assets_quarterly.(name);
%     liabs = liab_quarterly.(name);
%     if isa(assets, 'cell') == 1
%         product = NaN(1,21)';
%         count = count +1;
%     else
%         product = assets-liabs;
%     end
%     book_value = addvars(book_value, product, 'NewVariableNames', name);
% end
% 
% book_value = rmmissing(book_value, 2, 'MinNumMissing', height(book_value)); % remove remainder of all NaN columns
% 
% %% Market Cap #############################################################
% % Redo for shares outstanding then multiply with daily price data
% sharesOutstanding_quarterly = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\control_variables\outstanding_all.csv",'ReadVariableNames',1,'TreatAsMissing',"" );
% sharesOutstanding_quarterly = rmmissing(sharesOutstanding_quarterly, 2, "MinNumMissing", height(sharesOutstanding_quarterly));
% sharesOutstanding_quarterly = sortrows(sharesOutstanding_quarterly,1,'descend');
% sharesOutstanding_quarterly = addvars(sharesOutstanding_quarterly, year(sharesOutstanding_quarterly{:,1}),quarter(sharesOutstanding_quarterly{:,1}), 'After',1, 'NewVariableNames', {'year', 'quarter'});
% id1 = [1:2:39];
% id2 = [2:2:40];
% sharesOutstanding_quarterly_1 = sharesOutstanding_quarterly(id1,:);
% sharesOutstanding_quarterly_2 = sharesOutstanding_quarterly(id2,:);
% 
% sharesOutstanding_quarterly_1 = rmmissing(sharesOutstanding_quarterly_1,2, 'MinNumMissing', height(sharesOutstanding_quarterly_1));
% sharesOutstanding_quarterly_2 = rmmissing(sharesOutstanding_quarterly_2,2, 'MinNumMissing', height(sharesOutstanding_quarterly_2));
% 
% for i = 4:width(sharesOutstanding_quarterly_2)
%     var = [sharesOutstanding_quarterly_2{:,i}];
%     name = sharesOutstanding_quarterly_2.Properties.VariableNames{i};
%     sharesOutstanding_quarterly_1 = addvars(sharesOutstanding_quarterly_1,var, 'NewVariableNames', name);
% end
% 
% sharesOutstanding_quarterly = sharesOutstanding_quarterly_1;

%% Price & Return data for whole universe #################################
prices_daily = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\data\00_market structure data\control_variables\closing_all.csv",'ReadVariableNames',1,'TreatAsMissing',"" );

prices_daily = rmmissing(prices_daily, 2, "MinNumMissing", height(prices_daily));
prices_daily = sortrows(prices_daily,1,'descend');


prices_daily = addvars(prices_daily, year(prices_daily{:,1}),quarter(prices_daily{:,1}), 'After',1, 'NewVariableNames', {'year', 'quarter'});

returns_daily = table2timetable(prices_daily, 'RowTimes', 'Var1');
returns_daily = sortrows(returns_daily, 'Var1', 'ascend');

returns_daily_clean = returns_daily(:,1:2);
for i = 3:width(returns_daily)
    test_logic = returns_daily{:,i};
    name = returns_daily.Properties.VariableNames{i};
    if isa(test_logic, 'cell') == 1
        continue
    else
        returns_daily_clean = addvars(returns_daily_clean, test_logic, 'NewVariableNames', name);
    end
        
end

logReturns_daily = returns_daily_clean(2:height(returns_daily_clean),:);
logReturns_daily{:,3:width(returns_daily_clean)} = log(tick2ret(returns_daily_clean{:,3:width(returns_daily_clean)})+1);


%% only do once, load afterwards from written csv #########################
% market_value = prices_daily(:,1:3);
% count = 0;
% for i = 4:width(prices_daily)
%     name = prices_daily.Properties.VariableNames{i};
%     availableNames = sharesOutstanding_quarterly.Properties.VariableNames;
%     check = intersect(availableNames, name);
%     vec = zeros(height(prices_daily),1);
%     if ~isempty(check) == 1
%         for k = 1:height(sharesOutstanding_quarterly)
%             year = sharesOutstanding_quarterly{k,2};
%             quarter = sharesOutstanding_quarterly{k,3};
%             shares = sharesOutstanding_quarterly.(name)(k);
% 
%             for j = 1:1310
%                 if prices_daily{j,2} == year && prices_daily{j,3} == quarter
%                         if isa(shares, 'cell') == 1
%                             product = NaN;
%                             vec(j) = product;
%                             count = count +1;
%                         else
%                             price = prices_daily{j,i};
%                             product = price*shares;
%                             vec(j) = product;
%                         end
%                         
%                 end
% 
%             end
% 
%         end
%     else
%         continue
%     end
%     market_value = addvars(market_value, vec, 'NewVariableNames', name);
%     if rem(i,10) == 0
%         disp(i);
%     end
% end
% %%
% 
% writetable(market_value, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\control_variables\market_value.csv");
%% load market value from csv
market_value = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\control_variables\market_value.csv",'ReadVariableNames',1);
market_value = market_value(52:1309,:); % remove null entries that appeared due to limited balance sheet data availability

%% Book-to-Market Ratio ###################################################
% only do once, takes some time
% b2m = market_value(:, 1:3);
% 
% for i = 4:width(market_value)
%     name = market_value.Properties.VariableNames{i};
%     availableNames = book_value.Properties.VariableNames;
%     check = intersect(availableNames, name);
%     vec = zeros(height(market_value),1);
%     if ~isempty(check) == 1
%         for k = 1:height(book_value)
%             year = book_value{k,2};
%             quarter = book_value{k,3};
%             bookval = book_value.(name)(k);
%             
%             for j = 1:height(market_value)
%                 if market_value{j,2} == year && market_value{j,3} == quarter
%                     marketval = market_value{j,i};
%                     b2mratio = bookval/marketval;
%                     vec(j) = b2mratio;
%                 end
%             end
%         end
%     else 
%         continue
%     end
%     
%     b2m = addvars(b2m, vec, 'newVariableNames', name);
%     if rem(i,10) == 0
%         disp(i);
%     end
%     
%     
%     
% end

%%
% writetable(b2m, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\control_variables\book2market_value_correct.csv");
b2m = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\control_variables\book2market_value_correct.csv",'ReadVariableNames',1);
%% Period Definition and Splits ###########################################
% For Robinhood dataset: Daily appraisal from
% For Charles Schwab dataset: Weekly appraisal from March 2019 to September
% 2021
% For Interactive Brokers dataset: Monthly appraisal from 2008 to September
% 2021
% For Ameritrade and ETrade datasets: Quarterly appraisal



%% Descriptive Statistics #################################################
%% DAILY - Robinhood#######################################################
ds = tabularTextDatastore('C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\Robinhood');
% Sp500ticks = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\SP500codes.csv", 'ReadVariableNames', 0);
% Sp500ticks.Properties.VariableNames{1} = 'ticker';
% Sp500ticks = table2array(Sp500ticks);
Sp500ticks = string(Sp500ticks);
N = length(ds.Files);
allTicks = strings([N,1]);

% Find exact matches of SP500 tickers among Rhobinhood data and select
for i = 1:N
    allTicks(i) = regexp(ds.Files{i,1},"[\w]*(?=\.\w)", 'match');  
    if rem(i,100) == 0
        disp(i);
    end
end
% %% Save allTicks to external file
% allTicks_table = table(allTicks);
% writetable(allTicks_table, "output\allTicks.txt");


logic = intersect(allTicks,Sp500ticks); % ### very important, basis sample!!! <-- for all SP500 constituents


% open all Robinhood files contained in logic and save to cell
N = length(logic);
rhood_sp500_cell = cell(length(logic),1);

for i = 1:N
    temp_path = "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\Robinhood\" + logic{i}+".txt";
    rhood_sp500_cell{i} = readtable(temp_path);
    if rem(i,10) == 0
        disp(i);
    end
end

%% Robinhood - full sample with intraday data #############################
%  open ALL Robinhood files (first daily aggregated ones) and save to large
%  table, only once, load from file afterwards
% N = length(allTicks);
% 
% % loop through all stocks,l open respective file and save to table
% for i = 1:N
%     temp_path = "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\Robinhood\" + allTicks(i) + ".txt";
%     stock_hold = readtable(temp_path);
%     stock_hold.day_temp1 = datetime(stock_hold.day_temp1, 'InputFormat', 'dd-MMMM-yyyy');
%     stock_hold = table2timetable(stock_hold, 'RowTimes', 'day_temp1');
%     stock_hold = removevars(stock_hold, 'GroupCount');
%     stock_hold = renamevars(stock_hold, 'mean_temp2', allTicks(i) ); % + "_held" % depends on where table is used afterwards
%     if i == 1
%         rhood_table_agg = stock_hold;
%     else
%         rhood_table_agg = synchronize(rhood_table_agg, stock_hold);
%     end
%     if rem(i,200) == 0
%         disp(i);
%     end
%  
% end

%% shortcut
% writetimetable(rhood_table_agg, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\rhood_table_all.csv");
rhood_table_agg = table2timetable(readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\rhood_table_all.csv",'ReadVariableNames', 1));

%% Merge and synchronize RH user activity with GARCH vola estimation data #
% only do once, load afterwards
% volas = readtable("C://Users//maxem//Documents//Uni//Master//MA//MA//code//01_R//output//vola_estimation_sp500.csv",'ReadVariableNames', 1); % for whole universe or sp500 only
% 
% volas = table2timetable(volas, 'RowTimes', 'date');
% vola_names = volas.Properties.VariableNames;
% rh_names = rhood_table_agg.Properties.VariableNames;
% vola_rh_names = intersect(vola_names, rh_names); % find tickers that form union of both sets
% rhood_table_agg_vola = rhood_table_agg(:,vola_rh_names);
% volas_table_rh = volas(:,vola_rh_names);
% 
% rhood_table_agg_vola_prct = price2ret(rhood_table_agg_vola{:,:}+0.000001); % for numerical stability as log(0) not defined
% rhood_table_agg_vola{2:818,:} = rhood_table_agg_vola_prct; % matlab data type inconvenience reformulations :D --> check once more in the end, as 1:817 was used initially and turned out to shift dates by one erroneously
% rhood_table_agg_vola_prct = rhood_table_agg_vola(2:818,:);
% vola_RH = synchronize(volas_table_rh,rhood_table_agg_vola_prct, volas.date);
% 
% vola_RH = renamevars(vola_RH, vola_RH(:,1:(width(vola_RH)/2)).Properties.VariableNames, vola_rh_names); % first 5638 entries pertain to vola measures, second half to rhood user percentage change
%%
% writetimetable(vola_RH, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\Robinhood_Vola_table\rhood_vola_joined_sp500_correct.csv");
vola_RH = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\Robinhood_Vola_table\rhood_vola_joined_sp500.csv");
%% Stationarity for RH and vola estimation ################################
% test for stationarity of percentage user changes and conditional vola
% series. From eyeballing and common sense, user percentaqge change is
% stationary (as user percentage change = log user changes which are in 
% turn differenced log counts, thus yield a difference stationary series)


size_N = (width(vola_RH)-1)/2;

test_table_TE = NaN(size_N,2);

for i = 1:size_N
    try
        test_table_TE(i,1) = adftest(vola_RH{:,1+i},'model','ARD');
        test_table_TE(i,2) = adftest(vola_RH{:,1+size_N+i},'model','AR');
    catch
        test_table_TE(i,1) = NaN;
        test_table_TE(i,2) = NaN;
    end
        
    
end
%
test_cond_vola = mean(test_table_TE(:,1), 'omitnan'); % only some 44% of cases rejects a unit-root null in favour of the alternative being an AR(1) with coef <1
test_prct_user_change = mean(test_table_TE(:,2), 'omitnan'); % over 97% of cases must reject a unit-root null

% Diagnostics for AR(1)-GACRH(1,1) for TE-estimation
vola_RH_coefs_pvals = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\01_R\output\vola_estimation_sp500_coefs_pvals.csv");
vola_RH_coefs_pvals = addvars(vola_RH_coefs_pvals,[vola_RH_coefs_pvals{:,1}+vola_RH_coefs_pvals{:,2} <= 1] , 'NewVariableNames', 'a+b logic');
test_sum_a_b = mean(vola_RH_coefs_pvals{:,7}); %fraction of series with sums of alpha and beta coefs smaller than 1
test_ar = mean([abs(vola_RH_coefs_pvals{:,3}) <=0.12]); %fraction of series with an AR(1) coef that deviates from zero by less than 0.1
test_alpha_pval =  mean([abs(vola_RH_coefs_pvals{:,4}) <=0.05]);
test_beta_pval =  mean([abs(vola_RH_coefs_pvals{:,5}) <=0.05]);
test_ar_pval =  mean([abs(vola_RH_coefs_pvals{:,6}) <=0.05]);
%%
% %% Summary Statistics and descriptive Statistics for full sample
% rhood_array_agg = rhood_table_agg{:,:};
% 
% for i = 1:length(rhood_array_agg)
%     rhood_array_agg_diff(:,i) = [NaN, [rhood_array_agg(2:818,i)-rhood_array_agg(1:817,i)]'];
% end
% 
% rhood_table_agg_diff = array2timetable(rhood_array_agg_diff, "RowTimes", rhood_table_agg.day_temp1);
% rhood_table_agg_diff = renamevars(rhood_table_agg_diff, rhood_table_agg_diff.Properties.VariableNames, rhood_table_agg.Properties.VariableNames + "_diff");
% 
% %% Summary
% rhood_table_agg_summary = summary(rhood_table_agg);
% rhood_table_agg_diff_summary = summary(rhood_table_agg_diff);
% % Daily descending sort of stocks with largest amount of users holding
% [B,IDX] = sort(rhood_array_agg,2, "descend");
% rhood_table_agg_maxperday = array2timetable(IDX, "RowTimes", rhood_table_agg.day_temp1);
% rhood_table_agg_maxperday = renamevars(rhood_table_agg_maxperday, rhood_table_agg_maxperday.Properties.VariableNames, rhood_table_agg.Properties.VariableNames);
% % Daily descending sort of stocks with largest amount of change in users
% % from prior day
% [B,IDX2] = sort(rhood_array_agg_diff,2, "descend");
% rhood_table_agg_diff_maxperday = array2timetable(IDX2, "RowTimes", rhood_table_agg.day_temp1);
% rhood_table_agg_diff_maxperday = renamevars(rhood_table_agg_diff_maxperday, rhood_table_agg_diff_maxperday.Properties.VariableNames, rhood_table_agg_diff.Properties.VariableNames);



%
% %% Seeds, samples and everything else random ##############################
% rng(42);
% logic = logReturns_df(:,ismember(logReturns_df.Properties.VariableNames,logic)); % <-- further reduced to SP500 firms available from Robinhood dataset
% logic = logic.Properties.VariableNames;
% % 1st divide SP500 data up into 2 splits (S_explanatory and S_predictive)
% % logReturns_df = rows2vars(logReturns_df);
% S1 = randsample([1:length(logic)],(length(logic)/2));
% Shelp = [1:length(logic)];
% S2 = setdiff(Shelp,S1);
% S_explan = logReturns_df(:,S1); % half of viable SP500 constituents chosen at random
% S_pred = logReturns_df(:,S2); % other remainder of viable SP500 constituents
% 
% %% Beta estimation - daily --> functionalize! #############################
% % subset data for period 02.05.2018 - 13.08.2020 to meet Robinhood scope
% tr = timerange("2018-05-02", "2020-08-13");
% S_explan_rhood = S_explan(tr,:);
% S_explan_rhood = removevars(S_explan_rhood, 'BRK_B'); % unnerving naming conventions!
% S_pred_rhood = S_pred(tr,:);
% factors_daily_rhood = factors_daily_df(tr,:);
% 
% sec_rhood_df = sec_sp500_df(tr,:);
% sec_rhood_NYSE_df = sec_rhood_df(ismember(table2cell(sec_rhood_df(:,3)),{'NYSE'}),:);
% sec_rhood_NASDAQ_df = sec_rhood_df(ismember(table2cell(sec_rhood_df(:,3)),{'Nasdaq'}),:);
% 
% % Now select for which feature to format tables
% sec_rhood_NYSE_trades_df = sec_rhood_NYSE_df(:,[2 9]);
% sec_rhood_NYSE_trades_df = unstack(sec_rhood_NYSE_trades_df, 'Trades', 'Ticker');
% 
% sec_rhood_NASDAQ_trades_df = sec_rhood_NASDAQ_df(:,[2 9]);
% sec_rhood_NASDAQ_trades_df = unstack(sec_rhood_NASDAQ_trades_df, 'Trades', 'Ticker');
% 
% sec_rhood_NASDAQ_trades_explan_df = sec_rhood_NASDAQ_trades_df(:, ismember(sec_rhood_NASDAQ_trades_df.Properties.VariableNames,S_explan.Properties.VariableNames));
% % looses some firms from S_explan sample due to lack of completeness in 
% sec_rhood_NASDAQ_trades_pred_df = sec_rhood_NASDAQ_trades_df(:, ismember(sec_rhood_NASDAQ_trades_df.Properties.VariableNames,S_pred.Properties.VariableNames));
% % NYSE explan and pred split still missing
% regX = synchronize(S_explan_rhood, factors_daily_rhood);
% regX = rmmissing(regX, 2);
% coef = cell(width(regX)-4,1);
% coef_alt = cell(width(regX)-4,1);
% 
% % full observation period regression and beta 
% for i = 1:width(regX)-4
%     y = regX{:,i}-(regX.RF/100);
%     X = [ones(height(regX),1),(zeros(height(regX),1)+(regX.Mkt_RF/100))];
%     coef{i} = (X'*X)\(X'*y);
%     coef_alt{i} = regress(y,X);
% end
% 
% %% rolling window of 5 trading days for beta over time ####################
% coef_rolling = cell(width(regX)-4,height(regX)-4);
% coef_alt_rolling = cell(width(regX)-4,height(regX)-4);
% for j = 1:height(regX)-4
%     for i = 1:width(regX)-4
%         y = regX{j:j+4,i}-(regX.RF(j:j+4)/100);
%         X = [ones(5,1),(zeros(5,1)+(regX.Mkt_RF(j:j+4)/100))];
%         coef_rolling{i,j} = (X'*X)\(X'*y);
%         coef_alt_rolling{i,j} = regress(y,X); %regress as much faster as fitlm
%     end 
%     
% end
% 
%     
% %% Extract all beta coefs and add to exisiting table
% vec = zeros(1,width(coef_rolling));
% helper_tt = regX;
% for i = 1:height(coef_rolling)
%     vec = zeros(1,width(coef_rolling));
%     for k = 1:width(coef_rolling)
%         vec(k) = coef_rolling{i,k}(2);
%     end
% 
%     vec = [NaN, NaN, NaN, NaN, vec]'; %[vec, NaN, NaN, NaN, NaN]'; this specification determines whether a the 5 day rolling window correspongs to first or last day within window
%     tick = helper_tt.Properties.VariableNames{i};
%     tick_beta = tick+"_beta";
%     helper_tt = addvars(helper_tt, vec, 'NewVariableNames', tick_beta); % add rolling betas
%     temp_path = "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\Robinhood\"+tick+".txt";
%     users_holding = readtable(temp_path);
%     users_holding.day_temp1 = datetime(users_holding.day_temp1, 'InputFormat', 'dd-MMMM-yyyy');
%     users_holding = table2timetable(users_holding, 'RowTimes', 'day_temp1');
%     users_holding = removevars(users_holding, 'GroupCount');
%     users_holding = renamevars(users_holding, 'mean_temp2', tick + "_held");
%     users_trading = tick2ret(users_holding);
%     users_trading = renamevars(users_trading, 1, tick+"_pctch");
%     if ismember({tick}, sec_rhood_NASDAQ_trades_explan_df.Properties.VariableNames) == 1
%         sec_trading = sec_rhood_NASDAQ_trades_explan_df(:,tick);
%     else
%         sec_rhood_NASDAQ_trades_explan_df(:,tick) = table(ones(575,1));
%         sec_trading = sec_rhood_NASDAQ_trades_explan_df(:,tick);
%     end
%     sec_trading = renamevars(sec_trading, 1, tick+"_sec_trades");
%     sec_trading_chg = tick2ret(sec_trading);
%     sec_trading_chg = renamevars(sec_trading_chg, 1, tick+"_sec_trades_chg");
%     
%     helper_tt = synchronize(helper_tt, users_holding); % add avg users holding
%     helper_tt = synchronize(helper_tt, users_trading);
%     helper_tt = synchronize(helper_tt, sec_trading);
%     helper_tt = synchronize(helper_tt, sec_trading_chg);
%     helper_tt = rmmissing(helper_tt, 'DataVariables', 'RF');
%     if rem(i,10) == 0
%         disp(i);
%     end
%     
% end
% 
% 
% %% Plots and Visualization ################################################
% % NOT NECESSARY EACH TIME!
% % Iterate over firms and show 4 plots each time
% helper_tt(:,247:width(helper_tt)) = fillmissing(helper_tt(:,247:width(helper_tt)), 'next'); % impute NaNs for visualization using 'next' method
% path = "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\beta_plots\beta_pctchg_shift_sec";
% % n = 242;
% k = 61; % ceil(242/4)
% for l = 1:k
%     fig = figure('Name', 'Beta vs. Trading Act');
%     for i = (l*4)-3:l*4
%         p = i-((l-1)*4);
%         subplot(4,1,p);
%         x = [1:571];
%         plot(x, helper_tt{1:571,242+(i*5)},'--g', x, (helper_tt{1:571,244+(i*5)})*100, 'm',x, (helper_tt{1:571,246+(i*5)})*100, 'r');
%         t = title("Beta and Trading Activity of: " + helper_tt.Properties.VariableNames{i});
%         t.FontSize = 6;
%         xlim([1 571]);
%         
%     end
%     Lgnd = legend('beta','%-change rhood', '%-change sec');
%     fig.Position(3) = fig.Position(3) + 250; % create some sapce
%     Lgnd.Position = [0.02 0.45 0.02 0.04];
%     name = l + "_beta_vs_pctchg_shift_sec";
%     exportgraphics(fig, fullfile(path, name + '.png'), 'Resolution',300);
% end
% % x, helper_tt{1:571,245+(i*3)}/100, 'r',
% % 'holding',
% 
% 
% %%
% test = table2array(helper_tt(1:571,247:575));
% test = corr(test);
% beta2hold_corr = diag(test,-1);
% %% Entropy risk measure - Set up
% %% Kernel Density Estimation using differrent kernels #####################
% kernel_estimates = cell(499,2);
% 
% for i = 1:499
%     x = [logReturns_df{:,i}];
%     x = rmmissing(x);
%     bw = 1.06*std(x)*length(x)^(-0.2); % bandwidth according to rule of thumb i.e. 1.06sigma*n^-1/5 Silverman's rule
%     [kernel_estimates{i,1}, kernel_estimates{i,2}] = ksdensity(x,x,'Bandwidth', bw, 'Kernel', 'normal');
%     if rem(i,10) == 0
%         disp(i+" out of 499");
%     end
% end
% 
% %% Plot first 5 kernel estimates fo visual evaluation
% % normality test (Kolmogorov-Smirnov Test??)
% figure();
% for i = 1:5
%     ax(i) = subplot(5,1,i);
%     col = ['g', 'r', 'b', 'c', 'm'];
%     scatter(kernel_estimates{i,2}, kernel_estimates{i,1},'c', col(i));
%     title(logReturns_df.Properties.VariableNames{i});
%     xlim([-0.1 0.1]);
% end
% 
% linkaxes([ax(1), ax(2), ax(3), ax(4), ax(5)], 'xy');
% 
% %% Entropy estimation --> Still wrong as P(X=xi) =0 in density fct, and fx(X) != P(X=xi)
% % Shannon entropy
% ShanEnt = zeros(499,1);
% 
% for i = 1:499
%     ShanEnt(i,1) = -(kernel_estimates{i,1}'*log2(kernel_estimates{i,1}));
% end
% %%
% % Renyi entropy
% RenEnt = zeros(499,1);
% 
% for i = 1:499
%     RenEnt(i,1) = -log2(kernel_estimates{i,1}'*kernel_estimates{i,1});
% end
% 
% %% Standardize to avoid negative risk measures
% ShanEnt_stand = normalize(ShanEnt); % Z-score normalization/standardization
% RentEnt_stand = normalize(RenEnt);
% 
% ShanEnt_norm = (ShanEnt-min(ShanEnt))/(max(ShanEnt)-min(ShanEnt)); % max-min normalization into [0,1] 
% RenEnt_norm = (RenEnt-min(RenEnt))/(max(RenEnt)-min(RenEnt));
% 
% %% Descriptive Statistics #################################################
% % number of obs, periods, location, dispersion and cor/relation
% 
% 
% %% Sketch: CAPM with past users holding as an additional factor risk
% % pick 20 randomly picked stocks from SP500 (S_explan sample) for which Rhood data is
% % available
% 
% %% Full period Time Series Regression ###################################
% 
% % calculate overall users_holding per day in SP500 S_explan universe
% helper_tt = addvars(helper_tt,sum(helper_tt{:,[(247+5*[1:243]'-3)]},2, 'omitnan'), 'NewVariableNames', 'agg_users_holding');
% %%
% rng(49);
% idx_randomdraw = randsample(243, 20);
% 
% regX_capm_usersholding = helper_tt(:,[idx_randomdraw; (247+5*idx_randomdraw-3); [244:247]'; 1463]); % subset for returns and respective users holding per day
% 
% coef_capm_usersholding = cell(20,1);
% h = height(regX_capm_usersholding)-1; % due to lag in usersholding
% 
% for i = 1:20
%     y = regX_capm_usersholding{2:h+1,i}- (regX_capm_usersholding.RF(2:h+1)/100);
%     X = [(regX_capm_usersholding.Mkt_RF(2:h+1)/100), regX_capm_usersholding{1:h, 20+i}./regX_capm_usersholding.agg_users_holding(1:h)];
%     [coef_capm_usersholding{i}] = fitlm(X,y);
% end
% %%
% % now for 5 day rolling window
% coef_capm_usersholding_rolling_simpleModel = cell(20, h-4);
% coef_capm_usersholding_rolling = cell(20, h-4);
% for j = 1:h-4
%     for i = 1:20
%         y = regX_capm_usersholding{j+1:j+5,i}- (regX_capm_usersholding.RF(j+1:j+5)/100);
%         X1 = [(regX_capm_usersholding.Mkt_RF(j+1:j+5)/100), regX_capm_usersholding{j:j+4, 20+i}./regX_capm_usersholding.agg_users_holding(j:j+4)];
%         X2 =[(regX_capm_usersholding.Mkt_RF(j+1:j+5)/100)];
%         coef_capm_usersholding_rolling{i,j} = fitlm(X1,y);
%         coef_capm_usersholding_rolling_simpleModel{i,j} = fitlm(X2,y);
%     end
% end

%% Evaluate TE results ####################################################

te_rh_vola = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\01_R\output\TE_estimation.csv");

pval_rh_vola = sum(te_rh_vola{:,9} <= 0.05);


te_rh_vola_sp500 = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\01_R\output\TE_estimation_sp500.csv"); % use "TE_estimation_sp500.csv" for lagged impact of rh on vola

pval_rh_vola_sp500 = sum(te_rh_vola_sp500{:,9} <= 0.05 & te_rh_vola_sp500{:,5} <= 0.05 )/height(te_rh_vola_sp500); %; & te_rh_vola_sp500{:,9} <= 0.05);

both = sum(te_rh_vola_sp500{:,9} <= 0.05 & te_rh_vola_sp500{:,5} <= 0.05);
rh_vol = sum(te_rh_vola_sp500{:,9} <= 0.05);
vol_rh = sum(te_rh_vola_sp500{:,5} <= 0.05);
% Comparative analysis with control variables
market_value = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\control_variables\market_value.csv",'ReadVariableNames',1);
market_value = market_value(52:1309,:); % remove null entries that appeared due to limited balance sheet data availability

te_tickers = te_rh_vola_sp500{:,1};
market_val_tickers = market_value.Properties.VariableNames(4:width(market_value));
%%

% 1) market cap (avg over period) only 303 available onbservations, aftzer
% NA removal, only 228
avail_tickers = intersect(te_tickers, market_val_tickers);
market_value_sp500 = market_value(:,['Var1', 'year', 'quarter',avail_tickers']);

% narrow down market cap to RH data period
market_value_sp500 = table2timetable(market_value_sp500, 'RowTimes', 'Var1');
tr = timerange("2018-05-02", "2020-08-13");
market_value_sp500 = market_value_sp500(tr,:);
avg_market_value_sp500 = mean(market_value_sp500{:,3:width(market_value_sp500)}, 1);
avg_market_value_sp500 = table(market_value_sp500.Properties.VariableNames(:,3:width(market_value_sp500))',avg_market_value_sp500');

te_market_value = join(avg_market_value_sp500, te_rh_vola_sp500);
te_market_value = te_market_value(~isnan(te_market_value{:,2}),:);
te_market_value = addvars(te_market_value, [te_market_value{:,10} <=0.05], 'NewVariableNames', 'Logic_rh_vola');
test_rh_vola = [te_market_value{:,10} <=0.05];
test_vola_rh = [te_market_value{:,6} <=0.05];

dat1_val = te_market_value(te_market_value{:,11} == 0,:);
dat2_val = te_market_value(te_market_value{:,11} == 1,:);

figure;
h1 = cdfplot(log(dat1_val{:,2}));
h1.LineWidth = 1.25;
hold on
h2 = cdfplot(log(dat2_val{:,2}));
h2.LineWidth = 1.25;
legend('E-CDF of (log(market cap)|insig)', 'E-CDF of (log(market cap)|sig)', 'Location', 'southeast', 'FontSize', 8);
xlabel('log(market cap)', 'FontSize', 8);
ylabel('F(X)','FontSize', 8);
title('E-CDF for Market Cap','FontSize', 9, 'FontWeight', 'normal');

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\marketcap.png", 'Resolution', 300);
set(gcf,'color','w');



savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_overview_pos_BHAR_min100_30_tidy_test.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\marketcap.png", '-png', '-m2');
%%
% 2) popularity index (ranked # users holding, avg over period)
rhood_pop_tickers = rhood_table_agg.Properties.VariableNames(1:width(rhood_table_agg));
avail_tickers = intersect(te_tickers, rhood_pop_tickers);
rhood_pop_sp500 = rhood_table_agg(:,avail_tickers);
rhood_pop_sp500 = rhood_pop_sp500(tr,:);
% rhood_pop_sp500 = rmmissing(rhood_pop_sp500, 2, 'MinNumMissing', 1); not
% necessary if avg over period and rot afterwards, only nec if sorted daily

rhood_pop_sp500_mean = mean(rhood_pop_sp500{:,:},1, 'omitnan'); 

[rhood_pop_sp500_rank, Idx] = sort(rhood_pop_sp500_mean);

ranked_tickers = rhood_pop_sp500.Properties.VariableNames(Idx);
temp = table(ranked_tickers',[1:485]');

te_pop = join(te_rh_vola_sp500, temp);
te_pop = addvars(te_pop, [te_pop{:,9} <= 0.05], 'NewVariableNames', 'Logic_rh_vola');

dat1 = te_pop(te_pop{:,11} == 0,:);
dat2 = te_pop(te_pop{:,11} == 1,:);
% te_rh_vola_sp500 = join(te_rh_vola_sp500, temp);
% te_rh_vola_sp500 = addvars(te_rh_vola_sp500, [te_rh_vola_sp500{:,9} <= 0.05], 'NewVariableNames', 'Logic_rh_vola');
% 
% dat1 = te_rh_vola_sp500(te_rh_vola_sp500{:,11} == 0,:);
% dat2 = te_rh_vola_sp500(te_rh_vola_sp500{:,11} == 1,:);

figure;
h1 = cdfplot(dat1{:,10});
h1.LineWidth = 1.25;
hold on
h2 = cdfplot(dat2{:,10});
h2.LineWidth = 1.25;
legend('E-CDF of (rank|insig)', 'E-CDF of (rank|sig)', 'Location', 'southeast','FontSize', 8);
xlabel('average rank^{-1}','FontSize', 8);
ylabel('F(X)','FontSize', 8);
title('E-CDF for Popularity Index','FontSize', 9, 'FontWeight', 'normal');

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\rank.png", 'Resolution', 300);
set(gcf,'color','w');



savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_overview_pos_BHAR_min100_30_tidy_test.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\rank.png", '-png', '-m2');
%  maybe argue with first order stat dominance of F(rank|sig) <=
%  F(rank|insig)
q_sig_insig = quantile(dat2{:,10}, [0.25 0.50 0.75])-quantile(dat1{:,10},[0.25 0.50 0.75]); % computes quartile differences between sig and insignificant rankings
%% 3) book2market ratio

b2m_tickers = b2m.Properties.VariableNames(4:width(b2m));
avail_tickers = intersect(te_tickers, b2m_tickers);

b2m_sp500 = b2m(:,['Var1', 'year', 'quarter',avail_tickers']);

b2m_sp500 = table2timetable(b2m_sp500, 'RowTimes', 'Var1');
b2m_sp500(tr,:);
avg_b2m_sp500 = mean(b2m_sp500{:,3:width(b2m_sp500)},1);
avg_b2m_sp500 = table(b2m_sp500.Properties.VariableNames(:,3:width(b2m_sp500))', avg_b2m_sp500');

te_b2m = join(avg_b2m_sp500, te_rh_vola_sp500);
te_b2m = te_b2m(~isnan(te_b2m{:,2}),:);
te_b2m = addvars(te_b2m, [te_b2m{:,10} <= 0.05], 'NewVariableNames', 'Logic_rh_vola');

dat1_b2m = te_b2m(te_b2m{:,11} == 0,:);
dat2_b2m = te_b2m(te_b2m{:,11} == 1,:);


figure;
h1 = cdfplot(dat1_b2m{:,2});
h1.LineWidth = 1.25;
hold on
h2 = cdfplot(dat2_b2m{:,2});
h2.LineWidth = 1.25;
legend('Empirical CDF of (B2M|insignificant)', 'Empirical CDF of (B2M|significant)', 'Position', [0.6,-0.09,0,1],'FontSize', 8);
xlabel('average B2M ratio','FontSize', 8);
ylabel('F(X)','FontSize', 8);
title('E-CDF for Book-2-Market Ratio','FontSize', 9, 'FontWeight', 'normal');
% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\b2m.png", 'Resolution', 300);
set(gcf,'color','w');



savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_overview_pos_BHAR_min100_30_tidy_test.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\b2m.png", '-png', '-m2');
%%
% 3) search intensity (ranked # of ppl searching for ticker, SVI from Google API)
% still missing the necessary data, may skip

%%
% 4) Top-Mover heuristic (ranked # days a specific stock's returns have
% ended up in the top mover list (!!! max absolute not (pos) returns)

logReturns_abs_df = timetable(logReturns_df.Date);
for i = 1:width(logReturns_df)
    logReturns_abs_df = addvars(logReturns_abs_df, abs(logReturns_df{:,i})); % intriguing observattion: leave out abs and look at real ranked returns, then sig, insig ist switched
    
end

logReturns_abs_df = renamevars(logReturns_abs_df, [1:499], logReturns_df.Properties.VariableNames);
logReturns_abs_tickers = logReturns_abs_df.Properties.VariableNames;
avail_tickers = intersect(te_tickers, logReturns_abs_tickers);
logReturns_abs_df = logReturns_abs_df(:,avail_tickers);
logReturns_abs_df = logReturns_abs_df(tr,:);

logReturns_abs_mean = mean(logReturns_abs_df{:,:},1,'omitnan');

[logReturns_abs_rank, Idx] = sort(logReturns_abs_mean);

ranked_tickers = logReturns_abs_df.Properties.VariableNames(Idx);
temp = table(ranked_tickers', [1:485]');

te_topmover = join(te_rh_vola_sp500, temp);
te_topmover = addvars(te_topmover, [te_topmover{:,9} <= 0.05], 'NewVariableNames', 'Logic_rh_vola');

dat1_top = te_topmover(te_topmover{:,11} == 0,:);
dat2_top = te_topmover(te_topmover{:,11} == 1,:);

figure;
h1 = cdfplot(dat1_top{:,10});
h1.LineWidth = 1.25;
hold on
h2 = cdfplot(dat2_top{:,10});
h2.LineWidth = 1.25;
legend('E-CDF of (TopMoverRank|insig)', 'E-CDF of (TopMoverRank|sig)', 'Location', 'southeast','FontSize', 8);
xlabel('average absolute mover rank^{-1}','FontSize', 8);
ylabel('F(X)','FontSize', 8);
title('E-CDF for Top Mover','FontSize', 9, 'FontWeight', 'normal');
% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\topmover.png", 'Resolution', 300);
% 
set(gcf,'color','w');



savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_overview_pos_BHAR_min100_30_tidy_test.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\topmover.png", '-png', '-m2');

%% Evaluate TE results - Part 2 ####################################################
%% again with full universe ###############################################

%% Comparative analysis with control variables
market_value = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\control_variables\market_value.csv",'ReadVariableNames',1);
market_value = market_value(52:1309,:); % remove null entries that appeared due to limited balance sheet data availability

te_tickers = te_rh_vola{:,1};
market_val_tickers = market_value.Properties.VariableNames(4:width(market_value));
%%

% 1) market cap (avg over period) only 303 available onbservations, aftzer
% NA removal, only 228
avail_tickers = intersect(te_tickers, market_val_tickers);
market_value = market_value(:,['Var1', 'year', 'quarter',avail_tickers']);

% narrow down market cap to RH data period
market_value = table2timetable(market_value, 'RowTimes', 'Var1');
tr = timerange("2018-05-02", "2020-08-13");
market_value = market_value(tr,:);
avg_market_value = mean(market_value{:,3:width(market_value)}, 1);
avg_market_value = table(market_value.Properties.VariableNames(:,3:width(market_value))', avg_market_value');

te_market_value = join(avg_market_value, te_rh_vola);
te_market_value = te_market_value(~isnan(te_market_value{:,2}),:);
te_market_value = addvars(te_market_value, [te_market_value{:,10} <=0.05], 'NewVariableNames', 'Logic_rh_vola');
test_rh_vola = [te_market_value{:,10} <=0.05];
test_vola_rh = [te_market_value{:,6} <=0.05];

dat1_val = te_market_value(te_market_value{:,11} == 0,:);
dat2_val = te_market_value(te_market_value{:,11} == 1,:);

figure;
h1 = cdfplot(log(dat1_val{:,2}));
h1.LineWidth = 1.25;
hold on
h2 = cdfplot(log(dat2_val{:,2}));
h2.LineWidth = 1.25;
legend('E-CDF of (log(market cap)|insig)', 'E-CDF of (log(market cap)|sig)', 'Location', 'southeast', 'FontSize', 8);
xlabel('log(market cap)', 'FontSize', 8);
ylabel('F(X)','FontSize', 8);
title('E-CDF for Market Cap - Full Sample','FontSize', 9, 'FontWeight', 'normal');

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\marketcap_full.png", 'Resolution', 300);
set(gcf,'color','w');



savehandle = gcf;

% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\marketcap_full.png", '-png', '-m2');
%%
% 2) popularity index (ranked # users holding, avg over period)
rhood_pop_tickers = rhood_table_agg.Properties.VariableNames(1:width(rhood_table_agg));
avail_tickers = intersect(te_tickers, rhood_pop_tickers);
rhood_pop = rhood_table_agg(:,avail_tickers);
rhood_pop = rhood_pop(tr,:);
% rhood_pop_sp500 = rmmissing(rhood_pop_sp500, 2, 'MinNumMissing', 1); not
% necessary if avg over period and rot afterwards, only nec if sorted daily

rhood_pop_mean = mean(rhood_pop{:,:},1, 'omitnan'); 

[rhood_pop_rank, Idx] = sort(rhood_pop_mean);

ranked_tickers = rhood_pop.Properties.VariableNames(Idx);
temp = table(ranked_tickers',[1:width(ranked_tickers)]');

te_pop = join(te_rh_vola, temp);
te_pop = addvars(te_pop, [te_pop{:,9} <= 0.05], 'NewVariableNames', 'Logic_rh_vola');

dat1 = te_pop(te_pop{:,11} == 0,:);
dat2 = te_pop(te_pop{:,11} == 1,:);
% te_rh_vola_sp500 = join(te_rh_vola_sp500, temp);
% te_rh_vola_sp500 = addvars(te_rh_vola_sp500, [te_rh_vola_sp500{:,9} <= 0.05], 'NewVariableNames', 'Logic_rh_vola');
% 
% dat1 = te_rh_vola_sp500(te_rh_vola_sp500{:,11} == 0,:);
% dat2 = te_rh_vola_sp500(te_rh_vola_sp500{:,11} == 1,:);

figure;
h1 = cdfplot(dat1{:,10});
h1.LineWidth = 1.25;
hold on
h2 = cdfplot(dat2{:,10});
h2.LineWidth = 1.25;
legend('E-CDF of (rank|insig)', 'E-CDF of (rank|sig)', 'Location', 'southeast','FontSize', 8);
xlabel('average rank^{-1}','FontSize', 8);
ylabel('F(X)','FontSize', 8);
title('E-CDF for Popularity Index - Full Sample','FontSize', 9, 'FontWeight', 'normal');

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\rank_full.png", 'Resolution', 300);

%  maybe argue with first order stat dominance of F(rank|sig) <=
%  F(rank|insig)
% q_sig_insig = quantile(dat2{:,10}, [0.25 0.50 0.75])-quantile(dat1{:,10},[0.25 0.50 0.75]); % computes quartile differences between sig and insignificant rankings
set(gcf,'color','w');



savehandle = gcf;

% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\rank_full.png", '-png', '-m2');
%% 3) book2market ratio

b2m_tickers = b2m.Properties.VariableNames(4:width(b2m));
avail_tickers = intersect(te_tickers, b2m_tickers);

b2m_all = b2m(:,['Var1', 'year', 'quarter',avail_tickers']);

b2m_all = table2timetable(b2m_all, 'RowTimes', 'Var1');
b2m_all(tr,:);
avg_b2m_all = mean(b2m_all{:,3:width(b2m_all)},1);
avg_b2m_all = table(b2m_all.Properties.VariableNames(:,3:width(b2m_all))', avg_b2m_all');

te_b2m = join(avg_b2m_all, te_rh_vola);
te_b2m = te_b2m(~isnan(te_b2m{:,2}),:);
te_b2m = addvars(te_b2m, [te_b2m{:,10} <= 0.05], 'NewVariableNames', 'Logic_rh_vola');

dat1_b2m = te_b2m(te_b2m{:,11} == 0 & te_b2m{:,2} >= 0 & te_b2m{:,2} <= 3,:);
dat2_b2m = te_b2m(te_b2m{:,11} == 1 & te_b2m{:,2} >= 0 & te_b2m{:,2} <= 3,:);


figure;
h1 = cdfplot(dat1_b2m{:,2});
h1.LineWidth = 1.25;
hold on
h2 = cdfplot(dat2_b2m{:,2});
h2.LineWidth = 1.25;
legend('Empirical CDF of (B2M|insignificant)', 'Empirical CDF of (B2M|significant)', 'Position', [0.6,-0.09,0,1],'FontSize', 8);
xlabel('average B2M ratio','FontSize', 8);
ylabel('F(X)','FontSize', 8);
title('E-CDF for Book-2-Market Ratio - Full Sample','FontSize', 9, 'FontWeight', 'normal');
% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\b2m_full.png", 'Resolution', 300);
set(gcf,'color','w');



savehandle = gcf;

% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\b2m_full.png", '-png', '-m2');

%%
% 4) Top-Mover heuristic (ranked # days a specific stock's returns have
% ended up in the top mover list (!!! max absolute not (pos) returns)

logReturns_abs_df = timetable(logReturns_daily.Var1);
for i = 1:width(logReturns_daily)
    logReturns_abs_df = addvars(logReturns_abs_df, abs(logReturns_daily{:,i})); % intriguing observattion: leave out abs and look at real ranked returns, then sig, insig ist switched
    
end

logReturns_abs_df = renamevars(logReturns_abs_df, [1:length(logReturns_daily.Properties.VariableNames)], logReturns_daily.Properties.VariableNames);
logReturns_abs_tickers = logReturns_abs_df.Properties.VariableNames;
avail_tickers = intersect(te_tickers, logReturns_abs_tickers);
logReturns_abs_df = logReturns_abs_df(:,avail_tickers);
logReturns_abs_df = logReturns_abs_df(tr,:);

logReturns_abs_mean = mean(logReturns_abs_df{:,:},1,'omitnan');

[logReturns_abs_rank, Idx] = sort(logReturns_abs_mean);

ranked_tickers = logReturns_abs_df.Properties.VariableNames(Idx);
temp = table(ranked_tickers', [1:length(ranked_tickers)]');

te_topmover = outerjoin(te_rh_vola, temp, 'Type', 'Left', 'MergeKeys', true);
te_topmover = addvars(te_topmover, [te_topmover{:,9} <= 0.05], 'NewVariableNames', 'Logic_rh_vola');

dat1_top = te_topmover(te_topmover{:,11} == 0,:);
dat2_top = te_topmover(te_topmover{:,11} == 1,:);

figure;
h1 = cdfplot(dat1_top{:,10});
h1.LineWidth = 1.25;
hold on
h2 = cdfplot(dat2_top{:,10});
h2.LineWidth = 1.25;
legend('E-CDF of (TopMoverRank|insig)', 'E-CDF of (TopMoverRank|sig)', 'Location', 'southeast','FontSize', 8);
xlabel('average absolute mover rank^{-1}','FontSize', 8);
ylabel('F(X)','FontSize', 8);
title('E-CDF for Top Mover - Full Sample','FontSize', 9, 'FontWeight', 'normal');
% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\topmover_full.png", 'Resolution', 300);
set(gcf,'color','w');



savehandle = gcf;

% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\TE_plots\topmover_full.png", '-png', '-m2');


%% Event-Study approach ###################################################
% to assess whether a leap in RH users holding triggers abnormal returns
% and a period of clustered high volaitlity regimes in the aftermath


rhood_table_agg_prct = rhood_table_agg;
% here decide whether abosulte change or prct change, for more narrow event
% identification use absolute change
temp = price2ret(rhood_table_agg{:,:}+0.0000001, [], 'Periodic'); % for now: only abs returns , [], 'Periodic')
% temp = rhood_table_agg{2:818,:}-rhood_table_agg{1:817,:};

rhood_table_agg_prct{2:818,:} = temp;
rhood_table_agg_prct = rhood_table_agg_prct(2:818,:);
%%
% func = @(x) quantile(x, [0.25 0.50 0.75, 0.975, 0.999]);
% quantiles_per_stock = varfun(func, rhood_table_agg_prct);
% 
% for i =1:width(quantiles_per_stock)
%     vec1(i) = quantiles_per_stock{1,i}(1);
%     vec2(i) = quantiles_per_stock{1,i}(2);
%     vec3(i) = quantiles_per_stock{1,i}(3);
%     vec4(i) = quantiles_per_stock{1,i}(4);
%     vec5(i) = quantiles_per_stock{1,i}(5);
% end
%%
% quantile_medians = [median(vec1, 'omitnan'), median(vec2, 'omitnan'), median(vec3, 'omitnan'), median(vec4, 'omitnan'), median(vec5, 'omitnan'), mean(vec5, 'omitnan'), max(vec5)]; % use median as heavy outliers present
%%
% identify event treshold abs change at 30%, i.e. corresponding to approx
% the 99,9% qunatile and cap at 1000% porct change which can easily be reached due to
% numerical stability correcttions, when e.g. going from 0 (=0.0000001)
% users to 1 user, which would tally to 999999900%. Or use absolute psotive
% change (ie users increasing) mean 99% qunatile corresponding to a 150
% threshold


%%
%  get viable event dates per stock
T = height(rhood_table_agg_prct);
dates = rhood_table_agg_prct.day_temp1;
tickers = rhood_table_agg_prct.Properties.VariableNames;
N = width(rhood_table_agg_prct);
events_array = cell(width(rhood_table_agg_prct),3);

% for i = 1:N
%     name = tickers(i);
%     events = dates(([rhood_table_agg_prct{:,i} >=0.3]) | ([rhood_table_agg_prct{:,i} <= -0.3])); % dates([rhood_table_agg_prct{:,i} >=100]); 
%     changes = rhood_table_agg_prct{:,i};
%     relevant_changes = changes(([rhood_table_agg_prct{:,i} >=0.3]) | ([rhood_table_agg_prct{:,i} <= -0.3]));
%     events_array{i,1} = events;
%     events_array{i,2} = name;
%     events_array{i,3} = relevant_changes;
% end

for i = 1:N
    name = tickers(i);
    events = dates(([rhood_table_agg_prct{:,i} >=0.3] & [rhood_table_agg_prct{:,i} <10]) | ([rhood_table_agg_prct{:,i} <= -0.3] & [rhood_table_agg_prct{:,i} > -10])); % dates([rhood_table_agg_prct{:,i} >=100]); 
    changes = rhood_table_agg_prct{:,i};
    relevant_changes = changes(([rhood_table_agg_prct{:,i} >=0.3] & [rhood_table_agg_prct{:,i} <10]) | ([rhood_table_agg_prct{:,i} <= -0.3]& [rhood_table_agg_prct{:,i} > -10]));
    events_array{i,1} = events;
    events_array{i,2} = name;
    events_array{i,3} = relevant_changes;
end

%% Preprocess event data
% Ascertains that for any event day with more than 30% increase in users
% holding, only the very first of such incidences is marked as an event.
% That is, consecutive days subsequent to a first event marker also
% exhibiting user changes >30% are omitted to deal with hysteresis effects.
tidy_events_array = cell(width(rhood_table_agg_prct),3);


for i = 1:N
    messy_events = events_array{i,1};
    messy_changes = events_array{i,3};
    name = events_array{i,2};
    help = 0;
    idx = 0;
    length_messy_events = length(messy_events);
    tidy_events = datetime('01-01-0001');
    tidy_changes = [0];
    disp(i);
    disp(name);
    try
        for j = 1:length_messy_events
            if j < length_messy_events
                dist = caldays(between(messy_events(j), messy_events(j+1), 'days'));
                if dist <= 1
                    help = help+1;
                    continue
                else
                    idx = idx+1;
                    tidy_events(idx) = messy_events(j-help);
                    tidy_changes(idx) = messy_changes(j-help);
                    
                    help = 0;
                    continue            
                end
            else
                idx = idx+1;
                tidy_events(idx) = messy_events(j);
                tidy_changes(idx) = messy_changes(j);
            end

        end
        tidy_events_array{i,1} = tidy_events;
        tidy_events_array{i,2} = name;
        tidy_events_array{i,3} = tidy_changes;
    catch
        tidy_events_array{i,2} = name;
        tidy_events_array{i,1} = datetime('01-01-0001');
        tidy_events_array{i,3} = [0];
        continue
    end

end


for i = 1:N
   if tidy_events_array{i,1} == datetime('01-01-0001')
       tidy_events_array{i,1} = [];
   end
end

%% messy events
% To replicate based on messy events use this section, otherwise use
% previous section

% tidy_events_array = cell(width(rhood_table_agg_prct),3);
% 
% for i = 1:N
%     messy_events = events_array{i,1};
%     messy_changes = events_array{i,3};
%     name = events_array{i,2};
% 
%     tidy_events_array{i,1} = messy_events;
%     tidy_events_array{i,2} = name;
%     tidy_events_array{i,3} = messy_changes;
% 
% 
% end
% 
% 
% for i = 1:N
%    if tidy_events_array{i,1} == datetime('01-01-0001')
%        tidy_events_array{i,1} = [];
%    end
% end
%% Normal and abnormal return measurement
% add stock returns and market returns to array
event_tickers = cell2table(tidy_events_array(:,2));
event_tickers = event_tickers{:,1};
return_tickers = logReturns_daily.Properties.VariableNames(3:width(logReturns_daily));
avail_tickers = intersect(event_tickers, return_tickers);
logReturns_daily_avail = logReturns_daily(:,avail_tickers);
N_event_all = 0;

for i = 1:N
    ticker = tidy_events_array{i,2}{1,1};
    disp(i);
    disp(ticker);
    for k = 1:length(tidy_events_array{i,1})
        event_date = tidy_events_array{i,1}(k);
        if isweekend(event_date) == 1
            continue
        elseif ismember(ticker, avail_tickers) == 0
            continue
        elseif min(rhood_table_agg{:,i}) <= 100 % rhood_table_agg{event_date-1,i} <= 100  OR min(rhood_table_agg{:,i}) <= 100 !!!! super important: ensures cap from below. May be varied, but alters all computations
            continue
        else
            id = find(logReturns_daily_avail.Var1 == event_date);
            stock_returns = logReturns_daily_avail.(ticker)(id-120:id+39); % estimation window spec is 120 trading days prior to event, excluding event day
            id2 = find(factors_daily_df.Var1 == event_date);
            market_premium = factors_daily_df{id2-120:id2+39,1}+factors_daily_df{id2-120:id2+39,4}; % catch length of event window here, ie 5 or 10, 20 or 40
            % check whether market premium (Rm-Rf) or only Rm !!!!
            
            tidy_events_array{i,k+3} = [stock_returns, market_premium];
            N_event_all = N_event_all+1;
            
        end
        
    end
    
end

%% Estimation procedure
% Prior to any aggregation concerns perform estimation procedure for each
% security and all previously idtentified events
N_event_all_temp = 0;
max_event_count = width(tidy_events_array)-3;
for i = 1:N
    disp(i);
    logic = tidy_events_array{i,1};
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = 4:(4+max_event_count-1) % using the above criteria at most length(tidy_events_array)-3 events were identified, currently 15
            event = tidy_events_array{i,j};
            if isempty(event) == 1
                continue
            else
                N_event_all_temp = N_event_all_temp+1;
                est_returns = event(1:113,1);
                event_returns = event(114:160,1); % catch length of event window here, ie 5 or 10, 20 or 40
                market_est_returns = event(1:113,2)/100; % do never trust blindlessly... ever.
                market_event_returns = event(114:160,2)/100; % catch length of event window here, ie 5 or 10, 20 or 40
                
                % deploy market model from here on with spec Ri = Xi*thetai
                % + epsi including an intersect and slope where Xi = [1',
                % Rmarket']
                Ri = est_returns;
                Xi = [ones(113,1),market_est_returns];
                theta = (Xi'*Xi)\(Xi'*Ri);
                eps_est = Ri-Xi*theta;
                res_var = eps_est'*eps_est*(1/(113-2)); % dof correction
                theta_var = (Xi'*Xi)^-1*res_var; % via CLT and LLN, asymptotically consistent
                
                % now use estimates to disentangle abnormal returns from
                % actual and expected returns, ie. abnormal = actual -
                % expected(modelled)
                Xi_event = [ones(47,1),market_event_returns]; % catch length of event window here, ie 5 or 10, 20 or 40
                abn_event_returns = event_returns-Xi_event*theta;
                norm_event_returns = Xi_event*theta;
                realised_event_returns = event_returns;
                abn_var = ones(47,47)*res_var + Xi_event*(Xi'*Xi)^-1*Xi_event'*res_var; % catch length of event window here, ie 5 or 10, 20 or 40
                new_j = max_event_count+j;
                temp_cell = cell(10,1);
                temp_cell{1,1} = abn_event_returns;
                temp_cell{2,1} = abn_var;
                temp_cell{3,1} = norm_event_returns;
                temp_cell{4,1} = realised_event_returns;
                temp_cell{5,1} = theta(1); %alpha
                temp_cell{6,1} = theta(2); %beta
                
                % 5 day rolling window beta for event window
                for k = -3:39
                   Xi_temp = Xi_event(k+4:k+8,:);
                   Ri_temp = event_returns(k+4:k+8,:);
                   theta_event = (Xi_temp'*Xi_temp)\(Xi_temp'*Ri_temp);
                   beta_series(k+4) = theta_event(2);
                   
                end
                
                
                
                temp_cell{7,1} = beta_series; %beta_series from rolling window
                temp_cell{8,1} = market_event_returns;
                temp_cell{9,1} = eps_est;
                temp_cell{10,1} = abn_var;
                tidy_events_array{i,new_j} = temp_cell;

            end

        end
    end
end
%%
% first loop to distinguish between pos and neg extreme changes
sig = 0;
sigpos = 0;
signeg = 0;
new_marker = width(tidy_events_array)+1;

for i = 1:N
    % additionally calculate average abnormal returns per stock
    % and avg CAR per stock
    return_mat_pos = [];
    market_mat_pos = [];
    return_mat_neg = [];
    market_mat_neg = [];
    event_mat_pos = [];
    event_mat_neg = [];
    count1 = 1;
    count2 = 1;
    l = 0;
    for k = (new_marker-max_event_count):(new_marker-1)
        help = tidy_events_array{i, k};
        if isempty(help)
            continue
        else
            return_temp = tidy_events_array{i, k}{1, 1};
            market_temp = tidy_events_array{i, k}{8, 1};
            event_temp = tidy_events_array{i, k}{4, 1};
            l = l+1;
            if isnan(return_temp(1))
                sig = sig+1;
                continue
            elseif tidy_events_array{i,3}(l) > 0
                return_mat_pos(:,count1) = return_temp;
                market_mat_pos(:, count1) = market_temp;
                event_mat_pos(:, count1) = event_temp;
                count1 = count1+1;
                sigpos = sigpos+1;
          
            elseif tidy_events_array{i,3}(l) < 0
                return_mat_neg(:,count2) = return_temp;
                market_mat_neg(:, count2) = market_temp;
                event_mat_neg(:, count2) = event_temp;
                count2 = count2+1;
                signeg = signeg+1;
            end
        end
    end
    
    tidy_events_array{i,new_marker} = mean(return_mat_pos, 2, 'omitnan');
    car_per_event_stock_pos = cumsum(return_mat_pos, 1, 'omitnan');
    tidy_events_array{i,new_marker+1} = mean(car_per_event_stock_pos, 2, 'omitnan');
    tidy_events_array{i,new_marker+2} = mean(return_mat_neg, 2, 'omitnan');
    car_per_event_stock_neg = cumsum(return_mat_neg, 1, 'omitnan');
    tidy_events_array{i,new_marker+3} = mean(car_per_event_stock_neg, 2, 'omitnan');
    tidy_events_array{i,new_marker+4} = mean(market_mat_pos, 2, 'omitnan');
    tidy_events_array{i,new_marker+5} = mean(market_mat_neg, 2, 'omitnan');
    tidy_events_array{i,new_marker+6} = mean(event_mat_pos, 2, 'omitnan');
    tidy_events_array{i,new_marker+7} = mean(event_mat_neg, 2, 'omitnan');
    
end

% 2nd loop to look at pos and neg extreme changes jointly
sig2 = 0;
for i = 1:N
    % additionally calculate average abnormal returns per stock
    % and avg CAR per stock
    count = 1;
    return_mat = [];
    for k = (new_marker-max_event_count):(new_marker-1)
        help = tidy_events_array{i, k};
        if isempty(help)
            
            continue
        else
            
            return_temp = tidy_events_array{i, k}{1, 1};
            if isnan(return_temp(1))
                sig2 = sig2+1;
               continue
            else
                return_mat(:,count) = return_temp;
                count = count+1;
            end
        end
    end
    
    tidy_events_array{i,new_marker+8} = mean(return_mat, 2, 'omitnan');
    car_per_event_stock = cumsum(return_mat, 1, 'omitnan');
    tidy_events_array{i,new_marker+9} = mean(car_per_event_stock, 2, 'omitnan');

    
end


%% Time averages per stock AVG and CAR

double_avg_mat_pos = [];
double_avg_mat_pos_market = [];
double_avg_mat_pos_event = [];
double_avg_car_mat_pos = [];
double_avg_mat_neg = [];
double_avg_mat_neg_market = [];
double_avg_mat_neg_event = [];
double_avg_car_mat_neg = [];
double_avg_mat = [];
double_avg_car_mat = [];
 

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, new_marker})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, new_marker};
        avg_car_temp_pos = tidy_events_array{i, new_marker+1};
        avg_temp_market_pos = tidy_events_array{i, new_marker+4};
        avg_temp_event_pos = tidy_events_array{i, new_marker+6};
        double_avg_mat_pos(:,i-count) = avg_temp_pos;
        double_avg_mat_pos_market(:,i-count) = avg_temp_market_pos;
        double_avg_mat_pos_event(:,i-count) = avg_temp_event_pos;
        double_avg_car_mat_pos(:,i-count) = avg_car_temp_pos;
%         avg_temp_neg = tidy_events_array{i, 76};
%         avg_car_temp_neg = tidy_events_array{i, 77};
%         double_avg_mat_neg(:,i-count) = avg_temp_neg;
%         double_avg_car_mat_neg(:,i-count) = avg_car_temp_neg;
%  
    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, new_marker+2})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, new_marker+2};
        avg_car_temp_neg = tidy_events_array{i, new_marker+3};
        avg_temp_market_neg = tidy_events_array{i, new_marker+5};
        avg_temp_event_neg = tidy_events_array{i, new_marker+7};
        double_avg_mat_neg(:,i-count) = avg_temp_neg;
        double_avg_mat_neg_market(:,i-count) = avg_temp_market_neg;
        double_avg_mat_neg_event(:,i-count) = avg_temp_event_neg;
        double_avg_car_mat_neg(:,i-count) = avg_car_temp_neg;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, new_marker+8})
        count = count+1;
        continue
    else
        avg_temp = tidy_events_array{i, new_marker+8};
        avg_car_temp = tidy_events_array{i, new_marker+9};
        double_avg_mat(:,i-count) = avg_temp;
        double_avg_car_mat(:,i-count) = avg_car_temp;

    end   
end
% Cross-Sectional averaging
double_avg_pos = mean(double_avg_mat_pos, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_car_pos = mean(double_avg_car_mat_pos, 2, 'omitnan');

double_avg_neg = mean(double_avg_mat_neg, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_car_neg = mean(double_avg_car_mat_neg, 2, 'omitnan');

double_avg = mean(double_avg_mat, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_car = mean(double_avg_car_mat, 2, 'omitnan');


% BHAR calculation and averaging

double_avg_market_pos = mean(double_avg_mat_pos_market, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_market_neg = mean(double_avg_mat_neg_market, 2, 'omitnan'); % 2 NaNs introduced, simply skip

double_avg_event_pos = mean(double_avg_mat_pos_event, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_event_neg = mean(double_avg_mat_neg_event, 2, 'omitnan'); % 2 NaNs introduced, simply skip

BHAR_avg_pos = [];
BHAR_avg_neg = [];

for t = 1:47
    pos_bhar_temp = prod((double_avg_event_pos(1:t)+1));
    pos_bhar_market_temp = prod((double_avg_market_pos(1:t)+1));
    BHAR_avg_pos(t) = pos_bhar_temp - pos_bhar_market_temp;
    neg_bhar_temp = prod((double_avg_event_neg(1:t)+1));
    neg_bhar_market_temp = prod((double_avg_market_neg(1:t)+1));
    BHAR_avg_neg(t) = neg_bhar_temp - neg_bhar_market_temp;
    
end

BHAR_avg_pos = cumprod(double_avg_event_pos+1)- cumprod(double_avg_market_pos+1);


BHAR_avg_pos720 = cumprod(double_avg_event_pos(8:28)+1) - cumprod(double_avg_market_pos(8:28)+1);


CAAR_avg_pos720 = cumsum(double_avg_event_pos(8:28), 1, 'omitnan');
%%
figure;
subplot(3,1,1);

plot(-7:12, double_avg_pos(1:20), -7:12, double_avg_car_pos(1:20), 'LineWidth', 1.25);
title("(a) AAR and CAAR for Positive Events",'FontSize', 9, 'FontWeight', 'normal');
yline(0);
grid on
grid minor
subplot(3,1,2);
plot(-7:12, double_avg_neg(1:20), -7:12, double_avg_car_neg(1:20), 'LineWidth', 1.25);
title("(b) AAR and CAAR for Negative Events",'FontSize', 9, 'FontWeight', 'normal');
ylabel("AAR and CAAR",'FontSize', 8);
yline(0);
legend("AAR","CAAR^{avg}", "zero",'FontSize', 8);
grid on
grid minor
subplot(3,1,3);

plot(-7:12, double_avg(1:20), -7:12, double_avg_car(1:20), 'LineWidth', 1.25);
title("(c) AAR and CAAR for All Events",'FontSize', 9, 'FontWeight', 'normal');
xlabel("days relative to event",'FontSize', 8);
yline(0);
grid on
grid minor
set(gcf,'color','w');
savehandle = gcf;
% %
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_min100_30_tidy.png.png", '-png', '-m2');
%%
figure;

subplot(2,2,[1,2]);
plot(-7:20, double_avg_pos(1:28), -7:20, double_avg_car_pos(1:28), -7:20, BHAR_avg_pos(1:28), 'LineWidth', 1.25);
yline(0);
xline(0);
title("(a) AAR, CAAR and BHAAR for Positive Events",'FontSize', 9, 'FontWeight', 'normal');
xlabel("days relative to event",'FontSize', 8);
ylabel("AAR, CAAR, BHAAR",'FontSize', 8);
legend("AAR^{+}","CAAR^{+}", "BHAAR^{+}", "zero",'FontSize', 8);
grid on
grid minor
subplot(2,2,3);
plot(-7:20, double_avg_car_pos(1:28), 'LineWidth', 1.25, 'Color', [0.8500 0.3250 0.0980]);
hold on
plot(-7:20, BHAR_avg_pos(1:28), 'LineWidth', 1.25, 'Color', [0.9290 0.6940 0.1250]);
hold off
title("(b) CAAR^{+}, BHAAR^{+} for (-7,20)",'FontSize', 9, 'FontWeight', 'normal');
xlabel("days relative to event",'FontSize', 8);
ylabel("CAAR, BHAAR",'FontSize', 8);
yline(0);
xline(0);
ylim([min(min([double_avg_car_pos(1:28) BHAR_avg_pos(1:28)]))-0.005 max(max([double_avg_car_pos(1:28) BHAR_avg_pos(1:28)]))+0.005]);
grid on
grid minor
subplot(2,2,4);
plot(0:20, double_avg_car_pos(8:28)-double_avg_car_pos(8), 'LineWidth', 1.25, 'Color', [0.8500 0.3250 0.0980]);
hold on
plot(0:20, BHAR_avg_pos(8:28)-BHAR_avg_pos(8), 'LineWidth', 1.25, 'Color', [0.9290 0.6940 0.1250]); % BHAR_avg_pos(8:28)-BHAR_avg_pos(8)
hold off
title("(c) CAAR^{+}, BHAAR^{+} for (0,20)",'FontSize', 9, 'FontWeight', 'normal');
xlabel("days relative to event",'FontSize', 8);
grid on
grid minor
set(gcf,'color','w');



savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_overview_pos_BHAR_min100_30_tidy_test.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_overview_pos_BHAR_min100_30_tidy.png", '-png', '-m2');

%% Appendix tidy vs messy and event cutoff comparison

% messy_min100_30_double_avg_pos = double_avg_pos;
% messy_min100_30_double_avg_car_pos = double_avg_car_pos;
% messy_min100_30_BHAR_avg_pos = BHAR_avg_pos;
% 
% 
% 
% figure;
% 
% subplot(2,3,1);
% plot(-7:20, tidy_min100_30_double_avg_pos(1:28), -7:20, tidy_min100_30_double_avg_car_pos(1:28), -7:20, tidy_min100_30_BHAR_avg_pos(1:28), 'LineWidth', 1.25);
% yline(0);
% xline(0);
% title(["(a) AAR, CAAR and BHAAR for Positive Events,"," min 100, 30% Cut-Off and Tidy"],'FontSize', 10, 'FontWeight', 'normal');
% ylim([-0.05 0.25]);
% ylabel("AAR, CAAR, BHAAR",'FontSize', 9);
% xlim([-7 20]);
% grid on
% grid minor
% subplot(2,3,2);
% plot(-7:20, tidy_min100_50_double_avg_pos(1:28), -7:20, tidy_min100_50_double_avg_car_pos(1:28), -7:20, tidy_min100_50_BHAR_avg_pos(1:28), 'LineWidth', 1.25);
% yline(0);
% xline(0);
% title(["(b) AAR, CAAR and BHAAR for Positive Events,"," min 100, 50% Cut-Off and Tidy"],'FontSize', 10, 'FontWeight', 'normal');
% xlim([-7 20]);
% grid on
% grid minor
% subplot(2,3,3);
% plot(-7:20, tidy_min100_70_double_avg_pos(1:28), -7:20, tidy_min100_70_double_avg_car_pos(1:28), -7:20, tidy_min100_70_BHAR_avg_pos(1:28), 'LineWidth', 1.25);
% yline(0);
% xline(0);
% xlim([-7 20]);
% title(["(c) AAR, CAAR and BHAAR for Positive Events,"," min 100, 70% Cut-Off and Tidy"],'FontSize', 10, 'FontWeight', 'normal');
% 
% legend("AAR^{+}","CAAR^{+}", "BHAAR^{+}", "zero",'FontSize', 8);
% grid on
% grid minor
% subplot(2,3,4);
% plot(-7:20, messy_min100_30_double_avg_pos(1:28), -7:20, messy_min100_30_double_avg_car_pos(1:28), -7:20, messy_min100_30_BHAR_avg_pos(1:28), 'LineWidth', 1.25);
% yline(0);
% xline(0);
% xlim([-7 20]);
% ylim([-0.05 0.25])
% title(["(d) AAR, CAAR and BHAAR for Positive Events,"," min 100, 30% Cut-Off and Messy"],'FontSize', 10, 'FontWeight', 'normal');
% xlabel("days relative to event",'FontSize', 9);
% ylabel("AAR, CAAR, BHAAR",'FontSize', 9);
% 
% grid on
% grid minor
% subplot(2,3,5);
% plot(-7:20, messy_min100_50_double_avg_pos(1:28), -7:20, messy_min100_50_double_avg_car_pos(1:28), -7:20, messy_min100_50_BHAR_avg_pos(1:28), 'LineWidth', 1.25);
% yline(0);
% xline(0);
% xlim([-7 20]);
% title(["(e) AAR, CAAR and BHAAR for Positive Events,"," min 100, 50% Cut-Off and Messy"],'FontSize', 10, 'FontWeight', 'normal');
% xlabel("days relative to event",'FontSize', 9);
% 
% 
% grid on
% grid minor
% subplot(2,3,6);
% plot(-7:20, messy_min100_70_double_avg_pos(1:28), -7:20, messy_min100_70_double_avg_car_pos(1:28), -7:20, messy_min100_70_BHAR_avg_pos(1:28), 'LineWidth', 1.25);
% yline(0);
% xline(0);
% xlim([-7 20]);
% title(["(f) AAR, CAAR and BHAAR for Positive Events,"," min 100, 70% Cut-Off and Messy"],'FontSize', 10, 'FontWeight', 'normal');
% xlabel("days relative to event",'FontSize', 9);
% 
% legend("AAR^{+}","CAAR^{+}", "BHAAR^{+}", "zero",'FontSize', 8);
% grid on
% grid minor

%% Robustness test and hypothesis testing ################################
% in order to conduct conventional inference on the estimates, (admittedly
% rather arbitrarily) I subset the securities according to the number of
% available events and omit all events that share a mutual/overlapping
% windows of X days (here 10, as afterwards daily average returns become
% negligible and are likely to not being governed ynmore by event
% repercussions). The remainder of events can then be deemed mutually
% exclusive and non overlapping thereby enabling standard inference w/o
% clustering as in Campbell

%% Export table

exporttable = table([-7:39]', double_avg_pos, double_avg_car_pos, BHAR_avg_pos, double_avg_neg, double_avg_car_neg, BHAR_avg_neg');
exporttable.Variables = round(exporttable.Variables,4);

exporttable020 = table([0:20]', double_avg_event_pos(8:28), CAAR_avg_pos720, BHAR_avg_pos720);
exporttable020.Variables = round(exporttable020.Variables,4);

%% Inference following Campbell

inference_tidy_events_array = tidy_events_array(:,1:3);
var_cell_pos = zeros(47,47);
var_cell_neg = zeros(47,47);
for i = 1:N
    % additionally calculate average abnormal returns per stock
    % and avg CAR per stock
    abn_ret_pos = [];
    abn_ret_neg = [];


    count1 = 1;
    count2 = 1;
    l = 0;
    for k = (new_marker-max_event_count):(new_marker-1)
        help = tidy_events_array{i, k};
        if isempty(help)
            continue
        else
            abn_ret_temp = tidy_events_array{i, k}{1, 1};
            var_temp = tidy_events_array{i, k}{10, 1};
            l = l+1;
            if isnan(abn_ret_temp(1))
                sig = sig+1;
                continue
            elseif tidy_events_array{i,3}(l) > 0

                abn_ret_pos(:,count1) = abn_ret_temp;
                var_cell_pos = cat(3,var_cell_pos,var_temp);
                count1 = count1+1;
                sigpos = sigpos+1;
          
            elseif tidy_events_array{i,3}(l) < 0
                abn_ret_neg(:,count2) = abn_ret_temp;
                var_cell_neg = cat(3,var_cell_neg,var_temp);
                count2 = count2+1;
                signeg = signeg+1;
            end
        end
    end
    
    inference_tidy_events_array{i,4} = mean(abn_ret_pos, 2, 'omitnan');
    inference_tidy_events_array{i,5} = mean(abn_ret_neg, 2, 'omitnan');

    
end


avg_abn_temp_mat_pos = [];

count = 0;
for i = 1:N
    if isempty(inference_tidy_events_array{i, 4})
        count = count+1;
        continue
    else
        avg_abn_temp_pos = inference_tidy_events_array{i, 4};

        avg_abn_temp_mat_pos(:,i-count) = avg_abn_temp_pos;

    end   
end


avg_abn_temp_mat_neg = [];

count = 0;
for i = 1:N
    if isempty(inference_tidy_events_array{i, 5})
        count = count+1;
        continue
    else
        avg_abn_temp_neg = inference_tidy_events_array{i, 5};

        avg_abn_temp_mat_neg(:,i-count) = avg_abn_temp_neg;



    end   
end

VAR_pos = (size(var_cell_pos,3))^-2*sum(var_cell_pos,3, 'omitnan');
VAR_neg = (size(var_cell_neg,3))^-2*sum(var_cell_neg,3, 'omitnan');
CAR_pos = mean(avg_abn_temp_mat_pos, 2, 'omitnan');
CAR_neg = mean(avg_abn_temp_mat_neg, 2, 'omitnan');


VAR_pos_tau = [];
VAR_neg_tau = [];
CAR_pos_tau = [];
CAR_neg_tau = [];
J_pos = [];
J_neg = [];
for t = 1:47
    gamma = [ones(t,1); zeros(47-t,1)];
    VAR_pos_tau(t) = gamma'*VAR_pos*gamma;
    CAR_pos_tau(t) = gamma'*CAR_pos;
    VAR_neg_tau(t) = gamma'*VAR_pos*gamma;
    CAR_neg_tau(t) = gamma'*CAR_neg;
    J_pos(t) = CAR_pos_tau(t)/sqrt(VAR_pos_tau(t));
    J_neg(t) = CAR_neg_tau(t)/sqrt(VAR_neg_tau(t));
    
end

p_val_J_pos = 2*(1-normcdf(J_pos,0,1));
p_val_J_neg = 2*(1-normcdf(J_neg,0,1));

exporttable_p = table([-7:39]', p_val_J_pos', p_val_J_neg');
exporttable_p.Variables = round(exporttable_p.Variables,4);


%% Add Control Variables ##################################################
% 1) start with market cap ################################################
% load market value from csv
market_value = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\control_variables\market_value.csv",'ReadVariableNames',1);
market_value = market_value(52:1309,:); % remove null entries that appeared due to limited balance sheet data availability

market_value_tt = table2timetable(market_value, 'RowTimes', 'Var1');

market_value_tt = market_value_tt(tr,:);
market_value_tt = rmmissing(market_value_tt, 2, 'MinNumMissing', height(market_value_tt));
market_val_tickers = market_value_tt.Properties.VariableNames(3:width(market_value_tt));

for i = 1:N
   ticker = tidy_events_array{i,2}{1,1};
   temp = intersect(ticker, market_val_tickers);
   if isempty(temp)
       
       continue
   elseif isempty(tidy_events_array{i,42})
       continue
   else
       stock_market_val = market_value_tt.(ticker);
       mean_market_val = mean(stock_market_val, 'omitnan');
       tidy_events_array{i,44} = mean_market_val;
   end
   
    
end


count = 0;
for i = 1:N
    if isempty(tidy_events_array{i,44})
        count = count+1;
        continue
    elseif  isempty(tidy_events_array{i,42})
        count = count+1;
        continue
    else
        tic = tidy_events_array{i,2}{1,1};
        market_val = tidy_events_array{i,44};
        all_market_vals(i-count) = market_val;  
    end
end

market_val_quantiles = quantile(all_market_vals, [0.05 0.5 0.95]); % decide here which quantile cuts to use
threshold_market_val_up = market_val_quantiles(3);
threshold_market_val_low = market_val_quantiles(1);

for i = 1:N
    if isempty(tidy_events_array{i,44})
        continue
    elseif tidy_events_array{i,44} >= threshold_market_val_up
        tidy_events_array{i,45} = 1;
    elseif tidy_events_array{i,44} <= threshold_market_val_low
        tidy_events_array{i,45} = -1;
    else
        tidy_events_array{i,45} = 0;
        
    end

end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 34})
        count = count+1;
        continue
    elseif tidy_events_array{i, 45} == 1
        avg_temp_mktval_up_pos = tidy_events_array{i, 34};
        avg_car_temp_mktval_up_pos = tidy_events_array{i, 35};
        double_avg_mat_mktval_up_pos(:,i-count) = avg_temp_mktval_up_pos;
        double_avg_car_mat_mktval_up_pos(:,i-count) = avg_car_temp_mktval_up_pos;
    else
        count = count+1;

    end   
end
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 34})
        count = count+1;
        continue

        
    elseif tidy_events_array{i, 45} == 0
        avg_temp_mktval_iqr_pos = tidy_events_array{i, 34};
        avg_car_temp_mktval_iqr_pos = tidy_events_array{i, 35};
        double_avg_mat_mktval_iqr_pos(:,i-count) = avg_temp_mktval_iqr_pos;
        double_avg_car_mat_mktval_iqr_pos(:,i-count) = avg_car_temp_mktval_iqr_pos;
    else
        count = count+1;

        

    end   
end
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 34})
        count = count+1;
        continue
        
    elseif tidy_events_array{i, 45} == -1
        avg_temp_mktval_low_pos = tidy_events_array{i, 34};
        avg_car_temp_mktval_low_pos = tidy_events_array{i, 35};
        double_avg_mat_mktval_low_pos(:,i-count) = avg_temp_mktval_low_pos;
        double_avg_car_mat_mktval_low_pos(:,i-count) = avg_car_temp_mktval_low_pos;
    else
        count = count+1;
        

    end   
end

double_avg_mktval_up_pos = mean(double_avg_mat_mktval_up_pos, 2, 'omitnan'); 
double_avg_car_mktval_up_pos = mean(double_avg_car_mat_mktval_up_pos, 2, 'omitnan');

double_avg_mktval_iqr_pos = mean(double_avg_mat_mktval_iqr_pos, 2, 'omitnan'); 
double_avg_car_mktval_iqr_pos = mean(double_avg_car_mat_mktval_iqr_pos, 2, 'omitnan');

double_avg_mktval_low_pos = mean(double_avg_mat_mktval_low_pos, 2, 'omitnan'); 
double_avg_car_mktval_low_pos = mean(double_avg_car_mat_mktval_low_pos, 2, 'omitnan');
%%
figure;
subplot(3,1,1);
plot(-7:12, double_avg_mktval_up_pos(1:20), -7:12, double_avg_car_mktval_up_pos(1:20), 'LineWidth', 1.25);
title("(a) AAR and CAAR for Positive Events for Top 5% Percentile of Market Cap",'FontSize', 9, 'FontWeight', 'normal');
yline(0);
grid on
grid minor
subplot(3,1,2);
plot(-7:12, double_avg_mktval_iqr_pos(1:20), -7:12, double_avg_car_mktval_iqr_pos(1:20), 'LineWidth', 1.25);
title("(b) AAR and CAAR for Positive Events and 5%-95% of Market Cap",'FontSize', 9, 'FontWeight', 'normal');
yline(0);
grid on
grid minor
ylabel("AAR and CAAR",'FontSize', 8);
legend("AAR","CAAR", "zero",'FontSize', 8);
subplot(3,1,3);

plot(-7:12, double_avg_mktval_low_pos(1:20), -7:12, double_avg_car_mktval_low_pos(1:20), 'LineWidth', 1.25);
title("(c) AAR and CAAR for Positive Events for Bottom 95% Percentile of Market Cap",'FontSize', 9, 'FontWeight', 'normal');
xlabel("days relative event day",'FontSize', 8);
yline(0);
grid on
grid minor
set(gcf,'color','w');



savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_overview_pos_BHAR_min100_30_tidy_test.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_positive_marketcap_5_95_min100_30_tidy.png", '-png', '-m2');


%% GARCH vola estimation for abnormal return series #######################

% for each abnormal returns series per event per stock estimate a
% GARCH(1,1) spec and extract the implied vola series
span = (width(tidy_events_array)+1)-(new_marker-max_event_count);
for i = 1:N
    disp(i);
    logic = tidy_events_array{i,1};
    
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = (new_marker-max_event_count):(new_marker-1)
            event = tidy_events_array{i,j};
            if isempty(event) == 1
                continue
            elseif isnan(tidy_events_array{i,j}{1,1}(1))
                continue
            else
                abnormal_returns = tidy_events_array{i,j}{1,1};
                %abnormal_returns = abnormal_returns - mean(abnormal_returns, 'omitnan');
%                 mdl = garch(1,1); % fit garch(1,1) to data and infer corresponding cond variances (std dev) !!!!! MAYBE USE ARIMAX GARCH as well
                mdl = arima(0,0,0);
                mdl.Constant = NaN;
                mdl.Variance = garch(1,1);
%                 mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
                est = estimate(mdl, abnormal_returns);
                [res,sigma, logL] = infer(est, abnormal_returns); % extract cond var series !!!! Additionally infer residuals
                res_cell = cell(2,1);
                res_cell{1,1} = res;
                res_cell{2,1} = sigma; % codnitinal variances!!! not std dev
                tidy_events_array{i,j+span} = res_cell; %span = 27?

            end

        end
    end
end

%%
new_marker_1 = width(tidy_events_array)+1; % 61
for i = 1:N
    % additionally calculate average abnormal vola per stock
    % and avg CAR per stock
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos = [];
        vola_mat_neg = [];
        count1 = 1;
        count2 = 1;
        l=0;
        for k = (new_marker_1-max_event_count):(new_marker_1-1) % 46-60
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = sqrt(tidy_events_array{i, k}{2,1});
                l = l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,new_marker_1} = mean(vola_mat_pos, 2);

        tidy_events_array{i,new_marker_1+1} = mean(vola_mat_neg, 2);

    end
    
end


double_avg_mat_pos_vola = [];

double_avg_mat_neg_vola = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, new_marker_1})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, new_marker_1};
        double_avg_mat_pos_vola(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, new_marker_1+1})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, new_marker_1+1};
        double_avg_mat_neg_vola(:,i-count) = avg_temp_neg;


    end   
end

double_avg_pos_vola = mean(double_avg_mat_pos_vola, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola = mean(double_avg_mat_neg_vola, 2, 'omitnan'); % 2 NaNs introduced, simply skip

%%
figure;
subplot(3,2,[1,2]);
plot(-7:39, double_avg_pos_vola(1:47),-7:39, double_avg_neg_vola(1:47), 'LineWidth', 1.25);
title("(a) AAV for Positive and Negative Events from GARCH(1,1) on abnormal returns",'FontSize', 10, 'FontWeight', 'normal');
ylabel("h_{abn}", 'FontSize', 8);
grid on
grid minor

legend("AAV^+","AAV^{-}", 'FontSize', 8);
xlabel("days relative to event", 'FontSize', 8);
subplot(3,2,3);
autocorr(double_avg_pos_vola, 'NumLags', 39);
title("(b) AAV ACF for Positive Events",'FontSize', 10, 'FontWeight', 'normal');
subplot(3,2,4);
autocorr(double_avg_neg_vola, 'NumLags', 39);
title("(c) AAV ACF for Negative Events",'FontSize', 10, 'FontWeight', 'normal');
subplot(3,2,5);
autocorr((double_avg_pos-mean(double_avg_pos))./sqrt(double_avg_pos_vola), 'NumLags', 39);
title("(d) AVG Std. Residuals for Positive Events",'FontSize', 10, 'FontWeight', 'normal');
subplot(3,2,6);
autocorr((double_avg_neg-mean(double_avg_neg))./sqrt(double_avg_neg_vola), 'NumLags', 39);
title("(e) AVG Std. Residuals for Negative Events",'FontSize', 10, 'FontWeight', 'normal');

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\ACF_abnvola_min100_30_tidy.png", 'Resolution', 300);
set(gcf,'color','w');
savehandle = gcf;
% %
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\ACF_abnvola_min100_30_tidy.png", '-png', '-m2');

%% Normal and realised GARCH
% for each normal and realised returns series per event per stock estimate a
% GARCH(1,1) spec and extract the implied vola series

% for i = 1:N
%     disp(i);
%     logic = tidy_events_array{i,1};
%     
%     if isa(logic, 'datetime') == 0
%         continue
%     else
%         for j = 39:73
%             event = tidy_events_array{i,j};
%             if isempty(event) == 1
%                 continue
%             elseif isnan(tidy_events_array{i,j}{3,1}(1)) 
%                 continue
%             else
%                 normal_returns = tidy_events_array{i,j}{3,1};
%                 %normal_returns = normal_returns - mean(normal_returns, 'omitnan');
%                 mdl = garch(1,1); % fit garch(1,1) to data and infer corresponding cond variances (std dev)
%                 est = estimate(mdl, normal_returns);
%                 sigma = infer(est, normal_returns); % extract cond std dev series
%                 tidy_events_array{i,j+80} = sigma;
% 
%             end
% 
%         end
%     end
% end
% 
% 
% 
% for i = 1:N
%     disp(i);
%     logic = tidy_events_array{i,1};
%     
%     if isa(logic, 'datetime') == 0
%         continue
%     else
%         for j = 39:73
%             event = tidy_events_array{i,j};
%             if isempty(event) == 1
%                 continue
%             elseif isnan(tidy_events_array{i,j}{4,1}(1)) 
%                 continue
%             else
%                 realised_returns = tidy_events_array{i,j}{4,1};
%                 %realised_returns = realised_returns - mean(realised_returns, 'omitnan');
% %                 mdl = garch(1,1); % fit garch(1,1) to data and infer corresponding cond variances (std dev)
%                 mdl = garch(1,1);
%                 est = estimate(mdl, realised_returns); % https://de.mathworks.com/help/econ/arima.estimate.html
%                 sigma = infer(est, realised_returns); % extract cond std dev series
%                 tidy_events_array{i,j+115} = sigma;
% 
%             end
% 
%         end
%     end
% end

%% Normal and realised GARCH
% for each normal and realised returns series per event per stock estimate a
% GARCH(1,1) spec and extract the implied vola series

% different approach with arima mdl instead of pure garch
span = (width(tidy_events_array)+1)-(new_marker-max_event_count); % 44
for i = 1:N
    disp(i);
    logic = tidy_events_array{i,1};
    
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = (new_marker-max_event_count):(new_marker-1)
            event = tidy_events_array{i,j};
            if isempty(event) == 1
                continue
            elseif isnan(tidy_events_array{i,j}{3,1}(1)) 
                continue
            else


                normal_returns = tidy_events_array{i,j}{3,1};
                %abnormal_returns = abnormal_returns - mean(abnormal_returns, 'omitnan');
%                 mdl = garch(1,1); % fit garch(1,1) to data and infer corresponding cond variances (std dev) !!!!! MAYBE USE ARIMAX GARCH as well
                mdl = arima(0,0,0);
                mdl.Constant = NaN;
                mdl.Variance = garch(1,1);
%                 mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
                est = estimate(mdl, normal_returns);
                [res,sigma,logL] = infer(est, normal_returns); % extract cond std dev series !!!! Additionally infer residuals
                res_cell = cell(2,1);
                res_cell{1,1} = res;
                res_cell{2,1} = sigma; % variance terms not std dev!!
                tidy_events_array{i,j+44} = res_cell; %span = 44?
            end

        end
    end
end

%%
span = (width(tidy_events_array)+1)-(new_marker-max_event_count);
for i = 1:N
    disp(i);
    
    logic = tidy_events_array{i,1};
    
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = (new_marker-max_event_count):(new_marker-1)
            event = tidy_events_array{i,j};
            if isempty(event) == 1
                continue
            elseif isnan(tidy_events_array{i,j}{4,1}(1)) 
                continue
            else

                realised_returns = tidy_events_array{i,j}{4,1};
                %abnormal_returns = abnormal_returns - mean(abnormal_returns, 'omitnan');
%                 mdl = garch(1,1); % fit garch(1,1) to data and infer corresponding cond variances (std dev) !!!!! MAYBE USE ARIMAX GARCH as well
                mdl = arima(0,0,0);
                mdl.Constant = NaN;
                mdl.Variance = garch(1,1);
%                 mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
                est = estimate(mdl, realised_returns);
                [res,sigma, logL] = infer(est, realised_returns); % extract cond std dev series !!!! Additionally infer residuals
                res_cell = cell(2,1);
                res_cell{1,1} = res;
                res_cell{2,1} = sigma; % variance terms not std dev!!
                tidy_events_array{i,j+span} = res_cell;

            end

        end
    end
end

%%

for i = 1:N
    % additionally calculate average normal vola per stock
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos_normal = [];
        vola_mat_neg_normal = [];
        count1 = 1;
        count2 = 1;
        l = 0;
        for k = 63:77
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = sqrt(tidy_events_array{i, k}{2,1});
                l = l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos_normal(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg_normal(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,93} = mean(vola_mat_pos_normal, 2);

        tidy_events_array{i,94} = mean(vola_mat_neg_normal, 2);

    end
    
end

for i = 1:N
    % additionally calculate realised normal vola per stock
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos_realised = [];
        vola_mat_neg_realised = [];
        count1 = 1;
        count2 = 1;
        l = 0;
        for k = 78:92
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = sqrt(tidy_events_array{i, k}{2,1});
                l=l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos_realised(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg_realised(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,95} = mean(vola_mat_pos_realised, 2);

        tidy_events_array{i,96} = mean(vola_mat_neg_realised, 2);

    end
    
end


double_avg_mat_pos_vola_normal = [];

double_avg_mat_neg_vola_normal = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 93})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, 93};
        double_avg_mat_pos_vola_normal(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 94})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, 94};
        double_avg_mat_neg_vola_normal(:,i-count) = avg_temp_neg;


    end   
end

double_avg_pos_vola_normal = mean(double_avg_mat_pos_vola_normal, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola_normal = mean(double_avg_mat_neg_vola_normal, 2, 'omitnan'); % 2 NaNs introduced, simply skip

double_avg_mat_pos_vola_realised = [];

double_avg_mat_neg_vola_realised = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 95})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, 95};
        double_avg_mat_pos_vola_realised(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 96})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, 96};
        double_avg_mat_neg_vola_realised(:,i-count) = avg_temp_neg;


    end   
end

double_avg_pos_vola_realised = mean(double_avg_mat_pos_vola_realised, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola_realised = mean(double_avg_mat_neg_vola_realised, 2, 'omitnan'); % 2 NaNs introduced, simply skip

%%
figure;
subplot(2,1,1);
plot(-7:39, double_avg_pos_vola_realised, -7:39, double_avg_pos_vola_normal, 'LineWidth', 1.25);%, -7:39, double_avg_pos_vola_realised, -7:39, double_avg_pos_vola_realised-double_avg_pos_vola_normal);
title("(a) GARCH(1,1) fitted AVG Conditional Volatility",'FontSize', 10, 'FontWeight', 'normal');
legend("realised", "normal", 'FontSize', 8);
ylabel("h_{real}, h_{norm}", 'FontSize', 8);
grid on
grid minor
subplot(2,1,2);
plot(-7:39, (double_avg_pos_vola_realised)./(double_avg_pos_vola_normal), 'LineWidth', 1.25, 'Color', [0.9290 0.6940 0.1250]);%, -7:39, double_avg_pos_vola_normal./double_avg_pos_vola_realised);
title("(b) Ratio",'FontSize', 10, 'FontWeight', 'normal');
yline(1);
legend("realised/normal");%, "normal/realised");
ylabel("Ratio", 'FontSize', 8);
xlabel("days relative to event", 'FontSize', 8);
grid on
grid minor
% 
% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
set(gcf,'color','w');
savehandle = gcf;
% %
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", '-png', '-m2');



max_abn_ratio_garch = maxAR(double_avg_pos_vola_realised,0);
%% Stratyfying by market cap ##############################################
market_val_quantiles = quantile(all_market_vals, [0.25 0.5 0.75]); % decide here which quantile cuts to use
threshold_market_val_up = market_val_quantiles(3);
threshold_market_val_low = market_val_quantiles(1);

for i = 1:N
    if isempty(tidy_events_array{i,44})
        continue
    elseif tidy_events_array{i,44} >= threshold_market_val_up
        tidy_events_array{i,45} = 1;
    elseif tidy_events_array{i,44} <= threshold_market_val_low
        tidy_events_array{i,45} = -1;
    else
        tidy_events_array{i,45} = 0;
        
    end

end
%%
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 93}) | isempty(tidy_events_array{i, 95})
        count = count+1;
        continue
    elseif tidy_events_array{i, 45} == 1
        avg_temp_mktval_up_pos_vola_normal = tidy_events_array{i, 93};
        avg_temp_mktval_up_pos_vola_realised = tidy_events_array{i, 95};
        double_avg_vola_mat_mktval_up_pos_normal(:,i-count) = avg_temp_mktval_up_pos_vola_normal;
        double_avg_vola_mat_mktval_up_pos_realised(:,i-count) = avg_temp_mktval_up_pos_vola_realised;
    else
        count = count+1;

    end   
end
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 93}) | isempty(tidy_events_array{i, 95})
        count = count+1;
        continue

        
    elseif tidy_events_array{i, 45} == 0
        avg_temp_mktval_up_iqr_vola_normal = tidy_events_array{i, 93};
        avg_temp_mktval_up_iqr_vola_realised = tidy_events_array{i, 95};
        double_avg_vola_mat_mktval_up_iqr_normal(:,i-count) = avg_temp_mktval_up_iqr_vola_normal;
        double_avg_vola_mat_mktval_up_iqr_realised(:,i-count) = avg_temp_mktval_up_iqr_vola_realised;
    else
        count = count+1;

        

    end   
end
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 93}) | isempty(tidy_events_array{i, 95})
        count = count+1;
        continue
        
    elseif tidy_events_array{i, 45} == -1
        avg_temp_mktval_up_low_vola_normal = tidy_events_array{i, 93};
        avg_temp_mktval_up_low_vola_realised = tidy_events_array{i, 95};
        double_avg_vola_mat_mktval_up_low_normal(:,i-count) = avg_temp_mktval_up_low_vola_normal;
        double_avg_vola_mat_mktval_up_low_realised(:,i-count) = avg_temp_mktval_up_low_vola_realised;
    else
        count = count+1;
        

    end   
end

double_avg_vola_mktval_up_pos_normal = mean(double_avg_vola_mat_mktval_up_pos_normal,2, 'omitnan');
double_avg_vola_mktval_up_pos_realised = mean(double_avg_vola_mat_mktval_up_pos_realised, 2, 'omitnan');

double_avg_vola_mktval_up_iqr_normal = mean(double_avg_vola_mat_mktval_up_iqr_normal, 2, 'omitnan'); 
double_avg_vola_mktval_up_iqr_realised = mean(double_avg_vola_mat_mktval_up_iqr_realised, 2, 'omitnan');

double_avg_vola_mktval_up_low_normal = mean(double_avg_vola_mat_mktval_up_low_normal, 2, 'omitnan'); 
double_avg_vola_mktval_up_low_realised = mean(double_avg_vola_mat_mktval_up_low_realised, 2, 'omitnan');

%%
figure;
subplot(4,1,1);
plot(-7:12, double_avg_vola_mktval_up_pos_realised(1:20), -7:12, double_avg_vola_mktval_up_pos_normal(1:20), 'LineWidth', 1.25);
title("(a) h_{real} and h_{norm} for positive events for top 25% percentile of market cap",'FontSize', 10, 'FontWeight', 'normal');
xline(0);
grid on
grid minor
subplot(4,1,2);
plot(-7:12, double_avg_vola_mktval_up_iqr_realised(1:20), -7:12, double_avg_vola_mktval_up_iqr_normal(1:20),  'LineWidth', 1.25);
title("(b) h_{real} and h_{norm} for positive events and IQR of market cap",'FontSize', 10, 'FontWeight', 'normal');
xline(0);
grid on
grid minor
ylabel("h_{real}, h_{norm}", 'FontSize', 8);
legend("h_{real}","h_{norm}", 'FontSize', 6);

subplot(4,1,3);

plot(-7:12, double_avg_vola_mktval_up_low_realised(1:20), -7:12, double_avg_vola_mktval_up_low_normal(1:20), 'LineWidth', 1.25);
title("(c) h_{real} and h_{norm} for positive only events for bottom 25% percentile of market cap",'FontSize', 10, 'FontWeight', 'normal');
xline(0);
grid on
grid minor
subplot(4,1,4);

plot(-7:12, double_avg_vola_mktval_up_pos_realised(1:20)./double_avg_vola_mktval_up_pos_normal(1:20), 'Color', [0.6350 0.0780 0.1840], 'LineWidth', 1.25);
hold on
plot(-7:12, double_avg_vola_mktval_up_iqr_realised(1:20)./double_avg_vola_mktval_up_iqr_normal(1:20), 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 1.25);
hold on
plot(-7:12,double_avg_vola_mktval_up_low_realised(1:20)./double_avg_vola_mktval_up_low_normal(1:20) , 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.25);
title("(d) h_{real} to h_{norm} ratio",'FontSize', 10, 'FontWeight', 'normal');
xlabel("days relative event day", 'FontSize', 8);
xline(0);
legend("upper","mid", "lower", 'FontSize', 6);
grid on
grid minor



% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVG_VOLA_positive_marketcap_25_75_min100_30_tidy.png", 'Resolution', 300);
set(gcf,'color','w');
savehandle = gcf;
% %
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVG_VOLA_positive_marketcap_25_75_min100_30_tidy.png", '-png', '-m2');

%% Testing for ARCH effects ###############################################
% Use Engle ARCH LM test to check whether rediudals exhibit
% time-variant/conditional heteroskedasticity in the first place
% n_test = 0;
% arch = 0;
% non_arch = 0;
% test_res_abn = cell(N,15);
% for i = 1:N %!!!!! flawed, as based on 47 obs per sample only, therefore all rejected
%     disp(i);
%     logic = tidy_events_array{i,1};
%     
%     if isa(logic, 'datetime') == 0
%         continue
%     else
%         for j = 39:73
%             event = tidy_events_array{i,j};
%             if isempty(event) == 1
%                 continue
%             elseif isnan(tidy_events_array{i,j}{1,1}(1))
%                 continue
%             else
%                 abnormal_returns = tidy_events_array{i,j}{1,1};
%                 mu = mean(abnormal_returns, 'omitnan');
%                 eps = abnormal_returns - mu;
%                 h = archtest(eps, 'Alpha', 0.1);
%                 n_test = n_test+1;
%                 
%                 if h == 1
%                     arch = arch+1;
%                 else
%                     non_arch = non_arch +1;
%                 end
%                     
%                 
% 
%                 test_res_abn{i,j-38} = h; % use somthing different
%             end
% 
%         end
%     end
% end

%% Full sample check ######################################################

% may skip, takes ~hours

n_test = 0;
arch = 0;
non_arch = 0;
test_res = cell(width(logReturns_daily)-2,6);
for i = 3:width(logReturns_daily)
    disp(i);
    test_returns = logReturns_daily{:,i};
    name = logReturns_daily.Properties.VariableNames{i};
    mdl = arima(0,0,0);
    mdl.Constant = NaN;
    mdl.Variance = garch(1,1);
    % mdl = garch(1,1);
    %                 mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
    try
        est = estimate(mdl, test_returns);
        [res,sigma] = infer(est, test_returns); % extract cond std dev series !!!! Additionally infer residuals
        res_mean = test_returns-mean(test_returns, 'omitnan');

        test_res{i-2,1} = name;
        test_res{i-2,2} = res;
        test_res{i-2,3} = sqrt(sigma);
        test_res{i-2,4} = res_mean;
    catch
        continue
    end
    
end

%
a_test_before = 0;
a_test_after = 0;
all_after = 0;
all_before = 0;
sw_test = 0;
all_sw = 0;
ad_test = 0;
all_ad = 0;
ks_test = 0;
all_ks = 0;
jb_test = 0;
all_jb = 0;
skew = 0;
skew_avg = 0;
kurt = 0;
kurt_avg = 0;
lbq_test = 0;
all_lbq = 0;
lbqsq_test = 0;
all_lbqsq = 0;

for i = 1:length(test_res)
    disp(i);
    res = test_res{i,2};
    sigma_root = test_res{i,3};
    res_mean = test_res{i,4};
    
    if isempty(res)
        continue
%     elseif length(res) < 1000 % robustness check
%         continue
    else
        res_mean = res_mean(~isnan(res_mean));
        a1 = archtest(res_mean, 'Alpha', 0.05);
        a2 = archtest(res./sigma_root, 'Alpha', 0.05);
        

        test_res{i,5} = a1;
        test_res{i,6} = a2;

        if a1 == 1
            a_test_before = a_test_before +1;
            all_before = all_before +1;
        else
            a_test_before = a_test_before;
            all_before = all_before +1;
        end

        if a2 == 1
            a_test_after = a_test_after +1;
            all_after = all_after +1;
        else
            a_test_after = a_test_after;
            all_after = all_after +1;
        end
        
        %Shapiro-Wilk
        sw = swtest(res./sigma_root, 0.05);
        test_res{i,7} = sw;
        
        if sw == 1
            sw_test = sw_test+1;
            all_sw = all_sw +1;
        else
            sw_test= sw_test;
            all_sw = all_sw +1;
        end
        
        %Jarque-Bera
        jb = jbtest(res./sigma_root);
        test_res{i,8} = jb;
        
        if jb == 1
            jb_test = jb_test+1;
            all_jb = all_jb +1;
        else
            jb_test = jb_test;
            all_jb = all_jb +1;
        end
        
        %Anderson-Darling
        ad = adtest(res./sigma_root);
        test_res{i,9} = ad;
        
        if ad == 1
            ad_test = ad_test+1;
            all_ad = all_ad +1;
        else
            ad_test = ad_test;
            all_ad = all_ad +1;
        end
        
        %Kolmogorov-Smirnov
        ks = kstest(res./sigma_root);
        test_res{i,10} = ks;
        
        if ks == 1
            ks_test = ks_test+1;
            all_ks = all_ks +1;
        else
            ks_test = ks_test;
            all_ks = all_ks +1;
        end
        
        %AVG Skewness and Kurtosis
        
        skew = skewness(res./sigma_root);
        skew_avg = skew_avg+skew;
        test_res{i,11} = skew;
        
        kurt = kurtosis(res./sigma_root);
        kurt_avg = kurt_avg+kurt;
        test_res{i,12} = kurt;
        
        % Ljung-Box-Q test
        lbq = lbqtest(res./sigma_root);
        test_res{i,13} = lbq;
        
        if lbq == 1
            lbq_test = lbq_test+1;
            all_lbq = all_lbq +1;
        else
            lbq_test = lbq_test;
            all_lbq = all_lbq +1;
        end
        
        lbqsq = lbqtest((res./sigma_root).^2);
        test_res{i,14} = lbqsq;
        
        if lbqsq == 1
            lbqsq_test = lbqsq_test+1;
            all_lbqsq = all_lbqsq +1;
        else
            lbqsq_test = lbqsq_test;
            all_lbqsq = all_lbqsq +1;
        end
        
    end
end

%
arch_share_before = a_test_before/all_before; % rejection of no ARCH effects hypothesis in 75% os cases pre modelling at 5%

arch_share_after = a_test_after/all_after; % drops to 5% of cases with rejection of no ARCH effects hypothesis --> GARCH specification sensible

share_sw = sw_test/all_sw;

share_jb = jb_test/all_jb;

share_ad = ad_test/all_ad;

share_ks = ks_test/all_ks;

skew_avg = skew_avg/all_sw;

kurt_avg = kurt_avg/all_sw;

share_lbq = lbq_test/all_lbq;

share_lbqsq = lbqsq_test/all_lbqsq;
%% quick check
% test_returns = logReturns_daily{:,20};
% name = logReturns_daily.Properties.VariableNames(3);
% mdl = arima(0,0,0);
% mdl.Constant = NaN;
% mdl.Variance = garch(1,1);
% % mdl = garch(1,1);
% %                 mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
% est = estimate(mdl, test_returns);
% [res,sigma] = infer(est, test_returns); % extract cond std dev series !!!! Additionally infer residuals
% res_cell = cell(2,1);
% res_cell{1,1} = res;
% res_cell{2,1} = sigma;
% res_mean = test_returns-mean(test_returns, 'omitnan');
% a1 = archtest(res_mean)
% a2 = archtest(res./sigma)
% figure;
% subplot(3,1,1);
% autocorr(res_mean.^2);
% subplot(3,1,2);
% parcorr(res.^2./sigma);
% subplot(3,1,3);
% plot(1:length(res),res./sigma);

%% Alternative Approach ###################################################
%Estimating a GARCH(1,1) for every estimation window corresponding to an
%event, then forecasting the vola (std.dev) for each stopck and event using
%the estimated parameters to get a normal volatility. Additionally
%estimate a GARCH for the event window serving as the actual/realised vola.
%Eventually compute the difference between the normal vola as predicted by
%the estimation window and the actual vola as measured by garch on realised
%returns to tally abnormal vola.
for i = 1:N
    disp(i);
    logic = tidy_events_array{i,1};
    
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = (new_marker-max_event_count):(new_marker-1)
            event = tidy_events_array{i,j};
            if isempty(event) == 1
                continue
            elseif isnan(tidy_events_array{i,j}{4,1}(1)) 
                continue
            else
                realised_returns = tidy_events_array{i,j}{4,1};
                %realised_returns = realised_returns - mean(realised_returns, 'omitnan');
%                 mdl = garch(1,1); % fit garch(1,1) to data and infer corresponding cond variances (std dev)
                mdl = arima(0,0,0);
                mdl.Constant = NaN;
                mdl.Variance = garch(1,1);
                mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
                X = tidy_events_array{i,j-15}(114:160,2)/100;
                est = estimate(mdl, realised_returns, 'X', X); % https://de.mathworks.com/help/econ/arima.estimate.html
                [res,sigma, logL] = infer(est, realised_returns); % extract cond std dev series
                tidy_events_array{i,j+78} = sqrt(sigma);

            end

        end
    end

end
%%
for i = 1:N
    disp(i);
    logic = tidy_events_array{i,1};
    
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = (new_marker-max_event_count):(new_marker-1)
            event = tidy_events_array{i,j};
            if isempty(event) == 1
                continue
            elseif isnan(tidy_events_array{i,j}{3,1}(1)) 
                continue
            else
                normal_returns = tidy_events_array{i,j-15}(1:160,1);
                %normal_returns = normal_returns - mean(normal_returns, 'omitnan');
                mdl = arima(0,0,0);
                mdl.Constant = NaN;
                mdl.Variance = garch(1,1);
                mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
                X = tidy_events_array{i,j-15}(1:160,2)/100;
                est = estimate(mdl, normal_returns(1:113), 'X', X(1:113)); % https://de.mathworks.com/help/econ/arima.estimate.html
                [res0,v0,logL] = infer(est,normal_returns(1:113)); % extract cond std dev series
                [y, ~, sigma] = forecast(est,47, normal_returns(1:113), 'E0', res0, 'V0', v0);
                tidy_events_array{i,j+93} = sqrt(sigma);


            end

        end
    end
end
%%

for i = 1:N
    % additionally calculate average normal vola per stock from
    % ARIMAX-GARCH estimation
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos_normal_ARIMAX = [];
        vola_mat_neg_normal_ARIMAX = [];
        count1 = 1;
        count2 = 1;
        l = 0;
        for k = 112:126
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = tidy_events_array{i, k}; %sqrt one step before
                l = l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos_normal_ARIMAX(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg_normal_ARIMAX(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,127} = mean(vola_mat_pos_normal_ARIMAX, 2);

        tidy_events_array{i,128} = mean(vola_mat_neg_normal_ARIMAX, 2);

    end
    
end

for i = 1:N
    % additionally calculate realised normal vola per stock
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos_realised_ARIMAX = [];
        vola_mat_neg_realised_ARIMAX = [];
        count1 = 1;
        count2 = 1;
        l = 0;
        for k = 97:111
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = tidy_events_array{i, k}; %sqrt one step before
                l = l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos_realised_ARIMAX(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg_realised_ARIMAX(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,129} = mean(vola_mat_pos_realised_ARIMAX, 2);

        tidy_events_array{i,130} = mean(vola_mat_neg_realised_ARIMAX, 2);

    end
    
end


double_avg_mat_pos_vola_normal_ARIMAX = [];

double_avg_mat_neg_vola_normal_ARIMAX = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 127})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, 127};
        double_avg_mat_pos_vola_normal_ARIMAX(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 128})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, 128};
        double_avg_mat_neg_vola_normal_ARIMAX(:,i-count) = avg_temp_neg;


    end   
end

double_avg_pos_vola_normal_ARIMAX = mean(double_avg_mat_pos_vola_normal_ARIMAX, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola_normal_ARIMAX = mean(double_avg_mat_neg_vola_normal_ARIMAX, 2, 'omitnan'); % 2 NaNs introduced, simply skip
%%
double_avg_mat_pos_vola_realised_ARIMAX = [];

double_avg_mat_neg_vola_realised_ARIMAX = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 129})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, 129};
        double_avg_mat_pos_vola_realised_ARIMAX(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 130})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, 130};
        double_avg_mat_neg_vola_realised_ARIMAX(:,i-count) = avg_temp_neg;


    end   
end

double_avg_pos_vola_realised_ARIMAX = mean(double_avg_mat_pos_vola_realised_ARIMAX, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola_realised_ARMIAX = mean(double_avg_mat_neg_vola_realised_ARIMAX, 2, 'omitnan'); % 2 NaNs introduced, simply skip

%%

figure;
subplot(2,1,1);
plot(-7:39, double_avg_pos_vola_realised_ARIMAX, -7:39, double_avg_pos_vola_normal_ARIMAX, 'LineWidth', 1.25);%, -7:39, double_avg_pos_vola_realised_ARIMAX);
title("(a) ARIMAX-GARCH(1,1) fitted and forecast AVG Conditional Volatility", 'FontSize', 10, 'FontWeight', 'normal');
legend("realised", "normal", 'FontSize', 8);
ylabel("h_{real}, h_{norm}^*", 'FontSize', 8);
grid on
grid minor
subplot(2,1,2);
plot(-7:39, double_avg_pos_vola_realised_ARIMAX./double_avg_pos_vola_normal_ARIMAX, 'LineWidth', 1.25, 'Color', [0.9290 0.6940 0.1250]);%, -7:39, double_avg_pos_vola_normal_ARIMAX./double_avg_pos_vola_realised_ARIMAX);
title("(b) Ratio",'FontSize', 10, 'FontWeight', 'normal');
yline(1);
ylabel("Ratio", 'FontSize', 8);
xlabel("days relative to event", 'FontSize', 8);
legend("realised/normal", 'FontSize', 8);
grid on
grid minor


% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\ARIMAX_GARCH_fit_forecast_abn_vola_min100_30_tidy.png", 'Resolution', 300);

set(gcf,'color','w');
savehandle = gcf;
% %
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\ARIMAX_GARCH_fit_forecast_abn_vola_min100_30_tidy.png", '-png', '-m2');

%
max_abn_ratio_armiax = maxAR(double_avg_pos_vola_realised_ARIMAX,0);
%% Stratyfying by market cap ##############################################
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 127}) | isempty(tidy_events_array{i, 129})
        count = count+1;
        continue
    elseif tidy_events_array{i, 45} == 1
        avg_temp_mktval_up_pos_vola_normal_ARIMAX = tidy_events_array{i, 127};
        avg_temp_mktval_up_pos_vola_realised_ARIMAX = tidy_events_array{i, 129};
        double_avg_vola_mat_mktval_up_pos_normal_ARIMAX(:,i-count) = avg_temp_mktval_up_pos_vola_normal_ARIMAX;
        double_avg_vola_mat_mktval_up_pos_realised_ARIMAX(:,i-count) = avg_temp_mktval_up_pos_vola_realised_ARIMAX;
    else
        count = count+1;

    end   
end
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 127}) | isempty(tidy_events_array{i, 129})
        count = count+1;
        continue

        
    elseif tidy_events_array{i, 45} == 0
        avg_temp_mktval_up_iqr_vola_normal_ARIMAX = tidy_events_array{i, 127};
        avg_temp_mktval_up_iqr_vola_realised_ARIMAX = tidy_events_array{i, 129};
        double_avg_vola_mat_mktval_up_iqr_normal_ARIMAX(:,i-count) = avg_temp_mktval_up_iqr_vola_normal_ARIMAX;
        double_avg_vola_mat_mktval_up_iqr_realised_ARIMAX(:,i-count) = avg_temp_mktval_up_iqr_vola_realised_ARIMAX;
    else
        count = count+1;

        

    end   
end
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 45}) | isempty(tidy_events_array{i, 127}) | isempty(tidy_events_array{i, 129})
        count = count+1;
        continue
        
    elseif tidy_events_array{i, 45} == -1
        avg_temp_mktval_up_low_vola_normal_ARIMAX = tidy_events_array{i, 127};
        avg_temp_mktval_up_low_vola_realised_ARIMAX = tidy_events_array{i, 129};
        double_avg_vola_mat_mktval_up_low_normal_ARIMAX(:,i-count) = avg_temp_mktval_up_low_vola_normal_ARIMAX;
        double_avg_vola_mat_mktval_up_low_realised_ARIMAX(:,i-count) = avg_temp_mktval_up_low_vola_realised_ARIMAX;
    else
        count = count+1;
        

    end   
end
%
double_avg_vola_mktval_up_pos_normal_ARIMAX = mean(double_avg_vola_mat_mktval_up_pos_normal_ARIMAX,2, 'omitnan');
double_avg_vola_mktval_up_pos_realised_ARIMAX = mean(double_avg_vola_mat_mktval_up_pos_realised_ARIMAX, 2, 'omitnan');

double_avg_vola_mktval_up_iqr_normal_ARIMAX = mean(double_avg_vola_mat_mktval_up_iqr_normal_ARIMAX, 2, 'omitnan'); 
double_avg_vola_mktval_up_iqr_realised_ARIMAX = mean(double_avg_vola_mat_mktval_up_iqr_realised_ARIMAX, 2, 'omitnan');

double_avg_vola_mktval_up_low_normal_ARIMAX = mean(double_avg_vola_mat_mktval_up_low_normal_ARIMAX, 2, 'omitnan'); 
double_avg_vola_mktval_up_low_realised_ARIMAX = mean(double_avg_vola_mat_mktval_up_low_realised_ARIMAX, 2, 'omitnan');

%%
figure;
subplot(4,1,1);
plot(-7:12, double_avg_vola_mktval_up_pos_realised_ARIMAX(1:20), -7:12, double_avg_vola_mktval_up_pos_normal_ARIMAX(1:20), 'LineWidth', 1.25);
title("(a) ARIMAX h_{real} and h_{norm} for Positive Events for Top 25% Percentile of Market Cap", 'FontSize', 10, 'FontWeight', 'normal');
xline(0);
grid on
grid minor
subplot(4,1,2);
plot(-7:12, double_avg_vola_mktval_up_iqr_realised_ARIMAX(1:20), -7:12, double_avg_vola_mktval_up_iqr_normal_ARIMAX(1:20),  'LineWidth', 1.25);
title("(b) ARIMAX h_{real} and h_{norm} for Positive Events and IQR of Market Cap", 'FontSize', 10, 'FontWeight', 'normal');
xline(0);
grid on
grid minor
ylabel("h_{real}, h_{norm}", 'FontSize', 8);
legend("h_{real}","h_{norm}", 'FontSize', 6);

subplot(4,1,3);

plot(-7:12, double_avg_vola_mktval_up_low_realised_ARIMAX(1:20), -7:12, double_avg_vola_mktval_up_low_normal_ARIMAX(1:20), 'LineWidth', 1.25);
title("(c) ARIMAX h_{real} and h_{norm} for Positive Events for Bottom 25% Percentile of Market Cap", 'FontSize', 10, 'FontWeight', 'normal');
xline(0);
grid on
grid minor
subplot(4,1,4);

plot(-7:12, double_avg_vola_mktval_up_pos_realised_ARIMAX(1:20)./double_avg_vola_mktval_up_pos_normal_ARIMAX(1:20), 'Color', [0.6350 0.0780 0.1840], 'LineWidth', 1.25);
hold on
plot(-7:12, double_avg_vola_mktval_up_iqr_realised_ARIMAX(1:20)./double_avg_vola_mktval_up_iqr_normal_ARIMAX(1:20), 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 1.25);
hold on
plot(-7:12,double_avg_vola_mktval_up_low_realised_ARIMAX(1:20)./double_avg_vola_mktval_up_low_normal_ARIMAX(1:20) , 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.25);
title("(d) h_{real} to h_{norm} ratio", 'FontSize', 10, 'FontWeight', 'normal');
xlabel("days relative event day", 'FontSize', 8);
xline(0);
legend("upper","mid", "lower", 'FontSize', 6);
grid on
grid minor

set(gcf,'color','w');
savehandle = gcf;
% %
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVG_VOLA_positive_marketcap_25_75_min100_30_tidy_ARIMAX.png", '-png', '-m2');

%% Heuristic with squared and abs returns only ############################

for i = 1:N
    % additionally calculate average normal vola per stock from
    % suqared returns
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos_normal_sq = [];
        vola_mat_neg_normal_sq = [];
        count1 = 1;
        count2 = 1;
        l = 0;
        for k = (new_marker-max_event_count):(new_marker-1)
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = abs(tidy_events_array{i, k}{3,1}); % or (tidy_events_array{i, k}{3,1}).^2;
                l = l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos_normal_sq(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg_normal_sq(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,131} = mean(vola_mat_pos_normal_sq, 2, 'omitnan');

        tidy_events_array{i,132} = mean(vola_mat_neg_normal_sq, 2, 'omitnan');

    end
    
end

for i = 1:N
    % additionally calculate realised normal vola per stock
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos_realised_sq = [];
        vola_mat_neg_realised_sq = [];
        count1 = 1;
        count2 = 1;
        l =0;
        for k = (new_marker-max_event_count):(new_marker-1)
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = abs(tidy_events_array{i, k}{4,1});
                l =l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos_realised_sq(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg_realised_sq(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,133} = mean(vola_mat_pos_realised_sq, 2, 'omitnan');

        tidy_events_array{i,134} = mean(vola_mat_neg_realised_sq, 2, 'omitnan');

    end
    
end


double_avg_mat_pos_vola_normal_sq = [];

double_avg_mat_neg_vola_normal_sq = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 131})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, 131};
        double_avg_mat_pos_vola_normal_sq(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 132})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, 132};
        double_avg_mat_neg_vola_normal_sq(:,i-count) = avg_temp_neg;


    end   
end

double_avg_pos_vola_normal_sq = mean(double_avg_mat_pos_vola_normal_sq, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola_normal_sq = mean(double_avg_mat_neg_vola_normal_sq, 2, 'omitnan'); % 2 NaNs introduced, simply skip

double_avg_mat_pos_vola_realised_sq = [];

double_avg_mat_neg_vola_realised_sq = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 133})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, 133};
        double_avg_mat_pos_vola_realised_sq(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 134})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, 134};
        double_avg_mat_neg_vola_realised_sq(:,i-count) = avg_temp_neg;


    end   
end

double_avg_pos_vola_realised_sq = mean(double_avg_mat_pos_vola_realised_sq, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola_realised_sq = mean(double_avg_mat_neg_vola_realised_sq, 2, 'omitnan'); % 2 NaNs introduced, simply skip


for i = 1:N
    % additionally calculate realised abnormal vola per stock
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos_abnormal_sq = [];
        vola_mat_neg_abnormal_sq = [];
        count1 = 1;
        count2 = 1;
        l=0;
        for k = (new_marker-max_event_count):(new_marker-1)
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = abs(tidy_events_array{i, k}{1,1});
                l = l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos_abnormal_sq(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg_abnormal_sq(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,135} = mean(vola_mat_pos_abnormal_sq, 2, 'omitnan');

        tidy_events_array{i,136} = mean(vola_mat_neg_abnormal_sq, 2, 'omitnan');

    end
    
end

%
double_avg_mat_pos_vola_abnormal_sq = [];

double_avg_mat_neg_vola_abnormal_sq = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 135})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, 135};
        double_avg_mat_pos_vola_abnormal_sq(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 136})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, 136};
        double_avg_mat_neg_vola_abnormal_sq(:,i-count) = avg_temp_neg;


    end   
end
%
double_avg_pos_vola_abnormal_sq = mean(double_avg_mat_pos_vola_abnormal_sq, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola_abnormal_sq = mean(double_avg_mat_neg_vola_abnormal_sq, 2, 'omitnan'); % 2 NaNs introduced, simply skip

%% average beta
% for i = 1:N
%     % additionally calculate average beta
%     % 
%     if isempty(tidy_events_array{i, 1})
%         continue
%     else
%         vola_mat_pos_beta = [];
%         vola_mat_neg_beta = [];
%         count1 = 1;
%         count2 = 1;
%         for k = 39:73
%             help = tidy_events_array{i, k};
%             if isempty(help)
%                 continue
%             else
%                 vola_temp = (tidy_events_array{i, k}{7,1});
%                 if isnan(vola_temp(1))
%                     continue
%                 elseif tidy_events_array{i,3}(count1) >= 0
%                     if isnan(vola_temp)
%                         continue
%                     else
%                         vola_mat_pos_beta(:,count1) = vola_temp;
%                         count1 = count1+1;
%                     end
%                 elseif tidy_events_array{i,3}(count2) <= 0
%                     if isnan(vola_temp)
%                         continue
%                     else
%                         vola_mat_neg_beta(:,count2) = vola_temp;
%                         count2 = count2+1;
%                     end
%                 end
%             end
%         end
% 
%         tidy_events_array{i,384} = mean(vola_mat_pos_beta, 2);
% 
%         tidy_events_array{i,385} = mean(vola_mat_neg_beta, 2);
% 
%     end
%     
% end
% 
% 
% double_avg_mat_pos_vola_beta = [];
% 
% double_avg_mat_neg_vola_beta = [];
% 
% 
% 
% 
% count = 0;
% for i = 1:N
%     if isempty(tidy_events_array{i, 384})
%         count = count+1;
%         continue
%     else
%         avg_temp_pos = tidy_events_array{i, 384};
%         double_avg_mat_pos_vola_beta(:,i-count) = avg_temp_pos;
% 
%     end   
% end
% 
% count = 0;
% for i = 1:N
%     if isempty(tidy_events_array{i, 268})
%         count = count+1;
%         continue
%     else
%         avg_temp_neg = tidy_events_array{i, 268};
%         double_avg_mat_neg_vola_beta(:,i-count) = avg_temp_neg;
% 
% 
%     end   
% end
% 
% double_avg_pos_vola_beta = mean(double_avg_mat_pos_vola_beta, 2, 'omitnan'); % 2 NaNs introduced, simply skip
% 
% 
% double_avg_neg_vola_beta = mean(double_avg_mat_neg_vola_beta, 2, 'omitnan'); % 2 NaNs introduced, simply skip

%% Squared
% check for when sqrt is necessary
figure;
subplot(2,1,1);
plot(-7:39, sqrt(double_avg_pos_vola_realised_sq), -7:39, sqrt(double_avg_pos_vola_normal_sq), 'LineWidth', 1.25);%, -7:9, double_avg_pos_vola_realised_sq(1:17)); %, -7:9, double_avg_pos_vola_realised_sq(1:17)-double_avg_pos_vola_normal_sq(1:17));
title("(a) Average Squared Returns", 'FontSize', 10, 'FontWeight', 'normal');
legend("realised", "normal", 'FontSize', 8);

ylabel("(real^2)^{0.5}, (norm^2)^{0.5}", 'FontSize', 8);
% ylabel("abs(real), abs(norm)", 'FontSize', 8);
grid on
grid minor
subplot(2,1,2);
plot(-7:39,(sqrt(double_avg_pos_vola_realised_sq))./sqrt(double_avg_pos_vola_normal_sq), 'LineWidth', 1.25, 'Color', [0.9290 0.6940 0.1250]);%, -7:9, double_avg_pos_vola_normal_sq(1:17)./double_avg_pos_vola_realised_sq(1:17));
yline(1);
% hold on
% plot(-3:9, -2*double_avg_pos_vola_beta(1:13)+1);
% hold off
title("(b) Ratios", 'FontSize', 10, 'FontWeight', 'normal');
legend("realised/normal", 'FontSize', 8);

ylabel("Ratio", 'FontSize', 8);

xlabel("days relative to event", 'FontSize', 8);

grid on
grid minor

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_squaredret_norm_abn_realised_min100_30_tidy.png", 'Resolution', 300);
set(gcf,'color','w');
savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_squared_norm_abn_realised_min100_30_tidy.png", '-png', '-m2');

%% Absolute

figure;
subplot(2,1,1);
plot(-7:39, (double_avg_pos_vola_realised_sq), -7:39, (double_avg_pos_vola_normal_sq), 'LineWidth', 1.25);%, -7:9, double_avg_pos_vola_realised_sq(1:17)); %, -7:9, double_avg_pos_vola_realised_sq(1:17)-double_avg_pos_vola_normal_sq(1:17));
title("(a) Average Absolute Returns", 'FontSize', 10, 'FontWeight', 'normal');
legend("realised", "normal", 'FontSize', 8);

% ylabel("(real^2)^{0.5}, (norm^2)^{0.5}", 'FontSize', 8);
ylabel("abs(real), abs(norm)", 'FontSize', 8);
grid on
grid minor
subplot(2,1,2);
plot(-7:39,((double_avg_pos_vola_realised_sq))./(double_avg_pos_vola_normal_sq), 'LineWidth', 1.25, 'Color', [0.9290 0.6940 0.1250]);%, -7:9, double_avg_pos_vola_normal_sq(1:17)./double_avg_pos_vola_realised_sq(1:17));
yline(1);
% hold on
% plot(-3:9, -2*double_avg_pos_vola_beta(1:13)+1);
% hold off
title("(b) Ratios", 'FontSize', 10, 'FontWeight', 'normal');
legend("realised/normal", 'FontSize', 8);

ylabel("Ratio", 'FontSize', 8);

xlabel("days relative to event", 'FontSize', 8);

grid on
grid minor

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_squaredret_norm_abn_realised_min100_30_tidy.png", 'Resolution', 300);
set(gcf,'color','w');
savehandle = gcf;
% %
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_absolute_norm_abn_realised_min100_30_tidy.png", '-png', '-m2');

%% Max Abnormal Volatility Ratio
% Idea user realised volatility series and subset into peak volatility and
% non-peak volatility. THat is, divide mean(max(h_real)+/-2 days)) by mean
% (~max(h_real)+/-2 days)

max_abn_ratio_sq = maxAR(sqrt(double_avg_pos_vola_realised_sq), 1);


max_abn_ratio_abs = maxAR(double_avg_pos_vola_realised_sq, 1);
%%

for i = 1:N
    % additionally calculate cov between normal and realised
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        vola_mat_pos_cov = [];
        vola_mat_neg_cov = [];
        count1 = 1;
        count2 = 1;
        l= 0;
        for k = (new_marker-max_event_count):(new_marker-1)
            help = tidy_events_array{i, k};
            if isempty(help)
                continue
            else
                vola_temp = 2*(tidy_events_array{i, k}{3,1}.*tidy_events_array{i, k}{4,1}); % 2*cov(norm,real) = 2*E(norm*real)-0
                l = l+1;
                if isnan(vola_temp(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_pos_cov(:,count1) = vola_temp;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(vola_temp) ~= 47
                        continue
                    else
                        vola_mat_neg_cov(:,count2) = vola_temp;
                        count2 = count2+1;
                    end
                end
            end
        end

        tidy_events_array{i,137} = mean(vola_mat_pos_cov, 2, 'omitnan');

        tidy_events_array{i,138} = mean(vola_mat_neg_cov, 2, 'omitnan');

    end
    
end

%%
double_avg_mat_pos_vola_cov = [];

double_avg_mat_neg_vola_cov = [];




count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 137})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array{i, 137};
        double_avg_mat_pos_vola_cov(:,i-count) = avg_temp_pos;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 138})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array{i, 138};
        double_avg_mat_neg_vola_cov(:,i-count) = avg_temp_neg;


    end   
end
%
double_avg_pos_vola_cov = mean(double_avg_mat_pos_vola_cov, 2, 'omitnan'); % 2 NaNs introduced, simply skip


double_avg_neg_vola_cov = mean(double_avg_mat_neg_vola_cov, 2, 'omitnan'); % 2 NaNs introduced, simply skip
%%
figure;
subplot(2,1,1);
plot(-7:9, double_avg_pos_vola_abnormal_sq(1:17),  -7:9, double_avg_pos_vola_realised_sq(1:17), -7:9, double_avg_pos_vola_abnormal_sq(1:17)-double_avg_pos_vola_realised_sq(1:17), -7:9, double_avg_pos_vola_cov(1:17));
yline(0);
title("Mean squared returns and Cov");
legend("abn", "realised","abn-real", "-2*Cov(real,norm)+real");
subplot(2,1,2);
plot(-7:39, double_avg_pos_vola_abnormal_sq./double_avg_pos_vola_realised_sq, -7:39, double_avg_pos_vola_normal_sq./double_avg_pos_vola_realised_sq);
title("Ratios");
legend("abn/realised", "normal/realised");

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_squaredret_cov.png", 'Resolution', 300);

set(gcf,'color','w');
savehandle = gcf;
% %
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_squaredret_norm_abn_realised_min100_30_tidy.png", '-png', '-m2');

%% Bialkowski et al approach using M estimator ############################
% "Stock market volatility around national elections" - 2008
% ARIMAX-GARCH(1,1) with X = Rm

for i = 1:N
    disp(i);
    logic = tidy_events_array{i,1};
    
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = (new_marker-max_event_count):(new_marker-1)
            event = tidy_events_array{i,j};
            if isempty(event) == 1
                continue
            elseif isnan(tidy_events_array{i,j}{3,1}(1)) 
                continue
            else
                normal_returns = tidy_events_array{i,j-15}(1:160,1);
                %normal_returns = normal_returns - mean(normal_returns, 'omitnan');
                mdl = arima(0,0,0);
                mdl.Constant = NaN;
                mdl.Variance = garch(1,1);
                mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
                X = tidy_events_array{i,j-15}(1:160,2)/100; 
                est = estimate(mdl, normal_returns(1:113), 'X', X(1:113)); % https://de.mathworks.com/help/econ/arima.estimate.html
                constant = est.Variance.Constant;
                GARCH_coef = est.Variance.GARCH{1};
                ARCH_coef = est.Variance.ARCH{1};
                mu = est.Constant;
                beta = est.Beta;
                
                [arima_res, V] = infer(est, normal_returns(1:113), 'X', X(1:113));
                temp_cell = cell(8,1);
                temp_cell{1,1} = constant;
                temp_cell{2,1} = GARCH_coef;
                temp_cell{3,1} = ARCH_coef;
                temp_cell{4,1} = arima_res; % ~ to epsilon
                temp_cell{5,1} = V; % ~ to h
                temp_cell{6,1} = mu; % ~ to ARIMA constant
                temp_cell{7,1} = beta; % ~ to ARIMAX beta
                epsilon_event = normal_returns(114:160)-(mu+beta.*X(114:160)); % ~ to Ri - (a+b*Rm)
                temp_cell{8,1} = epsilon_event;
                
                

                tidy_events_array{i,j+120} = temp_cell;
               


            end

        end
    end                                                                                                                                                                                                       
end
%%
% using an extended event window with prior event data t-7
% for i = 1:N
%     disp(i);
%     logic = tidy_events_array{i,1};
%     
%     if isa(logic, 'datetime') == 0
%         continue
%     else
%         for j = 39:73
%             event = tidy_events_array{i,j};
%             if isempty(event) == 1
%                 continue
%             elseif isnan(tidy_events_array{i,j}{3,1}(1)) 
%                 continue
%             else
%                 normal_returns = tidy_events_array{i,j-35}(1:160,1);
%                 %normal_returns = normal_returns - mean(normal_returns, 'omitnan');
%                 mdl = arima(0,0,0);
%                 mdl.Constant = NaN;
%                 mdl.Variance = garch(1,1);
%                 mdl.Beta = NaN;% fit garch(1,1) to data and infer corresponding cond variances (std dev)
%                 X = tidy_events_array{i,j-35}(1:160,2);
%                 est = estimate(mdl, normal_returns(1:113), 'X', X(1:113)); % https://de.mathworks.com/help/econ/arima.estimate.html
%                 constant = est.Variance.Constant;
%                 GARCH_coef = est.Variance.GARCH{1};
%                 ARCH_coef = est.Variance.ARCH{1};
%                 mu = est.Constant;
%                 beta = est.Beta;
%                 
%                 [arima_res, V] = infer(est, normal_returns(1:113), 'X', X(1:113));
%                 temp_cell = cell(8,1);
%                 temp_cell{1,1} = constant;
%                 temp_cell{2,1} = GARCH_coef;
%                 temp_cell{3,1} = ARCH_coef;
%                 temp_cell{4,1} = arima_res; % ~ to epsilon
%                 temp_cell{5,1} = V; % ~ to h
%                 temp_cell{6,1} = mu; % ~ to ARIMA constant
%                 temp_cell{7,1} = beta; % ~ to ARIMAX beta
%                 epsilon_event = normal_returns(114:160)-(mu+beta.*X(114:160)); % ~ to Ri - (a+b*Rm)
%                 temp_cell{8,1} = epsilon_event;
%                 
%                 
% 
%                 tidy_events_array{i,j+310} = temp_cell;
%                
% 
% 
%             end
% 
%         end
%     end
% end

%%
% k-step ahead forecast for each event and ticker

for i = 1:N
    disp(i);
    logic = tidy_events_array{i,1};
    
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = (new_marker-max_event_count):(new_marker-1)
            event = tidy_events_array{i,j+120}; %or 236 depending on which alternative is used
            E_h_vector = [];
            if isempty(event) == 1
                continue
            else
                c = tidy_events_array{i,j+120}{1,1};
                GARCH = tidy_events_array{i,j+120}{2,1};
                ARCH = tidy_events_array{i,j+120}{3,1};
                e_sq = tidy_events_array{i,j+120}{4,1}(113)^2;
                h = tidy_events_array{i,j+120}{5,1}(113);
                E_h_omega_1 = c+GARCH*h+ARCH*e_sq;
                temp_sum = 1;
                
                E_h_vector(1) = E_h_omega_1;
                for k = 2:47
                    temp_sum = temp_sum+(GARCH+ARCH)^(k-1);
                    E_h_omega_k = c*temp_sum+(GARCH+ARCH)^(k-1)*GARCH*h+(GARCH+ARCH)^(k-1)*ARCH*e_sq;
                    E_h_vector(k) = E_h_omega_k;   
                end
                
                tidy_events_array{i,j+135} = E_h_vector';


            end

        end
    end
end

%% aggregate over time and then cross-sectionally

for i = 1:N
    
    % 
    if isempty(tidy_events_array{i, 1})
        continue
    else
        residuals_pos = [];
        residuals_neg = [];
        forecast_pos = [];
        forecast_neg = [];

        count1 = 1;
        count2 = 1;
        l =0;
        for k = (new_marker-max_event_count):(new_marker-1)
            help = tidy_events_array{i, k+120}; %or 236
            if isempty(help)
                continue
            else
                residuals = tidy_events_array{i,k+120}{8,1};
                E_h_k = tidy_events_array{i,k+135};
                l = l+1;
                if isnan(residuals(1))
                    continue
                elseif tidy_events_array{i,3}(l) >= 0
                    if length(residuals) ~= 47
                        continue
                    else
                        residuals_pos(:,count1) = residuals;
                        forecast_pos(:,count1) = E_h_k;
                        count1 = count1+1;
                    end
                elseif tidy_events_array{i,3}(l) <= 0
                    if length(residuals) ~= 47
                        continue
                    else
                        residuals_neg(:,count2) = residuals;
                        forecast_neg(:,count2) = E_h_k;
                        count2 = count2+1;
                    end
                end
            end
        end
        temp_cell_pos = cell(2,1);
        temp_cell_pos{1,1} = residuals_pos;
        temp_cell_pos{2,1} = forecast_pos;
        
        temp_cell_neg = cell(2,1);
        temp_cell_neg{1,1} = residuals_neg;
        temp_cell_neg{2,1} = forecast_neg;
        
        

        tidy_events_array{i,169} = temp_cell_pos;

        tidy_events_array{i,170} = temp_cell_neg;

    end
    
end

%%
% pos
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 169})
        count = count+1;
        continue
    elseif isempty(tidy_events_array{i, 169}{1,1})
        count = count+1;
        continue
    else
        mean_residuals = mean(tidy_events_array{i, 169}{1,1},2, 'omitnan');
        mean_E_h_k_i = mean(tidy_events_array{i, 169}{2,1},2, 'omitnan');
        
        temp_cell = cell(2,1);
        temp_cell{1,1} = mean_residuals;
        temp_cell{2,1} = mean_E_h_k_i;
        tidy_events_array{i,171} = temp_cell;     
        
    end   
end

% neg
count = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 170})
        count = count+1;
        continue
    elseif isempty(tidy_events_array{i, 170}{1,1})
        count = count+1;
        continue
    else
        mean_residuals = mean(tidy_events_array{i, 170}{1,1},2, 'omitnan');
        mean_E_h_k_i = mean(tidy_events_array{i, 170}{2,1},2, 'omitnan');
        
        temp_cell = cell(2,1);
        temp_cell{1,1} = mean_residuals;
        temp_cell{2,1} = mean_E_h_k_i;
        tidy_events_array{i,172} = temp_cell;    


    end   
end

%% cross-sectional to get Mt

% pos
count = 0;
sum_residuals_pos = 0;
sum_E_h_k_i_pos = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 171})
        count = count+1;
        continue
    elseif isempty(tidy_events_array{i, 171}{1,1})
        count = count+1;
        continue
%     elseif tidy_events_array{i, 45} ~= 0 % for market cap stratification
%         count = count+1;
%         continue
    else
        sum_residuals_pos = sum_residuals_pos+tidy_events_array{i, 171}{1,1};
        sum_E_h_k_i_pos = sum_E_h_k_i_pos + tidy_events_array{i, 171}{2,1};
        
        
    end   
end
N_pos = N-count;
% neg
count = 0;
sum_residuals_neg = 0;
sum_E_h_k_i_neg = 0;
for i = 1:N
    if isempty(tidy_events_array{i, 172})
        count = count+1;
        continue
    elseif isempty(tidy_events_array{i, 172}{1,1})
        count = count+1;
        continue
    else
        sum_residuals_neg = sum_residuals_neg+tidy_events_array{i, 172}{1,1};
        sum_E_h_k_i_neg = sum_E_h_k_i_neg + tidy_events_array{i, 172}{2,1};

    end   
end
N_neg = N-count;

%%
% pos
Mt_pos = zeros(47,1);
for t = 1:47
    count = 0;
    temp_sum = 0;
    for i = 1:N
        if isempty(tidy_events_array{i, 171})
            count = count+1;
            continue
        elseif isempty(tidy_events_array{i, 171}{1,1})
            count = count+1;
            continue
        else
            epsilon_i_t = tidy_events_array{i,171}{1,1}(t);
            E_h_k_i_t = tidy_events_array{i,171}{2,1}(t);
            sum_residuals_pos_t = sum_residuals_pos(t);
            sum_E_h_k_i_pos_t = sum_E_h_k_i_pos(t);
            
            temp_sum = temp_sum + ((N_pos*epsilon_i_t - sum_residuals_pos_t)^2)/(N_pos*(N_pos-2)*E_h_k_i_t + sum_E_h_k_i_pos_t);
            
            

        end
  
    end
    M_t = 1/(N_pos-1)*temp_sum;
    Mt_pos(t) = M_t;
    
    
end

% neg
Mt_neg = zeros(47,1);
for t = 1:47
    count = 0;
    temp_sum = 0;
    for i = 1:N
        if isempty(tidy_events_array{i, 172})
            count = count+1;
            continue
        elseif isempty(tidy_events_array{i, 172}{1,1})
            count = count+1;
            continue
        else
            epsilon_i_t = tidy_events_array{i,172}{1,1}(t);
            E_h_k_i_t = tidy_events_array{i,172}{2,1}(t);
            sum_residuals_neg_t = sum_residuals_neg(t);
            sum_E_h_k_i_neg_t = sum_E_h_k_i_neg(t);
            
            temp_sum = temp_sum + ((N_neg*epsilon_i_t - sum_residuals_neg_t)^2)/(N_neg*(N_neg-2)*E_h_k_i_t + sum_E_h_k_i_neg_t);
            
            

        end
  
    end
    M_t = 1/(N_neg-1)*temp_sum;
    Mt_neg(t) = M_t;
    
    
end

%% Cumulative Abnormal Volatility
cum_abn_vola_pos = [];
chi_cum_abn_vola_pos = [];
cum_abn_vola_neg = [];
chi_cum_abn_vola_neg = [];

for t = 1:47
    cum_abn_vola_pos(t) = sum(Mt_pos(1:t), 'omitnan')-(t-1+1);
    chi_cum_abn_vola_pos(t,1) = sum((N_pos-1)*Mt_pos(1:t), 'omitnan'); % chi squared according to bialkoswki and barunik
    chi_cum_abn_vola_pos(t,2) = (N_pos-1)*(t-1+1);
    cum_abn_vola_neg(t) = sum(Mt_neg(1:t), 'omitnan')-(t-1+1);
    chi_cum_abn_vola_neg(t,1) = sum((N_neg-1)*Mt_neg(1:t), 'omitnan');
    chi_cum_abn_vola_neg(t,2) = (N_neg-1)*(t-1+1);
end
%%
% Chi-squared test statistic

chi2_pos = chi2cdf(chi_cum_abn_vola_pos(:,1), chi_cum_abn_vola_pos(:,2), 'upper');
chi2_neg = chi2cdf(chi_cum_abn_vola_neg(:,1), chi_cum_abn_vola_neg(:,2), 'upper');



%%
figure;
subplot(2,1,1);
plot(-7:39,cum_abn_vola_pos, -7:39,cum_abn_vola_neg, 'LineWidth', 1.25);
title("M_{t}-Multiplicator approach following Bialkowski et al. (2008) (Version 1)");
xline(0);
legend("CAAV^{pos}", "CAAV^{neg}");
ylabel("CAAV");
grid on
grid minor
subplot(2,1,2);
plot(-7:39,Mt_pos, -7:39,Mt_neg, 'LineWidth', 1.25);
xline(0);
legend("M_t{t}^{pos}", "M_t{t}^{neg}");
ylabel("M_t");
xlabel("days relative to event");
grid on
grid minor

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\Mt_multiplicator_version1_min100_30_tidy.png", 'Resolution', 300);
%% market cap plot Version 1
% figure;
% subplot(2,1,1);
% plot(-7:39,cum_abn_vola_pos_up, -7:39,cum_abn_vola_pos_iqr, -7:39,cum_abn_vola_pos_low ,'LineWidth', 1.25);
% title("M_{t}-Multiplicator approach (Version 1) for different Market Caps");
% xline(0);
% legend("CAAV^{up}", "CAAV^{mid}", "CAAV^{low}");
% ylabel("CAAV");
% grid on
% grid minor
% subplot(2,1,2);
% plot(-7:39,Mt_pos_up, -7:39,Mt_pos_iqr,-7:39,Mt_pos_low, 'LineWidth', 1.25);
% xline(0);
% legend("M_t{t}^{up}", "M_t{t}^{mid}", "M_t{t}^{low}");
% ylabel("M_t");
% xlabel("days relative to event");
% grid on
% grid minor
% % savehandle = gcf;
% % exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\Mt_multiplicator_version1_min100_30_tidy_market_cap_25_75.png", 'Resolution', 300);

%% alternative approach neglecting time series character ##################
% compute residual and forecast sums
% as if all events pertain to one stock, neglecting overlaps and other
% stock specific features

count1 = 1;

residuals_all_pos = [];
residuals_all_neg = [];
forecast_all_pos = [];
forecast_all_neg = [];
for i = 1:N
    if isempty(tidy_events_array{i, 169})
        continue
    else


        
        if isempty(tidy_events_array{i, 169}{1, 1})
            continue
        else
            residuals = tidy_events_array{i,169}{1,1};
            forecasts = tidy_events_array{i,169}{2,1};
            
            if isnan(residuals(1))
                continue
%             elseif tidy_events_array{i, 45} ~=  -1 % for market cap stratification
%                 count = count+1;
%                 continue
            else
                residuals_all_pos(:,(count1):(count1+width(residuals)-1)) = residuals;
                forecast_all_pos(:,(count1):(count1+width(residuals)-1)) = forecasts;
                count1 = count1 + width(residuals);
                
            end
            
        end

    end
    
    
end

count1 = 1;
for i = 1:N
    if isempty(tidy_events_array{i, 170})
        continue
    else


        
        if isempty(tidy_events_array{i, 170}{1, 1})
            continue
        else
            residuals = tidy_events_array{i,170}{1,1};
            forecasts = tidy_events_array{i,170}{2,1};
            
            if isnan(residuals(1))
                continue
            else
                residuals_all_neg(:,(count1):(count1+width(residuals)-1)) = residuals;
                forecast_all_neg(:,(count1):(count1+width(residuals)-1)) = forecasts;
                count1 = count1 + width(residuals);
                
            end
            
        end

    end

end
%%
sum_residuals_all_pos = sum(residuals_all_pos,2, 'omitnan'); % width indicates number of positive events, ie 4838
sum_forecast_all_pos = sum(forecast_all_pos,2, 'omitnan');

sum_residuals_all_neg = sum(residuals_all_neg,2, 'omitnan') ;% width indicates number of negative events, ie 453
sum_forecast_all_neg = sum(forecast_all_neg,2, 'omitnan');
%%

Mt_all_pos = zeros(47,1);

for t = 1:47
    count = 0;
    temp_sum = 0;
    sum_res = sum_residuals_all_pos(t);
    sum_fore = sum_forecast_all_pos(t);
    K = length(residuals_all_pos);
    for i = 1:K
       eps_i = residuals_all_pos(t,i);
       for_i = forecast_all_pos(t,i);
       
       if isnan(eps_i)
           count = count+1;
           continue
       elseif isnan(for_i)
           count = count+1;
           continue
       end
    end
    K_clean = K-count;
    for i = 1:K
       eps_i = residuals_all_pos(t,i);
       for_i = forecast_all_pos(t,i);
       
       if isnan(eps_i)
           count = count+1;
           continue
       elseif isnan(for_i)
           count = count+1;
           continue
       else
           temp_sum = temp_sum + (((K_clean*eps_i)-sum_res)^2)/((K_clean*(K_clean-2)*for_i)+sum_fore);
       end
    end
Mt = 1/(K_clean-1)*temp_sum;
Mt_all_pos(t) = Mt;
    
end
%%

Mt_all_neg = zeros(47,1);
for t = 1:47
    count = 0;
    temp_sum = 0;
    sum_res = sum_residuals_all_neg(t);
    sum_fore = sum_forecast_all_neg(t);
    K = width(residuals_all_neg);
    for i = 1:K
       eps_i = residuals_all_neg(t,i);
       for_i = forecast_all_neg(t,i);
       
       if isnan(eps_i)
           count = count+1;
           continue
       elseif isnan(for_i)
           count = count+1;
           continue
       end
    end
    K_clean = K-count;
    for i = 1:K
       eps_i = residuals_all_neg(t,i);
       for_i = forecast_all_neg(t,i);
       
       if isnan(eps_i)
           count = count+1;
           continue
       elseif isnan(for_i)
           count = count+1;
           continue
       else
           temp_sum = temp_sum + (((K_clean*eps_i)-sum_res)^2)/((K_clean*(K_clean-2)*for_i)+sum_fore);
       end
    end
Mt = 1/(K_clean-1)*temp_sum;
Mt_all_neg(t) = Mt;
end

%% CAV 
cum_abn_vola_all_pos = [];
cum_abn_vola_all_neg = [];
chi_cum_abn_vola_all_pos = [];
chi_cum_abn_vola_all_neg = [];
K_pos = width(residuals_all_pos);
K_neg = width(residuals_all_neg);

for t = 1:47
    cum_abn_vola_all_pos(t) = sum(Mt_all_pos(1:t), 'omitnan')-(t-1+1);
    chi_cum_abn_vola_all_pos(t,1) = sum((K_pos-1)*Mt_all_pos(1:t), 'omitnan'); % chi squared according to bialkoswki and barunik
    chi_cum_abn_vola_all_pos(t,2) = (N_pos-1)*(t-1+1);
    cum_abn_vola_all_neg(t) = sum(Mt_all_neg(1:t), 'omitnan')-(t-1+1);
    chi_cum_abn_vola_all_neg(t,1) = sum((K_neg-1)*Mt_all_neg(1:t), 'omitnan');
    chi_cum_abn_vola_all_neg(t,2) =(N_neg-1)*(t-1+1);
end
%% Chi squared asymptotics test ###########################################

chi2_all_pos = chi2cdf(chi_cum_abn_vola_all_pos(:,1), chi_cum_abn_vola_all_pos(:,2), 'upper');
chi2_all_neg = chi2cdf(chi_cum_abn_vola_all_neg(:,1), chi_cum_abn_vola_all_neg(:,2), 'upper');

%% Bootstrap procedure following Efron(1979) ##############################

bootstrap_Mt_pos = [];

for b = 1:5000 % 5k bootstrap sample with replacement 
    [sample_i_residuals_all_pos, sample_idx] = datasample(residuals_all_pos,width(residuals_all_pos),2);
    sample_i_forecast_all_pos = forecast_all_pos(:,sample_idx);
    
    sample_i_sum_residuals_all_pos = sum(sample_i_residuals_all_pos,2, 'omitnan');
    sample_i_sum_forecast_all_pos = sum(sample_i_forecast_all_pos,2, 'omitnan');
    
    sample_i_Mt_all_pos = zeros(47,1);

    for t = 1:47 % counting to get K
        count = 0;
        temp_sum = 0;
        sum_res = sample_i_sum_residuals_all_pos(t);
        sum_fore = sample_i_sum_forecast_all_pos(t);
        K = length(residuals_all_pos);
        for i = 1:K
           eps_i = sample_i_residuals_all_pos(t,i);
           for_i = sample_i_forecast_all_pos(t,i);

           if isnan(eps_i)
               count = count+1;
               continue
           elseif isnan(for_i)
               count = count+1;
               continue
           end
        end
        K_clean = K-count;
        
        for i = 1:K % summing according to formula
           eps_i = sample_i_residuals_all_pos(t,i);
           for_i = sample_i_forecast_all_pos(t,i);

           if isnan(eps_i)
               count = count+1;
               continue
           elseif isnan(for_i)
               count = count+1;
               continue
           else
               temp_sum = temp_sum + (((K_clean*eps_i)-sum_res)^2)/((K_clean*(K_clean-2)*for_i)+sum_fore);
           end
        end
    Mt = 1/(K_clean-1)*temp_sum;
    sample_i_Mt_all_pos(t) = Mt;

    end
    
    sample_cum_abn_vola_all_pos = [];


    for t = 1:47 % CAV
        sample_cum_abn_vola_all_pos(t) = sum(sample_i_Mt_all_pos(1:t), 'omitnan')-(t-1+1);
    end
    
    bootstrap_cum_abn_pos(:,b) = sample_cum_abn_vola_all_pos';
end
%%
% sort each row in ascending order
sorted_bootstrap_cum_abn_pos = sort(bootstrap_cum_abn_pos, 2);
bootstrapped_p_vals = [];
for i = 1:47
   row_i = sorted_bootstrap_cum_abn_pos(i,:);
   row_i = row_i - mean(row_i); % as we require the distribution under Ho, ie with zero mean https://stats.stackexchange.com/questions/20701/computing-p-value-using-bootstrap-with-r
   thresh = cum_abn_vola_all_pos(i);
   all_larger = row_i(row_i>=thresh);
   id = length(all_larger);
   bootstrapped_p_vals(i) = id/5000;
end

%%
exporttable_p_Mt = table([-7:39]', chi2_all_pos, bootstrapped_p_vals',chi2_all_neg);
exporttable_p_Mt.Variables = round(exporttable_p_Mt.Variables,4);
%%
figure;
subplot(2,1,1);
plot(-7:39,cum_abn_vola_all_pos,-7:39,cum_abn_vola_all_neg, 'LineWidth', 1.25);
title("M_{t}-Multiplicator Approach following Bialkowski et al. (2008)", 'FontSize', 10, 'FontWeight', 'normal');
xline(0);
legend("CAAV^{pos}","CAAV^{neg}", 'FontSize', 8);
ylabel("CAAV", 'FontSize', 8);
grid on
grid minor
subplot(2,1,2);
plot(-7:39,Mt_all_pos, -7:39, Mt_all_neg, 'LineWidth', 1.25);
xline(0);
legend("M_t{t}^{pos}", "M_t{t}^{neg}", 'FontSize', 8);
ylabel("M_t", 'FontSize', 8);
xlabel("days relative to event", 'FontSize', 8);
grid on
grid minor

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\Mt_multiplicator_version2_min100_30_tidy.png", 'Resolution', 300);
set(gcf,'color','w');
savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\Mt_multiplicator_version2_min100_30_tidy.png", '-png', '-m2');


%% market cap plot Version 2
% figure;
% subplot(2,1,1);
% plot(-7:39,cum_abn_vola_all_pos_up2, -7:39,cum_abn_vola_pos_iqr2, -7:39,cum_abn_vola_pos_low2 ,'LineWidth', 1.25);
% title("M_{t}-Multiplicator Approach for different Market Caps", 'FontSize', 10, 'FontWeight', 'normal');
% xline(0);
% legend("CAAV^{up}", "CAAV^{mid}", "CAAV^{low}", 'FontSize', 8);
% ylabel("CAAV", 'FontSize', 8);
% grid on
% grid minor
% subplot(2,1,2);
% plot(-7:39,Mt_pos_up2, -7:39,Mt_pos_iqr2,-7:39,Mt_pos_low2, 'LineWidth', 1.25);
% xline(0);
% legend("M_t{t}^{up}", "M_t{t}^{mid}", "M_t{t}^{low}", 'FontSize', 8);
% ylabel("M_t", 'FontSize', 8);
% xlabel("days relative to event", 'FontSize', 8);
% grid on
% grid minor
% % savehandle = gcf;
% % exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\Mt_multiplicator_version2_min100_30_tidy_market_cap_25_75.png", 'Resolution', 300);
% set(gcf,'color','w');
% savehandle = gcf;
% 
% % exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% % export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\Mt_multiplicator_version2_min100_30_tidy_market_cap_25_75.png", '-png', '-m2');
% 



%%
Mt_all_pos_trans = ((Mt_all_pos-1)/100)+1;
max_abn_ratio_Mt = maxAR(Mt_all_pos_trans, 1);

%% Prasad et al procedure - adapted #######################################
% #########################################################################
% eventually left out -----------------------------------------------------
% AVAR pos
AVAR_dist = [];
AVAR_dist_cond = [];
for t = 1:47
    
    for i = 1:N
        if isempty(tidy_events_array{i, 135})
            continue
        else
            abn_vola = sqrt(tidy_events_array{i, 135}(t));

            all_garch_pos = [];
            all_garch_cond_pos = [];

            count1 = 1;
            count2 = 1;
            for k = (new_marker-max_event_count):(new_marker-1)
                help = tidy_events_array{i, k+120}; % or 236
                if isempty(help)
                    continue
                else
                    const = tidy_events_array{i,k+120}{1,1};
                    GARCH = tidy_events_array{i,k+120}{2,1};
                    ARCH = tidy_events_array{i,k+120}{3,1};
                    cond_vola = tidy_events_array{i,k+120}{5,1};
                    if isnan(const)
                        continue
                    else
                        sigma = const/(1-(GARCH+ARCH));
                        all_garch_pos(count1) = sqrt(sigma);
                        all_garch_cond_pos(:,count1) = cond_vola;
                        count1 = count1+1;
                    end
                end
            end
            mean_sigma = mean(all_garch_pos, 'omitnan');
            mean_cond_vola = mean(all_garch_cond_pos, 2, 'omitnan');
            AVAR = abn_vola/mean_sigma;

            tidy_events_array{i,173} = AVAR;
            tidy_events_array{i,174} = mean_cond_vola;
        end


    end
    AVG_AVAR = [];
    AVG_AVAR_cond = [];
    count = 1;
    for i = 1:N
       if isempty(tidy_events_array{i,173})
           continue
       else
           AVAR_temp = tidy_events_array{i,173};
           AVG_AVAR(count) = AVAR_temp;
           AVG_AVAR_cond(:,count) = tidy_events_array{i,174};
           count = count+1;
       end


    end

    double_avg_avar_pos = mean(AVG_AVAR, 'omitnan');
    double_avg_avar_cond_pos = mean(AVG_AVAR_cond, 2, 'omitnan');
    AVAR_dist(t) = double_avg_avar_pos;
    AVAR_dist_cond(:,t) = double_avg_avar_cond_pos;
    
end



%%

figure;
plot(-7:39, AVAR_dist, 'LineWidth', 1.25);
title("AVAR-approach following Prasad et al. (2021) for Positive Events", 'FontSize', 10, 'FontWeight', 'normal');
xline(0);
ylabel("AVAR", 'FontSize', 8);
xlabel("days relative to event", 'FontSize', 8);
grid on
grid minor
% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVAR_Prasad_postive_correct_min100_30_tidy.png", 'Resolution', 300);
set(gcf,'color','w');
savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVAR_Prasad_postive_correct_min100_30_tidy.png", '-png', '-m2');

%%
max_abn_ratio_prasad_AVAR_const = maxAR(AVAR_dist,0);
%%
% AVAR neg
AVAR_dist_neg = [];
for t = 1:47
    for i = 1:N
        if isempty(tidy_events_array{i, 136})
            continue
        else
            abn_vola = sqrt(tidy_events_array{i, 136}(t));

            all_garch_neg = [];
            all_garch_cond_neg = [];

            count1 = 1;
            count2 = 1;
            for k = (new_marker-max_event_count):(new_marker-1)
                help = tidy_events_array{i, k+120}; % or 236
                if isempty(help)
                    continue
                else
                    const = tidy_events_array{i,k+120}{1,1};
                    GARCH = tidy_events_array{i,k+120}{2,1};
                    ARCH = tidy_events_array{i,k+120}{3,1};
                    cond_vola = tidy_events_array{i,k+120}{3,1};
                    if isnan(const)
                        continue
                    else
                        sigma = const/(1-(GARCH+ARCH));
                        all_garch_neg(count1) = sqrt(sigma);
                        all_garch_cond_neg(:,count1) = cond_vola;
                        count1 = count1+1;
                    end
                end
            end
            mean_sigma = mean(all_garch_neg, 'omitnan');
            mean_cond_vola = mean(all_garch_cond_neg, 2, 'omitnan');

            AVAR = abn_vola/mean_sigma;
            tidy_events_array{i,175} = AVAR;
            tidy_events_array{i,176} = mean_cond_vola;
        end


    end


    AVG_AVAR_neg = [];
    count = 1;
    for i = 1:N
       if isempty(tidy_events_array{i,175})
           continue
       else
           AVAR_temp = tidy_events_array{i,175};
           AVG_AVAR_neg(count) = AVAR_temp;
           count = count+1;
       end


    end

    double_avg_avar_neg = mean(AVG_AVAR_neg, 'omitnan');
    AVAR_dist_neg(t) = double_avg_avar_neg;
end

%%
figure;

plot(-7:39, AVAR_dist_neg, 'LineWidth', 1.25);
title("AVAR-approach following Prasad et al. (2021) Negative Events");
xline(0);
ylabel("AVAR");
grid on
grid minor
xlabel("days relative to event");

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVAR_Prasad_negative_correct.png", 'Resolution', 300);

%% Prasad et al with GARCH effects ########################################
% use GARCH(1,1) cond volas from tidy_events_array(:,119:153) which
% correspond to normal return series garch cond vola estimates
% AVAR_GARCH_dist = [];
% AVAR_GARCH_dist_cond = [];
% for t = 1:47
%     
%     for i = 1:N
%         if isempty(tidy_events_array{i, 135})
%             continue
%         else
%             abn_vola = tidy_events_array{i, 135}(t);
% 
%             all_garch_pos = [];
% 
%             count1 = 1;
%             count2 = 1;
%             for k = (new_marker-max_event_count):(new_marker-1)
%                 help = tidy_events_array{i, k+44}; % or 236
%                 if isempty(help)
%                     continue
%                 else
%                     sigma_all = tidy_events_array{i,k+44}{2,1};
%                     if isnan(sigma_all(1))
%                         continue
%                     else
%                         sigma = sigma_all(t);
%                         all_garch_pos(count1) = sigma;
%                         count1 = count1+1;
%                     end
%                 end
%             end
%             mean_sigma = median(all_garch_pos, 'omitnan');
%             AVAR = abn_vola/mean_sigma;
% 
%             tidy_events_array{i,178} = AVAR;
%         end
% 
% 
%     end
%     AVG_AVAR_GARCH = [];
%     count = 1;
%     for i = 1:N
%        if isempty(tidy_events_array{i,178})
%            continue
%        else
%            AVAR_temp = tidy_events_array{i,178};
%            AVG_AVAR_GARCH(count) = AVAR_temp;
%            count = count+1;
%        end
% 
% 
%     end
% 
%     double_avg_avar_pos = mean(AVG_AVAR_GARCH, 'omitnan');
%     AVAR_GARCH_dist(t) = double_avg_avar_pos;
%     
% end
%% 
figure;
plot(-7:39,sqrt(double_avg_pos_vola_abnormal_sq)./double_avg_pos_vola_normal_ARIMAX, 'LineWidth', 1.25);
title("AVAR-GARCH-approach following Prasad et al. (2021) for Positive Events", 'FontSize', 10, 'FontWeight', 'normal');
xline(0);
grid on
grid minor
ylabel("AVAR", 'FontSize', 8);
xlabel("days relative to event", 'FontSize', 8);

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVAR_Prasad_ARIMAX_correct_pos_min100_30_tidy.png", 'Resolution', 300);
set(gcf,'color','w');
savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\mean_garch_vola_norm_abn_realised_arima(0,0,0)_garch(1,1)_min100_30_tidy.png", 'Resolution', 300);
% export_fig("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVAR_Prasad_ARIMAX_correct_pos_min100_30_tidy.png", '-png', '-m2');

%%
figure;
plot(-7:39,sqrt(double_avg_neg_vola_abnormal_sq)./double_avg_neg_vola_normal_ARIMAX, 'LineWidth', 1.25);
title("AVAR-GARCH-approach following Prasad et al. (2021) for negative Events");
xline(0);
grid on
grid minor
ylabel("AVAR");
xlabel("days relative to event");

% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_GARCH_vola\AVAR_Prasad_ARIMAX_correct_neg_min100_30_tidy.png", 'Resolution', 300);


%
max_abn_ratio_prasad_AVAR_arimax = maxAR(sqrt(double_avg_pos_vola_abnormal_sq)./double_avg_pos_vola_normal_ARIMAX,0);

%% Robustness checks hereafter ############################################
% #########################################################################
% #########################################################################
% Not necessary, sandbox environment to fiddle around
%% Robustness Variation: Event-Study approach #############################
% and a period of clustered high volaitlity regimes in the aftermath

% compute abs percentage changes OR explicitely distinguish between neg and
% pos increments???
rhood_table_agg_prct = rhood_table_agg;
% here decide whether abosulte change or prct change, for more narrow event
% identification use absolute change
temp = price2ret(rhood_table_agg{:,:}+0.0000001, [], 'Periodic'); % for now: only abs returns , [], 'Periodic')
% temp = rhood_table_agg{2:818,:}-rhood_table_agg{1:817,:};
%%
rhood_table_agg_prct{2:818,:} = temp;
rhood_table_agg_prct = rhood_table_agg_prct(2:818,:);
%%
null_days =0;
quantile_per_day = [];
for i =1:height(rhood_table_agg_prct)
    quantile_per_day(i) = quantile(rhood_table_agg_prct{i,:}, 0.995);
    if quantile_per_day(i) == 0
        null_days = null_days+1;
    end
end

mean_quantile = sum(quantile_per_day)/(height(rhood_table_agg_prct)-null_days);
%%
% quantile_medians = [median(vec1, 'omitnan'), median(vec2, 'omitnan'), median(vec3, 'omitnan'), median(vec4, 'omitnan'), median(vec5, 'omitnan'), mean(vec5, 'omitnan'), mean(vec5, 'omitnan')]; % use median as heavy outliers present
%%
% identify event treshold abs change at 30%, i.e. corresponding to approx
% the 99,9% qunatile and cap at 1000% porct change which can easily be reached due to
% numerical stability correcttions, when e.g. going from 0 (=0.0000001)
% users to 1 user, which would tally to 999999900%. Or use absolute psotive
% change (ie users increasing) mean 99% qunatile corresponding to a 150
% threshold


%%
%  get viable event dates per stock
T = height(rhood_table_agg_prct);
dates = rhood_table_agg_prct.day_temp1;
tickers = rhood_table_agg_prct.Properties.VariableNames;
N = width(rhood_table_agg_prct);
events_array = cell(width(rhood_table_agg_prct),3);

for i = 1:N
    name = tickers(i);
    events = dates(([rhood_table_agg_prct{:,i} >=0.3] & [rhood_table_agg_prct{:,i} <10]) | ([rhood_table_agg_prct{:,i} <= -0.3] & [rhood_table_agg_prct{:,i} > -10])); % dates([rhood_table_agg_prct{:,i} >=100]); 
    changes = rhood_table_agg_prct{:,i};
    relevant_changes = changes(([rhood_table_agg_prct{:,i} >=0.3] & [rhood_table_agg_prct{:,i} <10]) | ([rhood_table_agg_prct{:,i} <= -0.3]& [rhood_table_agg_prct{:,i} > -10]));
    events_array{i,1} = events;
    events_array{i,2} = name;
    events_array{i,3} = relevant_changes;
end
% 

% alternative

% for t = 1:T
%     date = dates(t);
%     events_per_day = [];
%     for i = 1:N
%         events_per_day(i) = rhood_table_agg_prct{t,i};
%     end
%     cut_off = quantile(events_per_day, 0.995);
%     
%     for i = 1:N
%         name = tickers(i);
%         changes = rhood_table_agg_prct{t,i};
%         relevant_changes = changes(([rhood_table_agg_prct{t,i} >=cut_off]) | ([rhood_table_agg_prct{t,i} <= -cut_off]));
%         events_array{i,1} = events;
%         events_array{i,2} = name;
%         events_array{i,3} = relevant_changes;
%         
%     end
% end
%% Preprocess event data
% Ascertains that for any event day with more than 30% increase in users
% holding, only the very first of such incidences is marked as an event.
% That is, consecutive days subsequent to a first event marker also
% exhibiting user changes >30% are omitted to deal with hysteresis effects.
tidy_events_array_robust = cell(width(rhood_table_agg_prct),3);


for i = 1:N
    messy_events = events_array{i,1};
    messy_changes = events_array{i,3};
    name = events_array{i,2};
    help = 0;
    idx = 0;
    length_messy_events = length(messy_events);
    tidy_events = datetime('01-01-0001');
    tidy_changes = [0];
    disp(i);
    disp(name);
    try
        for j = 1:length_messy_events
            if j < length_messy_events
                dist = caldays(between(messy_events(j), messy_events(j+1), 'days'));
                if dist <= 1
                    help = help+1;
                    continue
                else
                    idx = idx+1;
                    tidy_events(idx) = messy_events(j-help);
                    tidy_changes(idx) = messy_changes(j-help);
                    
                    help = 0;
                    continue            
                end
            else
                idx = idx+1;
                tidy_events(idx) = messy_events(j);
                tidy_changes(idx) = messy_changes(j);
            end

        end
        tidy_events_array_robust{i,1} = tidy_events;
        tidy_events_array_robust{i,2} = name;
        tidy_events_array_robust{i,3} = tidy_changes;
    catch
        tidy_events_array_robust{i,2} = name;
        tidy_events_array_robust{i,1} = datetime('01-01-0001');
        tidy_events_array_robust{i,3} = [0];
        continue
    end

end


for i = 1:N
   if tidy_events_array_robust{i,1} == datetime('01-01-0001')
       tidy_events_array_robust{i,1} = [];
   end
end

%% alternative for messsy events
% tidy_events_array_robust = cell(width(rhood_table_agg_prct),3);
% for i = 1:N
%     messy_events = events_array{i,1};
%     messy_changes = events_array{i,3};
%     name = events_array{i,2};
% 
%     tidy_events_array_robust{i,1} = messy_events;
%     tidy_events_array_robust{i,2} = name;
%     tidy_events_array_robust{i,3} = messy_changes;
% 
% 
% end
% 
% 
% for i = 1:N
%    if tidy_events_array_robust{i,1} == datetime('01-01-0001')
%        tidy_events_array_robust{i,1} = [];
%    end
% end
%% Normal and abnormal return measurement
% add stock returns and market returns to array
event_tickers = cell2table(tidy_events_array_robust(:,2));
event_tickers = event_tickers{:,1};
return_tickers = logReturns_daily.Properties.VariableNames(3:width(logReturns_daily));
avail_tickers = intersect(event_tickers, return_tickers);
logReturns_daily_avail = logReturns_daily(:,avail_tickers);
N_event_all_robust = 0;
pre_day_pos_count = 0;
pre_day_all_count = 0;
for i = 1:N
    ticker = tidy_events_array_robust{i,2}{1,1};
    disp(i);
    disp(ticker);
    for k = 1:length(tidy_events_array_robust{i,1})
        event_date = tidy_events_array_robust{i,1}(k);
        if isweekend(event_date) == 1
            continue
        elseif ismember(ticker, avail_tickers) == 0
            continue
        elseif min(rhood_table_agg{:,i}) <= 100 %rhood_table_agg{event_date-1,i} <= 100  OR min(rhood_table_agg{:,i}) <= 100 % !!!! super important: ensures cap from below. May be varied, but alters all computations
            continue
        else
%             if rhood_table_agg_prct{event_date-1,i} >= 0
%                 pre_day_pos_count = pre_day_pos_count+1;
%                 pre_day_all_count = pre_day_all_count+1;
%             else
%                 pre_day_all_count = pre_day_all_count+1;
%             end
                
            id = find(logReturns_daily_avail.Var1 == event_date);
            stock_returns = logReturns_daily_avail.(ticker)(id-120:id+39); % estimation window spec is 120 trading days prior to event, excluding event day
            id2 = find(factors_daily_df.Var1 == event_date);
            market_premium = factors_daily_df{id2-120:id2+39,1}+factors_daily_df{id2-120:id2+39,4}; % catch length of event window here, ie 5 or 10, 20 or 40
            % check whether market premium (Rm-Rf) or only Rm !!!!
            
            tidy_events_array_robust{i,k+3} = [stock_returns, market_premium];
            N_event_all_robust = N_event_all_robust +1;
            
        end
        
    end
    
end

%% Estimation procedure
% Prior to any aggregation concerns perform estimation procedure for each
% security and all previously idtentified events
max_event_count = width(tidy_events_array_robust)-3;
for i = 1:N
    disp(i);
    logic = tidy_events_array_robust{i,1};
    if isa(logic, 'datetime') == 0
        continue
    else
        for j = 4:(4+max_event_count-1) % using the above criteria at most length(tidy_events_array_robust)-3 events were identified, currently 15
            event = tidy_events_array_robust{i,j};
            if isempty(event) == 1
                continue
            else
                
                est_returns = event(1:113,1);
                event_returns = event(114:160,1); % catch length of event window here, ie 5 or 10, 20 or 40
                market_est_returns = event(1:113,2)/100; % do never trust blindlessly... ever.
                market_event_returns = event(114:160,2)/100; % catch length of event window here, ie 5 or 10, 20 or 40
                
                % deploy market model from here on with spec Ri = Xi*thetai
                % + epsi including an intersect and slope where Xi = [1',
                % Rmarket']
                Ri = est_returns;
                Xi = [ones(113,1),market_est_returns];
                theta = (Xi'*Xi)\(Xi'*Ri);
                eps_est = Ri-Xi*theta;
                res_var = eps_est'*eps_est*(1/113-2); % dof correction
                theta_var = (Xi'*Xi)^-1*res_var; % via CLT and LLN, asymptotically consistent
                
                % now use estimates to disentangle abnormal returns from
                % actual and expected returns, ie. abnormal = actual -
                % expected(modelled)
                Xi_event = [ones(47,1),market_event_returns]; % catch length of event window here, ie 5 or 10, 20 or 40
                abn_event_returns = event_returns-Xi_event*theta;
                norm_event_returns = Xi_event*theta;
                realised_event_returns = event_returns;
                abn_var = ones(47,47)*res_var + Xi_event*(Xi'*Xi)^-1*Xi_event'*res_var; % catch length of event window here, ie 5 or 10, 20 or 40
                new_j = max_event_count+j;
                temp_cell = cell(8,1);
                temp_cell{1,1} = abn_event_returns;
                temp_cell{2,1} = abn_var;
                temp_cell{3,1} = norm_event_returns;
                temp_cell{4,1} = realised_event_returns;
                temp_cell{5,1} = theta(1); %alpha
                temp_cell{6,1} = theta(2); %beta
                
                % 5 day rolling window beta for event window
                for k = -3:39
                   Xi_temp = Xi_event(k+4:k+8,:);
                   Ri_temp = event_returns(k+4:k+8,:);
                   theta_event = (Xi_temp'*Xi_temp)\(Xi_temp'*Ri_temp);
                   beta_series(k+4) = theta_event(2);
                   
                end
                
                
                
                temp_cell{7,1} = beta_series; %beta_series from rolling window
                temp_cell{8,1} = market_event_returns;
                tidy_events_array_robust{i,new_j} = temp_cell;

            end

        end
    end
end
%%
% first loop to distinguish between pos and neg extreme changes
sig = 0;
sigpos = 0;
signeg = 0;
new_marker = width(tidy_events_array_robust)+1;

for i = 1:N
    % additionally calculate average abnormal returns per stock
    % and avg CAR per stock
    return_mat_pos = [];
    market_mat_pos = [];
    return_mat_neg = [];
    market_mat_neg = [];
    event_mat_pos = [];
    event_mat_neg = [];
    count1 = 1;
    count2 = 1;
    l = 0;
    for k = (new_marker-max_event_count):(new_marker-1)
        help = tidy_events_array_robust{i, k};
        if isempty(help)
            continue
        else
            return_temp = tidy_events_array_robust{i, k}{1, 1};
            market_temp = tidy_events_array_robust{i, k}{8, 1};
            event_temp = tidy_events_array_robust{i, k}{4, 1};
            l = l+1;
            if isnan(return_temp(1))

                continue
            elseif tidy_events_array_robust{i,3}(l) > 0
                return_mat_pos(:,count1) = return_temp;
                market_mat_pos(:, count1) = market_temp;
                event_mat_pos(:, count1) = event_temp;

          
            elseif tidy_events_array_robust{i,3}(l) < 0
                return_mat_neg(:,count2) = return_temp;
                market_mat_neg(:, count2) = market_temp;
                event_mat_neg(:, count2) = event_temp;

            end
        end
    end
    
    tidy_events_array_robust{i,new_marker} = mean(return_mat_pos, 2, 'omitnan');
    car_per_event_stock_pos = cumsum(return_mat_pos, 1, 'omitnan');
    tidy_events_array_robust{i,new_marker+1} = mean(car_per_event_stock_pos, 2, 'omitnan');
    tidy_events_array_robust{i,new_marker+2} = mean(return_mat_neg, 2, 'omitnan');
    car_per_event_stock_neg = cumsum(return_mat_neg, 1, 'omitnan');
    tidy_events_array_robust{i,new_marker+3} = mean(car_per_event_stock_neg, 2, 'omitnan');
    tidy_events_array_robust{i,new_marker+4} = mean(market_mat_pos, 2, 'omitnan');
    tidy_events_array_robust{i,new_marker+5} = mean(market_mat_neg, 2, 'omitnan');
    tidy_events_array_robust{i,new_marker+6} = mean(event_mat_pos, 2, 'omitnan');
    tidy_events_array_robust{i,new_marker+7} = mean(event_mat_neg, 2, 'omitnan');
    
end

% 2nd loop to look at pos and neg extreme changes jointly
sig2 = 0;
for i = 1:N
    % additionally calculate average abnormal returns per stock
    % and avg CAR per stock
    count = 1;
    return_mat = [];
    for k = (new_marker-max_event_count):(new_marker-1)
        help = tidy_events_array_robust{i, k};
        if isempty(help)
            
            continue
        else
            
            return_temp = tidy_events_array_robust{i, k}{1, 1};
            if isnan(return_temp(1))
                sig2 = sig2+1;
               continue
            else
                return_mat(:,count) = return_temp;
                count = count+1;
            end
        end
    end
    
    tidy_events_array_robust{i,new_marker+8} = mean(return_mat, 2, 'omitnan');
    car_per_event_stock = cumsum(return_mat, 1, 'omitnan');
    tidy_events_array_robust{i,new_marker+9} = mean(car_per_event_stock, 2, 'omitnan');

    
end


%% Time averages per stock AVG and CAR

double_avg_mat_pos = [];
double_avg_mat_pos_market = [];
double_avg_mat_pos_event = [];
double_avg_car_mat_pos = [];
double_avg_mat_neg = [];
double_avg_mat_neg_market = [];
double_avg_mat_neg_event = [];
double_avg_car_mat_neg = [];
double_avg_mat = [];
double_avg_car_mat = [];
 

count = 0;
for i = 1:N
    if isempty(tidy_events_array_robust{i, new_marker})
        count = count+1;
        continue
    else
        avg_temp_pos = tidy_events_array_robust{i, new_marker};
        avg_car_temp_pos = tidy_events_array_robust{i, new_marker+1};
        avg_temp_market_pos = tidy_events_array_robust{i, new_marker+4};
        avg_temp_event_pos = tidy_events_array_robust{i, new_marker+6};
        double_avg_mat_pos(:,i-count) = avg_temp_pos;
        double_avg_mat_pos_market(:,i-count) = avg_temp_market_pos;
        double_avg_mat_pos_event(:,i-count) = avg_temp_event_pos;
        double_avg_car_mat_pos(:,i-count) = avg_car_temp_pos;
%         avg_temp_neg = tidy_events_array_robust{i, 76};
%         avg_car_temp_neg = tidy_events_array_robust{i, 77};
%         double_avg_mat_neg(:,i-count) = avg_temp_neg;
%         double_avg_car_mat_neg(:,i-count) = avg_car_temp_neg;
%  
    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array_robust{i, new_marker+2})
        count = count+1;
        continue
    else
        avg_temp_neg = tidy_events_array_robust{i, new_marker+2};
        avg_car_temp_neg = tidy_events_array_robust{i, new_marker+3};
        avg_temp_market_neg = tidy_events_array_robust{i, new_marker+5};
        avg_temp_event_neg = tidy_events_array_robust{i, new_marker+7};
        double_avg_mat_neg(:,i-count) = avg_temp_neg;
        double_avg_mat_neg_market(:,i-count) = avg_temp_market_neg;
        double_avg_mat_neg_event(:,i-count) = avg_temp_event_neg;
        double_avg_car_mat_neg(:,i-count) = avg_car_temp_neg;

    end   
end

count = 0;
for i = 1:N
    if isempty(tidy_events_array_robust{i, new_marker+8})
        count = count+1;
        continue
    else
        avg_temp = tidy_events_array_robust{i, new_marker+8};
        avg_car_temp = tidy_events_array_robust{i, new_marker+9};
        double_avg_mat(:,i-count) = avg_temp;
        double_avg_car_mat(:,i-count) = avg_car_temp;

    end   
end
% Cross-Sectional averaging
double_avg_pos = mean(double_avg_mat_pos, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_car_pos = mean(double_avg_car_mat_pos, 2, 'omitnan');

double_avg_neg = mean(double_avg_mat_neg, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_car_neg = mean(double_avg_car_mat_neg, 2, 'omitnan');

double_avg = mean(double_avg_mat, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_car = mean(double_avg_car_mat, 2, 'omitnan');


% BHAR calculation and averaging

double_avg_market_pos = mean(double_avg_mat_pos_market, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_market_neg = mean(double_avg_mat_neg_market, 2, 'omitnan'); % 2 NaNs introduced, simply skip

double_avg_event_pos = mean(double_avg_mat_pos_event, 2, 'omitnan'); % 2 NaNs introduced, simply skip
double_avg_event_neg = mean(double_avg_mat_neg_event, 2, 'omitnan'); % 2 NaNs introduced, simply skip

BHAR_avg_pos = [];
BHAR_avg_neg = [];

for t = 1:47
    pos_bhar_temp = prod((double_avg_event_pos(1:t)+1));
    pos_bhar_market_temp = prod((double_avg_market_pos(1:t)+1));
    BHAR_avg_pos(t) = pos_bhar_temp - pos_bhar_market_temp;
    neg_bhar_temp = prod((double_avg_event_neg(1:t)+1));
    neg_bhar_market_temp = prod((double_avg_market_neg(1:t)+1));
    BHAR_avg_neg(t) = neg_bhar_temp - neg_bhar_market_temp;
    
end
%%
BHAR_avg_pos = cumprod(double_avg_event_pos+1)- cumprod(double_avg_market_pos+1);

%%
BHAR_avg_pos720 = cumprod(double_avg_event_pos(8:28)+1) - cumprod(double_avg_market_pos(8:28)+1);
%%
figure;
subplot(3,1,1);

plot(-7:12, double_avg_pos(1:20), -7:12, double_avg_car_pos(1:20), 'LineWidth', 1.25);
title("(a) AVG and CAR for positive events");
yline(0);
subplot(3,1,2);
plot(-7:12, double_avg_neg(1:20), -7:12, double_avg_car_neg(1:20), 'LineWidth', 1.25);
title("(b) AVG and CAR for negative events");
ylabel("AVG and CAR");
yline(0);
legend("AVG","CAR^{avg}", "zero");
subplot(3,1,3);

plot(-7:12, double_avg(1:20), -7:12, double_avg_car(1:20), 'LineWidth', 1.25);
title("(c) AVG and CAR for all events");
xlabel("days relative to event");
yline(0);
savehandle = gcf;
%
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR.png", 'Resolution', 300);

%%
figure;
subplot(2,2,[1,2]);
plot(-7:20, double_avg_pos(1:28), -7:20, double_avg_car_pos(1:28), -7:20, BHAR_avg_pos(1:28), 'LineWidth', 1.25);
yline(0);
title("(a) AVG and CAR for positive events");
xlabel("days relative to event");
ylabel("AVG, CAR, BHAR");
legend("AVG^{+}","CAR^{+}", "BHAR^{+}", "zero");
subplot(2,2,3);
plot(-7:20, double_avg_car_pos(1:28), 'LineWidth', 1.25, 'Color', [0.8500 0.3250 0.0980]);
hold on
plot(-7:20, BHAR_avg_pos(1:28), 'LineWidth', 1.25, 'Color', [0.9290 0.6940 0.1250]);
hold off
title("(b) CAR, BHAR for (-7,20)");
xlabel("days relative to event");
ylabel("CAR, BHAR");
ylim([-0.005 0.085]);

subplot(2,2,4);
plot(0:20, double_avg_car_pos(8:28)-double_avg_car_pos(8), 'LineWidth', 1.25, 'Color', [0.8500 0.3250 0.0980]);
hold on
plot(0:20, BHAR_avg_pos(8:28)-BHAR_avg_pos(8), 'LineWidth', 1.25, 'Color', [0.9290 0.6940 0.1250]); % BHAR_avg_pos(8:28)-BHAR_avg_pos(8)
hold off
title("(c) CAR, BHAR for (0,20)");
xlabel("days relative to event");
% savehandle = gcf;
% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_overview_pos_BHAR.png", 'Resolution', 300);
%% Counting events

N_event_pos = 0;
N_event_neg = 0;
N_event_all = 0;


for i = 1:N
   if tidy_events_array_robust{i,3} == 0
       continue
   else
       k = length(tidy_events_array_robust{i,3});
       changes = tidy_events_array_robust{i,3};
       N_event_all = N_event_all+k;
       for j = 1:k
           if changes(j) >= 0
               N_event_pos = N_event_pos +1;
           elseif changes(j) < 0
               N_event_neg = N_event_neg +1;
           end
       end
   end
end


%% Robustness test and hypothesis testing
% in order to conduct conventional inference on the estimates, (admittedly
% rather arbitrarily) I subset the securities according to the number of
% available events and omit all events that share a mutual/overlapping
% windows of X days (here 10, as afterwards daily average returns become
% negligible and are likely to not being governed ynmore by event
% repercussions). The remainder of events can then be deemed mutually
% exclusive and non overlapping thereby enabling standard inference w/o
% clustering as in Campbell

%% Export table

exporttable = table([-7:39]', double_avg_pos, double_avg_car_pos, double_avg_neg, double_avg_car_neg, double_avg, double_avg_car);
exporttable.Variables = round(exporttable.Variables,4);
% depending on specification, different outcomes possible, butin general
% (using abs extreme users percentage change and not signed one, averaging
% over all available firms that made it into the final table w/o assigning
% them to diff categories): palpable postive abnormal return on event day
% turning negative on subsequent days with a negative CAR on day 5 of
% -1,25%/ -1,77% on average. Testing for significance still pending in code routine
%% Add Control Variables ##################################################
% 1) start with market cap ################################################
%% load market value from csv
market_value = readtable("C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\control_variables\market_value.csv",'ReadVariableNames',1);
market_value = market_value(52:1309,:); % remove null entries that appeared due to limited balance sheet data availability

market_value_tt = table2timetable(market_value, 'RowTimes', 'Var1');

market_value_tt = market_value_tt(tr,:);
market_value_tt = rmmissing(market_value_tt, 2, 'MinNumMissing', height(market_value_tt));
market_val_tickers = market_value_tt.Properties.VariableNames(3:width(market_value_tt));
%%
for i = 1:N
   ticker = tidy_events_array_robust{i,2}{1,1};
   temp = intersect(ticker, market_val_tickers);
   if isempty(temp)
       
       continue
   elseif isempty(tidy_events_array_robust{i,42})
       continue
   else
       stock_market_val = market_value_tt.(ticker);
       mean_market_val = mean(stock_market_val, 'omitnan');
       tidy_events_array_robust{i,44} = mean_market_val;
   end
   
    
end

%% 
count = 0;
for i = 1:N
    if isempty(tidy_events_array_robust{i,44})
        count = count+1;
        continue
    elseif  isempty(tidy_events_array_robust{i,42})
        count = count+1;
        continue
    else
        tic = tidy_events_array_robust{i,2}{1,1};
        market_val = tidy_events_array_robust{i,44};
        all_market_vals(i-count) = market_val;  
    end
end

market_val_quantiles = quantile(all_market_vals, [0.05 0.5 0.95]); % decide here which quantile cuts to use
threshold_market_val_up = market_val_quantiles(3);
threshold_market_val_low = market_val_quantiles(1);

for i = 1:N
    if isempty(tidy_events_array_robust{i,44})
        continue
    elseif tidy_events_array_robust{i,44} >= threshold_market_val_up
        tidy_events_array_robust{i,45} = 1;
    elseif tidy_events_array_robust{i,44} <= threshold_market_val_low
        tidy_events_array_robust{i,45} = -1;
    else
        tidy_events_array_robust{i,45} = 0;
        
    end

end
%%
count = 0;
for i = 1:N
    if isempty(tidy_events_array_robust{i, 45}) | isempty(tidy_events_array_robust{i, 34})
        count = count+1;
        continue
    elseif tidy_events_array_robust{i, 45} == 1
        avg_temp_mktval_up_pos = tidy_events_array_robust{i, 34};
        avg_car_temp_mktval_up_pos = tidy_events_array_robust{i, 35};
        double_avg_mat_mktval_up_pos(:,i-count) = avg_temp_mktval_up_pos;
        double_avg_car_mat_mktval_up_pos(:,i-count) = avg_car_temp_mktval_up_pos;
    else
        count = count+1;

    end   
end
count = 0;
for i = 1:N
    if isempty(tidy_events_array_robust{i, 45}) | isempty(tidy_events_array_robust{i, 34})
        count = count+1;
        continue

        
    elseif tidy_events_array_robust{i, 45} == 0
        avg_temp_mktval_iqr_pos = tidy_events_array_robust{i, 34};
        avg_car_temp_mktval_iqr_pos = tidy_events_array_robust{i, 35};
        double_avg_mat_mktval_iqr_pos(:,i-count) = avg_temp_mktval_iqr_pos;
        double_avg_car_mat_mktval_iqr_pos(:,i-count) = avg_car_temp_mktval_iqr_pos;
    else
        count = count+1;

        

    end   
end
count = 0;
for i = 1:N
    if isempty(tidy_events_array_robust{i, 45}) | isempty(tidy_events_array_robust{i, 34})
        count = count+1;
        continue
        
    elseif tidy_events_array_robust{i, 45} == -1
        avg_temp_mktval_low_pos = tidy_events_array_robust{i, 34};
        avg_car_temp_mktval_low_pos = tidy_events_array_robust{i, 35};
        double_avg_mat_mktval_low_pos(:,i-count) = avg_temp_mktval_low_pos;
        double_avg_car_mat_mktval_low_pos(:,i-count) = avg_car_temp_mktval_low_pos;
    else
        count = count+1;
        

    end   
end
%%
double_avg_mktval_up_pos = mean(double_avg_mat_mktval_up_pos, 2, 'omitnan'); 
double_avg_car_mktval_up_pos = mean(double_avg_car_mat_mktval_up_pos, 2, 'omitnan');

double_avg_mktval_iqr_pos = mean(double_avg_mat_mktval_iqr_pos, 2, 'omitnan'); 
double_avg_car_mktval_iqr_pos = mean(double_avg_car_mat_mktval_iqr_pos, 2, 'omitnan');

double_avg_mktval_low_pos = mean(double_avg_mat_mktval_low_pos, 2, 'omitnan'); 
double_avg_car_mktval_low_pos = mean(double_avg_car_mat_mktval_low_pos, 2, 'omitnan');
%%
figure;
subplot(3,1,1);
plot(-7:12, double_avg_mktval_up_pos(1:20), -7:12, double_avg_car_mktval_up_pos(1:20), 'LineWidth', 1.25);
title("(a) AVG and CAR for positive events for top 5% percentile of market cap");
yline(0);
subplot(3,1,2);
plot(-7:12, double_avg_mktval_iqr_pos(1:20), -7:12, double_avg_car_mktval_iqr_pos(1:20), 'LineWidth', 1.25);
title("(b) AVG and CAR for positive events and 95-5-quantile range of market cap");
yline(0);
ylabel("AVG and CAR");
legend("AVG","CAR^{avg}", "zero");
subplot(3,1,3);

plot(-7:12, double_avg_mktval_low_pos(1:20), -7:12, double_avg_car_mktval_low_pos(1:20), 'LineWidth', 1.25);
title("(c) AVG and CAR for positive only events for bottom 5% percentile of market cap");
xlabel("days relative event day");
yline(0);
savehandle = gcf;

% exportgraphics(savehandle, "C:\Users\maxem\Documents\Uni\Master\MA\MA\code\00_matlab\output\EventStudy_AbnormalReturns\AVG_CAR_positive_marketcap_5_95_new.png", 'Resolution', 300);
%% Diagnostics ############################################################
count = 1;
arch_vec = [];
garch_vec = [];
garch_large = [];
const_vec = [];

for i = 1:N
    for j = 139:153
       if isempty(tidy_events_array{i,j})
           continue
       elseif isnan(tidy_events_array{i,j}{1,1})
           continue
       end
       arch_vec(count) = tidy_events_array{i,j}{3,1};
       garch_vec(count) = tidy_events_array{i,j}{2,1};
       const_vec(count) = tidy_events_array{i,j}{1,1};
       if tidy_events_array{i,j}{2,1} >= tidy_events_array{i,j}{3,1}
           garch_large(count) = 1;
       else
           garch_large(count) = 0;
       end
           
       count = count +1;
    end
    
end


%%
lol = [1 1 1 2 10 4 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];

for i = 1:(length(lol)-1)
   lol2(i) = 0.8 + 0.5*lol(i) + randn()*0.25;
end

figure;
subplot(2,1,1);
plot(1:length(lol),lol)
subplot(2,1,2);
plot(2:length(lol), lol2)
