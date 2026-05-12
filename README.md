# Symbolic Regression Benchmark Analysis

Compares PhySO, TPSR, MSR, and SRBench algorithms on the Feynman benchmark
using Friedman / Nemenyi critical-difference plots and R² boxplots.

## Repository layout

```
.
├── .github/workflows/run_analysis.yml   ← GitHub Actions pipeline
├── R/
│   ├── analysis.R                       ← main script
│   └── functions.R                      ← plotCDx, friedman_cd, rank_row
├── data/                                ← YOUR data files go here (see below)
│   ├── PhySO-main/benchmarking/FeynmanBenchmark/results/
│   │   ├── noise0.000/results_summary.csv
│   │   ├── noise0.001/results_summary.csv
│   │   ├── noise0.010/results_summary.csv
│   │   └── noise0.100/results_summary.csv
│   ├── srbench/
│   │   └── ground-truth_results.feather
│   └── srbench-srbench_2025/results/
│       ├── first-principles-tuning/results.feather
│       └── black-box-tuning/results.feather
└── results/                             ← plots are written here by the script
```

## One-time setup (do this once on your PC)

### 1. Create a GitHub account
Go to https://github.com and sign up (free).

### 2. Create a new repository
- Click **+** → **New repository**
- Name it e.g. `symreg-analysis`
- Set to **Private** if your data is unpublished
- Click **Create repository**

### 3. Install Git on Windows
Download from https://git-scm.com/download/win and install with defaults.

### 4. Clone the empty repo to your PC
Open **Git Bash** (installed with Git) and run:
```bash
git clone https://github.com/YOUR_USERNAME/symreg-analysis.git
cd symreg-analysis
```

### 5. Copy these files into the cloned folder
Copy the contents of this zip/folder into `symreg-analysis/` so the layout
matches the tree above.

### 6. Add your data files
Copy your local data into `data/` following the layout above.
**If any file is larger than 100 MB** you need Git LFS:
```bash
# run once per machine
git lfs install

# track large file types
git lfs track "*.feather"
git lfs track "*.csv"
git add .gitattributes
```

### 7. Push everything to GitHub
```bash
git add .
git commit -m "Initial commit"
git push origin main
```
This automatically triggers the GitHub Actions workflow.

## Running the analysis

### Automatically
Every `git push` to `main` triggers a new run.

### Manually (no code change needed)
1. Go to your repo on GitHub
2. Click **Actions** tab
3. Click **Symbolic Regression Analysis** on the left
4. Click **Run workflow** → **Run workflow**

## Downloading the plots

1. Go to **Actions** tab → click the latest green run
2. Scroll down to **Artifacts**
3. Click **plots-N** to download a zip with all PNGs

## Output files

| File | Description |
|------|-------------|
| `results/cd_plot_feynman.png` | CD plot – Feynman benchmark (max noise) |
| `results/boxplot_feynman.png` | Boxplot – Feynman benchmark |
| `results/cd_plot_first-principles.png` | CD plot – SRBench 2025 first-principles |
| `results/boxplot_first-principles.png` | Boxplot – SRBench 2025 first-principles |
| `results/cd_plot_black-box.png` | CD plot – SRBench 2025 black-box |
| `results/boxplot_black-box.png` | Boxplot – SRBench 2025 black-box |
