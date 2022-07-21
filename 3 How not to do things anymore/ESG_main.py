#%%
###################################################################################################
###################################################################################################
########################## Master Seminar in Econometrics - 2020/2021 #############################
########################            University of Tuebingen             ###########################
######################                ---By Max Haberl---                 #########################
####################        Submitted to Prof.  Dr.  Joachim Grammig        #######################
##################       Faculty of Economics, Department of Statistics,      #####################
##################            Econometrics and Empirical Economics            #####################
###################################################################################################
###################################################################################################

# Import required packages and install instances if necessary
import eikon as ek
import pandas as pd
import numpy as np
import random as rd
from bs4 import BeautifulSoup
import datetime
from datetime import datetime
from datetime import time
from datetime import date
import feather
import warnings
import yfinance as yf
from scipy.stats.mstats import gmean
from scipy.optimize import minimize
import matplotlib.pyplot as plt
import matplotlib as mpl
mpl.rcParams['figure.dpi'] = 300 # enhance visibility
warnings.filterwarnings('ignore')
ek.set_app_key('040599c845884dcf85bd213c64ca8ddcca9cf3dd') # Plug in EIKON Data API key here, can be obtained from software.pcl@wiwi.uni-tuebingen.de
# Until end of january, my key can be used as well, but an active instance of Refinitiv Workspace needs to be running on the same machine
###################################################################################################
tic = datetime.now()
# retrieve historic ESG data for SP500 and STOXX600 constituents
stoxx600, e600 = ek.get_data('0#.STOXX', fields=['TR.TRESGScore(Period=FY0,Frq=FY,SDate=0,EDate=-13)', 'TR.TRESGScore(Period=FY0,Frq=FY,SDate=0,EDate=-13).periodenddate'])

sp500, e500 = ek.get_data('0#.SPX', fields=['TR.TRESGScore(Period=FY0,Frq=FY,SDate=0,EDate=-13)', 'TR.TRESGScore(Period=FY0,Frq=FY,SDate=0,EDate=-13).periodenddate'])

# # or alternatively by loading csv files if available
# stoxx600 = pd.read_csv('stoxx600_ESGscores.csv', index_col= [0])
# sp500 = pd.read_csv('sp500_ESGscores.csv', index_col= [0])
# sp500_new = sp500

# ###################################################################################################


# #%% 
# # Several Controversy counts for later purposes
# sp500contr, err = ek.get_data(
#     instruments = ['0#.SPX'],
#     fields = [
#         'TR.ControvEnv(SDate=0,EDate=-13,IncludePartialYear=True)',
#         'TR.ControvEnv(SDate=0,EDate=-13,IncludePartialYear=True).periodenddate',
#         'TR.ControvWorkingCondition(SDate=0,EDate=-13,IncludePartialYear=True)',
#         'TR.ControvWorkingCondition(SDate=0,EDate=-13,IncludePartialYear=True).periodenddate',
#         'TR.ControvDiversityOpportunity(SDate=0,EDate=-13,IncludePartialYear=True)',
#         'TR.ControvDiversityOpportunity(SDate=0,EDate=-13,IncludePartialYear=True).periodenddate',
#         'TR.ControvEmployeesHS(SDate=0,EDate=-13,IncludePartialYear=True)',
#         'TR.ControvEmployeesHS(SDate=0,EDate=-13,IncludePartialYear=True).periodenddate'

#     ]
# )




# # %%
# stoxx600contr, err = ek.get_data(
#     instruments = ['0#.STOXX'],
#     fields = [
#         'TR.ControvEnv(SDate=0,EDate=-13,IncludePartialYear=True)',
#         'TR.ControvEnv(SDate=0,EDate=-13,IncludePartialYear=True).periodenddate',
#         'TR.ControvWorkingCondition(SDate=0,EDate=-13,IncludePartialYear=True)',
#         'TR.ControvWorkingCondition(SDate=0,EDate=-13,IncludePartialYear=True).periodenddate',
#         'TR.ControvDiversityOpportunity(SDate=0,EDate=-13,IncludePartialYear=True)',
#         'TR.ControvDiversityOpportunity(SDate=0,EDate=-13,IncludePartialYear=True).periodenddate',
#         'TR.ControvEmployeesHS(SDate=0,EDate=-13,IncludePartialYear=True)',
#         'TR.ControvEmployeesHS(SDate=0,EDate=-13,IncludePartialYear=True).periodenddate'

#     ]
# )

###################################################################################################
# Pre-process data and make uniform --------------------------------------------------------------
temp = sp500['Period End Date'].str.split('-', n = 1, expand = True)
temp2 = sp500['Instrument'].str.split('.', n = 1, expand = True)
sp500['End Date Year'] = temp[0]
sp500['Instrument'] = temp2 [0]

first_period_sp500 = sp500[(sp500['End Date Year'] == '2010') | (sp500['End Date Year'] == '2011') | (sp500['End Date Year'] == '2012') | (sp500['End Date Year'] == '2013')] 
# Sanity checks:
first_period_sp500 = first_period_sp500.groupby('Instrument').filter(lambda x : len(x) ==4)
second_period_sp500 = sp500[(sp500['End Date Year'] == '2014') | (sp500['End Date Year'] == '2015') | (sp500['End Date Year'] == '2016') | (sp500['End Date Year'] == '2017')] 
# Sanity checks: test = second_period_sp500[second_period_sp500]
second_period_sp500 = second_period_sp500.groupby('Instrument').filter(lambda y : len(y) ==4)

third_period_sp500 = sp500[(sp500['End Date Year'] == '2018') | (sp500['End Date Year'] == '2019')]

third_period_sp500 = third_period_sp500.groupby('Instrument').filter(lambda x : len(x) ==2)

first_period_mean_sp500 = first_period_sp500.groupby('Instrument')['ESG Score'].mean()
second_period_mean_sp500 = second_period_sp500.groupby('Instrument')['ESG Score'].mean()
third_period_mean_sp500 = third_period_sp500.groupby('Instrument')['ESG Score'].mean()


# repeat for stoxx 600 ----------------------------------------------------------------------------
temp = stoxx600['Period End Date'].str.split('-', n = 1, expand = True)
#temp2 = stoxx600['Instrument']#.str.split('.', n = 1, expand = True)
stoxx600['End Date Year'] = temp[0]
#stoxx600['Instrument'] = temp2 [0]

first_period_stoxx600 = stoxx600[(stoxx600['End Date Year'] == '2010') | (stoxx600['End Date Year'] == '2011') | (stoxx600['End Date Year'] == '2012') | (stoxx600['End Date Year'] == '2013')] 
second_period_stoxx600 = stoxx600[(stoxx600['End Date Year'] == '2014') | (stoxx600['End Date Year'] == '2015') | (stoxx600['End Date Year'] == '2016') | (stoxx600['End Date Year'] == '2017')] 

third_period_stoxx600 = stoxx600[(stoxx600['End Date Year'] == '2018') | (stoxx600['End Date Year'] == '2019')]


# Sanity Checks: if grouped by years it can sstill hold that there is some deviation in year counts due to reporting standards. The means are correct however
first_period_stoxx600 = first_period_stoxx600.groupby('Instrument').filter(lambda x : len(x) ==4)

second_period_stoxx600 = second_period_stoxx600.groupby('Instrument').filter(lambda y : len(y) ==4)

third_period_stoxx600 = third_period_stoxx600.groupby('Instrument').filter(lambda x : len(x) ==2)

first_period_mean_stoxx600 = first_period_stoxx600.groupby('Instrument')['ESG Score'].mean()
second_period_mean_stoxx600 = second_period_stoxx600.groupby('Instrument')['ESG Score'].mean()
third_period_mean_stoxx600 = third_period_stoxx600.groupby('Instrument')['ESG Score'].mean()


##################################################################################################
# Markowitz analysis -----------------------------------------------------------------------------
# Within each period look for 10 best and 10 worst ESG performances and undertake analysis accordningly
# Initiate required inputs for MC-Sampler and Markowitz Plots
# Get best and worst in-class constituents
first_period_best_sp500 = first_period_mean_sp500.nlargest(n = 10)
first_period_worst_sp500 = first_period_mean_sp500.nsmallest(n = 10)

second_period_best_sp500 = second_period_mean_sp500.nlargest(n = 10)
second_period_worst_sp500 = second_period_mean_sp500.nsmallest(n = 10)

third_period_best_sp500 = third_period_mean_sp500.nlargest(n = 10)
third_period_worst_sp500 = third_period_mean_sp500.nsmallest(n = 10)


# repeat for stoxx 600

first_period_best_stoxx600 = first_period_mean_stoxx600.nlargest(n = 10)
first_period_worst_stoxx600 = first_period_mean_stoxx600.nsmallest(n = 10)

second_period_best_stoxx600 = second_period_mean_stoxx600.nlargest(n = 10)
second_period_worst_stoxx600 = second_period_mean_stoxx600.nsmallest(n = 10)

third_period_best_stoxx600 = third_period_mean_stoxx600.nlargest(n = 10)
third_period_worst_stoxx600 = third_period_mean_stoxx600.nsmallest(n = 10)


# create modest portfolio from random draws from the second and third quartile
#1st period medium sp500
first_period_med_sp500_help = pd.DataFrame(first_period_mean_sp500, columns = ['ESG Score'])
first_period_med_sp500_help['quantile'] = pd.qcut(first_period_mean_sp500, 4, labels = ['Q1','Q2', 'Q3','Q4'])
df = first_period_med_sp500_help
df['quantile'] = df['quantile'].astype('str')
df = df.drop(df[(df['quantile'] == 'Q1') | (df['quantile'] == 'Q4')].index)


rd.seed(42) # Only seed throughout
first_period_med_sp500 = df.groupby('quantile').apply(lambda x: x.sample(5))

# 2nd period medium sp500
second_period_med_sp500_help = pd.DataFrame(second_period_mean_sp500, columns = ['ESG Score'])
second_period_med_sp500_help['quantile'] = pd.qcut(second_period_mean_sp500, 4, labels = ['Q1','Q2', 'Q3','Q4'])
df = second_period_med_sp500_help
df['quantile'] = df['quantile'].astype('str')
df = df.drop(df[(df['quantile'] == 'Q1') | (df['quantile'] == 'Q4')].index)


second_period_med_sp500 = df.groupby('quantile').apply(lambda x: x.sample(5))


# 3rd period medium sp500
third_period_med_sp500_help = pd.DataFrame(third_period_mean_sp500, columns = ['ESG Score'])
third_period_med_sp500_help['quantile'] = pd.qcut(third_period_mean_sp500, 4, labels = ['Q1','Q2', 'Q3','Q4'])
df = third_period_med_sp500_help
df['quantile'] = df['quantile'].astype('str')
df = df.drop(df[(df['quantile'] == 'Q1') | (df['quantile'] == 'Q4')].index)


third_period_med_sp500 = df.groupby('quantile').apply(lambda x: x.sample(5))


# Now for stoxx600 -----------------------------------------------------------------------------------------------------------
# 1st period medium stoxx600
first_period_med_stoxx600_help = pd.DataFrame(first_period_mean_stoxx600, columns = ['ESG Score'])
first_period_med_stoxx600_help['quantile'] = pd.qcut(first_period_mean_stoxx600, 4, labels = ['Q1','Q2', 'Q3','Q4'])
df = first_period_med_stoxx600_help
df['quantile'] = df['quantile'].astype('str')
df = df.drop(df[(df['quantile'] == 'Q1') | (df['quantile'] == 'Q4')].index)



first_period_med_stoxx600 = df.groupby('quantile').apply(lambda x: x.sample(5))

# 2nd period medium stoxx600
second_period_med_stoxx600_help = pd.DataFrame(second_period_mean_stoxx600, columns = ['ESG Score'])
second_period_med_stoxx600_help['quantile'] = pd.qcut(second_period_mean_stoxx600, 4, labels = ['Q1','Q2', 'Q3','Q4'])
df = second_period_med_stoxx600_help
df['quantile'] = df['quantile'].astype('str')
df = df.drop(df[(df['quantile'] == 'Q1') | (df['quantile'] == 'Q4')].index)


second_period_med_stoxx600 = df.groupby('quantile').apply(lambda x: x.sample(5))


