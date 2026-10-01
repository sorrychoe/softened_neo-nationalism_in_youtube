library(tidyverse)
library(tidytext)
library(showtext)
showtext_auto()

df <- read_csv("data/cluster_shorts.csv")

df |> 
  mutate(cluster = case_when(kmeans == 0 ~ "감성적 놀이로서의 민족주의",
                             kmeans == 1 ~ "음식 민족주의",
                             kmeans == 2 ~ "역사/정치적 민족주의",
                             kmeans == 3 ~ "문화 전쟁/반중 정서를 통한 민족주의",
                             kmeans == 4 ~ "개별 영웅 서사를 통한 민족주의",
                             kmeans == 5 ~ "기술/문화적 우월주의에 기반한 민족주의")) -> df

df |> 
  mutate(year = factor(year(publishedAt))) |> 
  group_by(cluster, year) |> 
  summarise(like = sum(likeCount)) |> 
  ggplot(aes(x = year, y = like, group = cluster, color = cluster))+
  geom_line() +
  geom_point() +
  # labs(x = "", y = "", title = "군집 별 좋아요 빈도 시계열 분석")+
  labs(x = "", y = "")+
  scale_y_continuous(labels = scales::comma)+
  theme(text = element_text(size = 18))

df |> 
  filter(channelName == "국뽕한그릇주소") |> 
  group_by(cluster) |> 
  summarise(like = sum(likeCount)) |> 
  ggplot(aes(x="", y=like, fill=cluster))+
  geom_bar(stat = "identity", width=1)+
  coord_polar("y", start=0) +
  xlab("")+
  ylab("")+
  ggtitle("국뽕한그릇주소 채널의 군집 비율")

df |> 
  filter(kmeans == 2) |> 
  mutate(year = factor(year(publishedAt))) |> 
  filter(year != 2022) |> 
  group_by(channelName, year) |> 
  tally() |> 
  ggplot(aes(x = year, y = n, group = channelName, color = channelName))+
  geom_line() +
  geom_point()

df|> 
  group_by(cluster) |>
  tally() |> 
  ggplot(aes(x = n, y = reorder(cluster,n), fill=cluster)) +
  geom_col(show.legend = F)+
  # labs(x = "", y = "", title = "군집 별 댓글 빈도")+
  labs(x = "", y = "")+
  theme(text = element_text(size = 18))

df|> 
  mutate(year = year(publishedAt)) |> 
  filter(year != 2022) |> 
  group_by(year, cluster) |> 
  tally() |> 
  ggplot(aes(x = year, y = n, fill = cluster))+
  geom_bar(stat = "identity") + 
  xlab("") +
  ylab("") +
  theme(text = element_text(size = 18))

df |> 
  group_by(cluster) |> 
  reframe(like = mean(likeCount)) |> 
  ggplot(aes(x = like, y = reorder(cluster,like), fill=cluster)) +
  geom_col(show.legend = F)+
  ylab("")

df |> 
   filter(kmeans == 5) |> 
   mutate(month = as.Date(floor_date(publishedAt, "month"))) |> 
   group_by(channelName, month) |> 
   tally() |> 
   ggplot(aes(x = month, y = n, group = channelName, color = channelName))+
   geom_line() +
   geom_point() +
   scale_x_date(
    date_breaks = "3 months",  
    date_labels = "%Y-%m"     
   ) +
   labs(title = "기술/문화적 우월주의에 기반한 민족주의")+
   theme_minimal()

# ======================
load("data/preprocessed.RData")

text.df|> 
  group_by(cluster, word) |> 
  tally() |> 
  filter(nchar(word)>=2, 
         !grepl("[[:digit:]]", word),
         !grepl("ㅠ|ㅜ|ㅎ|ㄷ|ㅋ", word)) |> 
  arrange(cluster, desc(n)) |>  
  slice_head(n = 10) |>
  ggplot(aes(x = n, y = reorder_within(word, n, cluster), fill = cluster))+
  geom_col(show.legend = F) +
  scale_y_reordered() +
  facet_wrap(~cluster, scales = "free") +
  ylab("words")+
  ggtitle("군집 별 상위 단어 빈도 분석")

text.df |> 
  filter(nchar(word)>=2, 
         !grepl("[[:digit:]]", word),
         !grepl("ㅠ|ㅜ|ㅎ|ㄷ|ㅋ", word)) |> 
  count(cluster, word, sort = TRUE) |> 
  bind_tf_idf(word, cluster, n) |> 
  arrange(cluster,desc(tf_idf)) |> 
  group_by(cluster) |> 
  slice_head(n = 10) |> 
  ungroup() |> 
  ggplot(aes(x = tf_idf, y = reorder_within(word, tf_idf, cluster), fill = cluster))+
  geom_col(show.legend = F) +
  scale_y_reordered() +
  facet_wrap(~cluster, scales = "free") +
  ylab("words") +
  ggtitle("군집 별 tf-idf 단어 빈도 분석")

