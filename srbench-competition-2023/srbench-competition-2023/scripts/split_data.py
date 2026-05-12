"""
The :mod:`create_data` module will create the datasets for the
competition. 
"""

# Author: Fabricio Olivetti de Franca <folivetti@ufabc.edu.br>
#
# License: BSD-3

import pandas as pd
import numpy as np
from numpy.random import default_rng
from scipy.spatial.distance import pdist, squareform, cdist

directory = r'datasets/'

def get_k_farthest_points(arr, k):
    n = arr.shape[0]
    d = squareform(pdist(arr))
    (i, j) = np.unravel_index(np.argmax(d),d.shape)

    P = {i, j}
    Q = {ix for ix in range(n) if ix not in P}

    while len(P) < k and len(Q) > 0:
       dict_q = { a:b for (a,b) in enumerate(list(Q)) }
       dp = cdist(arr[list(Q),:], arr[list(P),:])
       (ix_best, _) = np.unravel_index(np.argmax(dp),dp.shape)
       P.add(dict_q[ix_best])
       Q.remove(dict_q[ix_best])
    return list(P)

def split_data():
    df1 = pd.read_csv("datasets/NASA_dset_1.csv")
    df1 = df1.iloc[::50,:]
    df2 = pd.read_csv("datasets/NASA_dset_2.csv")

    ixs1 = get_k_farthest_points(df1.values[:, :-1], 2000)
    ixs2 = get_k_farthest_points(df2.values[:, :-1], 1000)

    df_train1 = df1.iloc[ixs1, :]
    df_train2 = df2.iloc[ixs2, :]

    save_data(df_train1, df1, [], "dataset_4")
    save_data(df_train2, df2, [], "dataset_5")

def save_data(data_train: pd.DataFrame, data_test: pd.DataFrame, map_ixs : list, name: str, directory: str = directory):
    data = pd.concat([data_train, data_test])
    data.to_csv(directory+name+'_full.csv', index=False)
    data_train.to_csv(directory+name+'.csv', index=False)
    data_test.to_csv(directory+name+'_test.csv', index=False)
    with open(directory+name+'_map', 'w') as f:
        print(map_ixs, file=f)

def main():
    split_data()

if __name__ == "__main__":
    main()
