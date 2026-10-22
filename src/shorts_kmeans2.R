library(tidyverse)
library(tidytext)
library(data.tree)
library(showtext)
showtext_auto()

df <- read_csv("data/cluster_shorts.csv") |> 
  mutate(cluster = case_when(kmeans == 0 ~ "감성적 놀이로서의 민족주의",
                            kmeans == 1 ~ "음식 민족주의",
                            kmeans == 2 ~ "역사/정치적 민족주의",
                            kmeans == 3 ~ "문화 전쟁/반중 정서를 통한 민족주의",
                            kmeans == 4 ~ "개별 영웅 서사를 통한 민족주의",
                            kmeans == 5 ~ "기술/문화적 우월주의에 기반한 민족주의"),
          date = as.Date(publishedAt),
          kmeans = factor(kmeans),
          hdbscan = factor(hdbscan)) |> 
group_by(channelName) |> 
mutate(upload_min  = min(publishedAt),
       days_since_upload = as.numeric(difftime(publishedAt, upload_min, units = "days")),
       comment = str_replace_all(comment, " ", ""),
       length = nchar(comment)) |> 
ungroup()

df |> 
  summarise(
  mean_length = mean(nchar(comment), na.rm=TRUE),
  med_length  = median(nchar(comment), na.rm=TRUE),
  mean_likes  = mean(likeCount, na.rm=TRUE),
  med_likes   = median(likeCount, na.rm=TRUE)
)

df |> 
  group_by(cluster) |> 
  summarise(
    mean_length = mean(length, na.rm=TRUE),
    med_length  = median(length, na.rm=TRUE),
    mean_likes  = mean(likeCount, na.rm=TRUE),
    med_likes   = median(likeCount, na.rm=TRUE),
    n_comments  = n()
) 

ggplot(df, aes(x = length, fill = cluster)) +
  geom_histogram(binwidth = 10, show.legend = F) +
  geom_density(aes(y = after_stat(count) * 10), alpha = 0.2, show.legend = F) +
  facet_wrap(~cluster) +
  scale_x_continuous(limits = c(0, 1000))+
  labs(title="댓글 길이 분포", x="댓글 길이 (chars)", y="Count")

ggplot(df, aes(x = likeCount + 1, fill = cluster)) +
  geom_histogram(show.legend = F) +
  facet_wrap(~cluster) +
  scale_x_log10(labels = scales::comma) +
  labs(title="좋아요 수 분포 (log scale)", x="좋아요 수 +1 (log10)", y="Count")

df |>
  ggplot(aes(x = cluster, y = length, fill=cluster)) +
  geom_boxplot(show.legend = F) +
  scale_y_continuous(trans="log10", labels = scales::comma) +
  labs(title="K-Means 군집별 댓글 길이(log scale)", x="Cluster", y="Length")

df |>
  ggplot(aes(x = cluster, y = likeCount, fill = cluster)) +
  geom_boxplot(show.legend = F) +
  scale_y_continuous(trans="log10", labels = scales::comma) +
  labs(title="K-Means 군집별 좋아요 수 (log scale)", x="Cluster", y="Likes")


kl_divergence <- function(p, q) {
  keep <- p > 0                   
  if (any(q[keep] == 0)) return(Inf)
  sum(p[keep] * log(p[keep] / q[keep]))
}

calculate_kl_for_feature <- function(data, feature_col, cluster_col) {
  max_val <- max(data[[feature_col]], na.rm = TRUE)
  breaks <- seq(0, max_val + 5, length.out = 40)
  
  total_hist <- hist(data[[feature_col]], breaks = breaks, plot = FALSE)
  q_dist <- total_hist$density / sum(total_hist$density, na.rm = TRUE)
  
  clusters <- sort(unique(data[[cluster_col]]))
  kl_results <- list()
  
  for (cluster_id in clusters) {
    cluster_data <- data %>% filter(.data[[cluster_col]] == cluster_id)
    
    if (nrow(cluster_data) < 2) {
        kl_results[[as.character(cluster_id)]] <- NA
        next
    }
    
    cluster_hist <- hist(cluster_data[[feature_col]], breaks = breaks, plot = FALSE)
    p_dist <- cluster_hist$density / sum(cluster_hist$density, na.rm = TRUE)
    
    kl_value <- kl_divergence(p_dist, q_dist)
    kl_results[[as.character(cluster_id)]] <- kl_value
  }
  
  return(kl_results)
}

kl_length <- calculate_kl_for_feature(df, "length", "kmeans")
kl_likes <- calculate_kl_for_feature(df, "likeCount", "kmeans")

kl_summary_df <- data.frame(
  feature = c(rep("length", length(kl_length)), rep("likeCount", length(kl_likes))),
  cluster = c(names(kl_length), names(kl_likes)),
  kl_score = c(unlist(kl_length), unlist(kl_likes))
)

