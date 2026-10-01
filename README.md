# Softened Neo-nationalist Public Sphere and Affective Reception of ‘Gukppong’ Content

This repository archives the code and analysis scripts for reproducing the research and validating the results of the paper **"Softened Neo-nationalist Public Sphere and Affective Reception of ‘Gukppong’ Content"**.

---

## 📄 Full Paper
The PDF file of the full paper can be found at the following path:
* Softened Neo-nationalist Public Sphere and Affective Reception of ‘Gukppong’ Content.pdf (located in docs/)

---

## 🔍 Research Overview
* **Research Topic**: Explores how neo-nationalism is consumed and affectively received on social media platforms, specifically focusing on YouTube Shorts "Gukppong" (chauvinistic/ultra-nationalistic Korean) content.
* **Analyzed YouTube Channels**: 10 prominent channels centering around nationalistic narratives:
  * 가나다라 (Ganadara), 국뽕한그릇주소 (Gukppong Hangeureut Juso), 대박s쇼츠 (Daebaks Shorts), 박노곰 (Baknogom), 별개다이쓔 (Byeolgaeda Issu), 썰렘 (Ssulrem), 쓸모왕 (Ssulmowang), 언택트립 (Untactrip), 잼킥 (Jamkick), 전국국뽕자랑 (Jeonguk Gukppong Jarang)
* **Key Methodologies**:
  * **Data Collection**: Fetching the top 100 comments per Shorts video (YouTube `relevance` order, one request per video) via the YouTube Data API v3. Collection date: 2025-09-21.
  * **Sentence Embedding & Dimensionality Reduction**: Generating semantic embeddings using the multi-task Korean Sentence-BERT (`jhgan/ko-sroberta-multitask`) and reducing dimensions via `UMAP`.
  * **Clustering**: Categorizing user reception into thematic dimensions using `K-means` ($K$ chosen by the Elbow Method). `HDBSCAN` labels are also computed in the notebook for exploratory comparison only; they are not used in the paper.
  * **Morphological Analysis**: Korean morphological tokenization and text preprocessing utilizing the `Ko-Mecab` morphological analyzer.
  * **Statistical Analysis**: Cluster statistical analysis, temporal trend analysis, and descriptive statistics verification.
* **Target Clusters ($K=6$)**:
  | Cluster | Cluster Title (Korean) | Cluster Title (English) | Description |
  | :---: | :--- | :--- | :--- |
  | **0** | 감성적 놀이로서의 민족주의 | Nationalism as Emotional Play | Lighthearted playfulness, internet memes, and collective positive sentiment. |
  | **1** | 음식 민족주의 | Food Nationalism | Collective pride driven by foreigners' reactions to Korean traditional and modern cuisine. |
  | **2** | 역사/정치적 민족주의 | Historical/Political Nationalism | Patriotism reinforced through critical stances on historical conflicts and territorial disputes. |
  | **3** | 문화 전쟁/반중 정서를 통한 민족주의 | Nationalism through Cultural War / Anti-Chinese Sentiment | Defensive and exclusive hostility against external cultural appropriation attempts. |
  | **4** | 개별 영웅 서사를 통한 민족주의 | Nationalism through Individual Hero Narratives | Narrative focus on individuals (athletes, artists, etc.) elevating national prestige globally. |
  | **5** | 기술/문화적 우월주의에 기반한 민족주의 | Nationalism based on Technological / Cultural Superiority | Celebration of domestic technological advancement (semiconductors, batteries) and global cultural influence. |

---

## 📂 Directory Structure
To ensure reproducibility, this repository logically separates the data collection and preprocessing phase, sentence embedding and clustering phase, and statistical analysis phase.

