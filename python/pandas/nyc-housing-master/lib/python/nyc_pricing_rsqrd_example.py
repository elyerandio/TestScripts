import csv
import pandas as pd
import numpy as np
import statsmodels.api as sm
from statistics.cost_functions import *
import MySQLdb
import pandas.io.sql as psql
import matplotlib
pd.plot_params

class Import:
    def __init__(self, path, file):
        self.path = path
        self.file = file

    def import_housing_data(self):

        full_path = self.path + '/' + self.file
        print "importing " + full_path

        data = pd.read_csv(full_path, index_col='property_id')

        return data


class Regression:
    def __init__(self, df, y, x, std_ol, std_oh):
        self.df = df
        self.y = y
        self.x = x
        self.std_oh = std_oh
        self.std_ol = std_ol

    def linear_regression(self):
        """
        Notes
        -----
        Only the following combinations make sense for family and link ::

                       + ident log logit probit cloglog pow opow nbinom loglog logc
          Gaussian     |   x    x                        x
          inv Gaussian |   x    x                        x
          binomial     |   x    x    x     x       x     x    x           x      x
          Poission     |   x    x                        x
          neg binomial |   x    x                        x          x
          gamma        |   x    x                        x

        Examples
        --------
        >>> from cost_functions import *
        >>> imp = imp = Import('./', 'nyc-condominium-dataset.csv')
        >>> df = imp.import_housing_data()
        >>> x_var = ['comp_full_market_value', 'comp2_full_market_value', 'gross_sqft']
        >>> reg = Regression(df, 'full_market_value', x_var, 2.5, 2.5)
        >>> df_final = reg.linear_regression()
        >>> cf = CostFunction(df_final, 'full_market_value', 'predicted', 'district', 10, 2.5, 2.5)
        >>> cf.all_glm()
        """
        df = self.df
        y = df[self.y]
        #Remove Outliers
        ol = y.describe()['mean'] - self.std_ol * y.describe()['std']
        oh = y.describe()['mean'] + self.std_oh * y.describe()['std']

        df = df[(df[self.y] > ol) & (df[self.y] < oh)]

        #Remove missing values
        df = df[(df['comp2_full_market_value'] > 0) & (df['comp_full_market_value'] > 0) & (df['full_market_value'] > 0)
                & (df[self.y] > ol) & (df[self.y] < oh)]
        df = df.reset_index(drop=True)
        y = df[self.y]
        #y.describe()

        x = sm.add_constant(df[self.x])
        #x.describe()
        #model = sm.GLM(Y, X, family = sm.families.Binomial())
        #model = sm.GLM(y, x, family=sm.families.Gaussian())
        #Note: GLS returns same results as GLM where you set const=1 and family=sm.families.Gaussian()
        m2 = sm.GLS(y, x)
        r2 = m2.fit()

        df_predicted = pd.DataFrame(r2.predict(), columns=['predicted'])
        df_final = df.combine_first(df_predicted)
 

        print r2.summary()

        return df_final
