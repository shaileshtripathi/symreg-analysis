source("R/functions.R")

library(arrow)
library(dplyr)
library(reshape2)
library(colorspace)
library(ggplot2)

dir.create("results", showWarnings = FALSE)


####
# Figure A and B: SRBench 2025 (first-principles and black-box tuning)
###
df_fp <- read_feather("data/srbench-srbench_2025/results/first-principles-tuning/results.feather")
df_bb <- read_feather("data/srbench-srbench_2025/results/black-box-tuning/results.feather")

lb1    <- c("dataset", "training time (s)", "r2_test", "model_size", "algorithm")
labels <- c("first-principles_A", "black-box_B")

for (ii in seq_along(list(df_fp, df_bb))) {
  dfl_i <- list(df_fp, df_bb)[[ii]]

  tmp <- dfl_i[, lb1] %>%
    group_by(dataset, algorithm) %>%
    filter({
      Q1        <- quantile(r2_test, 0.25, na.rm = TRUE)
      IQR_val   <- IQR(r2_test, na.rm = TRUE)
      r2_test >= Q1 - 1.5 * IQR_val          # drop lower outliers
    }) %>%
    summarise(
      training_time = mean(`training time (s)`, na.rm = TRUE),
      r2_test       = mean(r2_test,             na.rm = TRUE),
      model_size    = mean(model_size,          na.rm = TRUE),
      .groups = "drop"
    )

  ins_i <- unique(dfl_i$dataset)
  algos_i <- unique(tmp$algorithm)
  m_i <- matrix(NA, nrow = length(ins_i), ncol = length(algos_i),
                dimnames = list(ins_i, algos_i))

  for (i in seq_len(nrow(tmp))) {
    m_i[tmp$dataset[i], tmp$algorithm[i]] <- tmp$r2_test[i]
  }

  res_i <- t(apply(m_i, 1, rank_row))
  colnames(res_i) <- colnames(m_i)
  rownames(res_i) <- rownames(m_i)

  cdt_i <- friedman_cd(res_i, alpha = 0.01)

  png(paste0("results/cd_plot_", labels[ii], ".png"), width = 1300, height = 600)
  plotCDx(cdt_i$rank_matrix, sort(cdt_i$avg_ranks), cdt_i$CDb,
          cdt_i$N, cdt_i$k, alpha = cdt_i$alpha, cex = 1.5, mr = c(1.75, 3.75))
  dev.off()

  df_long_i <- melt(m_i, varnames = c("data", "algorithm"), value.name = "r2_test")
  df_long_i$algorithm <- factor(df_long_i$algorithm, levels = names(sort(cdt_i$avg_ranks)))

  n_alg_i     <- length(unique(df_long_i$algorithm))
  my_colors_i <- qualitative_hcl(n_alg_i, palette = "Set3")

  plt_i <- ggplot(df_long_i, aes(x = algorithm, y = r2_test, fill = algorithm)) +
    geom_boxplot(alpha = 0.8) +
    coord_cartesian(ylim = c(-1, 1)) +
    scale_fill_manual(values = my_colors_i) +
    theme_minimal(base_size = 18) +
    labs(x = "Algorithm", y = "R² Test") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "none")

  ggsave(paste0("results/boxplot_", labels[ii], ".png"),
         plt_i, width = 14, height = 7, dpi = 150)

  cat("Done:", labels[ii], "\n")
}

cat("All plots saved to results/\n")



#Figure C

# ── PhySO data ────────────────────────────────────────────────────────────────
physo_base <- "data/PhySO-main/benchmarking/FeynmanBenchmark/results"
dphy <- rbind(
  read.csv(file.path(physo_base, "noise0.000/results_summary.csv")),
  read.csv(file.path(physo_base, "noise0.001/results_summary.csv")),
  read.csv(file.path(physo_base, "noise0.010/results_summary.csv")),
  read.csv(file.path(physo_base, "noise0.100/results_summary.csv"))
)
dphy[["training_time"]] <- NA

# ── SRBench ground truth ──────────────────────────────────────────────────────
df1 <- read_feather("data/srbench/ground-truth_results.feather")

