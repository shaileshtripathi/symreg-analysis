# Symbolic Regression Comparison of Benchmark Data

Compares PhySO, TPSR, MSR, and SRBench algorithms on the Feynman benchmark
using Friedman / Nemenyi critical-difference plots and R² boxplots.

Data Sources are: 
**1** : srbench (https://github.com/cavalab/srbench)
**2** : srbench,2025 (https://github.com/cavalab/srbench/tree/srbench_2025)  
**3** : PhySO (https://github.com/WassimTenachi/PhySO/tree/main/benchmarking/FeynmanBenchmark/results)
**4** : deep-symbolic-mathematics (github.com/deep-symbolic-mathematics)
**5** :  TPSR (https://raw.githubusercontent.com/deep-symbolic-mathematics/TPSR/refs/heads/main/srbench_results/feynman_tpsr_l0.1_allnoise.csv)
**6** : MSR ("https://raw.githubusercontent.com/deep-symbolic-mathematics/Multimodal-Symbolic-Regression/refs/heads/main/srbench_results/feynman_snip_allnoise.csv")

## Results

CD diagrams  show average method ranks: lower is better, methods connected by a bar are statistically indistinguishable under the Friedman test with Nemenyi post-hoc analysis. Boxplots show test  R² distributions across datasets.

**(A)** Phenomenological and first-principles datasets comprising 13 physics and astronomy equations evaluated across 27 algorithms.

**(B)** Real-world black-box datasets comprising 12 datasets evaluated across 28 algorithms.

**(C)** SRBench Feynman benchmark comprising 115 equations at 10% noise level, evaluated across 17 algorithms including traditional symbolic regression and deep learning approaches (TPSR, PhySO, MSR).

