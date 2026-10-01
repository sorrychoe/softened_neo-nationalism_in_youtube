import os
import pandas as pd

files = os.listdir("data/raw")

df = pd.DataFrame()

for i in files:
    tmp = pd.read_csv(f"data/raw/{i}")
    df = pd.concat([df, tmp])
df.reset_index(drop=True, inplace=True)

df.to_csv("data/all_shorts_comments.csv", index=False, encoding='utf-8-sig')