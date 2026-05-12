#!/usr/bin/env bash
set -e

echo "============================================================"
echo " Symbolic Regression Analysis - GitHub Setup Script"
echo "============================================================"
echo ""

# ── 1. GitHub details ─────────────────────────────────────────
read -p "Enter your GitHub username: " GITHUB_USER
read -p "Enter your repository name (e.g. symreg-analysis): " REPO_NAME

# ── 2. Check Git ──────────────────────────────────────────────
echo ""
echo "── Checking Git ─────────────────────────────────────────"
git --version

# ── 3. Data paths ─────────────────────────────────────────────
echo ""
echo "── Locating your data ───────────────────────────────────"
echo "Paste paths using forward slashes, e.g.:"
echo "  /c/Users/you/2025/symreg/PhySO-main/benchmarking/FeynmanBenchmark/results"
echo ""
read -p "Path to PhySO results folder (contains noise0.000 ... noise0.100): " PHYSO_DIR
read -p "Path to srbench folder (contains ground-truth_results.feather): "     SRBENCH_DIR
read -p "Path to srbench_2025 results folder (contains first-principles-tuning and black-box-tuning): " SRBENCH25_DIR

# ── 4. Copy data into repo ────────────────────────────────────
echo ""
echo "── Copying data ─────────────────────────────────────────"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$REPO_DIR/data/PhySO-main/benchmarking/FeynmanBenchmark/results"
mkdir -p "$REPO_DIR/data/srbench"
mkdir -p "$REPO_DIR/data/srbench-srbench_2025/results/first-principles-tuning"
mkdir -p "$REPO_DIR/data/srbench-srbench_2025/results/black-box-tuning"

echo "Copying PhySO CSVs..."
cp -r "$PHYSO_DIR/noise0.000" "$REPO_DIR/data/PhySO-main/benchmarking/FeynmanBenchmark/results/"
cp -r "$PHYSO_DIR/noise0.001" "$REPO_DIR/data/PhySO-main/benchmarking/FeynmanBenchmark/results/"
cp -r "$PHYSO_DIR/noise0.010" "$REPO_DIR/data/PhySO-main/benchmarking/FeynmanBenchmark/results/"
cp -r "$PHYSO_DIR/noise0.100" "$REPO_DIR/data/PhySO-main/benchmarking/FeynmanBenchmark/results/"

echo "Copying SRBench feather..."
cp "$SRBENCH_DIR/ground-truth_results.feather" "$REPO_DIR/data/srbench/"

echo "Copying SRBench 2025 feathers..."
cp "$SRBENCH25_DIR/first-principles-tuning/results.feather" "$REPO_DIR/data/srbench-srbench_2025/results/first-principles-tuning/"
cp "$SRBENCH25_DIR/black-box-tuning/results.feather"        "$REPO_DIR/data/srbench-srbench_2025/results/black-box-tuning/"

echo "Data copied. OK."

# ── 5. Check sizes, set up LFS if needed ──────────────────────
echo ""
echo "── Checking file sizes ──────────────────────────────────"
LFS_NEEDED=0
for F in \
    "$REPO_DIR/data/srbench/ground-truth_results.feather" \
    "$REPO_DIR/data/srbench-srbench_2025/results/first-principles-tuning/results.feather" \
    "$REPO_DIR/data/srbench-srbench_2025/results/black-box-tuning/results.feather"
do
    SIZE=$(du -m "$F" | cut -f1)
    echo "  $(basename $F): ${SIZE} MB"
    if [ "$SIZE" -gt 90 ]; then
        echo "    -> over 90 MB, Git LFS will be used"
        LFS_NEEDED=1
    fi
done

cd "$REPO_DIR"
git init

if [ "$LFS_NEEDED" -eq 1 ]; then
    echo ""
    echo "── Setting up Git LFS ───────────────────────────────────"
    git lfs install
    git lfs track "*.feather"
    git add .gitattributes
    echo "LFS configured."
fi

# ── 6. Commit and push ────────────────────────────────────────
echo ""
echo "── Pushing to GitHub ────────────────────────────────────"
git add .
git commit -m "Initial commit: analysis scripts + data"
git branch -M main
git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
git push -u origin main

echo ""
echo "============================================================"
echo " SUCCESS!"
echo " Repo: https://github.com/$GITHUB_USER/$REPO_NAME"
echo ""
echo " Go to the Actions tab - the analysis runs automatically."
echo " Download plots from Artifacts when done (~10 min)."
echo "============================================================"
