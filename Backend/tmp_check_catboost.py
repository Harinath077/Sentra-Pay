try:
    import catboost
    print('catboost available', catboost.__version__)
except Exception as e:
    print('catboost import failed:', type(e).__name__, e)