# 3rd period medium stoxx600
third_period_med_stoxx600_help = pd.DataFrame(third_period_mean_stoxx600, columns = ['ESG Score'])
third_period_med_stoxx600_help['quantile'] = pd.qcut(third_period_mean_stoxx600, 4, labels = ['Q1','Q2', 'Q3','Q4'])
df = third_period_med_stoxx600_help
df['quantile'] = df['quantile'].astype('str')
df = df.drop(df[(df['quantile'] == 'Q1') | (df['quantile'] == 'Q4')].index)


third_period_med_stoxx600 = df.groupby('quantile').apply(lambda x: x.sample(5))
##################################################################################################
# Get tickers ------------------------------------------------------------------------------------

first_period_best_sp500_tickers = first_period_best_sp500.index
first_period_worst_sp500_tickers = first_period_worst_sp500.index
first_period_med_sp500_tickers = first_period_med_sp500.index.get_level_values('Instrument')

second_period_best_sp500_tickers = second_period_best_sp500.index
second_period_worst_sp500_tickers = second_period_worst_sp500.index
second_period_med_sp500_tickers = second_period_med_sp500.index.get_level_values('Instrument')

third_period_best_sp500_tickers = third_period_best_sp500.index
third_period_worst_sp500_tickers = third_period_worst_sp500.index
third_period_med_sp500_tickers = third_period_med_sp500.index.get_level_values('Instrument')

first_period_best_stoxx600_tickers = first_period_best_stoxx600.index
first_period_worst_stoxx600_tickers = first_period_worst_stoxx600.index
first_period_med_stoxx600_tickers = first_period_med_stoxx600.index.get_level_values('Instrument')

second_period_best_stoxx600_tickers = second_period_best_stoxx600.index
second_period_worst_stoxx600_tickers = second_period_worst_stoxx600.index
second_period_med_stoxx600_tickers = second_period_med_stoxx600.index.get_level_values('Instrument')

third_period_best_stoxx600_tickers = third_period_best_stoxx600.index
third_period_worst_stoxx600_tickers = third_period_worst_stoxx600.index
third_period_med_stoxx600_tickers = third_period_med_stoxx600.index.get_level_values('Instrument')

##################################################################################################
# Define periods and get functions ---------------------------------------------------------------
first_period_start = '2010-01-01'
first_period_end = '2013-12-31'

second_period_start = '2014-01-01'
second_period_end = '2017-12-31'

third_period_start = '2018-01-01' 
third_period_end = '2019-12-31'

def get_closing(tickers, start, stop):
    stocks = pd.DataFrame()
    for ticker in tickers:
        closing = yf.download(ticker, start = start, end = stop, progress = False)['Close']
        stocks[ticker] = closing

    stocks.columns = tickers
    return(stocks)

def get_closing_eikon(tickers, start, stop):
    stocks, e = ek.get_data(instruments = list(tickers), fields= ['TR.CLOSEPRICE(SDate=' +start+',EDate='+stop+',Frq=D,CURN=USD).Date', 'TR.CLOSEPRICE(SDate=' +start+',EDate='+stop+',Frq=D,CURN=USD)'])
    return(stocks)

##################################################################################################
# get closing prices -----------------------------------------------------------------------------
first_period_best_closing_sp500 = get_closing(first_period_best_sp500_tickers, first_period_start, first_period_end)
# mind yFinance request limits!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
first_period_worst_closing_sp500 = get_closing(first_period_worst_sp500_tickers, first_period_start, first_period_end)
first_period_med_closing_sp500 = get_closing(first_period_med_sp500_tickers, first_period_start, first_period_end)

second_period_best_closing_sp500 = get_closing(second_period_best_sp500_tickers, second_period_start, second_period_end)
second_period_worst_closing_sp500 = get_closing(second_period_worst_sp500_tickers, second_period_start, second_period_end)
second_period_med_closing_sp500 = get_closing(second_period_med_sp500_tickers, second_period_start, second_period_end)

third_period_best_closing_sp500 = get_closing(third_period_best_sp500_tickers, third_period_start, third_period_end)
third_period_worst_closing_sp500 = get_closing(third_period_worst_sp500_tickers, third_period_start, third_period_end)
third_period_med_closing_sp500 = get_closing(third_period_med_sp500_tickers, third_period_start, third_period_end)

