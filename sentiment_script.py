import requests
import json
import datetime
import os
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

# --- YAPILANDIRMA ---
CRYPTO_TERM = "Bitcoin"
SUBREDDIT = "cryptocurrency"
OUTPUT_PATH = "api_data/data.json" # Çıktı dosyasının yolu
# ---------------------

# 1. Veri Çekme (Reddit API Örneği)
def get_crypto_posts(subreddit=SUBREDDIT, limit=15):
    """Belirtilen subreddit'ten son başlıkları çeker."""
    url = f"https://www.reddit.com/r/{subreddit}/hot.json?limit={limit}"
    headers = {'User-Agent': 'KriptoAnalizSkripti/1.0 by github_action_bot'}
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        titles = []
        data = response.json()
        for post in data['data']['children']:
            title = post['data']['title']
            # Seçilen kripto kelimesini içeren başlıkları filtrele
            if CRYPTO_TERM.lower() in title.lower():
                titles.append(title)
        return titles
    except requests.RequestException as e:
        print(f"API isteği hatası: {e}")
        return []

# 2. Duyarlılık Analizi
def analyze_sentiment(texts):
    """Verilen metin listesinin ortalama duyarlılık skorunu hesaplar."""
    analyzer = SentimentIntensityAnalyzer()
    
    total_score = 0
    
    if not texts:
        return 0.0
        
    for text in texts:
        vs = analyzer.polarity_scores(text)
        total_score += vs['compound']
        
    average_sentiment = total_score / len(texts)
    return average_score

# 3. Ana Çalışma Fonksiyonu
if __name__ == "__main__":
    print(f"Reddit r/{SUBREDDIT} üzerinden '{CRYPTO_TERM}' başlıkları aranıyor...")
    posts = get_crypto_posts()

    if not posts:
        print("Analiz için yeterli başlık bulunamadı veya API hatası oluştu. JSON dosyası güncellenmeyecek.")
    else:
        sentiment_score = analyze_sentiment(posts)
        
        # Sonucu Kaydetme
        now_utc = datetime.datetime.now(datetime.timezone.utc).isoformat()
        
        result_data = {
            # Mobil uygulamanın kullanacağı temel skor
            "sentiment_score": round(sentiment_score, 4), 
            # Veri çekme zamanı
            "timestamp_utc": now_utc, 
            # Ek meta veriler
            "total_posts_analyzed": len(posts),
            "analyzed_term": CRYPTO_TERM,
            "source": f"Reddit r/{SUBREDDIT}"
        }
        
        # Klasörün varlığını kontrol et ve yoksa oluştur (GitHub Actions ortamında gerekli)
        os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
        
        # Sonucu 'api_data/data.json' dosyasına yaz
        with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
            json.dump(result_data, f, ensure_ascii=False, indent=4)
        
        print("-" * 30)
        print(f"✅ Başarılı. Duyarlılık Skoru Kaydedildi: {result_data['sentiment_score']}")
        print(f"JSON Çıktı Yolu: {OUTPUT_PATH}")
