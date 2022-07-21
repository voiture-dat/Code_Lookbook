rm(list = ls())
## R Imports -----
library(shinydashboard)
library(shiny)
library(ggplot2)
library(tidyverse)
library(httr)
library(rlist)
library(quantmod)
library(jsonlite)
library(lubridate)
library(plotly)
library(DT)
library(stringi)
library(reticulate)
library(dplyr)
library(tidyquant)
library(gdata)
library(RColorBrewer)
library(timetk)
library(broom)
library(shinyWidgets)
library(purrr)
library(shinydashboardPlus)

## We can also include more symbols here

## Complete Data Imports

symbol_df = read.csv('Data/symbols.csv', stringsAsFactors = F)
symbol_df$X = NULL
symbol_df <-
  symbol_df %>% mutate(display = paste(Symbol, Description, sep = " - "))


markets_esg = read.csv('Data/markets_esg.csv', stringsAsFactors = F)
markets_esg$X = NULL
colnames(markets_esg) = c('Time', 'Symbol', 'ESG-Score', 'E-Score', 'S-Score', 'G-Score')

markets_measures = read.csv('Data/markets_measures', stringsAsFactors = F)
markets_measures$X.1 = NULL
markets_measures$X = NULL

markets_measures$Instrument = gsub(pattern = '(.[N])',
                                   replacement = '',
                                   x = markets_measures$Instrument)
markets_measures = markets_measures[markets_measures$Period.End.Date != '',]

colnames(markets_measures) = colnames(markets_measures) %>% str_replace_all('\\.', ' ')


# measure and stock datasets for optimisation
opt_measures <- markets_measures
opt_measures$Year <- year(as.Date(opt_measures$`Period End Date`))
freeFac <- opt_measures
opt_measures <-
  opt_measures %>% group_by(Instrument) %>% filter(Year == max(as.numeric(Year)))
colnames(opt_measures) <-
  gsub('[[:punct:][:blank:]]+', ' ', colnames(opt_measures))

symbol_df_ESG = semi_join(symbol_df, markets_esg, by = "Symbol")
symbol_df_ESG = semi_join(symbol_df_ESG, opt_measures, by = c("Symbol" = "Instrument"))

esg <- markets_esg
esg$Time <- year(as.Date(esg$Time))
esg <-
  esg %>%  group_by(Symbol) %>% filter(Time == max(as.numeric(Time)))

opt_measures <-
  inner_join(esg, opt_measures, by = c("Symbol" = "Instrument", "Time" = "Year"))
opt_measures <-
  opt_measures[!duplicated(opt_measures[, c("Time", "Symbol")]),] # necessary as unclear where some observations belong to



ranking = read.csv('Data/Ranking.csv')
ranking$X = NULL


ranking = ranking %>%
  mutate(E.Rank = rank(E.Score ^ (-1)))

ranking = ranking %>%
  mutate(ESG.Rank = rank(ESG.Score ^ (-1)))

# Factor import and preparation

ffFac <-
  read.csv('Data/F-F_Research_Data_5_Factors_2x3_daily.csv', skip = 3) %>% dplyr::rename(Date = 'X', MKT = 'Mkt.RF') %>%
  mutate(Date = as.Date(ymd(Date))) %>% mutate_if(is.numeric, funs(. / 100))
threeFac <- ffFac[, c(1:4, 7)]

modelChoice <-
  list("Fama-French 5 Factor" = ffFac,
       "Fama-French 3 Factor" = threeFac)


# Input information loss issue: https://stackoverflow.com/questions/50245925/tabitem-cannot-show-the-content-when-more-functions-in-menuitem-using-shiny-and/50250232#50250232
convertMenuItem <- function(mi, tabName) {
  mi$children[[1]]$attribs['data-toggle'] = "tab"
  mi$children[[1]]$attribs['data-value'] = tabName
  mi
}

# Strategy Choices

Strategies = c(
  'Buy and Hold',
  'Best Constant Rebalanced Portfolio',
  'Dynamic Rebalancing Portfolio',
  #'Kelly Betting',
  'Modern Portfolio Approach',
  'On-Line Portfolio Selection with Moving Average Reversion',
  'Universal Portfolio'
)


# Script Imports ------
## Python Sourcing
use_python("C:\\Users\\maxem\\anaconda3\\envs\\esgdashboard\\python.exe")
source_python(file = 'Functions/Sentiment.py')
source_python(file = 'Functions/MonteCarloPortfolio.py')
source_python(file = 'Functions/PortfolioAnalyse.py')
source_python(file = 'Functions/RoboAdvisory.py')

## Source functions (R)
source(file = 'Functions/portfolio_backtesting.R')
source(file = 'Functions/portfolio_optimisation.R')