# ── TPSR & MSR (downloaded at runtime) ───────────────────────────────────────
dftpsr2 <- read.csv("https://raw.githubusercontent.com/deep-symbolic-mathematics/TPSR/refs/heads/main/srbench_results/feynman_tpsr_l0.1_allnoise.csv")
dfdsm2  <- read.csv("https://raw.githubusercontent.com/deep-symbolic-mathematics/Multimodal-Symbolic-Regression/refs/heads/main/srbench_results/feynman_snip_allnoise.csv")

# ── Column definitions ────────────────────────────────────────────────────────
cols_out  <- c("dataset", "training_time", "target_noise", "r2_test", "simplified_complexity", "algorithm")
cols_tpsr <- c("problem", "time", "target_noise", "r2_predict", "X_complexity_predict")

# ── SRBench: aggregate over trials ───────────────────────────────────────────
tmp1 <- df1[, c("dataset", "training time (s)", "target_noise", "r2_test", "simplified_complexity", "algorithm")] %>%
  group_by(dataset, algorithm, target_noise) %>%
  summarise(
    training_time         = mean(`training time (s)`, na.rm = TRUE),
    r2_test               = mean(r2_test,             na.rm = TRUE),
    simplified_complexity = mean(simplified_complexity, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  .[, cols_out]

# ── TPSR ─────────────────────────────────────────────────────────────────────
tmp2 <- dftpsr2[, cols_tpsr]
tmp2$algorithm <- "TPSR"
colnames(tmp2) <- cols_out

# ── MSR ──────────────────────────────────────────────────────────────────────
tmp3 <- dfdsm2[, cols_tpsr]
tmp3$algorithm <- "MSR"
colnames(tmp3) <- cols_out

# ── PhySO ─────────────────────────────────────────────────────────────────────
tmp4 <- dphy[, cols_out]

# ── Combine & find common datasets at max noise ───────────────────────────────
tmpall <- rbind(tmp1, tmp2, tmp3, tmp4)
noise  <- max(tmpall$target_noise)
ins    <- Reduce(intersect, lapply(list(tmp1, tmp2, tmp3, tmp4), `[[`, "dataset"))

# ── Build R² matrix ───────────────────────────────────────────────────────────
algos <- unique(tmpall$algorithm)
m <- matrix(NA, nrow = length(ins), ncol = length(algos),
            dimnames = list(ins, algos))

rows <- which(tmpall$dataset %in% ins & tmpall$target_noise == noise)
for (i in rows) {
  m[tmpall$dataset[i], tmpall$algorithm[i]] <- tmpall$r2_test[i]
}

# ── Friedman + CD plot ────────────────────────────────────────────────────────
res1 <- t(apply(na.omit(m), 1, function(x) rank(-x)))
cdt  <- friedman_cd(res1, alpha = 0.01)

png("results/cd_plot_feynman_C.png", width = 1300, height = 600)
plotCDx(cdt$rank_matrix, sort(cdt$avg_ranks), cdt$CDb, cdt$N, cdt$k,
        alpha = cdt$alpha, cex = 1.5, mr = c(1.75, 3.75))
dev.off()

# ── Boxplot ───────────────────────────────────────────────────────────────────
df_long <- melt(m, varnames = c("data", "algorithm"), value.name = "r2_test")
df_long$algorithm <- factor(df_long$algorithm, levels = names(sort(cdt$avg_ranks)))

n_alg     <- length(unique(df_long$algorithm))
my_colors <- qualitative_hcl(n_alg, palette = "Set3")

p_box <- ggplot(df_long, aes(x = algorithm, y = r2_test, fill = algorithm)) +
  geom_boxplot(alpha = 0.8) +
  coord_cartesian(ylim = c(-1, 1)) +
  scale_fill_manual(values = my_colors) +
  theme_minimal(base_size = 14) +
  labs(x = "Algorithm", y = "R² Test") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

ggsave("results/boxplot_feynman_C.png", p_box, width = 12, height = 6, dpi = 150)
