from universal import tools, algos
from pandas_datareader.data import DataReader

class RoboAdvisor:
    # This Class is a Robo Advisory Class
    # Inputs: Tickers as a list of Tickers
    #         Start as a YMD formated Date
    #         Strategy, a string from the choices
    #
    # Output: Results List
    #
    def __init__(self, tickers, start, adjustment, strategy, hyper):
        self.tickers = tickers
        self.start = start
        self.strategy = strategy
        self.adjustment = adjustment
        self.hyper = hyper # List Input - Has to be Specified in the UI and Server
        ## Here We inherit from Universal Portfolio Quite a lot.
        if strategy == 'Buy and Hold':
            self.algo = algos.BAH(
                b=hyper[0])
        if strategy == 'Best Constant Rebalanced Portfolio':
            self.algo = algos.BCRP()
        if strategy == 'Optimal Markowitz Portfolio over Time':
            self.algo = algos.BestMarkowitz()
        if strategy == 'Best Performance over Time':
            self.algo = algos.BestSoFar(
                n=hyper[0],
                metric=hyper[1])
        if strategy == 'Correlation Based Learning Approach':
            self.algo = algos.CORN(
                window=int(hyper[0]),
                rho=float(hyper[1]))
        if strategy == 'Constant Rebalanced Portfolio':
            self.algo = algos.CRP(
                b=hyper[0])
        if strategy == 'Dynamic Rebalancing Portfolio':
            self.algo = algos.DynamicCRP(
                n=hyper[0])
        if strategy == 'Exponential Gradient':
            self.algo = algos.EG(
                eta=float(hyper[0]))
        if strategy == 'Kelly Betting':
            self.algo = algos.Kelly(
                window=hyper[0],
                r=hyper[1],
                q=hyper[2],
                fraction=hyper[3],
                reg=hyper[4],
                long_only=hyper[5],
                mu_estimate=hyper[6],
                gamma=hyper[7],
                max_leverage=hyper[8])
        if strategy == 'Modern Portfolio Approach':
            self.algo = algos.MPT(
                window=hyper[0],
                mu_estimator=hyper[1],
                cov_estimator=hyper[2],
                mu_window=hyper[3],
                cov_window=hyper[4],
                min_history=hyper[5],
                max_leverage=hyper[6],
                method=hyper[7],
                q=hyper[8],
                gamma=hyper[9]
                )
        if strategy == 'On-Line Portfolio Selection with Moving Average Reversion':
            self.algo = algos.OLMAR(
                window=int(hyper[0]),
                eps=int(hyper[1]))
        if strategy == 'Robust Median Reversion':
            self.algo = algos.RMR(
                window=int(hyper[0]),
                eps=int(hyper[1]),
                tau=float(hyper[2]))
        if strategy == 'Universal Portfolio':
            self.algo = algos.UP(
                eval_points=hyper[0],
                leverage=hyper[1])
        if strategy == 'Weighted Moving Average Passive':
            self.algo = algos.WMAMR(window=int(hyper[0]))

    def advise(self):
        yahoo_data = DataReader(self.tickers, 'yahoo', start=self.start)['Adj Close']

        mS = yahoo_data.resample('M').last()

        wS = yahoo_data.resample('W').last()

        if self.adjustment == 'Daily':
            results = self.algo.run(yahoo_data)
        if self.adjustment == 'Weekly':
            results = self.algo.run(wS)
        if self.adjustment == 'Monthly':
            results = self.algo.run(mS)

        return results
