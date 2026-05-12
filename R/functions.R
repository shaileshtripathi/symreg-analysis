library(colorspace)

# Inlined from scmamp — avoids installing the package
getNemenyiCD <- function(alpha, num.alg, num.problems) {
  q_alpha <- qtukey(1 - alpha, nmeans = num.alg, df = Inf) / sqrt(2)
  q_alpha * sqrt(num.alg * (num.alg + 1) / (6 * num.problems))
}


rank_row <- function(x) {
  n    <- length(x)
  is_na <- is.na(x)
  r    <- rep(NA, n)
  r[!is_na] <- rank(-x[!is_na], ties.method = "min")
  r[is_na]  <- max(r[!is_na], na.rm = TRUE) + 1
  return(r)
}

plotCDx <- function(results.matrix, mean.rank, cd, N, k,
                    alpha = 0.05, cex = 0.75, mr = c(5, 5), grp = "_mse", ...) {
  opar <- par(mar = c(0, 0, 0, 0))
  on.exit(par(opar))

  names(mean.rank) <- gsub(grp, "", names(mean.rank))
  mthlbl       <- colnames(results.matrix)
  mthlbl_lower <- tolower(mthlbl)
  names(mthlbl) <- mthlbl_lower

  new_names <- sapply(tolower(names(mean.rank)), function(n) {
    if (n %in% names(mthlbl)) mthlbl[[n]] else n
  })
  names(mean.rank) <- new_names

  lp         <- round(k / 2)
  left.algs  <- mean.rank[1:lp]
  right.algs <- mean.rank[(lp + 1):k]
  max.rows   <- ceiling(k / 2)

  char.size          <- 0.001
  line.spacing       <- 0.25
  m                  <- floor(min(mean.rank))
  M                  <- ceiling(max(mean.rank))
  max.char           <- max(sapply(colnames(results.matrix), nchar))
  text.width         <- (max.char + 4) * char.size
  w                  <- (M - m) + 2 * text.width
  h.up               <- 2.5 * line.spacing
  h.down             <- (max.rows + 2.25) * line.spacing
  tick.h             <- 0.25 * line.spacing
  label.displacement <- 0.25
  line.displacement  <- 0.025

  plot(0, 0, type = "n",
       xlim = c((m - w / (M - m)) - mr[1], (M + w / (M - m)) + mr[2]),
       ylim = c(-h.down, h.up),
       xaxt = "n", yaxt = "n", xlab = "", ylab = "", bty = "n")

  lines(c(m, M), c(0, 0))
  sapply(m:M, function(x) {
    lines(c(x, x), c(0, tick.h))
    text(x, 3 * tick.h, labels = x, cex = cex)
  })

  lines(c(m, m + cd), c(1.75 * line.spacing, 1.75 * line.spacing))
  text(m + cd / 2, 2.25 * line.spacing, "CD", cex = cex)
  lines(c(m, m),         c(1.75 * line.spacing - tick.h / 4, 1.75 * line.spacing + tick.h / 4))
  lines(c(m + cd, m + cd), c(1.75 * line.spacing - tick.h / 4, 1.75 * line.spacing + tick.h / 4))

  sapply(seq_along(left.algs), function(x) {
    line.h <- -line.spacing * (x + 2)
    text(m - label.displacement, line.h, names(left.algs)[x], cex = cex, adj = 1)
    lines(c(m - label.displacement * 0.75, left.algs[x]), c(line.h, line.h))
    lines(c(left.algs[x], left.algs[x]), c(line.h, 0))
  })

  sapply(seq_along(right.algs), function(x) {
    line.h <- -line.spacing * (x + 2)
    text(M + label.displacement, line.h, names(right.algs)[x], cex = cex, adj = 0)
    lines(c(M + label.displacement * 0.75, right.algs[x]), c(line.h, line.h))
    lines(c(right.algs[x], right.algs[x]), c(line.h, 0))
  })

  getInterval <- function(x) {
    from <- mean.rank[x]
    diff <- mean.rank - from
    ls   <- which(diff > 0 & diff < cd)
    if (length(ls) > 0) c(from, mean.rank[max(ls)])
  }

  intervals <- mapply(1:k, FUN = getInterval)
  aux       <- do.call(rbind, intervals)

  if (NROW(aux) > 0) {
    to.join <- aux[1, ]
    if (nrow(aux) > 1) {
      for (r in 2:nrow(aux)) {
        if (aux[r - 1, 2] < aux[r, 2]) to.join <- rbind(to.join, aux[r, ])
      }
    }
    if (!is.matrix(to.join)) to.join <- t(as.matrix(to.join))
    nlines <- nrow(to.join)
    row    <- 1
    for (r in seq_len(nlines)[-1]) {
      row <- c(row, if (to.join[r, 1] > to.join[r - 1, 2]) 1 else tail(row, 1) + 1)
    }
    step <- max(row) / 2
    sapply(seq_len(nlines), function(x) {
      y <- -line.spacing * (0.5 + row[x] / step)
      lines(c(to.join[x, 1] - line.displacement, to.join[x, 2] + line.displacement),
            c(y, y), lwd = 3)
    })
  }
}

friedman_cd <- function(rank_matrix, alpha = 0.05) {
  k      <- ncol(rank_matrix)
  N      <- nrow(rank_matrix)
  avg_ranks <- numeric(k)
  counts    <- numeric(k)

  for (j in 1:k) {
    used         <- rank_matrix[, j] != 0
    avg_ranks[j] <- sum(rank_matrix[used, j])
    counts[j]    <- sum(used)
  }
  avg_ranks <- avg_ranks / counts

  q_alpha <- qtukey(1 - alpha, nmeans = k, df = Inf) / sqrt(2)
  CD      <- q_alpha * sqrt(k * (k + 1) / (6 * N))
  cd_b    <- getNemenyiCD(alpha = alpha, num.alg = k, num.problems = N)

  list(avg_ranks   = setNames(avg_ranks, colnames(rank_matrix)),
       CD          = CD,
       CDb         = cd_b,
       alpha       = alpha,
       k           = k,
       N           = N,
       rank_matrix = rank_matrix)
}