* docs/: Documents related to the paper
* notebook/: Jupyter notebook for sentence embeddings and clustering
* script/: Python scripts for comment collection and merging
* src/: R scripts for morphological tokenization, clustering analysis, and visualization
* data/: Collected and intermediate data (**not included**, see [Data Availability](#-data-availability))

### Pipeline (run from the repository root)
| Step | File | Input | Output |
| :---: | :--- | :--- | :--- |
| 1 | script/get_comment.py | YouTube Data API (`YOUTUBE_API_KEY` env var) | data/raw/top_100_comments_{channel}.csv |
| 2 | script/merge_comment.py | data/raw/*.csv | data/all_shorts_comments.csv |
| 3 | notebook/comment_clustering.ipynb | data/all_shorts_comments.csv | data/cluster_shorts.csv |
| 4 | src/shorts_preprocessing.R | data/cluster_shorts.csv | data/preprocessed.RData |
| 5 | src/shorts_kmeans.R | data/cluster_shorts.csv, data/preprocessed.RData | Fig. 2–6 |
| 6 | src/shorts_kmeans2.R | data/cluster_shorts.csv | Tables 2–4, Fig. 7–8 |
| 7 | src/shorts_table.R | data/cluster_shorts.csv | Top-50 comments per cluster (basis for cluster naming, Table 1) |

```
.
├── docs/
│   └── Softened Neo-nationalist Public Sphere and Affective Reception of ‘Gukppong’ Content.pdf
│
├── notebook/
│   └── comment_clustering.ipynb
│
├── script/
│   ├── get_comment.py
│   └── merge_comment.py
│
└── src/
    ├── shorts_preprocessing.R
    ├── shorts_kmeans.R
    ├── shorts_kmeans2.R
    └── shorts_table.R
```

---

## 💻 Detailed Components

### 1. Data Collection (script/)
* **script/**
  * get_comment.py: Python script to fetch the top 100 comments (`order='relevance'`) of every Shorts video (`UUSH` playlist) of the target channels via the YouTube Data API v3. Requires the `YOUTUBE_API_KEY` environment variable.
  * merge_comment.py: Python script to consolidate collected comment CSV files into a single unified dataset (all_shorts_comments.csv).

### 2. Sentence Embedding & Clustering (notebook/)
* **notebook/**
  * comment_clustering.ipynb: Jupyter notebook performing Sentence-BERT (`ko-sroberta-multitask`) embedding, UMAP dimensionality reduction (`n_components=15`, `random_state=123`, other parameters default), Elbow Method ($K$ = 2–19, distortion), K-means ($K=6$, `random_state=123`), and exploratory HDBSCAN (`min_cluster_size=15`), and outputting the clustered comments (data/cluster_shorts.csv).

### 3. Morphological Analysis, Statistical Analysis & Visualization (src/)
* **src/**
  * shorts_preprocessing.R: R script for Korean morphological tokenization using Mecab (utilizes `bitNLP` R package). Requires the notebook output. Token counts may differ slightly depending on the installed `mecab-ko-dic` version.
  * shorts_kmeans.R: R script conducting basic K-means cluster statistical analysis, distribution plotting, and visualization.
  * shorts_kmeans2.R: R script for detailed cluster trend analysis and statistical indices calculations.
  * shorts_table.R: R script listing the top 50 comments by likes per cluster, used for cluster naming.

---

## ⚙️ Environment Setup

### Key Dependencies
The following libraries are required to reproduce this analysis pipeline:

#### Python Environment (Python 3.8+)
* Sentence-Transformers (jhgan/ko-sroberta-multitask model utilized)
* UMAP-learn, scikit-learn, HDBSCAN, Yellowbrick (Dimensionality reduction, clustering, Elbow Method)
* Google API Python Client (YouTube Data API v3 client)
* Pandas, Tqdm, Jupyter

```bash
# Install Python packages
pip install pandas tqdm google-api-python-client sentence-transformers umap-learn scikit-learn hdbscan yellowbrick matplotlib jupyter
```

#### R Environment (requires system-level Mecab installation)
* Tidyverse, Tidytext (Data manipulation and text mining)
* Showtext, Gt, Data.tree, Future (Visualization and formatting)
* bitNLP (Ko-Mecab morphological tokenization)

```R
# Install R packages
install.packages(c("tidyverse", "tidytext", "showtext", "gt", "data.tree", "future"))
# Install dev version of bitNLP for Ko-Mecab support
# remotes::install_github("bit2r/bitNLP")
```

---

## 🗄️ Data Availability
The `data/` directory is excluded from this repository because the collected comments contain user-generated text and author display names, and redistribution of YouTube API data is restricted by the YouTube API Terms of Service. The raw data can be re-collected with `script/get_comment.py`; note that comments collected at a later date will differ from the original snapshot (2025-09-21). For access to the original dataset for verification purposes, please contact the corresponding author.

---

## ✉️ Contact & Citation
> Joo, J., Choe, J., & Kim, J. (2026). Softened Neo-nationalist Public Sphere and Affective Reception of ‘Gukppong’ Content: An Analysis of YouTube Shorts Comments Using sBERT Embeddings and K-means Clustering. *Journal of the Korea Contents Association*, 26(3).

If you wish to use this code or research data to conduct subsequent research or cite them, please refer to the paper located in `docs/`. For other inquiries related to the research, please refer to the corresponding author information in the paper.
