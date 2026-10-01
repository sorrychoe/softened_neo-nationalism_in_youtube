import os
import tqdm
import time
import csv

import pandas as pd
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

API_KEY = os.environ["YOUTUBE_API_KEY"]

channel_id_dict = {
                    "언택트립" : "UCF44GGIofZeEd_RRigSFafA",
                    "박노곰" : "UC4P0OunekUgaNC1i0i91Xww", 
                    "대박s쇼츠" : "UCy6X4RYTjGnrQQpwC6xQG9g",
                    "국뽕한그릇주소" : "UCst_mVE-gAub8Vmu8-dYqfg",
                    "별개다이쓔" : "UCHmwJFSi8uZjXeonbFqsXAw",
                    "가나다라" : "UCZ8HXiVLpvaGJYJ2jcN3Afg",
                    "썰렘" : "UC6h_t1mKuZyrzB24Av7BVJA",
                    "잼킥" : "UCLctTGJKoYfrok4dKWq5EsA",
                    "쓸모왕" : "UCVObSp4MlJwCsh6vtKz4PHQ",
                    "전국국뽕자랑":"UC7A_81958yjUZQbKG1LA9TA"
                  }

        
youtube = build('youtube', 'v3', developerKey=API_KEY)

def get_shorts_playlist_id(channel_id):
   """숏츠 전용 playlist ID 계산 (UUSH...)"""
   if channel_id.startswith('UC'):
       return 'UUSH' + channel_id[2:]
   else:
       raise ValueError("💡 UC로 시작하는 채널 ID 필요")

def get_all_video_ids_from_playlist(playlist_id):
    """uploads playlist에서 모든 videoId 추출"""
    video_ids = []
    next_page_token = None

    while True:
        response = youtube.playlistItems().list(
            part='contentDetails',
            playlistId=playlist_id,
            maxResults=50,
            pageToken=next_page_token
        ).execute()

        for item in response['items']:
            video_ids.append(item['contentDetails']['videoId'])

        next_page_token = response.get('nextPageToken')
        if not next_page_token:
            break

        time.sleep(0.3)
    print(f"{len(video_ids)}'s video ids are added!")
    return video_ids

def get_relevant_comments(video_id, channel_name):
    """유튜브 내부 추천시스템 기준 상위 100개의 댓글 추출 함수"""
    all_comments = []
    response = youtube.commentThreads().list(
            part='snippet',
            videoId=video_id,
            maxResults=100,
            textFormat='plainText',
            order='relevance',
        ).execute()
    
    for item in response['items']:
        snippet = item['snippet']['topLevelComment']['snippet']
        like = snippet.get('likeCount', 0)
        published_at = snippet.get('publishedAt', '')
        comment_data = {
            'channelName': channel_name,
            'videoId': video_id,
            'author': snippet.get('authorDisplayName'),
            'comment': snippet.get('textDisplay'),
            'likeCount': like,
            'publishedAt': published_at
        }
        all_comments.append(comment_data)
    return all_comments

if __name__ == "__main__":
    for channel_id in channel_id_dict.items():
        shorts_playlist_id = get_shorts_playlist_id(channel_id[1])
        
        video_ids = get_all_video_ids_from_playlist(shorts_playlist_id) 

        print(f"{channel_id[0]}의 영상 추출 진행중")
        all_top_comments = []
        for video_id in tqdm.tqdm(video_ids):
            try:
                time.sleep(0.3)
                comments = get_relevant_comments(video_id, channel_id[0])
                all_top_comments.extend(comments)
            except HttpError as e:
                if e.resp.status == 403 and 'commentsDisabled' in str(e):
                    print(f"⚠️ Video {video_id} has comments disabled. Skipping.")
                    continue
                else:
                    raise

        df = pd.DataFrame(all_top_comments)
        df.to_csv(f'data/raw/top_100_comments_{channel_id[0]}.csv', index=False, encoding='utf-8-sig', 
                quoting=csv.QUOTE_ALL, escapechar='\\')

    print("✅ 모든 영상에 대해 상위 100개 댓글 수집 완료")
