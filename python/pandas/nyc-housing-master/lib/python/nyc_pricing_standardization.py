import pandas as pd
import sys
import statsmodels.api as sm
#import pylab
import matplotlib.pyplot as plt

sys.path.append('lib/python/statistics')
import statistics.cost_functions as cf
from statistics.adjustments import *

pd.set_option('display.line_width', 300)
import numpy as np

if __name__ == '__main__':
    df = pd.read_csv('../../data/nyc-condominium-dataset.csv')
    #Normalize vars
    df['log_full_market_value'] = df['full_market_value'].apply(np.log)
    df['log_gross_sqft'] = df['gross_sqft'].apply(np.log)
    df['log_comp_full_market_value'] = df['comp_full_market_value'].apply(np.log)
    df['log_comp2_full_market_value'] = df['comp2_full_market_value'].apply(np.log)

    df['const'] = 1

    df = df[(df['log_comp2_full_market_value'] > 0) & (df['log_comp_full_market_value'] > 0) & (df['log_gross_sqft'] > 0)
            & (df['full_market_value'] > 0)]

    #Regression 1: Standard Linear Regression
    df.reset_index(inplace=True)
    xvars1 = ['const', 'n_units', 'comp_full_market_value', 'comp2_full_market_value', 'gross_sqft']
    yvar1 = ['full_market_value']

    Y1 = df[yvar1]
    X1 = df[xvars1]

    #plt.figure()
    #df[df['full_market_value'] < 100000000]['full_market_value'].hist(bins=25, color='blue')
    #plt.show()

    m1 = sm.GLS(Y1, X1)
    r1 = m1.fit()

    print "---------------------------------------------------------"
    print "---------Regression 1: Standard Linear Regression--------"
    print "\n"
    print r1.summary()

    df_predicted1 = pd.DataFrame(r1.predict(), columns=['predicted1'])
    df_final1 = df.combine_first(df_predicted1)

    cfn = cf.CostFunction(df_final1, 'full_market_value', 'predicted1', 'district', 10, 2.5, 2.5)
    print cfn.all_glm()

    print "---------------------------------------------------------"
    print "----Regression 2: Linear Regression of Log Transform-----"
    print "\n"
    #Regression 2: Linear Regression of Log Transform
    xvars2 = ['const', 'n_units', 'log_gross_sqft', 'log_comp_full_market_value', 'log_comp2_full_market_value']
    yvar2 = ['log_full_market_value']

    X2 = df[xvars2]
    Y2 = df[yvar2]

    #plt.figure()
    #df['log_full_market_value'].hist(bins=25, color='blue')
    #plt.show()

    m2 = sm.GLS(Y2, X2)
    r2 = m2.fit()
    print r2.summary()

    df_predicted2 = pd.DataFrame(r2.predict(), columns=['predicted2'])
    df_final2 = df.combine_first(df_predicted2)

    cfn = cf.CostFunction(df_final2, 'log_full_market_value', 'predicted2', 'district', 10, 2.5, 2.5)
    print cfn.all_glm()

    print "---------------------------------------------------------"
    print "Regression 2: Linear Regression of Log Transform(Smeared)"
    print "\n"

    df_final2['predicted_act'] = df_final2['predicted2'].apply(np.exp)
    adj = StatAdjust()
    sf = adj.smearing_factor(df_final2, 'log_full_market_value', 'predicted2')
    df_final2['smearing_factor'] = sf
    print sf
    df_final2['predicted_act_sf'] = df_final2['predicted_act'] * df_final2['smearing_factor']

    cfn = cf.CostFunction(df_final2, 'full_market_value', 'predicted_act_sf', 'district', 10, 2.5, 2.5)
    print cfn.all_glm()

    print "---------------------------------------------------------"
    print "-Regression 3: Linear Regression of price by square foot-"
    print "\n"

    #Regression 3: Linear Regression of price by square foot
    xvars3 = ['const', 'n_units', 'comp_market_value_sqft', 'comp2_market_value_sqft']
    yvar3 = ['market_value_sqft']

    X3 = df[xvars3]
    Y3 = df[yvar3]

    #plt.figure()
    #df['market_value_sqft'].hist(bins=20, color='blue')
    #plt.show()

    m3 = sm.GLS(Y3, X3)
    r3 = m3.fit()
    print r3.summary()

    df_predicted3 = pd.DataFrame(r3.predict(), columns=['predicted3'])
    df_final3 = df.combine_first(df_predicted3)

    cfn = cf.CostFunction(df_final3, 'market_value_sqft', 'predicted3', 'district', 10, 2.5, 2.5)
    print cfn.all_glm()

    print "---------------------------------------------------------"
    print "-Regression 3: Linear Regression of price by square foot-"
    print "\n"

    df_final3['market_value_act'] = df_final3['predicted3'] * df_final3['gross_sqft']

    cfn = cf.CostFunction(df_final3, 'full_market_value', 'market_value_act', 'district', 10, 2.5, 2.5)
    print cfn.all_glm()
