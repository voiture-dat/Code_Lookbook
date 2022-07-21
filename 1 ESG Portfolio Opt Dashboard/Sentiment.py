# Imports
import pandas as pd
from bs4 import BeautifulSoup
from urllib.request import urlopen, Request
from nltk.sentiment.vader import SentimentIntensityAnalyzer
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
#from gensim.models import KeyedVectors
#import umap as umap

class SentimentAnalysis():
    def __init__(self, tickers):
        self.tickers = tickers
        self.news = 0
        self.news_tables = {}
        self.news_analysed = 0
        self.news_analysed_mean = 0
        self.words = 0
        self.umap = 0
        
    def get_news(self):

        for ticker in self.tickers:
            finwiz_url = 'https://finviz.com/quote.ashx?t='
            url = finwiz_url + ticker
            req = Request(url=url, headers={'user-agent': 'my-app/0.0.1'})
            resp = urlopen(req)
            html = BeautifulSoup(resp, features="lxml")
            news_table = html.find(id='news-table')
            self.news_tables[ticker] = news_table

        try:
            for ticker in self.tickers:
                df = self.news_tables[ticker]
                df_tr = df.findAll('tr')

                for i, table_row in enumerate(df_tr):
                    a_text = table_row.a.text
                    td_text = table_row.td.text
                    td_text = td_text.strip()

        except KeyError:
            pass

        # Iterate through the news
        parsed_news = []
        for file_name, news_table in self.news_tables.items():
            for x in news_table.findAll('tr'):
                text = x.a.get_text()
                date_scrape = x.td.text.split()

                if len(date_scrape) == 1:
                    time = date_scrape[0]

                else:
                    date = date_scrape[0]
                    time = date_scrape[1]

                ticker = file_name.split('_')[0]

                parsed_news.append([ticker, date, time, text])
        columns = ['Ticker', 'Date', 'Time', 'Headline']
        news = pd.DataFrame(parsed_news, columns=columns)
        self.news = news

    def analysis(self):
        analyzer = SentimentIntensityAnalyzer()
        scores = self.news['Headline'].apply(analyzer.polarity_scores).tolist()
        df_scores = pd.DataFrame(scores)
        news = self.news.join(df_scores, rsuffix='_right')

        # View Data
        news['Date'] = pd.to_datetime(news.Date).dt.date

        unique_ticker = news['Ticker'].unique().tolist()
        news_dict = {name: news.loc[news['Ticker'] == name] for name in unique_ticker}

        values = []
        for ticker in self.tickers:
            dataframe = news_dict[ticker]
            dataframe = dataframe.set_index('Ticker')
            dataframe = dataframe.drop(columns=['Headline'])

            mean = round(dataframe['compound'].mean(), 2)
            values.append(mean)

        df = pd.DataFrame(list(zip(self.tickers, values)), columns=['Ticker', 'Mean Sentiment'])
        df = df.set_index('Ticker')
        self.news = news
        self.news_analysed_mean = df

#    def embedding(self):
#        titles = self.news['Headline']
#        titles = [title for title in titles]
#        elongated_title = ' '.join(titles)
#        tok = word_tokenize(elongated_title)
#        words = [word.lower() for word in tok if word.isalpha()]
#        stop_words = set(stopwords.words('english'))
#        words = [word for word in words if not word in stop_words]
#        elongated_words = ' '.join(words)
#        model = KeyedVectors.load_word2vec_format('D:\Onedrive\Desktop\Wintersemester 2020\Data Science Project\data\GoogleNews-vectors-negative300.bin', binary=True)
#        avail_vectors = [model[word] for word in words if word in model.vocab]
#        avail_words = [word for word in words if
#                       word in model.vocab]  # Usually only a fraction <5% of words should be removed from here on
#
#        word_vec_zip = zip(avail_words, avail_vectors)
#        word_vec_dict = dict(word_vec_zip)
#        word_vec_df = pd.DataFrame.from_dict(word_vec_dict, orient='index')
#        self.words = word_vec_df
#        words_df = umap.UMAP(metric='correlation', n_components=2, n_neighbors = 5).fit_transform(word_vec_df)
#        words_df = pd.DataFrame(words_df, columns=['c1', 'c2'])
#        self.umap = words_df