first_period_best_closing_stoxx600 = get_closing_eikon(first_period_best_stoxx600_tickers, first_period_start, first_period_end)
first_period_best_closing_stoxx600 = pd.pivot_table(first_period_best_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')
first_period_worst_closing_stoxx600 = get_closing_eikon(first_period_worst_stoxx600_tickers, first_period_start, first_period_end)
first_period_worst_closing_stoxx600 = pd.pivot_table(first_period_worst_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')
first_period_med_closing_stoxx600 = get_closing_eikon(first_period_med_stoxx600_tickers, first_period_start, first_period_end)
first_period_med_closing_stoxx600 = pd.pivot_table(first_period_med_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')


second_period_best_closing_stoxx600 = get_closing_eikon(second_period_best_stoxx600_tickers, second_period_start, second_period_end)
second_period_best_closing_stoxx600 = pd.pivot_table(second_period_best_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')
second_period_worst_closing_stoxx600 = get_closing_eikon(second_period_worst_stoxx600_tickers, second_period_start, second_period_end)
second_period_worst_closing_stoxx600 = pd.pivot_table(second_period_worst_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')
second_period_med_closing_stoxx600 = get_closing_eikon(second_period_med_stoxx600_tickers, second_period_start, second_period_end)
second_period_med_closing_stoxx600 = pd.pivot_table(second_period_med_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')


third_period_best_closing_stoxx600 = get_closing_eikon(third_period_best_stoxx600_tickers, third_period_start, third_period_end)
third_period_best_closing_stoxx600 = pd.pivot_table(third_period_best_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')
third_period_worst_closing_stoxx600 = get_closing_eikon(third_period_worst_stoxx600_tickers, third_period_start, third_period_end)
third_period_worst_closing_stoxx600 = pd.pivot_table(third_period_worst_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')
third_period_med_closing_stoxx600 = get_closing_eikon(third_period_med_stoxx600_tickers, third_period_start, third_period_end)
third_period_med_closing_stoxx600 = pd.pivot_table(third_period_med_closing_stoxx600, values='Close Price', index='Date', columns='Instrument')

##################################################################################################
# construct log returns and Var-Cov-matrices -----------------------------------------------------
# For sorted simulations
# def ret_cov(closing_prices):
#     log_return = np.log(closing_prices.pct_change()+1)
#     #log_return = np.log(closing_prices/closing_prices.shift(1)).dropna()
#     mean_log_returns = log_return.drop(log_return.head(1).index).dropna(axis = 1).mean()
#     log_cov = log_return.drop(log_return.head(1).index).dropna(axis = 1).cov()
#     sharpe_ratio = 0
#     return(log_return, mean_log_returns, log_cov, sharpe_ratio)


# FOR markowitz plots

def ret_cov(closing_prices):
    log_return = np.log(closing_prices/closing_prices.shift(1)).dropna()
    mean_log_returns = log_return.mean()
    log_cov = log_return.cov()
    return(log_return, mean_log_returns, log_cov)


first_period_best_sp500_input = ret_cov(first_period_best_closing_sp500)
# mind limits!!!
first_period_worst_sp500_input = ret_cov(first_period_worst_closing_sp500)
first_period_med_sp500_input = ret_cov(first_period_med_closing_sp500)

second_period_best_sp500_input = ret_cov(second_period_best_closing_sp500)
second_period_worst_sp500_input = ret_cov(second_period_worst_closing_sp500)
second_period_med_sp500_input = ret_cov(second_period_med_closing_sp500)

third_period_best_sp500_input = ret_cov(third_period_best_closing_sp500)
third_period_worst_sp500_input = ret_cov(third_period_worst_closing_sp500)
third_period_med_sp500_input = ret_cov(third_period_med_closing_sp500)

first_period_best_stoxx600_input = ret_cov(first_period_best_closing_stoxx600)
first_period_worst_stoxx600_input = ret_cov(first_period_worst_closing_stoxx600)
first_period_med_stoxx600_input = ret_cov(first_period_med_closing_stoxx600)

second_period_best_stoxx600_input = ret_cov(second_period_best_closing_stoxx600)
second_period_worst_stoxx600_input = ret_cov(second_period_worst_closing_stoxx600)
second_period_med_stoxx600_input = ret_cov(second_period_med_closing_stoxx600)

third_period_best_stoxx600_input = ret_cov(third_period_best_closing_stoxx600)
third_period_worst_stoxx600_input = ret_cov(third_period_worst_closing_stoxx600)
third_period_med_stoxx600_input = ret_cov(third_period_med_closing_stoxx600)


##################################################################################################

# Functions for optimizations and Monte Carlo sampling
# function for quick port performance, sampler and wrapper functions for optimization ------------
def port_perf(weights, mean_ret, covariance, risk_free_rate):
    # This shortcut function helps computing the perfomrance of any given portfolio
    port_return = np.sum(mean_ret*weights)
    port_return_annual = port_return * 252
    port_vol = np.sqrt(np.dot(weights.T, np.dot(covariance, weights)))
    port_vol_annual = np.sqrt(np.dot(weights.T, np.dot(covariance, weights))) * np.sqrt(252)
    sharpe_ratio = (port_return_annual - risk_free_rate)/port_vol_annual
    neg_sharpe = -sharpe_ratio
    return port_return, port_return_annual, port_vol, port_vol_annual, sharpe_ratio, neg_sharpe



# NOTE: Not needed in this application:
# def port_perf_sharpe(weights, mean_ret, covariance, risk_free_rate):
#     # Wrapper
#     results = port_perf(weights, mean_ret, covariance, risk_free_rate)
#     result = results[5]
#     return result

# def port_perf_var(weights, mean_ret, covariance, risk_free_rate):
#     # Wrapper
#     results = port_perf(weights, mean_ret, covariance, risk_free_rate)
#     result = results[3]
#     return result

# Monte Carlo sampler: https://pythonforfinance.net/2019/07/02/investment-portfolio-optimisationwith-python-revisited/
def mc_sampler(n, mean_return, covariance, risk_free_rate, tickers):
    results = np.zeros((len(mean_return)+5,n))
    for i in range(n):
        weights = np.random.dirichlet(np.ones(len(tickers)), size = 1)
        weights = weights[0]
        port_return,port_return_annual,port_vol,port_vol_annual,sharpe_ratio, waste = port_perf(weights, mean_return, covariance, risk_free_rate)
        results[0,i] = port_return
        results[1,i] = port_return_annual
        results[2,i] = port_vol
        results[3,i] = port_vol_annual
        results[4,i] = sharpe_ratio
        for j in range(len(weights)):
            results[j+5,i] = weights[j]
    results_data = pd.DataFrame(results.T, columns = ['ret', 'annual_ret', 'vol', 'annual_vol', 'sharpe_ratio'] + [ticker for ticker in tickers])
    return results_data

# NOTE: Not needed in this application:
# NUmerical optimization to retrieve optimal portfolio sharpe ratio and variance wise
# 1) sharperatio maximization ---------------------------------------------------------------------

# def max_sharpe_ratio(mean_return, covariance, risk_free_rate):
#     num_assets = len(mean_return)
#     args = (mean_return, covariance, risk_free_rate)
#     cons = ({'type': 'eq', 'fun': lambda x: np.sum(x) - 1})
#     bound = (0.0,1.0)
#     bounds = tuple(bound for asset in range(num_assets))
#     result = minimize(port_perf_sharpe, num_assets*[1./num_assets,], args=args,
#                         method='SLSQP', bounds=bounds, constraints=cons)
#     return result

# # must go inside of function!
# sharpe_optimal = max_sharpe_ratio(mean_log_returns, log_cov, rf)
# sharpe_optimal_weights = sharpe_optimal.x
# sharpe_optimal_weights = sharpe_optimal_weights.round(6)
# sharpe_optimal_ratio = sharpe_optimal.fun
# sharpe_optimal_ratio = round(sharpe_optimal_ratio, 6)



# # 2) variance/std minimization ------------------------------------------------------------------
# def min_variance(mean_return, covariance, risk_free_rate):
#     num_assets = len(mean_return)
#     args = (mean_return, covariance, risk_free_rate)
#     cons = ({'type': 'eq', 'fun': lambda x: np.sum(x) - 1})
#     bound = (0.0,1.0)
#     bounds = tuple(bound for asset in range(num_assets))
#     result = minimize(port_perf_var, num_assets*[1./num_assets,], args=args,
#                         method='SLSQP', bounds=bounds, constraints=cons)
#     return result

# 
# var_optimal = min_variance(mean_log_returns, log_cov, rf)
# var_optimal_weights = var_optimal.x
# var_optimal_weights = var_optimal_weights.round(6)
# var_optimal_std = var_optimal.fun
# var_optimal_std = round(var_optimal_std, 6)

###################################################################################################
# MC sampling for each period and subgroup --------------------------------------------------------
rf = 0.0
num_portfolios = 100000

start = datetime.now()
rd.seed(42)
first_period_best_sp500_results = mc_sampler(num_portfolios, first_period_best_sp500_input[1], first_period_best_sp500_input[2], 0.002, first_period_best_sp500_tickers)
first_period_worst_sp500_results = mc_sampler(num_portfolios, first_period_worst_sp500_input[1], first_period_worst_sp500_input[2], 0.002, first_period_worst_sp500_tickers)
first_period_med_sp500_results = mc_sampler(num_portfolios, first_period_med_sp500_input[1], first_period_med_sp500_input[2], 0.002, first_period_med_sp500_tickers)


second_period_best_sp500_results = mc_sampler(num_portfolios, second_period_best_sp500_input[1], second_period_best_sp500_input[2], 0.005, second_period_best_sp500_tickers)
second_period_worst_sp500_results = mc_sampler(num_portfolios, second_period_worst_sp500_input[1], second_period_worst_sp500_input[2], 0.005, second_period_worst_sp500_tickers)
second_period_med_sp500_results = mc_sampler(num_portfolios, second_period_med_sp500_input[1], second_period_med_sp500_input[2], 0.005, second_period_med_sp500_tickers)


third_period_best_sp500_results = mc_sampler(num_portfolios, third_period_best_sp500_input[1], third_period_best_sp500_input[2], 0.02, third_period_best_sp500_tickers)
third_period_worst_sp500_results = mc_sampler(num_portfolios, third_period_worst_sp500_input[1], third_period_worst_sp500_input[2], 0.02, third_period_worst_sp500_tickers)
third_period_med_sp500_results = mc_sampler(num_portfolios, third_period_med_sp500_input[1], third_period_med_sp500_input[2], 0.02, third_period_med_sp500_tickers)


first_period_best_stoxx600_results = mc_sampler(num_portfolios, first_period_best_stoxx600_input[1], first_period_best_stoxx600_input[2], 0.013, first_period_best_stoxx600_tickers)
first_period_worst_stoxx600_results = mc_sampler(num_portfolios, first_period_worst_stoxx600_input[1], first_period_worst_stoxx600_input[2], 0.013, first_period_worst_stoxx600_tickers)
first_period_med_stoxx600_results = mc_sampler(num_portfolios, first_period_med_stoxx600_input[1], first_period_med_stoxx600_input[2], 0.013, first_period_med_stoxx600_tickers)


second_period_best_stoxx600_results = mc_sampler(num_portfolios, second_period_best_stoxx600_input[1], second_period_best_stoxx600_input[2], 0.002, second_period_best_stoxx600_tickers)
second_period_worst_stoxx600_results = mc_sampler(num_portfolios, second_period_worst_stoxx600_input[1], second_period_worst_stoxx600_input[2], 0.002, second_period_worst_stoxx600_tickers)
second_period_med_stoxx600_results = mc_sampler(num_portfolios, second_period_med_stoxx600_input[1], second_period_med_stoxx600_input[2], 0.002, second_period_med_stoxx600_tickers)


third_period_best_stoxx600_results = mc_sampler(num_portfolios, third_period_best_stoxx600_input[1], third_period_best_stoxx600_input[2], 0.0, third_period_best_stoxx600_tickers)
third_period_worst_stoxx600_results = mc_sampler(num_portfolios, third_period_worst_stoxx600_input[1], third_period_worst_stoxx600_input[2], 0.0, third_period_worst_stoxx600_tickers)
third_period_med_stoxx600_results = mc_sampler(num_portfolios, third_period_med_stoxx600_input[1], third_period_med_stoxx600_input[2], 0.0, third_period_med_stoxx600_tickers)


mc_time = datetime.now() - start
print('mc simulation time: ', mc_time)

###################################################################################################
# Plotting function -------------------------------------------------------------------------------
def make_markowitz(mc_results, file_name, tickers, esg_period_mean, num_portfolios, risk_free_rate):
    # For debugging:
    # mc_results = first_period_best_sp500_results
    # file_name = 'test'
    # tickers = first_period_best_sp500_tickers
    # esg_period_mean = first_period_best_sp500




    max_sharpe = mc_results.iloc[mc_results['sharpe_ratio'].idxmax()]
    min_vola = mc_results.iloc[mc_results['annual_vol'].idxmin()]
    esg_relevant = esg_period_mean.to_frame().reset_index()
    


    sampler_weights = mc_results[tickers].T
    sampler_weights['Company Code'] = sampler_weights.index
    sampler_weights = esg_relevant.merge(sampler_weights, left_on = 'Instrument', right_on = 'Company Code').T
    esg_relevant = esg_relevant.set_index('Instrument')
    esg_relevant = esg_relevant.loc[tickers]
    #esg_relevant = esg_relevant.reset_index()
    #sampler_weights.columns = esg_relevant['Instrument']
    sampler_weights.columns = esg_relevant.index
    sampler_weights = sampler_weights.T
    sampler_scores = []
    sampler_weights = sampler_weights.drop('Company Code', 1)
    
    sampler_weights = sampler_weights.astype({'ESG Score' : 'float64'})
    sampler_scores = sampler_weights[sampler_weights.columns[-num_portfolios:]].multiply(sampler_weights['ESG Score'], axis = 'index')

    sampler_scores = np.sum(sampler_scores, axis = 0)


    esg_results = sampler_weights.append(sampler_scores, ignore_index = True) #!?!?! investigate!
    mc_results['ESG_port_score'] = sampler_scores # for plotting
    # NOTE: try to filter for highest sharpe ratio portfolios within each quartile
    mc_results['q'] = pd.qcut(mc_results['ESG_port_score'], 4, labels = ['Q1','Q2', 'Q3','Q4'])
    mc_results['q'] = mc_results['q'].astype('str')

    sharpe_chain_1 = mc_results[(mc_results['q'] == 'Q1')]
    max_sharpe_1 = mc_results.iloc[sharpe_chain_1['sharpe_ratio'].idxmax()]
    sharpe_chain_1 = mc_results.iloc[sharpe_chain_1['ESG_port_score'].nlargest(n = 20000).index]
    esg_1 = round(sharpe_chain_1['ESG_port_score'].mean(),2)

    sharpe_chain_2 = mc_results[(mc_results['q'] == 'Q2')]
    max_sharpe_2 = mc_results.iloc[sharpe_chain_2['sharpe_ratio'].idxmax()]
    sharpe_chain_2 = mc_results.iloc[sharpe_chain_2['ESG_port_score'].nlargest(n = 10000).index]
    esg_2 = round(sharpe_chain_2['ESG_port_score'].mean(),2)
    sharpe_chain_3 = mc_results[(mc_results['q'] == 'Q3')]
    max_sharpe_3 =mc_results.iloc[sharpe_chain_3['sharpe_ratio'].idxmax()]
    sharpe_chain_3 = mc_results.iloc[sharpe_chain_3['ESG_port_score'].nlargest(n = 10000).index]
    esg_3 = round(sharpe_chain_3['ESG_port_score'].mean(),2)

    sharpe_chain_4 = mc_results[(mc_results['q'] == 'Q4')]
    max_sharpe_4 = mc_results.iloc[sharpe_chain_4['sharpe_ratio'].idxmax()]
    sharpe_chain_4 = mc_results.iloc[sharpe_chain_4['ESG_port_score'].nlargest(n = 10000).index]
    esg_4 = round(sharpe_chain_4['ESG_port_score'].mean(),2)


    # NOTE: Only toggle if desired
    # sharpe_chain_5 = mc_results[(mc_results['q'] == 'Q1')]
    # sharpe_chain_5 = mc_results.iloc[sharpe_chain_5['sharpe_ratio'].nlargest(n = 100).index]
    # esg_5 = round(sharpe_chain_5['sharpe_ratio'].mean(),2)
    # sharpe_chain_6 = mc_results[(mc_results['q'] == 'Q2')]
    # sharpe_chain_6 = mc_results.iloc[sharpe_chain_6['sharpe_ratio'].nlargest(n = 100).index]
    # esg_6 = round(sharpe_chain_6['sharpe_ratio'].mean(),2)
    # sharpe_chain_7 = mc_results[(mc_results['q'] == 'Q3')]
    # sharpe_chain_7 = mc_results.iloc[sharpe_chain_7['sharpe_ratio'].nlargest(n = 100).index]
    # esg_7 = round(sharpe_chain_7['sharpe_ratio'].mean(),2)
    # sharpe_chain_8 = mc_results[(mc_results['q'] == 'Q4')]
    # sharpe_chain_8 = mc_results.iloc[sharpe_chain_8['sharpe_ratio'].nlargest(n = 100).index]
    # esg_8 = round(sharpe_chain_8['sharpe_ratio'].mean(),2)


    max_esg = mc_results.iloc[mc_results['ESG_port_score'].idxmax()]

    fig, ax = plt.subplots(figsize = (15,10))
    sc = ax.scatter(mc_results.annual_vol, mc_results.annual_ret, c = mc_results.ESG_port_score, cmap = 'RdYlBu', alpha = 0.6)
    ax.set_title('Mean-Variance Trade-off Visualization for n = {}'.format(num_portfolios) + ' simulated portfolios',fontsize=20) #{}'.format(num_portfolios) + ' 
    ax.set_xlabel('Annualized Standard Deviation/Volatility', fontsize=20)
    ax.set_ylabel('Annualized Mean Returns',fontsize=20)

    cbar = fig.colorbar(sc)
    cbar.set_label('ESG scores', rotation = 270)

    # NOTE: Only toggle if desired
    # For ESG sorting nad colormapping
    # ax.scatter(sharpe_chain_1.annual_vol, sharpe_chain_1.annual_ret, s = 20, alpha = 0.6, color = 'k', label = 'Highest ESGs in Q1 with AVG(ESG) = {}'.format(esg_1))
    # ax.scatter(sharpe_chain_2.annual_vol, sharpe_chain_2.annual_ret, s = 20, alpha = 0.6, color = 'grey', label = 'Highest ESGs in Q2 with AVG(ESG) = {}'.format(esg_2))
    # ax.scatter(sharpe_chain_3.annual_vol, sharpe_chain_3.annual_ret, s = 20, alpha = 0.6, color = 'yellow', label = 'Highest ESGs in Q3 with AVG(ESG) = {}'.format(esg_3))
    # ax.scatter(sharpe_chain_4.annual_vol, sharpe_chain_4.annual_ret, s = 20, alpha = 0.6, color = 'lime', label = 'Highest ESGs in Q4 with AVG(ESG) = {}'.format(esg_4))
    # # For ESG sorting and SR mapping
    # ax.scatter(sharpe_chain_5.annual_vol, sharpe_chain_5.annual_ret, s = 20, color = 'red',alpha = 0.6, label = 'Highest SRs in Q1 with AVG(SR) = {}'.format(esg_5))
    # ax.scatter(sharpe_chain_6.annual_vol, sharpe_chain_6.annual_ret, s = 20, color = 'red',alpha = 0.6, label = 'Highest SRs in Q2 with AVG(SR) = {}'.format(esg_6))
    # ax.scatter(sharpe_chain_7.annual_vol, sharpe_chain_7.annual_ret, s = 20, color = 'red',alpha = 0.6, label = 'Highest SRs in Q3 with AVG(SR) = {}'.format(esg_7))
    # ax.scatter(sharpe_chain_8.annual_vol, sharpe_chain_8.annual_ret, s = 20, color = 'red',alpha = 0.6, label = 'Highest SRs in Q4 with AVG(SR) = {}'.format(esg_8))


    ax.scatter(max_sharpe[3], max_sharpe[1], marker = '$S$', s = 130,  color = 'magenta', label = 'max sharpe-ratio')
    ax.scatter(min_vola[3], min_vola[1], marker = '$V$', s = 130, color = 'magenta', label = 'min vola')
    ax.scatter(max_esg[3], max_esg[1], marker = '$E$', s = 130,  color = 'magenta', label = 'max ESG portfolio')




    
    # NOTE: Only toggle if desired
    # ax.plot([0,max_sharpe_1[3]], [risk_free_rate,max_sharpe_1[1]], color = 'black')
    # ax.plot([0,max_sharpe_2[3]], [risk_free_rate,max_sharpe_2[1]], color = 'black')
    # ax.plot([0,max_sharpe_3[3]], [risk_free_rate,max_sharpe_3[1]], color = 'black')
    # ax.plot([0,max_sharpe_4[3]], [risk_free_rate,max_sharpe_4[1]], color = 'black')

    # # NOTE: Only toggle if desired
    # ax.scatter(max_sharpe_1[3], max_sharpe_1[1], marker = '$S1$', s = 130,  color = 'lime', label = 'max sharpe-ratio for Q1 = {}'.format(max_sharpe_1[4]))
    # ax.scatter(max_sharpe_2[3], max_sharpe_2[1], marker = '$S2$', s = 130,  color = 'lime', label = 'max sharpe-ratio for Q2 = {}'.format(max_sharpe_2[4]))
    # ax.scatter(max_sharpe_3[3], max_sharpe_3[1], marker = '$S3$', s = 130,  color = 'lime', label = 'max sharpe-ratio for Q3 = {}'.format(max_sharpe_3[4]))
    # ax.scatter(max_sharpe_4[3], max_sharpe_4[1], marker = '$S4$', s = 130,  color = 'lime', label = 'max sharpe-ratio for Q4 = {}'.format(max_sharpe_4[4]))


    ax.legend()

    fig.savefig('markov_esg_test_' + file_name + '.jpg', bbox_inches='tight')
    plt.close()
    #return(mc_results)


###################################################################################################
# Plot and save each markowitz contour ------------------------------------------------------------
tic2 = datetime.now()
make_markowitz(first_period_best_sp500_results, 'first_sp500_best', first_period_best_sp500_tickers, first_period_best_sp500, num_portfolios, 0.002)
make_markowitz(first_period_worst_sp500_results, 'first_sp500_worst', first_period_worst_sp500_tickers, first_period_worst_sp500, num_portfolios, 0.002)
make_markowitz(first_period_med_sp500_results, 'first_sp500_med', first_period_med_sp500_tickers, first_period_med_sp500.droplevel('quantile')['ESG Score'], num_portfolios, 0.002)


make_markowitz(second_period_best_sp500_results, 'second_sp500_best', second_period_best_sp500_tickers, second_period_best_sp500, num_portfolios,0.005)
make_markowitz(second_period_worst_sp500_results, 'second_sp500_worst', second_period_worst_sp500_tickers, second_period_worst_sp500, num_portfolios,0.005)
make_markowitz(second_period_med_sp500_results, 'second_sp500_med', second_period_med_sp500_tickers, second_period_med_sp500.droplevel('quantile')['ESG Score'], num_portfolios,0.005)


make_markowitz(third_period_best_sp500_results, 'third_sp500_best', third_period_best_sp500_tickers, third_period_best_sp500, num_portfolios,0.02)
make_markowitz(third_period_worst_sp500_results, 'third_sp500_worst', third_period_worst_sp500_tickers, third_period_worst_sp500, num_portfolios,0.02)
make_markowitz(third_period_med_sp500_results, 'third_sp500_med', third_period_med_sp500_tickers, third_period_med_sp500.droplevel('quantile')['ESG Score'], num_portfolios,0.02)


make_markowitz(first_period_best_stoxx600_results, 'first_stoxx600_best', first_period_best_stoxx600_tickers, first_period_best_stoxx600, num_portfolios,0.013)
make_markowitz(first_period_worst_stoxx600_results, 'first_stoxx600_worst', first_period_worst_stoxx600_tickers, first_period_worst_stoxx600, num_portfolios,0.013)
make_markowitz(first_period_med_stoxx600_results, 'first_stoxx600_med', first_period_med_stoxx600_tickers, first_period_med_stoxx600.droplevel('quantile')['ESG Score'], num_portfolios,0.013)


make_markowitz(second_period_best_stoxx600_results, 'second_stoxx600_best', second_period_best_stoxx600_tickers, second_period_best_stoxx600, num_portfolios,0.002)
make_markowitz(second_period_worst_stoxx600_results, 'second_stoxx600_worst', second_period_worst_stoxx600_tickers, second_period_worst_stoxx600, num_portfolios,0.002)
make_markowitz(second_period_med_stoxx600_results, 'second_stoxx600_med', second_period_med_stoxx600_tickers, second_period_med_stoxx600.droplevel('quantile')['ESG Score'], num_portfolios,0.002)



make_markowitz(third_period_best_stoxx600_results, 'third_stoxx600_best', third_period_best_stoxx600_tickers, third_period_best_stoxx600, num_portfolios,0)
make_markowitz(third_period_worst_stoxx600_results, 'third_stoxx600_worst', third_period_worst_stoxx600_tickers, third_period_worst_stoxx600, num_portfolios,0)
make_markowitz(third_period_med_stoxx600_results, 'third_stoxx600_med', third_period_med_stoxx600_tickers, third_period_med_stoxx600.droplevel('quantile')['ESG Score'], num_portfolios,0)

toc = datetime.now()
all_time = toc-tic2
print('script runtime: ', all_time)
#%%
#####################################################################################################
######################################## Supplementary Code #########################################
#####################################################################################################

#####################################################################################################
# Correlations and summaries ------------------------------------------------------------------------
# other ticker format necessary
sp500_new, e500 = ek.get_data('0#.SPX', fields=['TR.TRESGScore(Period=FY0,Frq=FY,SDate=0,EDate=-13)', 'TR.TRESGScore(Period=FY0,Frq=FY,SDate=0,EDate=-13).periodenddate'])
sp500_tickers = sp500_new['Instrument'].unique()

stoxx600_tickers = stoxx600['Instrument'].unique()

###################################################################################################
# SP500 -------------------------------------------------------------------------------------------

# #closing_sp500 = []

# t = datetime.now()
# for ticker1 in sp500_tickers[213:]:
#     hlp, e = ek.get_data(instruments= ticker1, fields= ['TR.CLOSEPRICE(SDate=' +first_period_start+',EDate='+third_period_end+',Frq=D,CURN=USD).Date', 'TR.CLOSEPRICE(SDate=' +first_period_start+',EDate='+third_period_end+',Frq=D,CURN=USD)'])# get_closing_eikon(ticker2, first_period_start, third_period_end)
#     closing_sp500.append(hlp)
#     print(ticker1)
# print(datetime.now()-t)
#closing_sp500_df = pd.concat(closing_sp500, ignore_index=True)
# Alternatively load 'stoxx600_all_closing.csv' as closing_stoxx600_df
closing_sp500_df = pd.read_csv('sp500_all_closing.csv', index_col='Date')

def ret_cov_bad_data(closing_prices):
    # other NaN treatment required
    log_return = np.log(closing_prices/closing_prices.shift(1)).dropna(how = 'all', axis = 1).dropna(how='all')
    mean_log_returns = log_return.mean()
    #mean_reg_returns = np.exp(mean_log_returns)-1
    log_cov = log_return.cov()
    return(log_return, mean_log_returns, log_cov)

# NOTE: not needed when loaded via csv ------------------------------------------------------------
# closing_sp500_df['Close Price'] = closing_sp500_df['Close Price'].astype(str)

# closing_sp500_df['Close Price'] = closing_sp500_df['Close Price'].astype(float)

# closing_sp500_df = pd.pivot_table(closing_sp500_df, values='Close Price', index='Date', columns='Instrument')
# -------------------------------------------------------------------------------------------------

closing_sp500_df['Year'] = closing_sp500_df.index 

temp = closing_sp500_df['Year'].str.split('-', n = 1, expand = True)
closing_sp500_df['Year'] = temp[0]

first_sp500_closing = closing_sp500_df[(closing_sp500_df['Year'] == '2010') | (closing_sp500_df['Year'] == '2011') | (closing_sp500_df['Year'] == '2012') | (closing_sp500_df['Year'] == '2013')]
first_sp500_closing.columns = first_sp500_closing.columns.str.split('.', n = 1, expand = True).get_level_values(level=0)
second_sp500_closing = closing_sp500_df[(closing_sp500_df['Year'] == '2014') | (closing_sp500_df['Year'] == '2015') | (closing_sp500_df['Year'] == '2016') | (closing_sp500_df['Year'] == '2017')]
second_sp500_closing.columns = second_sp500_closing.columns.str.split('.', n = 1, expand = True).get_level_values(level=0)
third_sp500_closing = closing_sp500_df[(closing_sp500_df['Year'] == '2018') | (closing_sp500_df['Year'] == '2019')]
third_sp500_closing.columns = third_sp500_closing.columns.str.split('.', n = 1, expand = True).get_level_values(level=0)

first_sp500_ret= ret_cov_bad_data(first_sp500_closing.drop('Year', axis=1))
second_sp500_ret = ret_cov_bad_data(second_sp500_closing.drop('Year', axis = 1))
third_sp500_ret = ret_cov_bad_data(third_sp500_closing.drop('Year', axis = 1))

# first_sp500_ret= ret_cov(first_sp500_closing.drop('Year', axis=1))
# second_sp500_ret = ret_cov(second_sp500_closing.drop('Year', axis = 1))
# third_sp500_ret = ret_cov(third_sp500_closing.drop('Year', axis = 1))


first_sp500_joint = pd.concat([first_sp500_ret[1],first_period_mean_sp500], axis = 1, join = 'inner')
second_sp500_joint = pd.concat([second_sp500_ret[1],second_period_mean_sp500], axis = 1, join = 'inner')
third_sp500_joint = pd.concat([third_sp500_ret[1],third_period_mean_sp500], axis = 1, join = 'inner')

r1_sp = np.corrcoef(first_sp500_joint[0], first_sp500_joint['ESG Score'])
r2_sp = np.corrcoef(second_sp500_joint[0], second_sp500_joint['ESG Score'])
r3_sp = np.corrcoef(third_sp500_joint[0], third_sp500_joint['ESG Score'])



# Take a look...
# plt.subplots(figsize = (15,10))
# plt.scatter(first_sp500_joint[0], first_sp500_joint['ESG Score'])
# plt.scatter(second_sp500_joint[0], second_sp500_joint['ESG Score'])
# plt.scatter(third_sp500_joint[0], third_sp500_joint['ESG Score'])

###################################################################################################
# STOXX 600 ---------------------------------------------------------------------------------------


# #closing_stoxx600 = []
# t = datetime.now()
# for ticker2 in stoxx600_tickers[399:]: # usually have to split, because you know... EIKON
#     hlp, e = ek.get_data(instruments= ticker2, fields= ['TR.CLOSEPRICE(SDate=' +first_period_start+',EDate='+third_period_end+',Frq=D,CURN=USD).Date', 'TR.CLOSEPRICE(SDate=' +first_period_start+',EDate='+third_period_end+',Frq=D,CURN=USD)'])# get_closing_eikon(ticker2, first_period_start, third_period_end)
#     closing_stoxx600.append(hlp)
#     print(ticker2)
# print(datetime.now()-t)
# Alternatively load 'stoxx600_all_closing.csv' as closing_stoxx600_df
closing_stoxx600_df = pd.read_csv('stoxx600_all_closing.csv', index_col='Date')

# NOTE: Not necessary when importing from csv -----------------------------------------------------
# closing_stoxx600_df = pd.concat(closing_stoxx600, ignore_index= True)
# closing_stoxx600_df['Close Price'] = closing_stoxx600_df['Close Price'].astype(str)

# closing_stoxx600_df['Close Price'] = closing_stoxx600_df['Close Price'].astype(float)

# closing_stoxx600_df = pd.pivot_table(closing_stoxx600_df, values='Close Price', index='Date', columns='Instrument')
# -------------------------------------------------------------------------------------------------
closing_stoxx600_df['Year'] = closing_stoxx600_df.index 

temp = closing_stoxx600_df['Year'].str.split('-', n = 1, expand = True)
closing_stoxx600_df['Year'] = temp[0]

first_stoxx600_closing = closing_stoxx600_df[(closing_stoxx600_df['Year'] == '2010') | (closing_stoxx600_df['Year'] == '2011') | (closing_stoxx600_df['Year'] == '2012') | (closing_stoxx600_df['Year'] == '2013')]
second_stoxx600_closing = closing_stoxx600_df[(closing_stoxx600_df['Year'] == '2014') | (closing_stoxx600_df['Year'] == '2015') | (closing_stoxx600_df['Year'] == '2016') | (closing_stoxx600_df['Year'] == '2017')]
third_stoxx600_closing = closing_stoxx600_df[(closing_stoxx600_df['Year'] == '2018') | (closing_stoxx600_df['Year'] == '2019')]


first_stoxx600_ret= ret_cov_bad_data(first_stoxx600_closing.drop('Year', axis=1))
second_stoxx600_ret = ret_cov_bad_data(second_stoxx600_closing.drop('Year', axis = 1))
third_stoxx600_ret = ret_cov_bad_data(third_stoxx600_closing.drop('Year', axis = 1))

# first_stoxx600_ret= ret_cov(first_stoxx600_closing.drop('Year', axis=1))
# second_stoxx600_ret = ret_cov(second_stoxx600_closing.drop('Year', axis=1))
# third_stoxx600_ret = ret_cov(third_stoxx600_closing.drop('Year', axis=1))


first_stoxx600_joint = pd.concat([first_stoxx600_ret[1],first_period_mean_stoxx600], axis = 1, join = 'inner')
second_stoxx600_joint = pd.concat([second_stoxx600_ret[1],second_period_mean_stoxx600], axis = 1, join = 'inner')
third_stoxx600_joint = pd.concat([third_stoxx600_ret[1],third_period_mean_stoxx600], axis = 1, join = 'inner')

r1 = np.corrcoef(first_stoxx600_joint[0], first_stoxx600_joint['ESG Score'])
r2 = np.corrcoef(second_stoxx600_joint[0], second_stoxx600_joint['ESG Score'])
r3 = np.corrcoef(third_stoxx600_joint[0], third_stoxx600_joint['ESG Score'])



# Take a look...
# plt.subplots(figsize = (15,10))
# plt.scatter(first_stoxx600_joint[0], first_stoxx600_joint['ESG Score'])
# plt.scatter(second_stoxx600_joint[0], second_stoxx600_joint['ESG Score'])
# plt.scatter(third_stoxx600_joint[0], third_stoxx600_joint['ESG Score'])
# plt.show()

###################################################################################################
# Create descriptive tables -----------------------------------------------------------------------
stoxx_descr = stoxx600.groupby('End Date Year').describe().round(2)


sp500_descr = sp500.groupby('End Date Year').describe().round(2)



correls = {'SP500' : {'2010-2013': r1_sp[1,0], '2014-2017' : r2_sp[1,0], '2018-2019' : r3_sp[1,0]},
            'STOXX600' : {'2010-2013': r1[1,0], '2014-2017' : r2[1,0], '2018-2019' : r3[1,0]}}

correls_df = pd.DataFrame(correls)


###################################################################################################
# Get annual vola and perform correlation analysis as above ---------------------------------------
first_stoxx600_joint_vola = pd.concat([pd.DataFrame(first_stoxx600_ret[2].to_numpy().diagonal(), index= first_stoxx600_ret[1].index, columns=['variance']),first_period_mean_stoxx600], axis = 1, join = 'inner')
first_stoxx600_joint_vola['Annual vola'] = np.sqrt(first_stoxx600_joint_vola['variance']) * np.sqrt(252)

second_stoxx600_joint_vola = pd.concat([pd.DataFrame(second_stoxx600_ret[2].to_numpy().diagonal(), index= second_stoxx600_ret[1].index, columns=['variance']),second_period_mean_stoxx600], axis = 1, join = 'inner')
second_stoxx600_joint_vola['Annual vola'] = np.sqrt(second_stoxx600_joint_vola['variance']) * np.sqrt(252)

third_stoxx600_joint_vola = pd.concat([pd.DataFrame(third_stoxx600_ret[2].to_numpy().diagonal(), index= third_stoxx600_ret[1].index, columns=['variance']),third_period_mean_stoxx600], axis = 1, join = 'inner')
third_stoxx600_joint_vola['Annual vola'] = np.sqrt(third_stoxx600_joint_vola['variance']) * np.sqrt(252)



r4 = np.corrcoef(first_stoxx600_joint_vola['Annual vola'], first_stoxx600_joint_vola['ESG Score'])
r5 = np.corrcoef(second_stoxx600_joint_vola['Annual vola'], second_stoxx600_joint_vola['ESG Score'])
r6 = np.corrcoef(third_stoxx600_joint_vola['Annual vola'], third_stoxx600_joint_vola['ESG Score'])

###################################################################################################
first_sp500_joint_vola = pd.concat([pd.DataFrame(first_sp500_ret[2].to_numpy().diagonal(), index= first_sp500_ret[1].index, columns=['variance']),first_period_mean_sp500], axis = 1, join = 'inner')
first_sp500_joint_vola['Annual vola'] = np.sqrt(first_sp500_joint_vola['variance']) * np.sqrt(252)

second_sp500_joint_vola = pd.concat([pd.DataFrame(second_sp500_ret[2].to_numpy().diagonal(), index= second_sp500_ret[1].index, columns=['variance']),second_period_mean_sp500], axis = 1, join = 'inner')
second_sp500_joint_vola['Annual vola'] = np.sqrt(second_sp500_joint_vola['variance']) * np.sqrt(252)

third_sp500_joint_vola = pd.concat([pd.DataFrame(third_sp500_ret[2].to_numpy().diagonal(), index= third_sp500_ret[1].index, columns=['variance']),third_period_mean_sp500], axis = 1, join = 'inner')
third_sp500_joint_vola['Annual vola'] = np.sqrt(third_sp500_joint_vola['variance']) * np.sqrt(252)



r4_sp = np.corrcoef(first_sp500_joint_vola['Annual vola'], first_sp500_joint_vola['ESG Score'])
r5_sp = np.corrcoef(second_sp500_joint_vola['Annual vola'], second_sp500_joint_vola['ESG Score'])
r6_sp = np.corrcoef(third_sp500_joint_vola['Annual vola'], third_sp500_joint_vola['ESG Score'])


correls_vola = {'SP500' : {'2010-2013': r4_sp[1,0], '2014-2017' : r5_sp[1,0], '2018-2019' : r6_sp[1,0]},
            'STOXX600' : {'2010-2013': r4[1,0], '2014-2017' : r5[1,0], '2018-2019' : r6[1,0]}}

correls_vola_df = pd.DataFrame(correls_vola)

###################################################################################################
# EXPORT aid:
# print(correls_df.to_latex(bold_rows = True, label = "Pearson's Correlation-Coefficients"))
###################################################################################################


#%%
###################################################################################################
# Some scribbles....
# # Sharpe vs ESG Score print for each stock  ----STUPID!
# third_sp500_joint_vola_ret = pd.concat([third_sp500_joint_vola, third_sp500_ret[1]], axis = 1, join= 'inner')

# third_sp500_joint_vola_ret['sharpe'] =  (third_sp500_joint_vola_ret[0]*252-0.00)/third_sp500_joint_vola_ret['Annual vola']

# plt.subplots(figsize = (15,10))
# plt.scatter(third_sp500_joint_vola_ret['ESG Score'], third_sp500_joint_vola_ret['sharpe'])
# plt.show()
###################################################################################################
#%%
num_portfolios = 10000
rd.seed(42)
# See scribbles: third period only! ---------------------------------------------------------------------------------
third_period_mean_sp500_df = pd.DataFrame([third_period_mean_sp500, pd.qcut(third_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
third_period_mean_sp500_df.columns = ['ESG Score', 'q']
third_period_mean_sp500_df['q'] = third_period_mean_sp500_df['q'].astype('str')
df_help = third_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(20))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(third_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(third_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(third_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(third_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(third_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)

#%%
def make_markowitz_suppressed(mc_results, file_name, tickers, esg_period_mean, num_portfolios):
    # mc_results = first_period_best_sp500_results
    # file_name = 'test'
    # tickers = first_period_best_sp500_tickers
    # esg_period_mean = first_period_best_sp500

    max_sharpe = mc_results.iloc[mc_results['sharpe_ratio'].idxmax()]
    min_vola = mc_results.iloc[mc_results['annual_vol'].idxmin()]
    esg_relevant = esg_period_mean.to_frame().reset_index()
    #sharpe_chain = mc_results.iloc[mc_results['sharpe_ratio'].nlargest(n = 100).index]


    sampler_weights = mc_results[tickers].T
    sampler_weights['Company Code'] = sampler_weights.index
    sampler_weights = esg_relevant.merge(sampler_weights, left_on = 'Instrument', right_on = 'Company Code').T
    sampler_weights.columns = esg_relevant['Instrument']
    sampler_weights = sampler_weights.T
    sampler_scores = []
    sampler_weights = sampler_weights.drop('Company Code', 1)
    #sampler_scores = [(np.sum(sampler_weights['ESG_overall'] * wgt)) for wgt in sampler_weights[sampler_weights.columns[-num_portfolios:]]]
    sampler_weights = sampler_weights.astype({'ESG Score' : 'float64'})
    sampler_scores = sampler_weights[sampler_weights.columns[-num_portfolios:]].multiply(sampler_weights['ESG Score'], axis = 'index')

    sampler_scores = np.sum(sampler_scores, axis = 0)


    esg_results = sampler_weights.append(sampler_scores, ignore_index = True) #!?!?! investigate!
    mc_results['ESG_port_score'] = sampler_scores # for plotting
    # NOTE: try to filter for highest sharpe ratio portfolios within each quartile
    mc_results['q'] = pd.qcut(mc_results['ESG_port_score'], 4, labels = ['Q1','Q2', 'Q3','Q4'])
    mc_results['q'] = mc_results['q'].astype('str')
    sharpe_chain_1 = mc_results[(mc_results['q'] == 'Q1')]
    sharpe_chain_1 = mc_results.iloc[sharpe_chain_1['ESG_port_score'].nlargest(n = 10000).index]
    esg_1 = round(sharpe_chain_1['ESG_port_score'].mean(),2)
    sharpe_chain_2 = mc_results[(mc_results['q'] == 'Q2')]
    sharpe_chain_2 = mc_results.iloc[sharpe_chain_2['ESG_port_score'].nlargest(n = 10000).index]
    esg_2 = round(sharpe_chain_2['ESG_port_score'].mean(),2)
    sharpe_chain_3 = mc_results[(mc_results['q'] == 'Q3')]
    sharpe_chain_3 = mc_results.iloc[sharpe_chain_3['ESG_port_score'].nlargest(n = 10000).index]
    esg_3 = round(sharpe_chain_3['ESG_port_score'].mean(),2)
    sharpe_chain_4 = mc_results[(mc_results['q'] == 'Q4')]
    sharpe_chain_4 = mc_results.iloc[sharpe_chain_4['ESG_port_score'].nlargest(n = 10000).index]
    esg_4 = round(sharpe_chain_4['ESG_port_score'].mean(),2)


    max_esg = mc_results.iloc[mc_results['ESG_port_score'].idxmax()]

    fig, ax = plt.subplots(figsize = (15,10))
    sc = ax.scatter(mc_results.annual_vol, mc_results.annual_ret, c = mc_results.ESG_port_score, cmap = 'RdYlBu', alpha = 0.6)
    ax.set_title('Mean-Variance Trade-off Visualization for n = {}'.format(num_portfolios) + ' simulated portfolios',fontsize=20) #{}'.format(num_portfolios) + ' 
    ax.set_xlabel('Annualized Standard Deviation/Volatility', fontsize=20)
    ax.set_ylabel('Annualized Mean Returns',fontsize=20)
    # cb = plt.colorbar()
    # cb.ax.set_ylabel('ESG scores', rotation = 270)
    cbar = fig.colorbar(sc)
    cbar.set_label('ESG scores', rotation = 270)

    ax.scatter(sharpe_chain_1.annual_vol, sharpe_chain_1.annual_ret, s = 20, color = 'k', label = 'Highest SR in Q1 with AVG(ESG) ={}'.format(esg_1))
    ax.scatter(sharpe_chain_2.annual_vol, sharpe_chain_2.annual_ret, s = 20, color = 'grey', label = 'Highest SR in Q2 with AVG(ESG) ={}'.format(esg_2))
    ax.scatter(sharpe_chain_3.annual_vol, sharpe_chain_3.annual_ret, s = 20, color = 'yellow', label = 'Highest SR in Q3 with AVG(ESG) ={}'.format(esg_3))
    ax.scatter(sharpe_chain_4.annual_vol, sharpe_chain_4.annual_ret, s = 20, color = 'lime', label = 'Highest SR in Q4 with AVG(ESG) ={}'.format(esg_4))

    ax.scatter(max_sharpe[3], max_sharpe[1], marker = '$S$', s = 130,  color = 'magenta', label = 'max sharpe-ratio')
    ax.scatter(min_vola[3], min_vola[1], marker = '$V$', s = 130, color = 'magenta', label = 'min vola')
    ax.scatter(max_esg[3], max_esg[1], marker = '$E$', s = 130,  color = 'magenta', label = 'max ESG portfolio')


    ax.legend()

    fig.savefig('markov_esg_' + file_name + '.jpg', bbox_inches='tight')
    plt.close()
    return(mc_results)
#%%
sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'Q1', sort1_sp500_ret[1].index, sort1_sp500['ESG Score'], num_portfolios)

sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'Q2', sort2_sp500_ret[1].index, sort2_sp500['ESG Score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'Q3', sort3_sp500_ret[1].index, sort3_sp500['ESG Score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'Q4', sort4_sp500_ret[1].index, sort4_sp500['ESG Score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'Q5', sort5_sp500_ret[1].index, sort5_sp500['ESG Score'], num_portfolios)

#%%

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['sharpe_ratio'])
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['sharpe_ratio'])
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['sharpe_ratio'])
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['sharpe_ratio'])
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['sharpe_ratio'])

plt.savefig('SR_ESG_SP500_2018_2019_test_aktuell_100k_5_420.jpg', bbox_inches='tight')
plt.show()
###################################################################################################
# Another scribble
# #%%
# num_portfolios = 1000000
# test_ret = ret_cov(third_sp500_closing.drop('Year', axis = 1)[third_period_mean_sp500.index])

# test_result = mc_sampler(num_portfolios, test_ret[1], test_ret[2], 0.0,test_ret[1].index)
# test_mark = make_markowitz_suppressed(test_result, 'NA', test_ret[1].index, third_period_mean_sp500, num_portfolios)
# plt.subplots(figsize = (15,10))
# plt.scatter(test_mark['ESG_port_score'], test_mark['sharpe_ratio'])
# plt.savefig('SR_ESG_SP500_2018_2019_all.jpg', bbox_inches='tight')
###################################################################################################

#%%

def ret_cov(closing_prices):
    log_return = np.log(closing_prices.pct_change()+1)
    #log_return = np.log(closing_prices/closing_prices.shift(1)).dropna()
    mean_log_returns = log_return.drop(log_return.head(1).index).dropna(axis = 1).mean()
    log_cov = log_return.drop(log_return.head(1).index).dropna(axis = 1).cov()
    sharpe_ratio = 0
    return(log_return, mean_log_returns, log_cov, sharpe_ratio)

# same with 10 sortings
num_portfolios = 1000
# See scribbles: third period only! ---------------------------------------------------------------------------------
third_period_mean_sp500_df = pd.DataFrame([third_period_mean_sp500, pd.qcut(third_period_mean_sp500, 10, labels= ['Q1','Q2', 'Q3','Q4', 'Q5', 'Q6', 'Q7','Q8','Q9','Q10'])]).T
third_period_mean_sp500_df.columns = ['ESG Score', 'q']
third_period_mean_sp500_df['q'] = third_period_mean_sp500_df['q'].astype('str')
rd.seed(42)
df_help = third_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(10))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
sort6_sp500  = df_help[(df_help['q'] == 'Q6')].droplevel(level = 0)
sort7_sp500  = df_help[(df_help['q'] == 'Q7')].droplevel(level = 0)
sort8_sp500  = df_help[(df_help['q'] == 'Q8')].droplevel(level = 0)
sort9_sp500  = df_help[(df_help['q'] == 'Q9')].droplevel(level = 0)
sort10_sp500  = df_help[(df_help['q'] == 'Q10')].droplevel(level = 0)
# simulate random portfolios in each quantile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(third_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(third_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(third_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(third_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(third_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort6_sp500_ret = ret_cov(third_sp500_closing[sort6_sp500.index])
sort7_sp500_ret = ret_cov(third_sp500_closing[sort7_sp500.index])
sort8_sp500_ret = ret_cov(third_sp500_closing[sort8_sp500.index])
sort9_sp500_ret = ret_cov(third_sp500_closing[sort9_sp500.index])
sort10_sp500_ret = ret_cov(third_sp500_closing[sort10_sp500.index])

sort6_sp500_results = mc_sampler(num_portfolios,sort6_sp500_ret[1], sort6_sp500_ret[2],0.0,sort6_sp500_ret[1].index)
sort7_sp500_results = mc_sampler(num_portfolios,sort7_sp500_ret[1], sort7_sp500_ret[2],0.0,sort7_sp500_ret[1].index)
sort8_sp500_results = mc_sampler(num_portfolios,sort8_sp500_ret[1], sort8_sp500_ret[2],0.0,sort8_sp500_ret[1].index)
sort9_sp500_results = mc_sampler(num_portfolios,sort9_sp500_ret[1], sort9_sp500_ret[2],0.0,sort9_sp500_ret[1].index)
sort10_sp500_results = mc_sampler(num_portfolios,sort10_sp500_ret[1], sort10_sp500_ret[2],0.0,sort10_sp500_ret[1].index)

sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'Q1', sort1_sp500_ret[1].index, sort1_sp500['ESG Score'], num_portfolios)
sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'Q2', sort2_sp500_ret[1].index, sort2_sp500['ESG Score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'Q3', sort3_sp500_ret[1].index, sort3_sp500['ESG Score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'Q4', sort4_sp500_ret[1].index, sort4_sp500['ESG Score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'Q5', sort5_sp500_ret[1].index, sort5_sp500['ESG Score'], num_portfolios)

sort6_sp500_final = make_markowitz_suppressed(sort6_sp500_results, 'Q6', sort6_sp500_ret[1].index, sort6_sp500['ESG Score'], num_portfolios)
sort7_sp500_final = make_markowitz_suppressed(sort7_sp500_results, 'Q7', sort7_sp500_ret[1].index, sort7_sp500['ESG Score'], num_portfolios)
sort8_sp500_final = make_markowitz_suppressed(sort8_sp500_results, 'Q8', sort8_sp500_ret[1].index, sort8_sp500['ESG Score'], num_portfolios)
sort9_sp500_final = make_markowitz_suppressed(sort9_sp500_results, 'Q9', sort9_sp500_ret[1].index, sort9_sp500['ESG Score'], num_portfolios)
sort10_sp500_final = make_markowitz_suppressed(sort10_sp500_results, 'Q10', sort10_sp500_ret[1].index, sort10_sp500['ESG Score'], num_portfolios)


plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['sharpe_ratio'])
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['sharpe_ratio'])
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['sharpe_ratio'])
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['sharpe_ratio'])
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['sharpe_ratio'])
plt.scatter(sort6_sp500_final['ESG_port_score'], sort6_sp500_final['sharpe_ratio'])
plt.scatter(sort7_sp500_final['ESG_port_score'], sort7_sp500_final['sharpe_ratio'])
plt.scatter(sort8_sp500_final['ESG_port_score'], sort8_sp500_final['sharpe_ratio'])
plt.scatter(sort9_sp500_final['ESG_port_score'], sort9_sp500_final['sharpe_ratio'])
plt.scatter(sort10_sp500_final['ESG_port_score'], sort10_sp500_final['sharpe_ratio'])

plt.savefig('SR_ESG_SP500_2018_2019_10q_100k_5_seed42.jpg', bbox_inches='tight')
plt.show()
#%%

# same with 20 sortings
num_portfolios = 100000
# See scribbles: specified period and market only! ---------------------------------------------------------------------------------
third_period_mean_sp500_df = pd.DataFrame([third_period_mean_sp500, pd.qcut(third_period_mean_sp500, 20, labels= ['Q1','Q2', 'Q3','Q4', 'Q5', 'Q6', 'Q7','Q8','Q9','Q10','Q11','Q12', 'Q13','Q14', 'Q15', 'Q16', 'Q17','Q18','Q19','Q20'])]).T
third_period_mean_sp500_df.columns = ['ESG Score', 'q']
third_period_mean_sp500_df['q'] = third_period_mean_sp500_df['q'].astype('str')
rd.seed(42)
# Might need to reduce sample to 19
df_help = third_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(20))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
sort6_sp500  = df_help[(df_help['q'] == 'Q6')].droplevel(level = 0)
sort7_sp500  = df_help[(df_help['q'] == 'Q7')].droplevel(level = 0)
sort8_sp500  = df_help[(df_help['q'] == 'Q8')].droplevel(level = 0)
sort9_sp500  = df_help[(df_help['q'] == 'Q9')].droplevel(level = 0)
sort10_sp500  = df_help[(df_help['q'] == 'Q10')].droplevel(level = 0)
sort11_sp500  = df_help[(df_help['q'] == 'Q11')].droplevel(level = 0)
sort12_sp500  = df_help[(df_help['q'] == 'Q12')].droplevel(level = 0)
sort13_sp500  = df_help[(df_help['q'] == 'Q13')].droplevel(level = 0)
sort14_sp500  = df_help[(df_help['q'] == 'Q14')].droplevel(level = 0)
sort15_sp500  = df_help[(df_help['q'] == 'Q15')].droplevel(level = 0)
sort16_sp500  = df_help[(df_help['q'] == 'Q16')].droplevel(level = 0)
sort17_sp500  = df_help[(df_help['q'] == 'Q17')].droplevel(level = 0)
sort18_sp500  = df_help[(df_help['q'] == 'Q18')].droplevel(level = 0)
sort19_sp500  = df_help[(df_help['q'] == 'Q19')].droplevel(level = 0)
sort20_sp500  = df_help[(df_help['q'] == 'Q20')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(third_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(third_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(third_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(third_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(third_sp500_closing[sort5_sp500.index])
sort6_sp500_ret = ret_cov(third_sp500_closing[sort6_sp500.index])
sort7_sp500_ret = ret_cov(third_sp500_closing[sort7_sp500.index])
sort8_sp500_ret = ret_cov(third_sp500_closing[sort8_sp500.index])
sort9_sp500_ret = ret_cov(third_sp500_closing[sort9_sp500.index])
sort10_sp500_ret = ret_cov(third_sp500_closing[sort10_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)
sort6_sp500_results = mc_sampler(num_portfolios,sort6_sp500_ret[1], sort6_sp500_ret[2],0.0,sort6_sp500_ret[1].index)
sort7_sp500_results = mc_sampler(num_portfolios,sort7_sp500_ret[1], sort7_sp500_ret[2],0.0,sort7_sp500_ret[1].index)
sort8_sp500_results = mc_sampler(num_portfolios,sort8_sp500_ret[1], sort8_sp500_ret[2],0.0,sort8_sp500_ret[1].index)
sort9_sp500_results = mc_sampler(num_portfolios,sort9_sp500_ret[1], sort9_sp500_ret[2],0.0,sort9_sp500_ret[1].index)
sort10_sp500_results = mc_sampler(num_portfolios,sort10_sp500_ret[1], sort10_sp500_ret[2],0.0,sort10_sp500_ret[1].index)


sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG Score'], num_portfolios)
sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG Score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG Score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG Score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG Score'], num_portfolios)
sort6_sp500_final = make_markowitz_suppressed(sort6_sp500_results, 'NA', sort6_sp500_ret[1].index, sort6_sp500['ESG Score'], num_portfolios)
sort7_sp500_final = make_markowitz_suppressed(sort7_sp500_results, 'NA', sort7_sp500_ret[1].index, sort7_sp500['ESG Score'], num_portfolios)
sort8_sp500_final = make_markowitz_suppressed(sort8_sp500_results, 'NA', sort8_sp500_ret[1].index, sort8_sp500['ESG Score'], num_portfolios)
sort9_sp500_final = make_markowitz_suppressed(sort9_sp500_results, 'NA', sort9_sp500_ret[1].index, sort9_sp500['ESG Score'], num_portfolios)
sort10_sp500_final = make_markowitz_suppressed(sort10_sp500_results, 'NA', sort10_sp500_ret[1].index, sort10_sp500['ESG Score'], num_portfolios)


sort11_sp500_ret = ret_cov(third_sp500_closing[sort11_sp500.index])
sort12_sp500_ret = ret_cov(third_sp500_closing[sort12_sp500.index])
sort13_sp500_ret = ret_cov(third_sp500_closing[sort13_sp500.index])
sort14_sp500_ret = ret_cov(third_sp500_closing[sort14_sp500.index])
sort15_sp500_ret = ret_cov(third_sp500_closing[sort15_sp500.index])
sort16_sp500_ret = ret_cov(third_sp500_closing[sort16_sp500.index])
sort17_sp500_ret = ret_cov(third_sp500_closing[sort17_sp500.index])
sort18_sp500_ret = ret_cov(third_sp500_closing[sort18_sp500.index])
sort19_sp500_ret = ret_cov(third_sp500_closing[sort19_sp500.index])
sort20_sp500_ret = ret_cov(third_sp500_closing[sort20_sp500.index])

sort11_sp500_results = mc_sampler(num_portfolios,sort11_sp500_ret[1], sort11_sp500_ret[2],0.0,sort11_sp500_ret[1].index)
sort12_sp500_results = mc_sampler(num_portfolios,sort12_sp500_ret[1], sort12_sp500_ret[2],0.0,sort12_sp500_ret[1].index)
sort13_sp500_results = mc_sampler(num_portfolios,sort13_sp500_ret[1], sort13_sp500_ret[2],0.0,sort13_sp500_ret[1].index)
sort14_sp500_results = mc_sampler(num_portfolios,sort14_sp500_ret[1], sort14_sp500_ret[2],0.0,sort14_sp500_ret[1].index)
sort15_sp500_results = mc_sampler(num_portfolios,sort15_sp500_ret[1], sort15_sp500_ret[2],0.0,sort15_sp500_ret[1].index)
sort16_sp500_results = mc_sampler(num_portfolios,sort16_sp500_ret[1], sort16_sp500_ret[2],0.0,sort16_sp500_ret[1].index)
sort17_sp500_results = mc_sampler(num_portfolios,sort17_sp500_ret[1], sort17_sp500_ret[2],0.0,sort17_sp500_ret[1].index)
sort18_sp500_results = mc_sampler(num_portfolios,sort18_sp500_ret[1], sort18_sp500_ret[2],0.0,sort18_sp500_ret[1].index)
sort19_sp500_results = mc_sampler(num_portfolios,sort19_sp500_ret[1], sort19_sp500_ret[2],0.0,sort19_sp500_ret[1].index)
sort20_sp500_results = mc_sampler(num_portfolios,sort20_sp500_ret[1], sort20_sp500_ret[2],0.0,sort20_sp500_ret[1].index)


sort11_sp500_final = make_markowitz_suppressed(sort11_sp500_results, 'NA', sort11_sp500_ret[1].index, sort11_sp500['ESG Score'], num_portfolios)
sort12_sp500_final = make_markowitz_suppressed(sort12_sp500_results, 'NA', sort12_sp500_ret[1].index, sort12_sp500['ESG Score'], num_portfolios)
sort13_sp500_final = make_markowitz_suppressed(sort13_sp500_results, 'NA', sort13_sp500_ret[1].index, sort13_sp500['ESG Score'], num_portfolios)
sort14_sp500_final = make_markowitz_suppressed(sort14_sp500_results, 'NA', sort14_sp500_ret[1].index, sort14_sp500['ESG Score'], num_portfolios)
sort15_sp500_final = make_markowitz_suppressed(sort15_sp500_results, 'NA', sort15_sp500_ret[1].index, sort15_sp500['ESG Score'], num_portfolios)
sort16_sp500_final = make_markowitz_suppressed(sort16_sp500_results, 'NA', sort16_sp500_ret[1].index, sort16_sp500['ESG Score'], num_portfolios)
sort17_sp500_final = make_markowitz_suppressed(sort17_sp500_results, 'NA', sort17_sp500_ret[1].index, sort17_sp500['ESG Score'], num_portfolios)
sort18_sp500_final = make_markowitz_suppressed(sort18_sp500_results, 'NA', sort18_sp500_ret[1].index, sort18_sp500['ESG Score'], num_portfolios)
sort19_sp500_final = make_markowitz_suppressed(sort19_sp500_results, 'NA', sort19_sp500_ret[1].index, sort19_sp500['ESG Score'], num_portfolios)
sort20_sp500_final = make_markowitz_suppressed(sort20_sp500_results, 'NA', sort20_sp500_ret[1].index, sort20_sp500['ESG Score'], num_portfolios)

#%%
plt.subplots(figsize = (15,10))

plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['sharpe_ratio'])
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['sharpe_ratio'])
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['sharpe_ratio'])
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['sharpe_ratio'])
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['sharpe_ratio'])
plt.scatter(sort6_sp500_final['ESG_port_score'], sort6_sp500_final['sharpe_ratio'])
plt.scatter(sort7_sp500_final['ESG_port_score'], sort7_sp500_final['sharpe_ratio'])
plt.scatter(sort8_sp500_final['ESG_port_score'], sort8_sp500_final['sharpe_ratio'])
plt.scatter(sort9_sp500_final['ESG_port_score'], sort9_sp500_final['sharpe_ratio'])
plt.scatter(sort10_sp500_final['ESG_port_score'], sort10_sp500_final['sharpe_ratio'])
plt.scatter(sort11_sp500_final['ESG_port_score'], sort11_sp500_final['sharpe_ratio'])
plt.scatter(sort12_sp500_final['ESG_port_score'], sort12_sp500_final['sharpe_ratio'])
plt.scatter(sort13_sp500_final['ESG_port_score'], sort13_sp500_final['sharpe_ratio'])
plt.scatter(sort14_sp500_final['ESG_port_score'], sort14_sp500_final['sharpe_ratio'])
plt.scatter(sort15_sp500_final['ESG_port_score'], sort15_sp500_final['sharpe_ratio'])
plt.scatter(sort16_sp500_final['ESG_port_score'], sort16_sp500_final['sharpe_ratio'])
plt.scatter(sort17_sp500_final['ESG_port_score'], sort17_sp500_final['sharpe_ratio'])
plt.scatter(sort18_sp500_final['ESG_port_score'], sort18_sp500_final['sharpe_ratio'])
plt.scatter(sort19_sp500_final['ESG_port_score'], sort19_sp500_final['sharpe_ratio'])
plt.scatter(sort20_sp500_final['ESG_port_score'], sort20_sp500_final['sharpe_ratio'])
plt.title('Simulation of 20 Quantile-Portfolios from the SP500 between 2018-2019', fontsize = 20)
plt.ylabel('annual Sharpe-Ratio', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)

plt.savefig('SR_ESG_SP500_2018_2019_20q_42.jpg', bbox_inches='tight')
plt.close()
# plt.show()

#%%
###################################################################################################
# Quintile sorted portfolios from section 4.5
###################################################################################################
# Yet another function necessary
def ret_cov(closing_prices):
    log_return = np.log(closing_prices.pct_change()+1)
    #log_return = np.log(closing_prices/closing_prices.shift(1)).dropna()
    mean_log_returns = log_return.drop(log_return.head(1).index).dropna(axis = 1).mean()
    log_cov = log_return.drop(log_return.head(1).index).dropna(axis = 1).cov()
    sharpe_ratio = 0
    return(log_return, mean_log_returns, log_cov, sharpe_ratio)

###################################################################################################
# New make_markowitz_suppresses neds to be initialized first!

def make_markowitz_suppressed(mc_results, file_name, tickers, esg_period_mean, num_portfolios):
    # mc_results = first_period_best_sp500_results
    # file_name = 'test'
    # tickers = first_period_best_sp500_tickers
    # esg_period_mean = first_period_best_sp500

    # max_sharpe = mc_results.iloc[mc_results['sharpe_ratio'].idxmax()]
    # min_vola = mc_results.iloc[mc_results['annual_vol'].idxmin()]
    esg_relevant = esg_period_mean.to_frame().reset_index()
    #sharpe_chain = mc_results.iloc[mc_results['sharpe_ratio'].nlargest(n = 100).index]


    sampler_weights = mc_results[tickers].T
    sampler_weights['Company Code'] = sampler_weights.index
    sampler_weights = esg_relevant.merge(sampler_weights, left_on = 'Instrument', right_on = 'Company Code').T
    esg_relevant = esg_relevant.set_index('Instrument')
    esg_relevant = esg_relevant.loc[tickers]
    #esg_relevant = esg_relevant.reset_index()
    #sampler_weights.columns = esg_relevant['Instrument']
    sampler_weights.columns = esg_relevant.index
    sampler_weights = sampler_weights.T
    sampler_scores = []
    sampler_weights = sampler_weights.drop('Company Code', 1)
    #sampler_scores = [(np.sum(sampler_weights['ESG_overall'] * wgt)) for wgt in sampler_weights[sampler_weights.columns[-num_portfolios:]]]
    sampler_weights = sampler_weights.astype({'ESG score' : 'float64'})
    sampler_scores = sampler_weights[sampler_weights.columns[-num_portfolios:]].multiply(sampler_weights['ESG score'], axis = 'index')

    sampler_scores = np.sum(sampler_scores, axis = 0)


    esg_results = sampler_weights.append(sampler_scores, ignore_index = True) #!?!?! investigate!
    mc_results['ESG_port_score'] = sampler_scores # for plotting
    # NOTE: try to filter for highest sharpe ratio portfolios within each quartile
    mc_results['q'] = pd.qcut(mc_results['ESG_port_score'], 4, labels = ['Q1','Q2', 'Q3','Q4'])
    mc_results['q'] = mc_results['q'].astype('str')
    sharpe_chain_1 = mc_results[(mc_results['q'] == 'Q1')]
    sharpe_chain_1 = mc_results.iloc[sharpe_chain_1['ESG_port_score'].nlargest(n = 10000).index]
    esg_1 = round(sharpe_chain_1['ESG_port_score'].mean(),2)
    sharpe_chain_2 = mc_results[(mc_results['q'] == 'Q2')]
    sharpe_chain_2 = mc_results.iloc[sharpe_chain_2['ESG_port_score'].nlargest(n = 10000).index]
    esg_2 = round(sharpe_chain_2['ESG_port_score'].mean(),2)
    sharpe_chain_3 = mc_results[(mc_results['q'] == 'Q3')]
    sharpe_chain_3 = mc_results.iloc[sharpe_chain_3['ESG_port_score'].nlargest(n = 10000).index]
    esg_3 = round(sharpe_chain_3['ESG_port_score'].mean(),2)
    sharpe_chain_4 = mc_results[(mc_results['q'] == 'Q4')]
    sharpe_chain_4 = mc_results.iloc[sharpe_chain_4['ESG_port_score'].nlargest(n = 10000).index]
    esg_4 = round(sharpe_chain_4['ESG_port_score'].mean(),2)


    # max_esg = mc_results.iloc[mc_results['ESG_port_score'].idxmax()]

    # fig, ax = plt.subplots(figsize = (15,10))
    # sc = ax.scatter(mc_results.annual_vol, mc_results.annual_ret, c = mc_results.ESG_port_score, cmap = 'RdYlBu', alpha = 0.6)
    # ax.set_title('Mean-Variance Trade-off Visualization for n = {}'.format(num_portfolios) + ' simulated portfolios',fontsize=20) #{}'.format(num_portfolios) + ' 
    # ax.set_xlabel('Annualized Standard Deviation/Volatility', fontsize=20)
    # ax.set_ylabel('Annualized Mean Returns',fontsize=20)
    # # cb = plt.colorbar()
    # # cb.ax.set_ylabel('ESG scores', rotation = 270)
    # cbar = fig.colorbar(sc)
    # cbar.set_label('ESG scores', rotation = 270)

    # ax.scatter(sharpe_chain_1.annual_vol, sharpe_chain_1.annual_ret, s = 20, color = 'k', label = 'Highest SR in Q1 with AVG(ESG) ={}'.format(esg_1))
    # ax.scatter(sharpe_chain_2.annual_vol, sharpe_chain_2.annual_ret, s = 20, color = 'grey', label = 'Highest SR in Q2 with AVG(ESG) ={}'.format(esg_2))
    # ax.scatter(sharpe_chain_3.annual_vol, sharpe_chain_3.annual_ret, s = 20, color = 'yellow', label = 'Highest SR in Q3 with AVG(ESG) ={}'.format(esg_3))
    # ax.scatter(sharpe_chain_4.annual_vol, sharpe_chain_4.annual_ret, s = 20, color = 'lime', label = 'Highest SR in Q4 with AVG(ESG) ={}'.format(esg_4))

    # ax.scatter(max_sharpe[3], max_sharpe[1], marker = '$S$', s = 130,  color = 'magenta', label = 'max sharpe-ratio')
    # ax.scatter(min_vola[3], min_vola[1], marker = '$V$', s = 130, color = 'magenta', label = 'min vola')
    # ax.scatter(max_esg[3], max_esg[1], marker = '$E$', s = 130,  color = 'magenta', label = 'max ESG portfolio')


    # ax.legend()

    # fig.savefig('markov_esg_test' + file_name + '.jpg', bbox_inches='tight')
    # plt.close()
    return(mc_results)

#%%
rd.seed(960)
num_portfolios = 10000
# See scribbles: third period only! ---------------------------------------------------------------------------------
third_period_mean_sp500_df = pd.DataFrame([third_period_mean_sp500, pd.qcut(third_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
third_period_mean_sp500_df.columns = ['ESG score', 'q']
third_period_mean_sp500_df['q'] = third_period_mean_sp500_df['q'].astype('str')
df_help = third_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(third_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(third_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(third_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(third_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(third_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)

sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['sharpe_ratio'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['sharpe_ratio'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['sharpe_ratio'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['sharpe_ratio'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['sharpe_ratio'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Sharpe-Ratio for 2018-2019', fontsize = 20)
plt.ylabel('annual Sharpe-Ratio', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)

plt.savefig('SR_ESG_SP500_2018_2019_960.jpg', bbox_inches='tight')
# plt.show()

rd.seed(960)
num_portfolios = 10000
# See scribbles: second period only! ---------------------------------------------------------------------------------
second_period_mean_sp500_df = pd.DataFrame([second_period_mean_sp500, pd.qcut(second_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
second_period_mean_sp500_df.columns = ['ESG score', 'q']
second_period_mean_sp500_df['q'] = second_period_mean_sp500_df['q'].astype('str')
df_help = second_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(second_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(second_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(second_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(second_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(second_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)
sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['sharpe_ratio'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['sharpe_ratio'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['sharpe_ratio'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['sharpe_ratio'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['sharpe_ratio'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Sharpe-Ratio for 2014-2017', fontsize = 20)
plt.ylabel('annual Sharpe-Ratio', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)

plt.savefig('SR_ESG_SP500_2014_2017_960.jpg', bbox_inches='tight')

rd.seed(960)
num_portfolios = 10000
# See scribbles: first period only! ---------------------------------------------------------------------------------
first_period_mean_sp500_df = pd.DataFrame([first_period_mean_sp500, pd.qcut(first_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
first_period_mean_sp500_df.columns = ['ESG score', 'q']
first_period_mean_sp500_df['q'] = first_period_mean_sp500_df['q'].astype('str')
df_help = first_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(first_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(first_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(first_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(first_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(first_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)
sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['sharpe_ratio'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['sharpe_ratio'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['sharpe_ratio'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['sharpe_ratio'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['sharpe_ratio'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Sharpe-Ratio for 2010-2013', fontsize = 20)
plt.ylabel('annual Sharpe-Ratio', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)
plt.savefig('SR_ESG_SP500_2010_2013_960.jpg', bbox_inches='tight')


#%%
###################################################################################################
# Volla vs ESG sorted portfolios ------------------------------------------------------------------
rd.seed(42)
num_portfolios = 10000
# See scribbles: third period only! ---------------------------------------------------------------------------------
third_period_mean_sp500_df = pd.DataFrame([third_period_mean_sp500, pd.qcut(third_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
third_period_mean_sp500_df.columns = ['ESG score', 'q']
third_period_mean_sp500_df['q'] = third_period_mean_sp500_df['q'].astype('str')
df_help = third_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(third_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(third_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(third_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(third_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(third_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)

sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['annual_vol'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['annual_vol'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['annual_vol'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['annual_vol'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['annual_vol'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Volatility for 2018-2019', fontsize = 20)
plt.ylabel('annual Volatility', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)

plt.savefig('Vola_ESG_SP500_2018_2019.jpg', bbox_inches='tight')
# plt.show()

rd.seed(42)
num_portfolios = 10000
# See scribbles: second period only! ---------------------------------------------------------------------------------
second_period_mean_sp500_df = pd.DataFrame([second_period_mean_sp500, pd.qcut(second_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
second_period_mean_sp500_df.columns = ['ESG score', 'q']
second_period_mean_sp500_df['q'] = second_period_mean_sp500_df['q'].astype('str')
df_help = second_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(second_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(second_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(second_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(second_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(second_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)
sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['annual_vol'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['annual_vol'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['annual_vol'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['annual_vol'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['annual_vol'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Volatility for 2014-2017', fontsize = 20)
plt.ylabel('annual Volatility', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)

plt.savefig('Vola_ESG_SP500_2014_2017.jpg', bbox_inches='tight')

rd.seed(42)
num_portfolios = 10000
# See scribbles: first period only! ---------------------------------------------------------------------------------
first_period_mean_sp500_df = pd.DataFrame([first_period_mean_sp500, pd.qcut(first_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
first_period_mean_sp500_df.columns = ['ESG score', 'q']
first_period_mean_sp500_df['q'] = first_period_mean_sp500_df['q'].astype('str')
df_help = first_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(first_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(first_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(first_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(first_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(first_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)
sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['annual_vol'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['annual_vol'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['annual_vol'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['annual_vol'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['annual_vol'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Volatility for 2010-2013', fontsize = 20)
plt.ylabel('annual Volatility', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)
plt.savefig('Vola_ESG_SP500_2010_2013.jpg', bbox_inches='tight')

#%%
###################################################################################################
# Ret vs ESG --------------------------------------------------------------------------------------
rd.seed(42)
num_portfolios = 10000
# See scribbles: third period only! ---------------------------------------------------------------------------------
third_period_mean_sp500_df = pd.DataFrame([third_period_mean_sp500, pd.qcut(third_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
third_period_mean_sp500_df.columns = ['ESG score', 'q']
third_period_mean_sp500_df['q'] = third_period_mean_sp500_df['q'].astype('str')
df_help = third_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(third_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(third_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(third_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(third_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(third_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)

sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['annual_ret'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['annual_ret'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['annual_ret'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['annual_ret'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['annual_ret'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Return for 2018-2019', fontsize = 20)
plt.ylabel('annual Return', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)

plt.savefig('RET_ESG_SP500_2018_2019.jpg', bbox_inches='tight')
# plt.show()

rd.seed(42)
num_portfolios = 10000
# See scribbles: second period only! ---------------------------------------------------------------------------------
second_period_mean_sp500_df = pd.DataFrame([second_period_mean_sp500, pd.qcut(second_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
second_period_mean_sp500_df.columns = ['ESG score', 'q']
second_period_mean_sp500_df['q'] = second_period_mean_sp500_df['q'].astype('str')
df_help = second_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(second_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(second_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(second_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(second_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(second_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)
sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['annual_ret'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['annual_ret'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['annual_ret'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['annual_ret'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['annual_ret'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Return for 2014-2017', fontsize = 20)
plt.ylabel('annual Return', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)

plt.savefig('RET_ESG_SP500_2014_2017.jpg', bbox_inches='tight')

rd.seed(42)
num_portfolios = 10000
# See scribbles: first period only! ---------------------------------------------------------------------------------
first_period_mean_sp500_df = pd.DataFrame([first_period_mean_sp500, pd.qcut(first_period_mean_sp500, 5, labels= ['Q1','Q2', 'Q3','Q4', 'Q5'])]).T
first_period_mean_sp500_df.columns = ['ESG score', 'q']
first_period_mean_sp500_df['q'] = first_period_mean_sp500_df['q'].astype('str')
df_help = first_period_mean_sp500_df.groupby('q').apply(lambda x: x.sample(50))
sort1_sp500  = df_help[(df_help['q'] == 'Q1')].droplevel(level = 0)
sort2_sp500  = df_help[(df_help['q'] == 'Q2')].droplevel(level = 0)
sort3_sp500  = df_help[(df_help['q'] == 'Q3')].droplevel(level = 0)
sort4_sp500  = df_help[(df_help['q'] == 'Q4')].droplevel(level = 0)
sort5_sp500  = df_help[(df_help['q'] == 'Q5')].droplevel(level = 0)
# simulate random portfolios in each quintile with 10 randomly drawn assets from each

sort1_sp500_ret = ret_cov(first_sp500_closing[sort1_sp500.index])
sort2_sp500_ret = ret_cov(first_sp500_closing[sort2_sp500.index])
sort3_sp500_ret = ret_cov(first_sp500_closing[sort3_sp500.index])
sort4_sp500_ret = ret_cov(first_sp500_closing[sort4_sp500.index])
sort5_sp500_ret = ret_cov(first_sp500_closing[sort5_sp500.index])

sort1_sp500_results = mc_sampler(num_portfolios,sort1_sp500_ret[1], sort1_sp500_ret[2],0.0,sort1_sp500_ret[1].index)
sort2_sp500_results = mc_sampler(num_portfolios,sort2_sp500_ret[1], sort2_sp500_ret[2],0.0,sort2_sp500_ret[1].index)
sort3_sp500_results = mc_sampler(num_portfolios,sort3_sp500_ret[1], sort3_sp500_ret[2],0.0,sort3_sp500_ret[1].index)
sort4_sp500_results = mc_sampler(num_portfolios,sort4_sp500_ret[1], sort4_sp500_ret[2],0.0,sort4_sp500_ret[1].index)
sort5_sp500_results = mc_sampler(num_portfolios,sort5_sp500_ret[1], sort5_sp500_ret[2],0.0,sort5_sp500_ret[1].index)



sort1_sp500_final = make_markowitz_suppressed(sort1_sp500_results, 'NA', sort1_sp500_ret[1].index, sort1_sp500['ESG score'], num_portfolios)
sort2_sp500_final = make_markowitz_suppressed(sort2_sp500_results, 'NA', sort2_sp500_ret[1].index, sort2_sp500['ESG score'], num_portfolios)
sort3_sp500_final = make_markowitz_suppressed(sort3_sp500_results, 'NA', sort3_sp500_ret[1].index, sort3_sp500['ESG score'], num_portfolios)
sort4_sp500_final = make_markowitz_suppressed(sort4_sp500_results, 'NA', sort4_sp500_ret[1].index, sort4_sp500['ESG score'], num_portfolios)
sort5_sp500_final = make_markowitz_suppressed(sort5_sp500_results, 'NA', sort5_sp500_ret[1].index, sort5_sp500['ESG score'], num_portfolios)

plt.subplots(figsize = (15,10))
plt.scatter(sort1_sp500_final['ESG_port_score'], sort1_sp500_final['annual_ret'], c=sort1_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)##4D1B2F
plt.scatter(sort2_sp500_final['ESG_port_score'], sort2_sp500_final['annual_ret'],  c=sort2_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort3_sp500_final['ESG_port_score'], sort3_sp500_final['annual_ret'],  c=sort3_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort4_sp500_final['ESG_port_score'], sort4_sp500_final['annual_ret'],  c=sort4_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.scatter(sort5_sp500_final['ESG_port_score'], sort5_sp500_final['annual_ret'],  c=sort5_sp500_final['ESG_port_score'], cmap = 'RdYlBu', alpha = 0.6)
plt.title('Portfolio-Simulations from ESG-sorted SP500 firms and their annual Return for 2010-2013', fontsize = 20)
plt.ylabel('annual Return', fontsize = 20)
plt.xlabel('averaged ESG-Portfolio Score', fontsize = 20)
plt.savefig('RET_ESG_SP500_2010_2013.jpg', bbox_inches='tight')

###################################################################################################
# Complete index simulation STUPID! ---------------------------------------------------------------
closing_test = third_sp500_closing.drop('Year', axis = 1)
closing_test = closing_test[closing_test.columns[closing_test.columns.isin(third_period_mean_sp500.index)]]

sp500_ret_1013 = ret_cov(closing_test)
sp500_joint_1013 = pd.concat([sp500_ret_1013[1],third_period_mean_sp500], axis = 1, join = 'inner')


sp500_result = mc_sampler(100000,sp500_joint_1013[0], sp500_ret_1013[2], 0.0, sp500_joint_1013.index)


make_markowitz(sp500_result,'SP500_whole_2018_2019',sp500_joint_1013.index,third_period_mean_sp500, 100000)
###################################################################################################
#%%
