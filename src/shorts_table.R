library(tidyverse)
library(gt)
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
       length = nchar(str_remove_all(comment, " "))) |> 
ungroup()

# 군집 명명용: 군집 별 좋아요 상위 50개 댓글
df |>
  group_by(cluster) |>
  slice_max(order_by = likeCount, n = 50) |>
  arrange(kmeans, desc(likeCount)) |>
  select(cluster, likeCount, comment) |>  gt()