kl_summary_df$pathString <- paste("Total Data", kl_summary_df$feature, paste("Cluster", kl_summary_df$cluster), sep = "/")
kl_tree <- as.Node(kl_summary_df)

GetNodeLabel <- function(node) {
  if (node$isLeaf) {
    return(paste0(node$name, "\nKL: ", round(node$kl_score, 3)))
  }
  return(node$name)
}

GetNodeColor <- function(node) {
  if (!node$isLeaf) return('lightblue')
  
  kl_score <- node$kl_score
  if (is.na(kl_score) || is.null(kl_score)) return("white")
  
  max_kl <- max(kl_summary_df$kl_score, na.rm = TRUE)
  alpha <- pmin(kl_score / max_kl, 1) 
  return(rgb(1, 0.4, 0.4, alpha)) 
}

SetNodeStyle(kl_tree, 
             fontname = 'helvetica', 
             shape = 'box', 
             style = 'filled,rounded',
             color = 'gray50',
             fontcolor = 'black',
             label = GetNodeLabel,
             fillcolor = GetNodeColor)

SetEdgeStyle(kl_tree, arrowhead = 'vee', color = 'gray40', penwidth = 1.5)

plot(kl_tree)


df |>
  mutate(month = floor_date(date, "month")) |>
  count(month) |> 
  ggplot(aes(x = month, y = n)) +
  geom_line(color="navy") +
  labs(title="월별 댓글 수 추이", x="Month", y="Count")+
  theme_minimal()

df |>
  mutate(month = floor_date(date, "month")) |>
  count(cluster, month) |>
  ggplot(aes(x = month, y = n, color = cluster)) +
  geom_line(show.legend = F) +
  facet_wrap(~ cluster, scales="free_y") +
  labs(title="K-Means 군집별 월별 댓글 수 추이", x="Month", y="Count")+
  theme_minimal()


# Top 10 댓글 수 작성자
df |>
  count(author, sort=TRUE) |>
  slice_max(n, n=10)

# 댓글 5개 이상 단 작성자 중 Top 10 평균 좋아요
df |>
  group_by(author) |>
  filter(n() >= 5) |>
  summarise(avg_likes = mean(likeCount)) |>
  slice_max(avg_likes, n=10)

# 채널 별 댓글 수 작성자 상위 순위
df |>
  group_by(channelName, author) |> 
  tally() |>  
  slice_max(n=5, order_by = n) |> 
  ggplot(aes(x = n, y = reorder_within(author, n, channelName), fill = channelName))+
  geom_col(show.legend = F) +
  scale_y_reordered() +
  facet_wrap(~channelName, scales = "free") +
  ylab("words")+
  ggtitle("채널 별 상위 이용 유저 분석")

# 채널 별 좋아요 수 상위 유저 순위
df |>
  group_by(channelName, author) |> 
  summarise(n = sum(likeCount)) |> 
  slice_max(n=5, order_by = n) |> 
  ggplot(aes(x = n, y = reorder_within(author, n, channelName), fill = channelName))+
  geom_col(show.legend = F) +
  scale_y_reordered() +
  facet_wrap(~channelName, scales = "free") +
  ylab("words")+
  ggtitle("채널 별 상위 좋아요 유저 분석")

# 유저 통계
author_stats <- df |> 
  group_by(cluster, author) |> 
  summarise(
    n_comments_by_author = n(),
    .groups = "drop_last"
  ) |> 
  mutate(
    total_comments = sum(n_comments_by_author),
    unique_authors = n()
  ) |> 
  ungroup()

#  클러스터별 지표 계산
cluster_metrics <- author_stats |> 
  group_by(cluster) |> 
  summarise(
    total_comments     = unique(total_comments),
    unique_authors     = unique(unique_authors),
    unique_authors_ratio = unique_authors / total_comments,
    avg_comments_per_author = total_comments / unique_authors,
    n_repeat_authors  = sum(n_comments_by_author > 1),
    repeat_author_ratio = n_repeat_authors / unique_authors
  ) |> 
  ungroup() |> 
  arrange(cluster)


# Unique Authors Ratio
ggplot(cluster_metrics, aes(x = reorder(cluster, unique_authors_ratio), y = unique_authors_ratio)) +
  geom_col(fill = "skyblue") +
  coord_flip() +
  labs(
    title = "Cluster별 Unique Authors Ratio",
    x = "K-Means Cluster",
    y = "Unique Authors / Total Comments"
  )


# Repeat Author Ratio
ggplot(cluster_metrics, aes(x = reorder(cluster, desc(unique_authors_ratio)), y = repeat_author_ratio)) +
  geom_col(fill = "lightgreen") +
  coord_flip() +
  labs(
    title = "Cluster별 작성자 재방문율",
    x = "K-Means Cluster",
    y = "Repeat Author Ratio"
  )
