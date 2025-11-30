import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ❗ API UÇ NOKTASI: Bu kısmı kendi GitHub RAW URL'nizle güncelleyin!
const String API_URL = 'https://raw.githubusercontent.com/kingdraww/Kriptoduyarlilik/main/api_data/data.json';

void main() {
  runApp(const CryptoSentimentApp());
}

class CryptoSentimentApp extends StatelessWidget {
  const CryptoSentimentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kripto Duyarlılık',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SentimentHomePage(),
    );
  }
}

class SentimentHomePage extends StatefulWidget {
  const SentimentHomePage({super.key});

  @override
  State<SentimentHomePage> createState() => _SentimentHomePageState();
}

class _SentimentHomePageState extends State<SentimentHomePage> {
  // Veri tutucular
  double _score = 0.0;
  String _label = 'Yükleniyor...';
  String _timestamp = 'Bilinmiyor';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSentimentData();
  }

  // GitHub Actions'tan (RAW JSON) veriyi çeken asenkron fonksiyon
  Future<void> _fetchSentimentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(API_URL));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Verileri al
        _score = (data['sentiment_score'] as num?)?.toDouble() ?? 0.0;
        final timestampUtc = data['timestamp_utc'] as String?;

        // Skora göre etiketi ve rengi belirle
        _updateSentimentVisuals(_score);
        
        // Zaman damgasını biçimlendir
        if (timestampUtc != null) {
          _timestamp = DateTime.parse(timestampUtc).toLocal().toString().substring(0, 16);
        } else {
          _timestamp = 'Zaman bilgisi yok';
        }
      } else {
        _label = 'Hata: API yanıtı başarısız oldu (${response.statusCode})';
      }
    } catch (e) {
      _label = 'Hata: Bağlantı sorunu veya geçersiz JSON. URL\'yi kontrol edin.';
      print('Veri çekme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Skora göre arayüzü güncelleyen fonksiyon
  void _updateSentimentVisuals(double score) {
    if (score > 0.3) {
      _label = "AŞIRI İYİMSERLİK (Yüksek Pozitif)";
    } else if (score > 0.05) {
      _label = "POZİTİF";
    } else if (score > -0.05) {
      _label = "NÖTR/DENGE";
    } else if (score > -0.3) {
      _label = "NEGATİF";
    } else {
      _label = "YÜKSEK KORKU/PANİK (Aşırı Negatif)";
    }
  }

  // Skora göre renk dönen fonksiyon
  Color _getScoreColor(double score) {
    if (score > 0.3) return Colors.green.shade700;
    if (score > 0.05) return Colors.green.shade400;
    if (score > -0.05) return Colors.amber;
    if (score > -0.3) return Colors.red.shade400;
    return Colors.red.shade700;
  }


  @override
  Widget build(BuildContext context) {
    // Uygulama yapısı (Scaffold)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kripto Duyarlılık Takipçisi'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchSentimentData, // Yüklenirken deaktif
          ),
        ],
      ),
      body: Center(
        child: _isLoading 
            ? const CircularProgressIndicator() // Yüklenirken spinner göster
            : SingleChildScrollView( // Mobil kaydırma özelliği
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Duyarlılık Skoru Kartı
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text('Güncel Duyarlılık Skoru', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            const SizedBox(height: 10),
                            Text(
                              _score.toStringAsFixed(4), // 4 ondalık basamak
                              style: TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(_score), // Skora göre renk
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _label,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _getScoreColor(_score),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Veri Kaynağı ve Güncelleme Kartı
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Son Güncelleme Zamanı (Yerel)'),
                        subtitle: Text(_timestamp),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Veri Kaynağı'),
                        subtitle: Text('GitHub Actions tarafından Reddit verisi analiz edilmiştir.'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
