import pandas as pd
import numpy as np
import yfinance as yf
from scipy.optimize import minimize



class mcportfolio:
    def __init__(self, tickers, start, end, rfrate):
        
        self.tickers = tickers
        self.start = start
        self.end = end
        self.rfrate = rfrate
        self.mean_return = 0
        self.covariance = 0
        self.results = 0
        self.n = 0
        
    def get_tickers(self):
        stocks = pd.DataFrame()
        tickers = self.tickers
        for ticker in tickers:
            closing = yf.download(ticker, start=self.start, end=self.end, progress=False)['Close']
            stocks[ticker] = closing

        stocks.columns = tickers
        return stocks


    def port_perf(self, weights, mean_ret, covariance, risk_free_rate):
        # This shortcut function helps computing the performance of any given portfolio
        port_return = np.sum(np.dot(mean_ret, weights))
        port_return_annual = port_return * 252
        port_vol = np.sqrt(np.dot(weights.T, np.dot(covariance, weights)))
        port_vol_annual = np.sqrt(np.dot(weights.T, np.dot(covariance, weights))) * np.sqrt(252)
        sharpe_ratio = (port_return_annual - risk_free_rate)/port_vol_annual
        neg_sharpe = -sharpe_ratio
        return port_return, port_return_annual, port_vol, port_vol_annual, sharpe_ratio, neg_sharpe
    
   
    
    # Monte Carlo sampler: https://pythonforfinance.net/2019/07/02/investment-portfolio-optimisation-with-python-revisited/
    def mc_sampler(self, n):
        n = np.int64(n)
        tickers = self.get_tickers()
        risk_free_rate =self.rfrate
        log_return = np.log(tickers/tickers.shift(1)).dropna()
        mean_return = log_return.mean()
        covariance = log_return.cov()
        results = np.zeros((len(log_return.columns)+5,n))
        for i in range(n):
            weights = np.random.dirichlet(np.ones(len(tickers.columns)), size = 1)
            weights = weights[0]
            port_return,port_return_annual,port_vol,port_vol_annual,sharpe_ratio, waste = self.port_perf(weights, mean_return, covariance, risk_free_rate)
            results[0,i] = port_return
            results[1,i] = port_return_annual
            results[2,i] = port_vol
            results[3,i] = port_vol_annual
            results[4,i] = sharpe_ratio
            for j in range(len(weights)):
                results[j+5,i] = weights[j]
        results_data = pd.DataFrame(results.T, columns=['ret', 'annual_ret', 'vol', 'annual_vol', 'sharpe_ratio'] + [ticker for ticker in tickers])
        self.results = results_data
        self.mean_return = mean_return
        self.covariance = covariance
        self.n = n
        return results_data, mean_return, covariance
    
    def port_perf_var(self, weights, mean_ret, covariance, risk_free_rate):
        results = self.port_perf(weights, mean_ret, covariance, risk_free_rate)
        result = results[3]
        return result
    
    def port_perf_sharpe(self, weights, mean_ret, covariance, risk_free_rate):
        results = self.port_perf(weights, mean_ret, covariance, risk_free_rate)
        result = results[5]
        return result
    
    def max_sharpe_ratio(self):
        num_assets = len(self.mean_return)
        args = (self.mean_return, self.covariance, self.rfrate)
        cons = ({'type': 'eq', 'fun': lambda x: np.sum(x) - 1})
        bound = (0.0,1.0)
        bounds = tuple(bound for asset in range(num_assets))
        result = minimize(self.port_perf_sharpe, num_assets*[1./num_assets,], args=args,
                            method='SLSQP', bounds=bounds, constraints=cons)
        return result

    def min_variance(self):
        num_assets = len(self.mean_return)
        args = (self.mean_return, self.covariance, self.rfrate)
        cons = ({'type': 'eq', 'fun': lambda x: np.sum(x) - 1})
        bound = (0.0,1.0)
        bounds = tuple(bound for asset in range(num_assets))
        result = minimize(self.port_perf_var, num_assets*[1./num_assets,], args=args,
                        method='SLSQP', bounds=bounds, constraints=cons)
        return result
    
    def esg_rated(self):
        esg = pd.read_csv('D:\Onedrive\Git Projects\Data Science Project\Data\markets_esg.csv')
        esg_relevant = esg[esg['Symbol'].isin(self.tickers)]
        sharpe_weights = pd.DataFrame(self.max_sharpe_ratio().x, columns= ['Weights'])
        sharpe_weights['Symbol'] = self.tickers

        sharpe_weights = sharpe_weights.merge(esg_relevant, on = 'Symbol')
        # Hier kriegen wir noch einen Fehler
        sharpe_weights = sharpe_weights.astype({'ESG-Score' : 'float64'})
        sharpe_score = np.sum(sharpe_weights['Weights']*sharpe_weights['ESG-Score'])


        #%%
        # Weigh all simulated portfolios with their Scores and plot ESG score mapped markov bullet
        sampler_weights = self.results[self.tickers].T
        sampler_weights['Symbol'] = sampler_weights.index
        sampler_weights = esg_relevant.merge(sampler_weights, on = 'Symbol').T
        sampler_weights.columns = esg_relevant['Symbol']
        sampler_weights = sampler_weights.T
        sampler_scores = []
        #sampler_scores = [(np.sum(sampler_weights['ESG_overall'] * wgt)) for wgt in sampler_weights[sampler_weights.columns[-num_portfolios:]]]
        sampler_weights = sampler_weights.astype({'ESG-Score' : 'float64'})
        sampler_scores = sampler_weights[sampler_weights.columns[-self.n:]].multiply(sampler_weights['ESG-Score'], axis = 'index')
        sampler_scores = np.sum(sampler_scores, axis = 0)
        #%%
        esg_results = sampler_weights.append(sampler_scores, ignore_index = True)
        self.results['ESG_port_score'] = sampler_scores # for plotting
         
