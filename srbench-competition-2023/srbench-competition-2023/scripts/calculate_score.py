"""
The :mod:`calculate_score` module calculates and store
the scores from the current participant. The participant 
name will be the last word in the repository name.
Passing the argument --test will evaluate on the test set.
"""

# Author: Fabricio Olivetti de Franca <folivetti@ufabc.edu.br>
#
# License: BSD-3

import sys
import numpy as np
import pandas as pd
from score import Score

def get_repo_name():
    with open(".git/config") as f:
        url = list(filter(lambda x: x.strip().startswith("url"), f.readlines()))[0]
    return url.split("-")[-1].strip()

participant = get_repo_name()

p_names = []
accs = []
sizes = []
ixs = []

test_set = "_test" if len(sys.argv) > 1 and sys.argv[1] == "--test" else ""

for ix in range(1, 4):
    with open(f"dataset_{ix}_best_model") as f_model:
        Z = np.loadtxt(f"datasets/dataset_{ix}{test_set}.csv", delimiter=",")
        X, y = Z[:, :-1], Z[:, -1]
        sc = Score(f_model.read(), X, y)
        ixs.append(ix)
        p_names.append(participant)
        accs.append(sc.r2)
        sizes.append(sc.n_nodes)
        print(sc.r2, sc.n_nodes, sc.expr.expr)
df = pd.DataFrame({"Name": p_names, "Dataset": ixs, "R2": accs, "size": sizes})
df.to_csv(f"scores_{participant}{test_set}.csv", index=False)