##
# UI ------
ui <- dashboardPage(
  skin = "black",
  
  dashboardHeader(title = "ESG Dashboard",
                  titleWidth = 240),
  
  ## Sidebar Definition --------
  dashboardSidebar(
    width = 240,
    sidebarMenu(
      id = "sbMenu",
      
      menuItem(
        text = "Security Analysis",
        tabName = "SingleStock",
        icon = icon("dashboard")
      ),
      
      menuItem(
        text = "Portfolio Analysis",
        tabName = "PortfolioSelect",
        icon = icon("cog"),
        menuSubItem(
          text = "Descriptives",
          tabName = "des",
          icon = icon('bar-chart')
        ),
        menuSubItem(
          text = "Optimisation",
          tabName = "opt",
          icon = icon('angle-double-right')
        ),
        menuSubItem(
          text = "Portfolio & Stock Performance",
          tabName = "analytics",
          icon = icon('line-chart')
        )
      ),
      
      menuItem(
        text = "Auxilliary Tools",
        tabName = "aux",
        icon = icon("th"),
        menuSubItem(
          text = "Factor Regression",
          tabName = "factor",
          icon = icon('calculator')
        ),
        menuSubItem(
          text = "Robo Advisory",
          tabName = "robo",
          icon = icon('robot')
        )
      )
      
      
    )
  ),
  ## Body Code -------
  dashboardBody(
    includeCSS("www/stylesheet.css"),
    
    
    tabItems(
      ### 1. Component : Simple Stock Analysis  --------
      
      
      tabItem(
        tabName = "SingleStock",
        
        fluidRow(
          box(
            width = 4,
            title = 'Individual Stock Anlaysis',
            selectInput(
              inputId = "Stock",
              label = 'Please Search for a Stock',
              choices = symbol_df$display,
              multiple = F,
              selected = 'TSLA - Tesla Inc'
            ),
            
            dateRangeInput(
              'Date',
              label = "Select the Range",
              start = lubridate::today() - 90,
              end = lubridate::today()
            ),
            
            h5(htmlOutput('textcp')),
            br(),
            
            submitButton("Submit", icon("refresh")),
            br(),
            plotlyOutput("pricechart")
            
          ),
          
          tabBox(
            width = 4,
            
            
            tabPanel(
              title = 'ESG Score and Ranking',
              br(),
              h4('Score'),
              
              DT::dataTableOutput("tablet1esg"),
              br(),
              'The scores range from 0 (worst) to 100 (best).',
              
              br(),
              
              h4('Ranking'),
              
              br(),
              
              DT::dataTableOutput('tablet1esgrank'),
              'Ranks range from 1 (best) up to 2300 (worst). The # denotes the rank for the corresponding variable. The industy rank is computed for the broader industry definition. The buisness rank for the specific business sector. To learn more, please look at the ESG Data Panel.'
              
              
            ),
            
            tabPanel(title = "ESG History",
                     br(),
                     plotlyOutput("esgHist"))
            
            
            
          ),
          
          tabBox(
            width = 4,
            tabPanel(
              title = 'Bollinger Bands',
              numericInput(
                inputId = 'nBband',
                label = 'Freq of Bollinger Bands ',
                value = 5,
                min = 1,
                max = 50,
                step = 1
                
              ),
              helpText(
                'The bands charachterize the prices and volatility over time of a financial instrument
                   using a formulaic method propounded by John Bollinger in the 1980s. Financial traders
                   employ these charts as a methodical tool to inform trading decisions, control automated
                   trading systems, or as a component of technical analysis. Bollinger Bands display a
                   graphical band (the envelope maximum and minimum of moving averages). Strategies, that can be deducted visually, can either
                                   include going long when the long term MA slows down, or going short with the market.'
              )
            ),
            tabPanel(
              title = 'EMA',
              numericInput(
                inputId = 'nEma',
                label = 'Freq of Exponential Moving Averages',
                value = 20,
                min = 1,
                max = 50,
                step = 1
              ),
              helpText(
                'An exponential moving average (EMA) is a type of moving average (MA) that places a greater
          weight and significance on the most recent data points. The exponential moving average is also
          referred to as the exponentially weighted moving average. An exponentially weighted moving
          average reacts more significantly to recent price changes than a simple moving average (SMA),
          which applies an equal weight to all observations in the period.'
              )
            ),
            tabPanel(
              title = 'MACD',
              numericInput(
                inputId = 'macdslow',
                label = 'Slow MA component',
                value = 12 ,
                min = 1,
                max = 100,
                step = 1
                
              ),
              numericInput(
                inputId = 'macdfast',
                label = 'Fast MA Component',
                value = 26 ,
                min = 1,
                max = 100,
                step = 1
                
              ),
              helpText(
                'Moving average convergence divergence (MACD) is a trend-following momentum indicator
                   that shows the relationship between two moving averages of a security’s price. Moving
                   average convergence divergence (MACD) indicators can be
                   interpreted in several ways, but the more common methods are crossovers, divergences,
                   and rapid rises/falls.'
              )
            ),
            tabPanel(
              title = 'Relative Strength Index (RSI)',
              numericInput(
                inputId = 'nrsi',
                label = 'Freq of Periods',
                value = 14,
                min = 1,
                max = 28,
                step = 1
                
              ),
              helpText(
                'The relative strength index (RSI) is a momentum indicator used in technical analysis
                     that measures the magnitude of recent price changes to evaluate the condition of
                     being overbought or oversold. The RSI is displayed as an oscillator and can lie in 0
                     to 100. The indicator was originally developed by J. Welles Wilder Jr. Traditionally
                     the RSI values of 70 or above indicate that a security is becoming overbought or
                     overvalued and may be primed for a trend reversal or corrective pullback in price. An
                     RSI reading of 30 or below indicates an oversold or undervalued condition.'
              )
            )
          )
        ),
        # Overview of Company Table
        
        fluidRow(
          tabBox(
            width = 12,
            
            tabPanel('Stock Chart & Analytics',
                     plotlyOutput("plot1"), ),
            
            tabPanel(
              'Company Overview',
              'Company Fundamental Data',
              DT::dataTableOutput("tablet1o")
            ),
            tabPanel(
              'ESG Ranking Data',
              'Overview of the available ESG Ranking Data for all companies in our database so far.',
              DT::dataTableOutput("tablet1esgranktot")
            ),
            tabPanel(
              title = 'ESG Peer Analysis',
              'Here You can find the ESG scores for the respective peers',
              DT::dataTableOutput('tablet1peers')
              
            ),
            tabPanel(
              'ESG Measure Data',
              'Overview of the available Measures taken by the company in terms of all ESG components.',
              DT::dataTableOutput("tablet1esgmeasures")
            )
            ,
            tabPanel(
              'Balance Sheet',
              
              'Balance Sheets Quarterly',
              
              DT::dataTableOutput("tablet1b")
            ),
            
            tabPanel(
              'Cash Flow Statement',
              'Cash Flow Statement',
              DT::dataTableOutput("tablet1c"),
            ),
            
            tabPanel(title = 'Income Statement',
                     DT::dataTableOutput("tablet1i")),
            
            tabPanel(title = 'News and Sentiment',
                     h5(htmlOutput('textsent')),
                     DT::dataTableOutput("tablet1news"))
            
          ),
          
        ),
      ),
      
      ### 2. Component : Portfolio Selection -----
      
      tabItem(tabName = 'PortfolioSelect',
              
              fluidRow(
                box(
                  title = 'Portfolio Stock Anlaysis',
                  selectInput(
                    inputId = "StockPfold",
                    label = 'Selected Stocks for the Portfolio Construction',
                    choices = symbol_df$Symbol,
                    multiple = T
                  ),
                  
                  submitButton("Submit", icon("refresh"))
                )
              )),
      
      #### 2.1 Descriptive -----
      tabItem(
        tabName = "des",
        fluidRow(
          box(
            width = 4,
            title = "Stock Selection",
            selectInput(
              inputId = "StockPf",
              label = 'Selected Stocks for the Portfolio Construction',
              choices = symbol_df$Symbol,
              multiple = T,
              selected = c('AMZN', 'AAPL', 'NFLX')
            ),
            actionButton('reset', 'Reset', icon = icon('trash')),
            
            dateRangeInput(
              'Date2',
              label = "Select the Range",
              start = lubridate::today() - 720,
              end = lubridate::today()
            ),
            
            submitButton("Submit", icon("refresh"))
            
          ),
          
          box(width = 8,
              title = "Weighting Scheme",
              DT::DTOutput("weight1"))
        ),
        
        fluidRow(
          # box(
          #   DTOutput("weight2")
          # ), # for sanity checks only
          valueBoxOutput("box1", width = 4),
          valueBoxOutput("box2", width = 4),
          valueBoxOutput("box3", width = 4)
        ),
        fluidRow(
          box(
            width = 4,
            title = "Backtesting & Multiple Portfolio Selection",
            selectInput(
              inputId = "StockPf1",
              label = 'Selected Stocks for Portfolio 1',
              choices = symbol_df$Symbol,
              multiple = T,
              selected = c('AAPL', 'GOOGL', 'TSLA')
            ),
            selectInput(
              inputId = "StockPf2",
              label = 'Selected Stocks for Portfolio 2',
              choices = symbol_df$Symbol,
              multiple = T,
              selected = c('AAPL', 'TSLA')
            ),
            selectInput(
              inputId = "StockPf3",
              label = 'Selected Stocks for Portfolio 3',
              choices = symbol_df$Symbol,
              multiple = T,
              selected = c('AAPL', 'GOOGL')
            ),
            selectInput(
              inputId = "StockPf4",
              label = 'Selected Stocks for Portfolio 4',
              choices = symbol_df$Symbol,
              multiple = T,
              selected = c('AAPL', 'TSLA', 'MMM')
            ),
            
            actionButton('reset1', 'Reset', icon = icon('trash')),
            numericInput(
              'invest',
              'Initial Investment: ',
              value = 10000,
              min = 0
            ),
            
            dateRangeInput(
              'Date3',
              label = "Select the Range",
              start = lubridate::today() - 720,
              end = lubridate::today()
            ),
            
            submitButton("Submit", icon("refresh"))
            
          ),
          box(
            width = 8,
            title = "Weighting Scheme",
            DT::DTOutput("weightMult")
          )
          
          
        ),
        fluidRow(
          box(width = 4,
              title = "ESG-Portfolio Scores",
              plotlyOutput('esgPlot')),
          box(width = 8,
              title = "Visualisation of Portfolio Performances",
              plotlyOutput('backtest'))
        )
        
      ),
      
      
      
      #### 2.3 Performance Measures -----
      
      tabItem(tabName = 'analytics',
              fluidRow(box(
                column(
                  3,
                  
                  selectInput(
                    inputId = "AnalyticsStocks",
                    label = 'Selected Stocks for the Portfolio that you want to analyse',
                    choices = symbol_df$Symbol,
                    multiple = T,
                    selected = c('AAPL', 'TSLA', 'SAP')
                  )
                ),
                column(
                  3,
                  
                  dateRangeInput(
                    'AnalyticsDate',
                    label = "Select the Range for the Period that you want to analyse.",
                    start = lubridate::today() - 90,
                    end = lubridate::today()
                  )
                ),
                column(
                  3,
                  
                  sliderInput(
                    inputId = 'AnalyticsRfrate',
                    label = 'Risk Free Rate',
                    value = 0.007,
                    # This is the rf-rate at the current point in time
                    min = 0,
                    max = 1,
                    step = 0.001
                  )
                ),
                column(
                  3,
                  
                  textInput(
                    'AnalyticsShares',
                    'Enter the number of Shares (comma delimited)',
                    "1,2,1"
                  ),
                  #textInput('AnalyticsPrices', 'Enter the Prices of the Shares (comma delimited)', "69,420,133"),
                  submitButton("Submit", icon("refresh"))
                )
              )),
              
              fluidRow(
                box(
                  title = 'Portfolios Stock Analysis',
                  width = 12,
                  plotlyOutput('AnalysisStocks'),
                  br(),
                  'The Sortino Ratio is a modification of the Sharpe ratio but penalizes
          only those returns falling below a user-specified target or required
          rate of return, while the Sharpe ratio penalizes both upside and downside
          volatility equally. The Sortino ratio is used as a way to compare the
          risk-adjusted performance of programs with differing risk and return
          profiles. In general, risk-adjusted returns seek to normalize the risk
          across programs and then see which has the higher return unit per risk
          The Calmar ratio uses a slightly modified Sterling ratio -
          average annual rate of return for the last 36 months divided by the maximum
          drawdown for the last 36 months - and calculates it on a monthly basis,
          instead of the Sterling ratios yearly basis'
                )
              ),
              fluidRow(
                box(
                  title = 'Portfolio Analysis',
                  width = 12,
                  plotlyOutput('AnalysisPortfolio'),
                  br(),
                  'The Sortino Ratio is a modification of the Sharpe ratio but penalizes
          only those returns falling below a user-specified target or required
          rate of return, while the Sharpe ratio penalizes both upside and downside
          volatility equally. The Sortino ratio is used as a way to compare the
          risk-adjusted performance of programs with differing risk and return
          profiles. In general, risk-adjusted returns seek to normalize the risk
          across programs and then see which has the higher return unit per risk
          The Calmar ratio uses a slightly modified Sterling ratio -
          average annual rate of return for the last 36 months divided by the maximum
          drawdown for the last 36 months - and calculates it on a monthly basis,
          instead of the Sterling ratios yearly basis'
                )
              )),
      
      #### 2.2 Optimization ----
      tabItem(
        tabName = 'opt',
        fluidRow(
          box(
            width = 3,
            height = "60vh",
            title = "Portfolio Optimisation",
            selectInput(
              inputId = "StockOpt",
              label = 'Selected Stocks for Optimisation',
              choices = symbol_df_ESG$Symbol,
              multiple = T,
              selected = c('AAPL', 'GOOGL', 'TSLA', 'MMM')
              
            ),
            dateRangeInput(
              'Date4',
              label = "Select the Range",
              start = lubridate::today() - 360,
              end = lubridate::today()
            ),
            sliderInput(
              "sim",
              label = "Number of simulated Portfolios",
              min = 100,
              max = 50000,
              value = 5000
            ),
            selectInput(
              "mapping",
              label = "Choose mapping",
              choices = colnames(opt_measures[,-c(1, 2, 52)])
            ),
            materialSwitch(
              "minmaxswitch",
              label = "Max/Min (default = Max)",
              right = T,
              status = "primary",
              value = T
            ),
            
            sliderInput(
              inputId = 'riskfree',
              label = 'Risk Free Rate',
              value = 0.007,
              # This is the rf-rate at the current point in time
              min = 0,
              max = 1,
              step = 0.001
            ),
            submitButton("Submit", icon("refresh"))
            
            
            
          ),
          box(
            width = 3,
            height = "60vh",
            plotlyOutput('pie1'),
            tableOutput("pie1table")
            
            
          ),
          box(
            width = 3,
            height = "60vh",
            plotlyOutput('pie2'),
            tableOutput("pie2table")
            
          ),
          box(
            width = 3,
            height = "60vh",
            plotlyOutput('pie3'),
            tableOutput("pie3table")
            
          )
          
        ),
        fluidRow(
          valueBoxOutput("box4", width = 4),
          valueBoxOutput("box5", width = 4),
          valueBoxOutput("box6", width = 4)
          
        ),
        fluidRow(
          box(width = 8,
              title = "Mean-Variance Frontier: the Markowitz Bullet",
              plotlyOutput("markov"))
        )
      ),
      
      ### 3.1 Component Factor Regression -----
      
      tabItem(tabName = "factor",
              tabsetPanel(
                tabPanel("Asset Factor Regression",
                         fluidRow(
                           box(
                             width = 4,
                             title = "Asset Selection",
                             selectInput(
                               inputId = "assetSel1",
                               label = 'Selected Stocks ',
                               choices = symbol_df_ESG$Symbol,
                               multiple = T,
                               selected = c('AAPL', 'GOOGL', 'TSLA', 'MMM')
                             ),
                             dateRangeInput(
                               'Date5',
                               label = "Select the Range",
                               start = lubridate::today() - 720,
                               end = lubridate::today()
                             ),
                             br(),
                             radioButtons(
                               'choose',
                               label = "Modelling Basis",
                               choices = names(modelChoice),
                               selected = "Fama-French 5 Factor"
                             ),
                             uiOutput('fact'),
                             submitButton("Estimate Model")
                             # multiInput('factors',
                             #            label = "Select Factors",
                             #            choices = colnames(ffFac))
                             
                           )
                           
                           
                           
                           ,
                           box(width = 8,
                               title = "Regression Output",
                               DT::DTOutput('assetreg'))
                         )),
                tabPanel(
                  "Portfolio Factor Regression",
                  fluidRow(
                    box(
                      width = 4,
                      title = "Stock Selection",
                      selectInput(
                        inputId = "assetSel2",
                        label = 'Selected Stocks for the Portfolio Construction',
                        choices = symbol_df_ESG$Symbol,
                        multiple = T,
                        selected = c('AAPL', 'TSLA', 'MMM')
                      ),
                      dateRangeInput(
                        'Date6',
                        label = "Select the Range",
                        start = lubridate::today() - 720,
                        end = lubridate::today()
                      ),
                      br(),
                      radioButtons(
                        'choose2',
                        label = "Modelling Basis",
                        choices = names(modelChoice),
                        selected = "Fama-French 5 Factor"
                      ),
                      uiOutput('fact2'),
                      submitButton("Estimate Model")
                      
                    ),
                    
                    box(width = 8,
                        title = "Weighting Scheme",
                        DT::DTOutput("weight3"))
                  ),
                  fluidRow(box(
                    width = 12,
                    title = "Regression Output",
                    DT::DTOutput("assetreg2")
                  ))
                )
                
              )),
      ## 3.2 Robo Advisory -----------
      
      tabItem(tabName = 'robo',
              fluidRow(
                box(
                  width = 2,
                  title = "Asset Selection",
                  selectInput(
                    inputId = "RoboAssets",
                    label = 'Selected Stocks',
                    choices = symbol_df$Symbol,
                    multiple = T,
                    selected = c('AAPL', 'GOOGL', 'TSLA', 'SAP')
                  ),
                  dateRangeInput(
                    inputId = 'RoboDate',
                    label = "Select the Start Date",
                    start = lubridate::today() - 720,
                    end = lubridate::today()
                  ),
                  
                  numericInput(
                    inputId = 'RoboFees',
                    label = 'Assumed Fees in %',
                    value = 0.01,
                    min = 0,
                    max = 1
                  ),
                  
                  selectInput(
                    inputId = 'RoboAdjustment',
                    label = 'Adjustment Per Day/Week/Month',
                    choices = c('Daily', 'Weekly', 'Monthly'),
                    selected = 'Weekly',
                    multiple = F
                  ),
                  
                  selectInput(
                    inputId = "Strategy",
                    label = 'Selected Investment Strategy',
                    choices = Strategies,
                    multiple = F
                  ),
                  submitButton("Robo Advise!", icon("robot"))
                ),
                
                box(
                  title = 'Strategy Analytics',
                  width = 3,
                  'Key Results from the Chosen Strategy.
                  Results can be obtained from the Summary underneath.',
                  htmlOutput('RoboSummary')
                ),
                
                tabBox(
                  width = 7,
                  tabPanel(title = 'Weights and Return Plot',
                           plotlyOutput('RoboPlot')),
                  tabPanel(title = 'Weights Table',
                           DT::dataTableOutput("RoboWeights"))
                )
              ),
              
              fluidRow(
                tabBox(
                  width = 12,
                  
                  tabPanel(
                    title = 'Buy and Hold',
                    'Buy and hold strategy: Buy an equal amount of each stock in
                    the beginning and hold them long.',
                    numericInput(
                      inputId = 'RoboBetandHold',
                      label = 'Amount of Stocks to Buy',
                      value = 2,
                      min = 1
                    ),
                    submitButton("Update Params", icon("robot"))
                  ),
                  
                  tabPanel(
                    title = 'Dynamic Rebalancing Portfolio',
                    'Dynamic Rebalancing Portfolio uses log price growth of
                    stocks to add more positions in a portfolio if a stock is
                    growing. It is often used as a benchmark with the Constant
                    Rebalancing Portfolio.',
                    numericInput(
                      inputId = 'RoboDCRPn',
                      label = 'Adjustment Period',
                      value = 252,
                      min = 1
                    ),
                    submitButton("Update Params", icon("robot"))
                  ),
                  tabPanel(
                    title = 'Modern Portfolio Approach',
                    
                    fluidRow(
                      column(
                        12,
                        'Modern portfolio theory approach: Modern portfolio theory (MPT),
                        or mean-variance analysis, is a mathematical framework for
                        assembling a portfolio of assets such that the expected return
                        is maximized for a given level of risk. It is a formalization and
                        extension of diversification in investing, the idea that
                        owning different kinds of financial assets is less risky
                        than owning only one type. Its key insight is that an
                        assets risk and return should not be assessed by itself,
                        but by how it contributes to a portfolios overall risk and return.'
                      )
                    ),
                    
                    fluidRow(
                      column(
                        3,
                        
                        numericInput(
                          inputId = 'RoboMPTWindow',
                          label = 'Window',
                          value = 52,
                          min = 1
                        ),
                        selectInput(
                          inputId = 'RoboMPTMu',
                          label = 'Expected Return Specification',
                          choices = c('historical', 'sharpe'),
                          selected = c('sharpe') ,
                          multiple = F
                        ),
                        selectInput(
                          inputId = 'RoboMPTCov',
                          label = 'Covariance Specification',
                          choices = c('empirical', 'ledoit-wolf', 'oas', 'single-index'),
                          selected = 'empirical',
                          multiple = F
                        )
                      ),
                      
                      column(
                        3,
                        
                        numericInput(
                          inputId = 'RoboMPTMuWindow',
                          label = 'Window for the Expected Return',
                          value = 30
                        ),
                        numericInput(
                          inputId = 'RoboMPTCovWindow',
                          label = 'Window for the Covariance',
                          value = 30
                        ),
                        numericInput(
                          inputId = 'RoboMPTMinHistory',
                          label = 'Minimal Histroy',
                          value = 5
                        )
                      ),
                      
                      column(
                        3,
                        numericInput(
                          inputId = 'RoboMPTq',
                          label = 'Risk Aversion Coefficient that balances the Cov.',
                          value = 0.01
                        ),
                        
                        numericInput(
                          inputId = 'RoboMPTLeverage',
                          label = 'Max Leverage',
                          value = 1,
                          min = 0,
                          max = 1
                        ),
                        selectInput(
                          inputId = 'RoboMPTMethod',
                          label = 'Optimization Objective - MPT',
                          choices = c("mpt"),
                          selected = 'mpt',
                          multiple = F
                        )
                      ),
                      
                      column(
                        3,
                        
                        numericInput(
                          inputId = 'RoboMPTgamma',
                          label = 'Penalize changing weights (e.g. to take Fees into account)',
                          value = 0.01
                        ),
                        submitButton("Update Params", icon("robot"))
                      )
                    )
                    
                  ),
                  tabPanel(
                    title = 'OLMAR',
                    'On-Line Portfolio Selection with Moving Average Reversion.
                    Empirical evidence show that stock’s high and low prices are
                    temporary and stock price relatives are likely to follow the
                    moving Average reversion (MAR) phenomenon. OLMAR, which exploits MAR by
                    applying powerful online learning techniques.',
                    numericInput(
                      inputId = 'RoboOLMARWindow',
                      label = 'Select the Window for the Period in Interest. Per default 5.',
                      value = 5,
                      min = 2
                    ),
                    numericInput(
                      inputId = 'RoboOLMAREps',
                      label = 'Constraint on return for new weights on last price',
                      value = 10,
                      min = 1
                    ),
                    submitButton("Update Params", icon("robot"))
                  ),
                  tabPanel(
                    title = 'Universal Portfolio',
                    'Universal Portfolio by Thomas Cover enhanced for "leverage" (instead of just taking weights from a simplex, leverage allows us to stretch simplex to contain negative positions)',
                    numericInput(
                      inputId = 'RoboUPEEval',
                      label = 'Number of evaluated points (approximately)',
                      value = 10000
                    ),
                    numericInput(
                      inputId = 'RoboUPLeverage',
                      label = 'Maximum leverage used. If > 1, we can short.',
                      value = 1
                    ),
                    submitButton("Update Params", icon("robot"))
                  )
                  #,tabPanel(title = 'Kelly Betting')
                )
                
                
                
              ))
    )
    ## Controll Bar Definition ---------------
  ),
  controlbar = dashboardControlbar(
    includeCSS("www/stylesheet.css"),
    id = "control",
    width = 460,
    fluidPage(
      verticalLayout(
        h1("How to use this App"),
        hr(),
        br(),
        p("Short Introduction of what this app is about blaaaa"),
        h2("1. Security Analysis"),
        p(
          'This Section allows the User to analyse a stock of his or her choice. The user can analyse the
          stocks ESG Score, the ranking, and the ESG History Data of the Company, if the data is available. 
          Furthermore, the user can track the recent history of the securities price and all of its publicly
          available accounting data, including the balance sheet, the income statement and the cash flow
          statement. In addition to that, the user can also plot quantiative trade measures indicating the
          boilinger bands, the RSI and EMA.'
        ),
        hr(),
        h2("2. Portfolio Analysis"),
        hr(),
        p(
          "This section is devoted to providing an extensive range of tools to assess a portfolio's performance. The ",
          strong("Descriptives"),
          "-section allows for single or multiple portfolio assessment with the possibility
                                       to deploy a ",
          strong("Backtesting"),
          "-analysis. The section on ",
          strong("Optimisation"),
          " uses
                                       Monte-Carlo sampling techniques (",
          a(href = "https://en.wikipedia.org/wiki/Monte_Carlo_method", "Wiki"),
          ") to optimise
                                       for a given set of assets the weighting scheme within a portfolio that seeks to meet a criterion as specified by the user.
                                       The last section on ",
          strong("Portfolio & Stock Performance"),
          "provides performance infromation measures for each stock in the portfolio as
                                       well as a unified Performance measure for a Portfolio."
        ),
        h3("2.1 Descriptives"),
        p(
          "The first row retrieves information on key portfolio performance metrics (Sharpe-Ratio, annualised Return and
                                     average ESG-Score for the respective period) in accordance with user-specified stocks, weights and period range. The row underneath
                                       does the same while allowing for a comparison of up to 4 portfolios simultaneuosly. Adding an initial amount of \"had been\"
                                       investment allows to simulate a hypothetical long-only position on these assets in a retrospective manner for the relevant period."
        ),
        code(id = "porty", "Manual:"),
        p(
          "Search for desired stocks and confirm selection by hitting ",
          code("Enter"),
          " , exit selection-bar and click \"Submit\". A Table with
                                       uniformly distributed inital weights will show up to the right. Click onto a cell in the ",
          em("Weighting"),
          "-column
                                       to modify the weights. Do so",
          strong("in any case"),
          " even if you do not wish to change the weights and hit ",
          code("Ctrl"),
          " + ",
          code("Enter"),
          " to submit changes to the data table. Finally hit \"Submit\" once more to process the query.
                                       The \"Reset\"-button allows to clear the defaults or to start from scratch and requires a hit on \"Submit\" as well.
                                       The ",
          strong("Backtesting"),
          " row works analogously."
        ),
        p(
          "Use ",
          code("Del"),
          " or ",
          code("Backspace"),
          " to remove assets from selection."
        ),
        p(
          "After each change of input make sure the weights still sum to 1 or meet your weighting criteria."
        ),
        h3("2.2 Optimisation"),
        p(
          "This subsection offers insights to which extent an optimised portfolio must comprise assets from a pre-defined selection of firms.
                                     Depending on an investor's preferences and intentions different compositions of assets can become optimal. This tool helps allocating
                                     the right share of an investment to the right asset while accounting for investor needs. It prompts the weighting schemes that correspond to
                                     a chosen mapping, i.e. the share of each portfolio constituent for the least volatile portfolio, the highest risk-adjusted return (SR) portfolio
                                     as well as for a portfolio optimised subject to the mapping chosen by the user. The sampling method allows to display the portfolio compositions
                                     spanned in a mean-variance space known as the ",
          a(href = "", "\"Markowitz Bullet\""),
          "."
        ),
        p(
          "The items available as mapping variables are collected from Reuters Refinitv. An extensive documentation can be found
                                        in ",
          a(href = "https://www.refinitiv.com/content/dam/marketing/en_us/documents/methodology/refinitiv-esg-scores-methodology.pdf", "Refinitiv's Methodology Brochure"),
          "."
        ),
        
        code("Manual:"),
        p(
          "Search for desired stocks and confirm selection by hitting ",
          code("Enter"),
          " , exit selection-bar and choose the
                                       period of interest serving as the basis for computations. Choose a desired mapping, such as ",
          em("ESG-Score"),
          "
                                        and decide whether the chosen factor needs to be minimised or maximised then hit \"Submit\"."
        ),
        p(
          "Use ",
          code("Del"),
          " or ",
          code("Backspace"),
          " to remove assets from selection."
        ),
        h3("2.3 Portfolio & Stock Performance"),
        p(
          "The user can find return characterisitcs for a Portfolio and the individual stocks in the Porfolio. The
                                       metrics include the sharpe ratio, the mean return, the calmar ratio and the sortino ratio. Additionally, the
                                       user can determine the length of drawdowns of the portfolio and determine the variance of the portfolio. The
                                       app should support the user with identifying paterns in the potfolio that are determine by single stocks."
        ),
        h2("3. Auxilliary Tools"),
        hr(),
        p("blaaablaaa"),
        h3("3.1 Factor Regression"),
        p(
          "This section covers topics that require a more sound understanding of Finance. In asset pricing theory the underlying tenets
                                     ask for few inital requirements to hold in order for a metric to be considered a viable factor: Does the metric enter the subjective
                                     discount factor (SDF) in a reasonable manner? If so, the factor is able to explain variation in a firm's sensitivity to systematic risk.
                                     Prominent factor asset-pricing models are the ",
          a(href = "https://en.wikipedia.org/wiki/Fama%E2%80%93French_three-factor_model", "Fama-French 3 and 5 Factor Model"),
          "
                                      which can be modelled here. As the factors themselves are returns one can use a Time-Series-Regression to assess the model.
                                      We provide both modelling-realms - the 5 and the 3 factor specifications. Using other kinds and self-devised factors will be
                                      possible in a while. An interpretation guide for the factor loadings can be found ",
          a(href = "http://www.efficientfrontier.com/ef/101/roll101.htm", "here"),
          "."
        ),
        p(
          "The second tab allows such modelling for a priorly defined portfolio (see ",
          a(href = "#porty", "above"),
          ")."
        ),
        code("Manual:"),
        p(
          "Search for desired stocks and confirm selection by hitting ",
          code("Enter"),
          " , exit selection-bar and choose the
                                       period of interest serving as the basis for computations. Switch between the \"Modelling Basis\" (Own Model not working yet)
                                       and pick factors as desired. Remove by clicking selection on right hand side. Hit \"Estimate Model\" to run regression. Default Model is the CAPM in each case,
                                       i.e. the factor pre-selected is the \"market premium\"."
        ),
        h3("3.2 Robo Advisory"),
        p(
          "Here, You can set a investment strategy and let machine learning invest in fictious portfolios. Many different options prevail. However, this is no guideline to become rich. Be aware of the survivorship bias!"
        )
        
        
      )
    )
    
  )
  
)


