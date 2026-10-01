library(tidyverse)
library(tidytext)
library(bitNLP)

library(future)
plan(multisession, workers = parallel::detectCores() - 1)

df <- read_csv("data/cluster_shorts.csv")

df |>
  mutate(kmeans = factor(kmeans)) -> df

df |> 
  filter(kmeans == 0) |> 
  unnest_tokens(word, comment, morpho_mecab) -> cluster0

df |> 
  filter(kmeans == 1) |> 
  unnest_tokens(word, comment, morpho_mecab) -> cluster1

df |> 
  filter(kmeans == 2) |> 
  unnest_tokens(word, comment, morpho_mecab) -> cluster2

df |> 
  filter(kmeans == 3) |> 
  unnest_tokens(word, comment, morpho_mecab) -> cluster3

df |> 
  filter(kmeans == 4) |> 
  unnest_tokens(word, comment, morpho_mecab) -> cluster4
  
df |> 
  filter(kmeans == 5) |> 
  unnest_tokens(word, comment, morpho_mecab) -> cluster5

tmp <- rbind(rbind(cluster0, cluster1), rbind(cluster2, cluster3))
text.df <- rbind(tmp, rbind(cluster4, cluster5))

text.df |> 
  mutate(kmeans = factor(kmeans)) |>
  unnest_tokens(word, comment, morpho_mecab) -> text.df

text.df |>
  mutate(cluster = case_when(kmeans == 0 ~ "감성적 놀이로서의 민족주의",
                             kmeans == 1 ~ "음식 민족주의",
                             kmeans == 2 ~ "역사/정치적 민족주의",
                             kmeans == 3 ~ "문화 전쟁/반중 정서를 통한 민족주의",
                             kmeans == 4 ~ "개별 영웅 서사를 통한 민족주의",
                             kmeans == 5 ~ "기술/문화적 우월주의에 기반한 민족주의")) -> text.df

save(text.df, file = "data/preprocessed.RData")
