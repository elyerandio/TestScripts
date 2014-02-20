class StatAdjust():
    def __init__(self):
        pass

    def smearing_factor(self, df, y, yhat):
        """
        Computes the Duan smearing factor. This is needed when implementing linear regression on log-tranformed data.
        Reference: http://stats.stackexchange.com/questions/49857/using-duan-smear-factor-on-a-two-part-model
        """
        return 1 + ((df[y] - df[yhat]).std() ** 2) / 2