# Server -----
server <- function(input, output, session) {
  ## First Component Server Functionality  -----
  
  # Todo: Add more interactions with the technical indicators
  # Todo:
  data = eventReactive({
    input$Stock
    input$Date
    input$nBband
    input$nEma
    input$macdfast
    input$macdslow
    input$nrsi
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    get = GET(
      "https://www.alphavantage.co/query",
      query = list(
        'function' = 'TIME_SERIES_DAILY',
        'symbol' = stock,
        'outputsize' = 'full',
        'datatype' = 'csv',
        'apikey' = 'TCRIWPYVQSEGVAMH' # RGXIZHML0G88KXLV or TCRIWPYVQSEGVAMH
      )
    ) %>%
      content(type = "text/csv") %>%
      mutate(direction = ifelse(close >= open, 'Increasing', 'Decreasing'))
    
    get$timestamp = ymd(get$timestamp)
    
    get = get %>% arrange(timestamp)
    
    bands = BBands(get[, c("high", "low", "close")], sd = 2, n = input$nBband)
    
    ## typically 20 but we can also make that adjustive
    ema = EMA(get[, c('close')], n = input$nEma)
    
    macd = as.data.frame(MACD(
      get$close,
      nFast = input$macdfast,
      nSlow = input$macdslow
    )) %>%
      mutate(difference = macd - signal)
    
    rsi = RSI(get$close, n = input$nrsi)
    
    data = as.data.frame(cbind(get, bands, ema, macd, rsi)) %>%
      mutate(macd_difference = ifelse(difference > 0, 'Positive', 'Negative'))
    
    ## lets compute the time dplyr::filter at the end to preserve the observations
    ## for the computation of the technical indicators
    
    data %>% dplyr::filter(timestamp > input$Date[1], timestamp < input$Date[2])
  })
  
  output$pricechart <- renderPlotly({
    data = data()
    data %>% plot_ly(
      x =  ~ timestamp,
      y =  ~ close,
      type = "scatter",
      mode = "lines+markers"
    ) %>%
      layout(
        title = "Daily Closing Prices",
        height = 250,
        yaxis = list(title = "Price in $"),
        xaxis = list(title = "")
      )
  })
  # First Plot
  output$plot1 <- renderPlotly({
    # Lest just make 1 Call per plot instead n - Decreases runtime tremendously
    
    #data = data()
    
    # plot candlestick chart
    bp = data %>%
      plot_ly(
        x = ~ timestamp,
        type = "candlestick",
        open = ~ open,
        close = ~ close,
        high = ~ high,
        low = ~ low,
        name = paste(input$Stock, 'Candlesticks')
      ) %>%
      add_lines(
        x = ~ timestamp,
        y = ~ up ,
        name = "BB Bands",
        line = list(color = '#EF553B', width = 1),
        legendgroup = "Bollinger Bands",
        hoverinfo = "none",
        inherit = F
      ) %>%
      add_lines(
        x = ~ timestamp,
        y = ~ dn,
        name = "BB Bands",
        line = list(color = '#636EFA', width = 1),
        legendgroup = "Bollinger Bands",
        inherit = F,
        showlegend = FALSE,
        hoverinfo = "none"
      ) %>%
      add_lines(
        x = ~ timestamp,
        y = ~ ema,
        name = "EMA",
        line = list(color = '#E377C2', width = 1),
        hoverinfo = "none",
        inherit = F
      ) %>%
      layout(yaxis = list(title = paste(input$Stock), "Stock"),
             xaxis = list(rangeslider = list(visible = F)))
    
    vp = data %>%
      plot_ly(
        x =  ~ timestamp,
        y =  ~ volume,
        type = 'bar',
        name = " Volume",
        color = ~ direction,
        colors = c('#17BECF', '#7F7F7F')
      ) %>%
      layout(yaxis = list(title = "Volume"),
             xaxis = list(title = ""))
    
    
    macdp = data %>%
      plot_ly(
        x =  ~ timestamp,
        y =  ~ difference,
        type = 'bar',
        name = 'Difference',
        color = ~ macd_difference,
        colors = c('#D62728', '#2CA02C')
      ) %>%
      add_lines(
        x = ~ timestamp,
        y = ~ signal,
        name = "Signal",
        line = list(color = '#1F77B4', width = 1),
        inherit = F
      ) %>%
      add_lines(
        x = ~ timestamp,
        y = ~ macd,
        name = "MACD",
        line = list(color = '#FF7E07', width = 1),
        inherit = F
      ) %>%
      layout(yaxis = list(title = "MACD"),
             xaxis = list(title = ""))
    
    
    
    rsip = data %>%
      plot_ly(
        x =  ~ timestamp,
        y =  ~ rsi,
        name = "RSI",
        type = 'scatter',
        mode = 'lines',
        line = list(color = '#1F77B4', width = 1)
      ) %>%
      add_lines(
        y = 70,
        name = 'Indic. Overbought',
        x = ~ timestamp,
        line = list(color = '#D62728', width = 1),
        inherit = F
      ) %>%
      add_lines(
        y = 30,
        name = 'Indic. Oversold',
        x = ~ timestamp,
        line = list(color = '#2CA02C', width = 1),
        inherit = F
      ) %>%
      layout(yaxis = list(title = "RSI"),
             xaxis = list(title = ""))
    
    
    rs = list(
      visible = TRUE,
      x = 0.5,
      y = -0.055,
      xanchor = 'center',
      yref = 'paper',
      font = list(size = 9),
      buttons = list(
        list(
          count = 1,
          label = 'RESET',
          step = 'all'
        ),
        list(
          count = 1,
          label = '1 YR',
          step = 'year',
          stepmode = 'backward'
        ),
        list(
          count = 3,
          label = '3 MO',
          step = 'month',
          stepmode = 'backward'
        ),
        list(
          count = 1,
          label = '1 MO',
          step = 'month',
          stepmode = 'backward'
        )
      )
    )
    
    fig = subplot(
      bp,
      vp,
      rsip,
      macdp,
      nrows = 4,
      shareX = T,
      titleY = T,
      heights = c(0.4, 0.2, 0.2, 0.2)
    ) %>% layout(height = 600)
    
    fig
  })
  
  
  
  
  # MACD Plot
  
  ## First component Second Part Company Overview
  
  data2 = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    get = GET(
      "https://www.alphavantage.co/query",
      query = list(
        'function' = 'OVERVIEW',
        'symbol' = stock,
        'datatype' = 'csv',
        'apikey' = 'TCRIWPYVQSEGVAMH'
      )
    ) %>% content(as = 'parsed') %>% bind_rows()
    
    get = as.data.frame(t(get))
    
    colnames(get) = 'Fundamental Stock Overview'
    
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    rownames(get) = stri_trans_totitle(rownames(get))
    
    get
  })
  output$tablet1o = DT::renderDataTable({
    datatable(data2())
  })
  
  data3 = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    get = GET(
      "https://www.alphavantage.co/query",
      query = list(
        'function' = 'BALANCE_SHEET',
        'symbol' = stock,
        'datatype' = 'csv',
        'apikey' = 'TCRIWPYVQSEGVAMH'
      )
    ) %>% content(as = 'parsed')
    
    get = get$annualReports %>% bind_rows()
    
    
    get = as.data.frame(t(get))
    
    colnames(get) = as.character(unlist(get[1,]))
    
    
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    rownames(get) = stri_trans_totitle(rownames(get))
    
    get = get[2:nrow(get), 1:5]
    get
    
  })
  output$tablet1b = DT::renderDataTable({
    data3()
  })
  
  
  data4 = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    get = GET(
      "https://www.alphavantage.co/query",
      query = list(
        'function' = 'INCOME_STATEMENT',
        'symbol' = stock,
        'datatype' = 'csv',
        'apikey' = 'TCRIWPYVQSEGVAMH'
      )
    ) %>% content(as = 'parsed')
    
    get = get$annualReports %>% bind_rows()
    
    
    get = as.data.frame(t(get))
    
    colnames(get) = as.character(unlist(get[1,]))
    get = get[2:nrow(get), 1:5]
    
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    
    rownames(get) = stri_trans_totitle(rownames(get))
    
    get
  })
  output$tablet1i = DT::renderDataTable({
    datatable(data4(), style = 'bootstrap4', editable = 'all')
  }, options = list(scrollX = TRUE))
  
  
  data5 = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    get = GET(
      "https://www.alphavantage.co/query",
      query = list(
        'function' = 'CASH_FLOW',
        'symbol' = stock,
        'datatype' = 'csv',
        'apikey' = 'TCRIWPYVQSEGVAMH'
      )
    ) %>% content(as = 'parsed')
    
    get = get$annualReports %>% bind_rows()
    
    get = as.data.frame(t(get))
    colnames(get) = as.character(unlist(get[1,]))
    get = get[2:nrow(get), 1:5]
    
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    
    rownames(get) = str_replace(rownames(get),
                                pattern = "(?<=[a-z])(?=[A-Z])",
                                replacement = " ")
    
    rownames(get) = stri_trans_totitle(rownames(get))
    
    get
  })
  output$tablet1c = DT::renderDataTable({
    data5()
  })
  
  dataesg = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    dataesg = markets_esg %>% dplyr::filter(Symbol == stock) %>%
      select('Time', 'ESG-Score', 'E-Score', 'S-Score', 'G-Score')
    
    rownames(dataesg) =  dataesg$Time
    
    #dataesg$Time = NULL
    
    dataesg[,-1] = round(dataesg[,-1], 3)
    dataesg$Time = as.Date(dataesg$Time)
    
    dataesg
  })
  
  output$tablet1esg = DT::renderDataTable({
    dataesg()[,-1]
  }, options = list(pageLength = 1,
                    dom = 't'))
  output$esgHist <-
    renderPlotly({
      dataesg() %>% plot_ly(
        x =  ~ Time,
        y =  ~ `ESG-Score`,
        name = "ESG-Score",
        type = "scatter",
        mode = "lines+markers",
        fill = "tozeroy"
      ) %>%
        add_trace(
          y =  ~ `E-Score`,
          name = "E-Score",
          mode = "lines+markers",
          fill = "none"
        ) %>%
        add_trace(
          y =  ~ `S-Score`,
          name = "S-Score",
          mode = "lines+markers",
          fill = "none"
        ) %>%
        add_trace(
          y =  ~ `G-Score`,
          name = "G-Score",
          mode = "lines+markers",
          fill = "none"
        ) %>%
        layout(
          title = "Historic ESG Panel",
          yaxis = list(title = "Score"),
          yaxis = list(title = "Year")
        )
      
    })
  
  
  datapeers = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    peers = GET(
      "https://finnhub.io/api/v1/stock/peers?",
      query = list('symbol' = stock,
                   'token' = 'buei3fv48v6vcc71qak0')
    ) %>%
      content(as = 'parsed') %>% unlist()
    
    Round = function(x, k)
      if (is.numeric(x))
        round(x, k)
    else
      x
    
    
    raning_sorted = ranking %>%
      filter(Symbol %in% peers) %>%
      select(
        Time,
        Symbol,
        Company.Common.Name,
        ESG.Score,
        ESG.Rank,
        E.Score,
        E.Rank,
        S.Score,
        S.Rank,
        G.Score,
        G.Rank,
        TRBC.Business.Sector.Name,
        Business.Sector.Rank,
        TRBC.Industry.Group.Name,
        Industry.Sector.Rank,
        TRBC.Economic.Sector.Name,
        Economic.Sector.Rank
      )
    
    colnames(raning_sorted) = c(
      "Time",
      'Ticker',
      "Company Common Name",
      "ESG Score",
      "ESG Rank",
      "E Score",
      "E Rank",
      "S Score",
      "S Rank",
      "G Score",
      "G Rank",
      "Business Sector",
      "Business Sector Rank",
      "Industry Sector",
      "Industry Rank",
      "Economic Sector",
      "Economic Sector Rank"
    )
    
    replace(raning_sorted, TRUE, lapply(raning_sorted, Round, 3))
    
    
  })
  
  output$tablet1peers = DT::renderDataTable({
    datapeers()
  }, options = list(
    pageLength = 10,
    scrollX = TRUE,
    scrollY = TRUE
  ))
  
  
  datacurrent = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    get = GET(
      "https://www.alphavantage.co/query",
      query = list(
        'function' = 'TIME_SERIES_INTRADAY',
        'symbol' = stock,
        'size' = 'compact',
        'interval' = '60min',
        'datatype' = 'csv',
        'apikey' = 'TCRIWPYVQSEGVAMH'
      )
    ) %>% content(type = "text/csv")
    
    get1 = get[1, 1:6]
    get2 = get[17, 1:6]
    get1$timestamp = ymd_hms(get1$timestamp)
    get2$timestamp = ymd_hms(get2$timestamp)
    
    colnames(get1) = c('Time', "Open", "High", "Low", "Close", 'Volume')
    colnames(get2) = c('Time', "Open", "High", "Low", "Close", 'Volume')
    
    currentprice = get1$Close
    daybeforeprice = get2$Close
    
    if (currentprice >= daybeforeprice) {
      price <-
        paste(
          'The closing price as of ',
          as.Date(get1$Time),
          ' is <b style="color:MediumSeaGreen;">',
          currentprice,
          '$</b>',
          sep = ' '
        )
    } else {
      price <-
        paste(
          'The closing price as of ',
          as.Date(get1$Time),
          ' is <b style="color:Tomato;">',
          currentprice,
          '$</b>',
          sep = ' '
        )
    }
    
    price
  })
  
  ## Current Price Output
  
  output$textcp = renderText({
    datacurrent()
  })
  
  
  dataesgrank = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    company = ranking[ranking$Symbol == stock,]
    
    ranks = ranking %>%
      dplyr::filter(Symbol == stock) %>%
      select(ESG.Rank,
             E.Rank,
             S.Rank,
             G.Rank,
             Business.Sector.Rank,
             Industry.Sector.Rank)
    
    colnames(ranks) = c('#ESG', "#E", "#S",
                        "#G", '#Business', '#Indusry')
    
    ranks
  })
  
  output$tablet1esgrank = DT::renderDataTable({
    dataesgrank()
  }, options = list(
    dom = 't',
    scrollX = T,
    scrollY = T
  ))
  
  ## ESG Data
  
  dataesgranktot = eventReactive({
    input$Stock
  }, {
    Round = function(x, k)
      if (is.numeric(x))
        round(x, k)
    else
      x
    
    
    
    raning_sorted = ranking %>%
      select(
        Time,
        Company.Common.Name,
        ESG.Score,
        ESG.Rank,
        E.Score,
        E.Rank,
        S.Score,
        S.Rank,
        G.Score,
        G.Rank,
        TRBC.Business.Sector.Name,
        Business.Sector.Rank,
        TRBC.Industry.Group.Name,
        Industry.Sector.Rank,
        TRBC.Economic.Sector.Name,
        Economic.Sector.Rank
      )
    
    
    colnames(raning_sorted) = c(
      "Time",
      "Company Common Name",
      "ESG Score",
      "ESG Rank",
      "E Score",
      "E Rank",
      "S Score",
      "S Rank",
      "G Score",
      "G Rank",
      "Business Sector",
      "Business Sector Rank",
      "Industry Sector",
      "Industry Rank",
      "Economic Sector",
      "Economic Sector Rank"
    )
    
    replace(raning_sorted, TRUE, lapply(raning_sorted, Round, 3))
  })
  
  output$tablet1esgranktot = DT::renderDataTable({
    dataesgranktot()
  }, options = list(
    dom = 't',
    scrollX = T,
    scrollY = T
  )) #,
  
  
  dataesgmeasures = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    markets_measuresc = markets_measures %>%
      dplyr::filter(Instrument == stock)
    
    markets_measuresc = as.data.frame(t(markets_measuresc))
    
    colnames(markets_measuresc) = as.character(unlist(markets_measuresc['Period End Date',]))
    
    markets_measuresc = markets_measuresc[2:nrow(markets_measuresc) - 1,]
    
    rownames(markets_measuresc) = gsub('[[:punct:][:blank:]]+', ' ', rownames(markets_measuresc))
    
    markets_measuresc
  })
  
  output$tablet1esgmeasures = DT::renderDataTable({
    dataesgmeasures()
  }, options = list(scrollX = TRUE, fixedColumns = TRUE))
  
  
  
  datanews = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    News = SentimentAnalysis(tickers = c(stock, stock))
    News$get_news()
    News$analysis()
    
    news_df = News$news
    
    dates = as.POSIXct(today())
    
    for (i in 1:length(news_df$Date)) {
      dates[i] = ymd(news_df$Date[[i]])
    }
    
    news_df$Date = dates
    
    
    colnames(news_df) = c(
      "Ticker",
      'Date',
      "Time",
      "Headline",
      "Negative Sentiment",
      "Neutral Sentiment",
      "Positive Sentiment",
      "Compound Sentiment"
    )
    
    news_df
    
  })
  
  
  output$tablet1news = DT::renderDataTable({
    datanews()
  })
  
  # mean sentiment
  newsmean = eventReactive({
    input$Stock
  }, {
    stock = symbol_df[symbol_df$display == input$Stock,]$Symbol[1]
    
    News = SentimentAnalysis(tickers = c(stock, stock))
    News$get_news()
    News$analysis()
    
    news_mean = News$news_analysed_mean
    
    mean = news_mean[[1]][1]
    
    mean
    
    if (mean >= 0) {
      result <-
        paste(
          'Latest average sentiment is:<b style="color:MediumSeaGreen;">',
          mean,
          "</b>",
          sep = ' '
        )
    } else {
      result <-
        paste('Latest average sentiment is:<b style="color:Tomato;">',
              mean,
              "</b>",
              sep = ' ')
    }
    result
  })
  
  # Sentiment server
  output$textsent = renderText({
    newsmean()
  })
  
  
  ## Second Component Server Functionality -----
  
  ### Portfolio Analysis ---
  observeEvent(input$StockPf, {
    if (!is.null(input$StockPf)) {
      stocks = symbol_df[symbol_df$Symbol %in% input$StockPf,]$Symbol
      #stocks = symbol_df %>% subset(Description %in% input$StockPf)$Symbol
      stocks_select = data.frame(Stocks = stocks,
                                 Weighting = round(as.numeric(rep((1 / length(stocks)), length(stocks)
                                 )), 4))
    } else {
      stocks = c('AMZN', 'AAPL', 'NFLX')
      stocks_select = data.frame(Stocks = stocks,
                                 Weighting = round(as.numeric(rep((1 / length(stocks)), length(stocks)
                                 )), 4))
    }
    
    
    
    output$weight1 <- renderDT({
      stocks_select
    },
    editable = 'column',
    rownames = F)
    
    
    
    
    observeEvent(input$weight1_cell_edit, {
      oldata <- stocks_select
      if (nrow(oldata) < nrow(input$weight1_cell_edit)) {
        newdata <<- oldata
      } else {
        newdata <<-
          editData(oldata, input$weight1_cell_edit, 'weight1', rownames = F)
        # output$weight2 <- renderDT({newdata}, # for sanity checks
        #                            rownames = F,
        #                            editable = 'column'
        #                            )
        
      }
      
      
      firms <- as.character(newdata['Stocks'][[1]])
      no_firms <- length(firms)
      weights <- newdata[['Weighting']]
      esg_score <- markets_esg[markets_esg$Symbol %in% firms,] %>%
        select('Time',
               'Symbol',
               'ESG-Score',
               'E-Score',
               'S-Score',
               'G-Score')
      esg_score$Time <- year(as.Date(esg_score$Time))
      
      start_date <- input$Date2[1]
      end_date <- input$Date2[2]
      
      
      
      stock_ret_daily <- firms %>%
        tq_get(get = 'stock.prices',
               # returns daily returns of parsed firms
               from = start_date,
               to = end_date) %>%
        group_by(symbol) %>%
        tq_transmute(
          select = adjusted,
          mutate_fun = periodReturn,
          period = 'daily',
          col_rename = 'ret'
        )
      
      ind_perf_SR <-
        stock_ret_daily %>%   # returns annualized stock individual performance measures
        tq_performance(
          Ra = ret,
          Rb = NULL,
          performance_fun = SharpeRatio,
          Rf = 0.0,
          p = 0.95,
          annualize = TRUE
        )
      
      # Portfolio Assessment ------------------------------------------------------------------------------
      port_ret_daily <- stock_ret_daily %>%
        tq_portfolio(
          assets_col = symbol,
          returns_col = ret,
          weights = weights,
          col_rename = 'ret'
        )
      
      port_perf_SR <-
        port_ret_daily %>%  # returns annualized portfolio performance SR (StdDev)
        tq_performance(
          Ra = ret,
          Rb = NULL,
          performance_fun = SharpeRatio,
          Rf = 0.0,
          p = 0.95,
          annualize = TRUE
        )
      
      port_perf_ret <-
        port_ret_daily %>%  # retruns annualized port return
        tq_performance(
          Ra = ret,
          Rb = NULL,
          performance_fun = Return.annualized,
          scale = 252,
          geometric = T
        )
      #browser() #for sanity checks
      temp_esg <-
        left_join(
          esg_score %>% group_by(Symbol) %>% filter(Time == max(as.numeric(Time))),
          newdata,
          by = c('Symbol' = 'Stocks')
        )
      port_perf_ESG <-
        sum(temp_esg$`ESG-Score` * temp_esg$Weighting)
      
      output$box1 <- renderValueBox({
        valueBox(
          paste0(round(port_perf_ret[1], 2) * 100, " %"),
          "Annualized \n Portfolio Return",
          icon = icon("arrow-up"),
          color = "blue"
        )
      })
      
      output$box2 <- renderValueBox({
        valueBox(
          round(port_perf_SR[2], 2),
          "Annualized \n Portfolio Sharpe-Ratio",
          icon = icon("superpowers"),
          color = "red"
        )
      })
      
      output$box3 <- renderValueBox({
        valueBox(
          paste0(round(port_perf_ESG[1], 2), " /100"),
          "Portfolio ESG-Score",
          icon = icon("leaf"),
          color = "green"
        )
      })
      
      
    })
    
  })
  
  observeEvent(input$reset, {
    # reset the selection, can be restored by resubmitting
    updateSelectInput(session = session, 'StockPf', selected = character(0))
    stocks_select = data.frame(Stocks = NA, Weighting = NA)
    output$weight1 <- renderDT({
      stocks_select
    },
    editable = 'column',
    rownames = F)
    output$weight2 <- renderDT({
      NULL
    }) # NULL?
    
    
  })
  
  ### Portfolio Backtesting ------
  observeEvent({
    input$StockPf1
    input$StockPf2
    input$StockPf3
    input$StockPf4
    input$invest
    input$Date3
  }, {
    stocks1 = symbol_df[symbol_df$Symbol %in% input$StockPf1,]$Symbol
    stocks_select1 = data.frame(Stocks1 = stocks1,
                                Weighting1 = round(as.numeric(rep((1 / length(stocks1)), length(stocks1)
                                )), 4))
    stocks2 = symbol_df[symbol_df$Symbol %in% input$StockPf2,]$Symbol
    stocks_select2 = data.frame(Stocks2 = stocks2,
                                Weighting2 = round(as.numeric(rep((1 / length(stocks2)), length(stocks2)
                                )), 4))
    stocks3 = symbol_df[symbol_df$Symbol %in% input$StockPf3,]$Symbol
    stocks_select3 = data.frame(Stocks3 = stocks3,
                                Weighting3 = round(as.numeric(rep((1 / length(stocks3)), length(stocks3)
                                )), 4))
    stocks4 = symbol_df[symbol_df$Symbol %in% input$StockPf4,]$Symbol
    stocks_select4 = data.frame(Stocks4 = stocks4,
                                Weighting4 = round(as.numeric(rep((1 / length(stocks4)), length(stocks4)
                                )), 4))
    
    stocks_select_all <-
      cbindX(stocks_select1,
             stocks_select2,
             stocks_select3,
             stocks_select4)
    
    
    
    output$weightMult <- renderDT({
      stocks_select_all
    },
    editable = 'column',
    rownames = F)
    
    
    
    observeEvent(input$weightMult_cell_edit, {
      oldataMult <- stocks_select_all
      newdataMult <<-
        editData(oldataMult,
                 input$weightMult_cell_edit,
                 'weightMult',
                 rownames = F)
      # output$weight2 <- renderDT({newdata}, # for sanity checks
      #                            rownames = F,
      #                            editable = 'column'
      #                            )
      
      
      df1 <- drop_na(newdataMult[, c(1, 2)])
      df2 <- drop_na(newdataMult[, c(3, 4)])
      df3 <- drop_na(newdataMult[, c(5, 6)])
      df4 <- drop_na(newdataMult[, c(7, 8)])
      
      firms1 <- as.character(df1[, 1])
      weights1 <- df1[[2]]
      
      firms2 <- as.character(df2[, 1])
      weights2 <- df2[[2]]
      
      firms3 <- as.character(df3[, 1])
      weights3 <- df3[[2]]
      
      firms4 <- as.character(df4[, 1])
      weights4 <- df4[[2]]
      
      parser <- list(df1, df2, df3, df4)
      growth_port <- vector(mode = "list", length = 4)
      names_port <- vector(mode = "list", length = 4)
      start_date1 <- input$Date3[1]
      end_date1 <- input$Date3[2]
      
      
      for (i in seq_along(parser)) {
        if (dim(parser[[i]])[1] == 0) {
          growth_port[[i]] <- NULL
          names_port[[i]] <- NA
          
          
        } else {
          growth_port[[i]] <-
            port_growth(
              firms = as.character(unlist(parser[[i]][1])),
              weighting = as.numeric(unlist(parser[[i]][2])),
              start = start_date1,
              stop = end_date1,
              invest = input$invest
            )
          names_port[[i]] <- as.character(unlist(parser[[i]][1]))
          
        }
      }
      
      growth_port <- growth_port[!sapply(growth_port, is.null)]
      names_port <- names_port[!sapply(names_port, is.null)]
      
      no_port <- length(growth_port)
      
      
      delta <- length(growth_port[[1]]$date)
      #growth_port <- list.stack(growth_port)
      # growth_port$firms <- rep(NA,nrow(growth_port))
      # for (i in 1:no_port) {
      #   growth_port$firms[(((i-1)*delta)+1):(i*delta)] <- paste(names_port[[i]], collapse = ", ")
      # }
      
      backtest_plot <- port_growth_plotter(
        no_port = no_port,
        list.stack(growth_port),
        invest_start = input$invest,
        start = start_date1,
        months = length(growth_port[[1]]$date),
        info = names_port
      )
      
      output$backtest <- renderPlotly({
        backtest_plot
      })
      
      
      
      
      
      
      
      if (length(firms1) == 0) {
        esg_score1 <- NA
        port_perf_ESG1 <- Na
      } else {
        esg_score1 <- markets_esg[markets_esg$Symbol %in% firms1,] %>%
          select('Time',
                 'Symbol',
                 'ESG-Score',
                 'E-Score',
                 'S-Score',
                 'G-Score')
        esg_score1$Time <- year(as.Date(esg_score1$Time))
        temp_esg1 <-
          left_join(
            esg_score1 %>% group_by(Symbol) %>% filter(Time == max(as.numeric(Time))),
            df1,
            by = c('Symbol' = 'Stocks1')
          )
        port_perf_ESG1 <-
          sum(temp_esg1$`ESG-Score` * temp_esg1$Weighting1)
      }
      
      if (length(firms2) == 0) {
        esg_score2 <- NA
        port_perf_ESG2 <- NA
      } else {
        esg_score2 <- markets_esg[markets_esg$Symbol %in% firms2,] %>%
          select('Time',
                 'Symbol',
                 'ESG-Score',
                 'E-Score',
                 'S-Score',
                 'G-Score')
        esg_score2$Time <- year(as.Date(esg_score2$Time))
        temp_esg2 <-
          left_join(
            esg_score2 %>% group_by(Symbol) %>% filter(Time == max(as.numeric(Time))),
            df2,
            by = c('Symbol' = 'Stocks2')
          )
        port_perf_ESG2 <-
          sum(temp_esg2$`ESG-Score` * temp_esg2$Weighting2)
      }
      
      if (length(firms3) == 0) {
        esg_score3 <- NA
        port_perf_ESG3 <- NA
      } else {
        esg_score3 <- markets_esg[markets_esg$Symbol %in% firms3,] %>%
          select('Time',
                 'Symbol',
                 'ESG-Score',
                 'E-Score',
                 'S-Score',
                 'G-Score')
        esg_score3$Time <- year(as.Date(esg_score3$Time))
        temp_esg3 <-
          left_join(
            esg_score3 %>% group_by(Symbol) %>% filter(Time == max(as.numeric(Time))),
            df3,
            by = c('Symbol' = 'Stocks3')
          )
        port_perf_ESG3 <-
          sum(temp_esg3$`ESG-Score` * temp_esg3$Weighting3)
      }
      
      
      if (length(firms4) == 0) {
        esg_score4 <- NA
        port_perf_ESG4 <- NA
      } else {
        esg_score4 <- markets_esg[markets_esg$Symbol %in% firms4,] %>%
          select('Time',
                 'Symbol',
                 'ESG-Score',
                 'E-Score',
                 'S-Score',
                 'G-Score')
        esg_score4$Time <- year(as.Date(esg_score4$Time))
        temp_esg4 <-
          left_join(
            esg_score4 %>% group_by(Symbol) %>% filter(Time == max(as.numeric(Time))),
            df4,
            by = c('Symbol' = 'Stocks4')
          )
        port_perf_ESG4 <-
          sum(temp_esg4$`ESG-Score` * temp_esg4$Weighting4)
      }
      
      
      
      
      
      
      
      
      
      
      
      esg_scores <-
        data.frame(
          "ESG-Score" = c(
            port_perf_ESG1,
            port_perf_ESG2,
            port_perf_ESG3,
            port_perf_ESG4
          ),
          "Portfolio" = c(
            paste(firms1, collapse = ", "),
            paste(firms2, collapse = ", "),
            paste(firms3, collapse = ", "),
            paste(firms4, collapse = ", ")
          )
        )
      esg_scores <- esg_scores %>% select_if(~ !all(is.na(.)))
      
      output$esgPlot <- renderPlotly({
        plot <-
          esg_scores %>% plot_ly(
            x = ~ Portfolio,
            y = ~ ESG.Score,
            color = ~ Portfolio,
            colors = "Dark2"
          ) %>% add_bars() %>%
          layout(title = "Average ESG-Score")
        plot
      })
      
      
      
    })
    
  })
  
  observeEvent(input$reset1, {
    # reset the selection, can be restored by resubmitting
    updateSelectInput(session = session, 'StockPf1', selected = character(0))
    stocks_select1 = data.frame(Stocks1 = NA, Weighting1 = NA)
    updateSelectInput(session = session, 'StockPf2', selected = character(0))
    stocks_select2 = data.frame(Stocks2 = NA, Weighting2 = NA)
    updateSelectInput(session = session, 'StockPf3', selected = character(0))
    stocks_select3 = data.frame(Stocks3 = NA, Weighting3 = NA)
    updateSelectInput(session = session, 'StockPf4', selected = character(0))
    stocks_select4 = data.frame(Stocks4 = NA, Weighting4 = NA)
    stocks_select_all <-
      cbindX(stocks_select1,
             stocks_select2,
             stocks_select3,
             stocks_select4)
    
    
    
    output$weightMult <- renderDT({
      stocks_select_all
    },
    editable = 'column',
    rownames = F)
    
    
    
  })
  
  # Portfolio Optimization ------------------------------------------------------
  
  observeEvent({
    input$StockOpt
    input$Date4
    input$sim
    input$mapping
    input$riskfree
    input$minmaxswitch
    
  }, {
    # Initialize inputs
    stocksOpt <-
      symbol_df[symbol_df$Symbol %in% input$StockOpt,]$Symbol
    # measures:
    esg_scoreOpt <-
      opt_measures[opt_measures$Symbol %in% stocksOpt,]
    
    mapper <- esg_scoreOpt[, c("Symbol", input$mapping)]
    
    
    start_date2 <- input$Date4[1]
    end_date2 <- input$Date4[2]
    
    no_firms <- nrow(mapper)
    
    stock_log_ret_daily <- as.character(unlist(mapper[, 1])) %>%
      tq_get(get = 'stock.prices',  # returns daily log returns of parsed firms
             from = start_date2,
             to = end_date2) %>%
      group_by(symbol) %>%
      tq_transmute(
        select = adjusted,
        mutate_fun = periodReturn,
        period = 'daily',
        col_rename = 'log_ret',
        type = 'log'
      )
    
    # To time series format
    log_ret_xts <- stock_log_ret_daily %>%
      spread(symbol, value = log_ret) %>% tk_xts()
    log_ret_xts <- log_ret_xts[-1,]
    
    # Optimisation preparation
    mean_log_ret <- colMeans(log_ret_xts)
    cov_log_ret <- cov(log_ret_xts) * 252
    
    
    mc_result <- mc_sampler(
      num_port = input$sim,
      firms = as.character(unlist(mapper[, 1])),
      mean_log_ret = mean_log_ret,
      covar = cov_log_ret,
      mapping = as.numeric(unlist(mapper[, 2])),
      rf = input$riskfree
    )
    
    min_risk <- mc_result[which.min(mc_result$Risk),]
    max_sr <- mc_result[which.max(mc_result$SharpeRatio),]
    
    # min-max switch
    if (input$minmaxswitch == T) {
      max_map <- mc_result[which.max(mc_result$Mapping),]
      max_string <- "maximum"
    } else {
      max_map <- mc_result[which.min(mc_result$Mapping),]
      max_string <- "minimum"
      
    }
    
    
    
    output$pie1 <- renderPlotly({
      pie_vola <-
        min_risk %>% gather(1:no_firms, key = Firm, value = Weights) %>%
        plot_ly(
          labels = ~ Firm,
          values = ~ Weights,
          type = 'pie',
          textinfo = 'label+percent',
          hoverinfo = 'text',
          text = ~ paste0("Asset: ", Firm, "\nWeight: ", round(Weights *
                                                                 100, 2)),
          marker = list(colors = colorRampPalette(brewer.pal(
            10, 'Spectral'
          ))(no_firms))
        ) %>%
        layout(title = "Portfolio Asset contribution <br>in % for Lowest Volatility",
               margin = list(t = 50, pad = 50))
      pie_vola
      
    })
    
    
    output$pie1table <-
      renderTable({
        min_risk[,-c(1:no_firms)] %>% purrr::set_names(c("Return", "Risk", "Sharpe-Ratio", input$mapping))
      })
    
    output$pie2 <- renderPlotly({
      pie_sr <-
        max_sr %>% gather(1:no_firms, key = Firm, value = Weights) %>%
        plot_ly(
          labels = ~ Firm,
          values = ~ Weights,
          type = 'pie',
          textinfo = 'label+percent',
          hoverinfo = 'text',
          text = ~ paste0("Asset: ", Firm, "\nWeight: ", round(Weights *
                                                                 100, 2)),
          marker = list(colors = colorRampPalette(brewer.pal(
            10, 'Spectral'
          ))(no_firms))
        ) %>%
        layout(title = "Portfolio Asset contribution <br>in % for Highest Sharpe Ratio",
               margin = list(t = 50, pad = 50))
      pie_sr
    })
    
    output$pie2table <-
      renderTable({
        max_sr[,-c(1:no_firms)] %>% purrr::set_names(c("Return", "Risk", "Sharpe-Ratio", input$mapping))
      })
    
    output$pie3 <- renderPlotly({
      pie_esg <-
        max_map %>% gather(1:no_firms, key = Firm, value = Weights) %>%
        plot_ly(
          labels = ~ Firm,
          values = ~ Weights,
          type = 'pie',
          textinfo = 'label+percent',
          hoverinfo = 'text',
          text = ~ paste0("Asset: ", Firm, "\nWeight: ", round(Weights *
                                                                 100, 2)),
          marker = list(colors = colorRampPalette(brewer.pal(
            10, 'Spectral'
          ))(no_firms))
        ) %>%
        layout(
          title = paste0(
            "Portfolio Asset contribution <br>in % for ",
            max_string,
            " ",
            input$mapping
          ),
          margin = list(t = 50, pad = 50)
        )
      pie_esg
      
    })
    
    output$pie3table <-
      renderTable({
        max_map[,-c(1:no_firms)] %>% purrr::set_names(c("Return", "Risk", "Sharpe-Ratio", input$mapping))
      })
    
    output$box4 <- renderValueBox({
      valueBox(
        paste0(round(min_risk$Risk, 2), " Std"),
        "Annualized \n Portfolio Standard Deviation",
        icon = icon("gitter"),
        color = "blue"
      )
    })
    output$box5 <- renderValueBox({
      valueBox(
        round(max_sr$SharpeRatio, 2),
        "Annualized \n Portfolio Sharpe Ratio",
        icon = icon("arrow-up"),
        color = "red"
      )
    })
    output$box6 <- renderValueBox({
      valueBox(
        round(max_map$Mapping, 2),
        input$mapping,
        icon = icon("leaf"),
        color = "green"
      )
    })
    
    
    output$markov <- renderPlotly({
      # Markov Bullet
      marko_bullet <- mc_result %>% plot_ly(hoverinfo = 'none') %>%
        add_markers(
          x = ~ Risk,
          y = ~ Return,
          color = ~ Mapping,
          showlegend = F,
          alpha = 0.8
        ) %>%
        layout(
          title = paste0("Mean-Variance-Frontier mapped to ", input$mapping),
          yaxis = list(title = "Annualized Log-Returns",
                       tickformat = '%'),
          xaxis = list(title = "Annualized Volatility",
                       tickformat = '%')
        ) %>%
        add_markers(
          data = min_risk,
          x = ~ Risk,
          y = ~ Return,
          color = I("red"),
          size = 3,
          symbol = I('cross'),
          hoverinfo = 'text',
          text = ~ paste0(
            "Annualized Return: ",
            round(Return, 2),
            "\nAnnualized Vola: ",
            round(Risk, 2),
            "\n",
            input$mapping,
            ": ",
            round(Mapping, 2)
          ),
          name = "min Vola"
        ) %>%
        add_markers(
          data = max_sr,
          x = ~ Risk,
          y = ~ Return,
          color = I('red'),
          size = 3,
          symbol = I('square'),
          hoverinfo = 'text',
          text = ~ paste0(
            "Annualized Return: ",
            round(Return, 2),
            "\nAnnualized Vola: ",
            round(Risk, 2),
            "\n",
            input$mapping,
            ": ",
            round(Mapping, 2)
          ),
          name = "max SR"
        ) %>%
        add_markers(
          data = max_map,
          x = ~ Risk,
          y = ~ Return,
          color = I('red'),
          size = 3,
          symbol = I('triangle-up'),
          hoverinfo = 'text',
          text = ~ paste0(
            "Annualized Return: ",
            round(Return, 2),
            "\nAnnualized Vola: ",
            round(Risk, 2),
            "\n",
            input$mapping,
            ": ",
            round(Mapping, 2)
          ),
          name = input$mapping
        ) %>%
        colorbar(title = input$mapping)
      marko_bullet
      
    })
    
    
    
    
  })
  
  
  observeEvent({
    input$choose
    
  }, {
    x <- input$choose
    if (is.null(x)) {
      x <- character(0)
    }
    
    # updateMultiInput(session = session, inputId = "factors",
    #                  choices = colnames(data.frame(modelChoice[x])),
    #                  selected = NULL)
    
    df <- data.frame(modelChoice[x])
    
    output$fact <- renderUI({
      multiInput(
        'fact',
        label = 'Select factors',
        selected = "Fama.French.5.Factor.MKT",
        choices = colnames(df[,-c(1)])
      )
    })
  })
  
  observeEvent({
    input$fact
    input$assetSel1
    input$Date5
    input$choose
  }, {
    assets <- symbol_df[symbol_df$Symbol %in% input$assetSel1,]$Symbol
    assets <- unlist(assets)
    
    start_date <- input$Date5[1]
    end_date <- input$Date5[2]
    x <- input$choose
    temp <- input$fact
    if (is.null(x)) {
      x <- character(0)
    }
    if (is.null(temp)) {
      temp <- "Fama.French.5.Factor.MKT"
    }
    #temp <- "Fama.French.5.Factor.MKT"
    
    # updateMultiInput(session = session, inputId = "factors",
    #                  choices = colnames(data.frame(modelChoice[x])),
    #                  selected = NULL)
    
    df <- data.frame(modelChoice[x])
    
    # Check whether daily or yearly returns have to be queried
    if (input$choose == "Fama-French 5 Factor") {
      # daily!!!
      stock_ret_daily <- assets %>%
        tq_get(get = 'stock.prices',
               # returns daily log returns of parsed firms
               from = start_date,
               to = end_date) %>%
        group_by(symbol) %>%
        tq_transmute(
          select = adjusted,
          mutate_fun = periodReturn,
          period = 'daily',
          col_rename = 'returns',
          type = 'log'
        )
      
      if (temp == "Fama.French.3.Factor.MKT" |
          temp == "Fama.French.3.Factor.HML" |
          temp == "Fama.French.3.Factor.SMB") {
        temp <- "Fama.French.5.Factor.MKT"
      }
      stock_fac_joined <-
        left_join(stock_ret_daily,
                  df[, c("Fama.French.5.Factor.Date",
                         temp,
                         "Fama.French.5.Factor.RF")],
                  by = c("date" = "Fama.French.5.Factor.Date"))
      stock_fac_joined <-
        stock_fac_joined %>% mutate(excess_returns = returns - Fama.French.5.Factor.RF)
      form <-
        as.formula(paste("excess_returns ~", paste(temp, collapse = " + ")))
      
      # Time Series regression
      #models <- stock_fac_joined %>% group_by(symbol) %>% do(model = lm(form, data = . )) %>% tidy(model)
      models <-
        stock_fac_joined %>% drop_na() %>% group_by(symbol) %>% do(model = lm(form, data = .) %>% tidy(conf.int = T, conf.level = 0.95) %>% as.data.frame())
      models_meta <-
        stock_fac_joined %>% drop_na() %>% group_by(symbol) %>% do(model = lm(form, data = .) %>% glance() %>% as.data.frame())

      reg_output <- data.frame(matrix(
        rep(NA),
        ncol = 9,
        nrow = length(assets) * (1 + length(temp))
      ))
      colnames(reg_output) <-
        c(
          "Stocks",
          "Coef",
          "Estimate",
          "s.e.",
          "t-stat",
          "p-value",
          "95% CI - low",
          "95% CI - high",
          "adj. R-Squared"
        )
      for (i in length(assets)) {
        reg_output[((i - 1) * (length(temp) + 1) + 1):((length(temp) + 1) * (i)), 1] <-
          models[[1]][[i]]
        reg_output[((i - 1) * (length(temp) + 1) + 1):((length(temp) + 1) *
                                                         (i)), 9] <-
          models_meta[[2]][[i]][[1]]
        reg_output[((i - 1) * (length(temp) + 1) + 1):((length(temp) + 1) *
                                                         (i)), 2:8] <-
          models[[2]][[i]]
        
      }
      reg_output[,-c(1, 2)] <- round(reg_output[,-c(1, 2)], 4)
      output$assetreg <- renderDT({
        reg_output
      })
      
      
      
      
    } else if (input$choose == "Fama-French 3 Factor") {
      stock_ret_daily <- assets %>%
        tq_get(get = 'stock.prices',
               # returns daily log returns of parsed firms
               from = start_date,
               to = end_date) %>%
        group_by(symbol) %>%
        tq_transmute(
          select = adjusted,
          mutate_fun = periodReturn,
          period = 'daily',
          col_rename = 'returns',
          type = 'log'
        )
      
      
      if (temp == "Fama.French.5.Factor.MKT" |
          temp == "Fama.French.5.Factor.HML" |
          temp == "Fama.French.5.Factor.SMB" |
          temp == "Fama.French.5.Factor.RMW" |
          temp == "Fama.French.5.Factor.CMA") {
        temp <- "Fama.French.3.Factor.MKT"
      }
      stock_fac_joined <-
        left_join(stock_ret_daily,
                  df[, c("Fama.French.3.Factor.Date",
                         temp,
                         "Fama.French.3.Factor.RF")],
                  by = c("date" = "Fama.French.3.Factor.Date"))
      stock_fac_joined <-
        stock_fac_joined %>% mutate(excess_returns = returns - Fama.French.3.Factor.RF)
      form <-
        as.formula(paste("excess_returns ~", paste(temp, collapse = " + ")))
      
      # Time Series regression
      #models <- stock_fac_joined %>% group_by(symbol) %>% do(model = lm(form, data = . )) %>% tidy(model)
      models <-
        stock_fac_joined %>% drop_na() %>% group_by(symbol) %>% do(model = lm(form, data = .) %>% tidy(conf.int = T, conf.level = 0.95) %>% as.data.frame())
      models_meta <-
        stock_fac_joined %>% drop_na() %>% group_by(symbol) %>% do(model = lm(form, data = .) %>% glance() %>% as.data.frame())
      
      reg_output <- data.frame(matrix(
        rep(NA),
        ncol = 9,
        nrow = length(assets) * (1 + length(temp))
      ))
      colnames(reg_output) <-
        c(
          "Stocks",
          "Coef",
          "Estimate",
          "s.e.",
          "t-stat",
          "p-value",
          "95% CI - low",
          "95% CI - high",
          "adj. R-Squared"
        )
      for (i in seq_along(assets)) {
        reg_output[((i - 1) * (length(temp) + 1) + 1):((length(temp) + 1) * (i)), 1] <-
          models[[1]][[i]]
        reg_output[((i - 1) * (length(temp) + 1) + 1):((length(temp) + 1) *
                                                         (i)), 9] <-
          models_meta[[2]][[i]][[1]]
        reg_output[((i - 1) * (length(temp) + 1) + 1):((length(temp) + 1) *
                                                         (i)), 2:8] <-
          models[[2]][[i]]
        
      }
      reg_output[,-c(1, 2)] <- round(reg_output[,-c(1, 2)], 4)
      
      output$assetreg <- renderDT({
        reg_output
      })
      
    } else {
      # if (start_date > 2017-01-01) (start_date <- as.Date("2017-01-01")) # otherwise to few observations
      # stock_ret_yearly <- assets %>%
      #   tq_get(get = 'stock.prices',  # returns daily log returns of parsed firms
      #          from = start_date,
      #          to = end_date) %>%
      #   group_by(symbol) %>%
      #   tq_transmute(select = adjusted,
      #                mutate_fun = periodReturn, # only annually available
      #                period = 'yearly',
      #                col_rename = 'returns',
      #                type = 'log')
      #
      #
      # if (temp =="Fama.French.5.Factor.MKT") {temp <- "Own.Model.Estimated.CO2.Equivalents.Emission.Total"}
      # stock_ret_yearly$date <- year(as.Date(stock_ret_yearly$date))
      #
      #
      # stock_fac_joined <- inner_join(stock_ret_yearly, df[,c("Own.Model.Year","Own.Model.Instrument",temp)], by = c("date" = "Own.Model.Year",
      #                                                                                        "symbol" = "Own.Model.Instrument"))
      # stock_fac_joined <- stock_fac_joined %>% mutate(excess_returns = returns - 0.0)
      # form <- as.formula(paste("excess_returns ~", paste(temp, collapse = " + ")))
      #
      # # Time Series regression
      # #models <- stock_fac_joined %>% group_by(symbol) %>% do(model = lm(form, data = . )) %>% tidy(model)
      # models <- stock_fac_joined %>% drop_na() %>% group_by(symbol) %>% do(model = lm(form, data = . ) %>% tidy(conf.int = T, conf.level = 0.95) %>% as.data.frame())
      # models_meta <- stock_fac_joined %>% drop_na() %>% group_by(symbol) %>% do(model = lm(form, data = . ) %>% glance() %>% as.data.frame())
      # browser()
      # reg_output <- data.frame(matrix(rep(NA), ncol = 9,
      #                                 nrow = length(assets)*(1+length(temp))))
      # colnames(reg_output) <- c("Stocks", colnames(models[[2]][[1]]), "adj. R-Squared")
      # for (i in seq_along(assets)) {
      #   reg_output[((i-1)*(length(temp)+1)+1):((length(temp)+1)*(i)),1] <- models[[1]][[i]]
      #   reg_output[((i-1)*(length(temp)+1)+1):((length(temp)+1)*(i)),9] <- models_meta[[2]][[i]][[1]]
      #   reg_output[((i-1)*(length(temp)+1)+1):((length(temp)+1)*(i)),2:8] <- models[[2]][[i]]
      #
      #
      # }
      # output$assetreg <- renderDT({reg_output})
    }
    
    
    
    
  })
  
  
  DataPriceWeight = eventReactive({
    input$Stock
    
  }, {
    output$weightMult <- renderDT({
      DataPriceWeight()
    },
    editable = 'column',
    rownames = F)
    
    
  })
  
  output$weightMult <- renderDT({
    DataPriceWeight()
  },
  editable = 'column',
  rownames = F)
  
  
  
  ## 2.3 Performance Measures Server Functionality ------
  
  ## Analytics Tab
  
  ### Analytics Portfolio Stock Data
  
  AnalyticsData = eventReactive({
    input$AnalyticsStocks
    input$AnalyticsDate
    input$AnalyticsRfrate
  }, {
    portfolioanalysed = PortfolioAnalyser(
      tickers = input$AnalyticsStocks,
      start = as.character(input$AnalyticsDate[1]),
      end = as.character(input$AnalyticsDate[2]),
      rfrate = input$AnalyticsRfrate
    )
    
    portfolioanalysed$summarise()
    
  })
  
  ### Analytics Portfolio Data
  AnalyticsPortfolio = eventReactive({
    input$AnalyticsStocks
    input$AnalyticsDate
    input$AnalyticsRfrate
    input$AnalyticsShares
  }, {
    portfolioanalysed = PortfolioAnalyser(
      tickers = input$AnalyticsStocks,
      start = as.character(input$AnalyticsDate[1]),
      end = as.character(input$AnalyticsDate[2]),
      rfrate = input$AnalyticsRfrate
    )
    
    results = portfolioanalysed$summarise()
    
    nshares = as.numeric(unlist(strsplit(input$AnalyticsShares, ",")))
    
    weights = nshares / length(nshares)
    
    append(results, as.data.frame(weights))
    
  })
  
  ### Analytics Stock Plot
  
  output$AnalysisStocks <- renderPlotly({
    results = AnalyticsData()
    
    
    stocksdata = results[[1]] %>%
      mutate(Date = rownames(results[[1]])) %>%
      gather(Stock, Price, -Date)
    
    rets = results[[2]] %>%
      mutate(Date = rownames(results[[2]])) %>%
      gather(Stock, Return, -Date)
    
    
    dd = results[[7]] %>%
      mutate(Date = rownames(results[[7]])) %>%
      gather(Stock, Drawdawn, -Date)
    
    vola = results[[6]] %>% as.data.frame()
    
    mean_return = results[[3]]
    sharpe_ratio = results[[4]]
    sortino_ratio = results[[5]]
    calmar = results[[9]]
    
    analytics = data.frame(mean_return, sharpe_ratio, sortino_ratio, calmar)
    
    DrawDown = dd %>%
      plot_ly(
        x = ~ Date,
        y = ~ Drawdawn,
        color = ~ Stock,
        #group_by = ~Stock,
        legendgroup = ~ Stock,
        type = 'scatter',
        mode = 'lines'
      ) %>%
      layout(
        title = "Stock Drawdown",
        yaxis = list(title = "Draw Down"),
        xaxis = list(rangeslider = list(visible = F))
      )
    
    
    StocksPlot = stocksdata %>%
      plot_ly(
        x = ~ Date,
        y = ~ Price,
        color = ~ Stock,
        #group_by = ~Stock,
        legendgroup = ~ Stock,
        type = 'scatter',
        mode = 'lines'
      ) %>%
      layout(
        title = "Stock Prices",
        yaxis = list(title = "Stock Prices"),
        xaxis = list(rangeslider = list(visible = F))
      )
    
    RetsPlot = rets %>%
      plot_ly(
        x = ~ Date,
        y = ~ Return,
        color = ~ Stock,
        #group_by = ~Stock,
        legendgroup = ~ Stock,
        type = 'scatter',
        mode = 'lines'
      ) %>%
      layout(
        title = "Stock Returns",
        yaxis = list(title = "Stock Returns"),
        xaxis = list(rangeslider = list(visible = F))
      )
    
    
    AnalyticsBar = plot_ly(
      analytics,
      x = ~ rownames(analytics),
      y = ~ mean_return,
      type = 'bar',
      name = 'Mean Return'
    ) %>%
      add_trace(y = ~ sharpe_ratio,
                name = 'Sharpe Ratio') %>%
      add_trace(y = ~ sortino_ratio,
                name = 'Sortino Ratio') %>%
      add_trace(y = ~ calmar,
                name = 'Calmar Ratio') %>%
      layout(
        title = "Stock Performance Measures",
        yaxis = list(title = "Stock Performance Measures"),
        xaxis = list(title = ''),
        barmode = 'group'
      )
    
    
    DistPlot =  plot_ly(
      rets,
      x = ~ Return,
      y =  ~ Stock,
      type = "histogram",
      legendgroup = ~ Stock,
      color = ~ Stock,
      alpha = 0.6
    ) %>%
      layout(
        title = "Stock Return Analysis",
        yaxis = list(title = "Mass"),
        xaxis = list(title = 'Return')
      )
    
    
    subplot(
      AnalyticsBar,
      StocksPlot,
      RetsPlot,
      DrawDown,
      DistPlot,
      nrows = 1,
      shareX = F,
      shareY = F,
      titleY = T
    )
    
  })
  ### Analytics Portfolio Aggregated Data
  
  output$AnalysisPortfolio <- renderPlotly({
    results = AnalyticsPortfolio()
    
    weights = results[10]
    
    prices = results[11]
    
    stocksdata = rowMeans(results[[1]] * weights) %>% as.data.frame()
    
    rets = rowMeans(results[[2]] * weights)  %>% as.data.frame()
    
    colnames(rets) = c('Return')
    
    dd = rowMeans(results[[7]] * weights) %>% as.data.frame()
    
    covariance = cov(results[[2]] * weights)
    
    
    mean_return = results[[3]]
    sharpe_ratio = results[[4]]
    sortino_ratio = results[[5]]
    calmar = results[[9]]
    
    
    
    analytics = data.frame(mean_return, sharpe_ratio, sortino_ratio, calmar)
    
    analytics = sapply(analytics, weighted.mean, weights$weights) %>% as.data.frame()
    
    rownames(analytics) = c('Mean Return',
                            'Sharpe Ratio',
                            'Sortino Ratio',
                            'Calmar Ratio')
    
    DrawDown = dd %>%
      plot_ly(
        x = ~ rownames(dd),
        y = ~ .,
        type = 'scatter',
        mode = 'lines',
        name = 'Draw Down'
      ) %>%
      layout(
        title = "Portfolio Drawdown",
        yaxis = list(title = "Draw Down"),
        xaxis = list(rangeslider = list(visible = F))
      )
    
    
    StocksPlot = stocksdata %>%
      plot_ly(
        x = ~ rownames(stocksdata),
        y = ~ .,
        type = 'scatter',
        mode = 'lines',
        name = 'Portfolio Price'
      ) %>%
      layout(
        title = "Portfolio Price",
        yaxis = list(title = "Portfolio Price"),
        xaxis = list(title = '', rangeslider = list(visible = F))
      )
    
    RetsPlot = rets %>%
      plot_ly(
        x = ~ rownames(rets),
        y = ~ Return,
        type = 'scatter',
        mode = 'lines',
        name = 'Returns'
      ) %>%
      layout(
        title = "Portfolio Return",
        yaxis = list(title = "Portfolio Returns"),
        xaxis = list(title = 'Return over Time')
      )
    
    
    AnalyticsBar = plot_ly(
      analytics,
      x = ~ rownames(analytics),
      y = ~ .,
      type = 'bar',
      name = 'Analytics',
      marker = list(color = c(
        '#1F77B4', '#FF7F0E',
        '#2CA02C', '#D62728'
      ))
    ) %>%
      layout(
        title = "Portfolio Performance Measures",
        yaxis = list(title = "Stock Performance Measures"),
        xaxis = list(title = "", rangeslider = list(visible = F))
      )
    
    
    DistPlot =  plot_ly(
      rets,
      x = ~ Return,
      #y =~.,
      type = "histogram",
      #color = ~Stock,
      alpha = 0.6,
      name = 'Portf. Dist.',
      marker = list(color = '#3366CC')
    ) %>%
      layout(
        title = "Portfolio Return Distribution",
        yaxis = list(title = "Probability Mass of Returns"),
        xaxis = list(title = 'Portfolio Return Analysis')
      )
    
    
    subplot(
      AnalyticsBar,
      StocksPlot,
      RetsPlot,
      DrawDown,
      DistPlot,
      nrows = 1,
      shareX = F,
      titleY = T
    )
    
  })
  
  observeEvent({
    input$choose2
    
  }, {
    x <- input$choose2
    if (is.null(x)) {
      x <- character(0)
    }
    
    # updateMultiInput(session = session, inputId = "factors",
    #                  choices = colnames(data.frame(modelChoice[x])),
    #                  selected = NULL)
    
    df <- data.frame(modelChoice[x])
    
    output$fact2 <- renderUI({
      multiInput(
        'fact2',
        label = 'Select factors',
        selected = "Fama.French.5.Factor.MKT",
        choices = colnames(df[,-c(1)])
      )
    })
  })
  
  
  
  
  
  
  observeEvent({
    input$fact2
    input$assetSel2
    input$Date6
    input$choose2
  }, {
    if (!is.null(input$assetSel2)) {
      stocks = symbol_df[symbol_df$Symbol %in% input$assetSel2,]$Symbol
      #stocks = symbol_df %>% subset(Description %in% input$StockPf)$Symbol
      stocks_select = data.frame(Stocks = stocks,
                                 Weighting = round(as.numeric(rep((1 / length(stocks)), length(stocks)
                                 )), 4))
    } else {
      stocks_select = data.frame(Stocks = NA, Weighting = NA)
    }
    
    
    
    output$weight3 <- renderDT({
      stocks_select
    },
    editable = 'column',
    rownames = F)
    
    
    
    
    observeEvent(input$weight3_cell_edit, {
      oldata <- stocks_select
      newdata <<-
        editData(oldata, input$weight3_cell_edit, 'weight3', rownames = F)
      # output$weight2 <- renderDT({newdata}, # for sanity checks
      #                            rownames = F,
      #                            editable = 'column'
      #                            )
      
      firms <- as.character(newdata['Stocks'][[1]])
      no_firms <- length(firms)
      weights <- newdata[['Weighting']]
      esg_score <- markets_esg[markets_esg$Symbol %in% firms,] %>%
        select('Time',
               'Symbol',
               'ESG-Score',
               'E-Score',
               'S-Score',
               'G-Score')
      esg_score$Time <- year(as.Date(esg_score$Time))
      
      start_date <- input$Date6[1]
      end_date <- input$Date6[2]
      
      
      
      stock_ret_daily <- firms %>%
        tq_get(get = 'stock.prices',
               # returns daily returns of parsed firms
               from = start_date,
               to = end_date) %>%
        group_by(symbol) %>%
        tq_transmute(
          select = adjusted,
          mutate_fun = periodReturn,
          period = 'daily',
          col_rename = 'returns',
          type = 'log'
        )
      
      ind_perf_SR <-
        stock_ret_daily %>%   # returns annualized stock individual performance measures
        tq_performance(
          Ra = returns,
          Rb = NULL,
          performance_fun = SharpeRatio,
          Rf = 0.0,
          p = 0.95,
          annualize = TRUE
        )
      
      # Portfolio Assessment ------------------------------------------------------------------------------
      port_ret_daily <- stock_ret_daily %>%
        tq_portfolio(
          assets_col = symbol,
          returns_col = returns,
          weights = weights,
          col_rename = 'returns'
        )
      
      x <- input$choose2
      temp <- input$fact2
      if (is.null(x)) {
        x <- character(0)
      }
      if (is.null(temp)) {
        temp <- "Fama.French.5.Factor.MKT"
      }
      #temp <- "Fama.French.5.Factor.MKT"
      
      # updateMultiInput(session = session, inputId = "factors",
      #                  choices = colnames(data.frame(modelChoice[x])),
      #                  selected = NULL)
      
      df <- data.frame(modelChoice[x])
      
      # Check whether daily or yearly returns have to be queried
      if (input$choose2 == "Fama-French 5 Factor") {
        # daily!!!
        
        
        
        if (temp == "Fama.French.3.Factor.MKT" |
            temp == "Fama.French.3.Factor.HML" |
            temp == "Fama.French.3.Factor.SMB") {
          temp <- "Fama.French.5.Factor.MKT"
        }
        stock_fac_joined <-
          left_join(port_ret_daily,
                    df[, c("Fama.French.5.Factor.Date",
                           temp,
                           "Fama.French.5.Factor.RF")],
                    by = c("date" = "Fama.French.5.Factor.Date"))
        stock_fac_joined <-
          stock_fac_joined %>% mutate(excess_returns = returns - Fama.French.5.Factor.RF)
        form <-
          as.formula(paste("excess_returns ~", paste(temp, collapse = " + ")))
        
        # Time Series regression
        #models <- stock_fac_joined %>% group_by(symbol) %>% do(model = lm(form, data = . )) %>% tidy(model)
        models <-
          stock_fac_joined %>% drop_na() %>%  lm(form, data = .) %>% tidy(conf.int = T, conf.level = 0.95) %>% as.data.frame()
        models_meta <-
          stock_fac_joined %>% drop_na() %>% lm(form, data = .) %>% glance() %>% as.data.frame()
        
        reg_output <- data.frame(matrix(
          rep(NA),
          ncol = 9,
          nrow = 1 * (1 + length(temp))
        ))
        colnames(reg_output) <-
          c(
            "Portfolio",
            "Coef",
            "Estimate",
            "s.e.",
            "t-stat",
            "p-value",
            "95% CI - low",
            "95% CI - high",
            "adj. R-Squared"
          )
        
        reg_output[0:(length(temp) + 1), 1] <- 1
        reg_output[0:(length(temp) + 1), 9] <- models_meta[[2]]
        reg_output[0:(length(temp) + 1), 2:8] <- models
        
        reg_output[,-c(1, 2)] <- round(reg_output[,-c(1, 2)], 4)
        output$assetreg2 <- renderDT({
          reg_output
        })
        
        
        
        
      } else if (input$choose2 == "Fama-French 3 Factor") {
        if (temp == "Fama.French.5.Factor.MKT" |
            temp == "Fama.French.5.Factor.HML" |
            temp == "Fama.French.5.Factor.SMB" |
            temp == "Fama.French.5.Factor.RMW" |
            temp == "Fama.French.5.Factor.CMA") {
          temp <- "Fama.French.3.Factor.MKT"
        }
        stock_fac_joined <-
          left_join(port_ret_daily,
                    df[, c("Fama.French.3.Factor.Date",
                           temp,
                           "Fama.French.3.Factor.RF")],
                    by = c("date" = "Fama.French.3.Factor.Date"))
        stock_fac_joined <-
          stock_fac_joined %>% mutate(excess_returns = returns - Fama.French.3.Factor.RF)
        form <-
          as.formula(paste("excess_returns ~", paste(temp, collapse = " + ")))
        
        # Time Series regression
        #models <- stock_fac_joined %>% group_by(symbol) %>% do(model = lm(form, data = . )) %>% tidy(model)
        models <-
          stock_fac_joined %>% drop_na() %>%  lm(form, data = .) %>% tidy(conf.int = T, conf.level = 0.95) %>% as.data.frame()
        models_meta <-
          stock_fac_joined %>% drop_na() %>% lm(form, data = .) %>% glance() %>% as.data.frame()
        
        reg_output <- data.frame(matrix(
          rep(NA),
          ncol = 9,
          nrow = 1 * (1 + length(temp))
        ))
        colnames(reg_output) <-
          c(
            "Portfolio",
            "Coef",
            "Estimate",
            "s.e.",
            "t-stat",
            "p-value",
            "95% CI - low",
            "95% CI - high",
            "adj. R-Squared"
          )
        
        reg_output[0:(length(temp) + 1), 1] <- 1
        reg_output[0:(length(temp) + 1), 9] <- models_meta[[2]]
        reg_output[0:(length(temp) + 1), 2:8] <- models
        
        reg_output[,-c(1, 2)] <- round(reg_output[,-c(1, 2)], 4)
        output$assetreg2 <- renderDT({
          reg_output
        })
        
      } else {
        # Under construction
        #
        
      }
      
      
      
    })
    
    
    ## 3.2 Robo Advisory ---------------
    
    ### 3.2 Data Robo ---------------------------
    RoboData = eventReactive({
      input$RoboAssets
      
      input$RoboDate
      
      input$RoboFees
      
      input$Strategy
      
      input$RoboBetandHold
      
      input$RoboDCRPn
      
      input$RoboMPTWindow
      input$RoboMPTMu
      input$RoboMPTCov
      input$RoboMPTMuWindow
      input$RoboMPTCovWindow
      input$RoboMPTMinHistory
      input$RoboMPTBounds
      input$RoboMPTLeverage
      input$RoboMPTMethod
      input$RoboMPTq
      input$RoboMPTgamma
      input$RoboMPToptimizer
      
      input$RoboOLMARWindow
      input$RoboOLMAREps
      
      input$RoboUPEEval
      input$RoboUPLeverage
    }, {
      if (input$Strategy == "Buy and Hold") {
        hyper = list(input$RoboBetandHold)
      }
      
      if (input$Strategy == "Best Constant Rebalanced Portfolio") {
        hyper = list()
      }
      
      if (input$Strategy == "Modern Portfolio Approach") {
        hyper = list(
          input$RoboMPTWindow,
          input$RoboMPTMu,
          input$RoboMPTCov,
          input$RoboMPTMuWindow,
          input$RoboMPTCovWindow,
          input$RoboMPTMinHistory,
          input$RoboMPTLeverage,
          input$RoboMPTMethod,
          input$RoboMPTq,
          input$RoboMPTgamma
        )
      }
      
      if (input$Strategy == "Universal Portfolio") {
        hyper = list(input$RoboUPEEval,
                     input$RoboUPLeverage)
      }
      
      if (input$Strategy == "On-Line Portfolio Selection with Moving Average Reversion") {
        hyper = list(input$RoboOLMARWindow,
                     input$RoboOLMAREps)
      }
      
      if (input$Strategy == "Dynamic Rebalancing Portfolio") {
        hyper = list(input$RoboDCRPn)
      }
      
      
      Robo = RoboAdvisor(
        tickers = input$RoboAssets,
        start = input$RoboDate[1],
        adjustment = input$RoboAdjustment,
        #
        strategy = input$Strategy,
        hyper = hyper
      ) # Döp Döp Döp Döp Dödödödöp :D
      
      Results = Robo$advise()
      
      Results$fee = input$RoboFees
      
      Results
    })
    
    ### 3.2 Summary Robo Advisory ----------
    output$RoboSummary = renderUI((RoboData()$summary()) %>%
                                    str_replace_all(pattern = '\n', replacement = '<br/>') %>%
                                    HTML()
    )
    
    ### 3.2 Plot Robo ---------------
    output$RoboPlot <- renderPlotly({
      Results = RoboData()
      
      UCRP_Return = Results$ucrp_r %>%
        as.data.frame() %>%
        mutate(Date = rownames(Results$r)) %>%
        rename('Return' = '.')
      
      
      
      Return = Results$r %>%
        as.data.frame() %>%
        mutate(Date = rownames(Results$r)) %>%
        rename('Return' = '.')
      
      ReturnPlot = plot_ly(
        Return,
        x = ~ Date,
        y = ~ Return,
        type = 'scatter',
        mode = 'lines',
        name = 'Robo Portfolio Return'
      ) %>%
        add_trace(
          UCRP_Return,
          x = ~ Date,
          y = ~ Return,
          type = 'scatter',
          mode = 'lines',
          name = 'UCRP Portfolio'
        )
      
      
      Weights = Results$weights %>%
        mutate(Date = rownames(Results$weights)) %>%
        gather(Stock, Weight, -Date)
      
      WeightsPlot = plot_ly(
        Weights,
        x = ~ Date,
        y = ~ Weight,
        color = ~ Stock,
        type = 'scatter',
        mode = 'Lines',
        fill = "",
        stackgroup = 'one',
        legendgroup = ~ Stock
      )
      
      
      
      
      AssetEquity = Results$asset_equity %>%
        mutate(Date = rownames(Results$weights)) %>%
        gather(Stock, AssetsEquity, -Date)
      
      
      EquityPlot = plot_ly(
        AssetEquity,
        x = ~ Date,
        y = ~ AssetsEquity,
        color = ~ Stock,
        type = 'scatter',
        mode = 'Lines',
        legendgroup = ~ Stock
        
      )
      
      
      subplot(ReturnPlot,
              WeightsPlot,
              EquityPlot,
              shareX = TRUE,
              titleY = T) %>%
        layout(title = 'Return, Weights and Equity of the Portfolio By Stocks')
      
    })
    
    output$RoboWeights = DT::renderDataTable({
      datatable(RoboData()$weights)
    })
    
  })
  
  
  
  
  ### Analytics Portfolio Plot
}

shinyApp(ui, server)