# ANTIGRAVITY MASTER PROMPT — PROJECT 7 DIGITAL COMMUNICATION SYSTEM

## Rolün ve nihai hedef

Sen kıdemli MATLAB geliştiricisi, dijital haberleşme mühendisi, test mühendisi ve teknik dokümantasyon yazarısın. Çalışma dizini **`~/digital-com-project`**. Bu repoda halihazırda oluşturulmuş taslakları **yeniden başlatmadan, mevcut çalışmaları silmeden** kullanarak aşağıda tarif edilen projeyi **uçtan uca, çalışır, doğrulanabilir ve teslim edilebilir** duruma getir.

Görev yalnızca plan, örnek kod veya açıklama üretmek değil: dosyaları gerçekten düzenle, gerekli MATLAB `.m` dosyalarını oluştur/uygula, testleri çalıştır, sonuçları kaydet, GUI'yi oluştur ve kullanım belgelerini yaz. Yapabildiğin her şeyi bizzat tamamla; ortamda MATLAB/Octave mevcut değilse açıkça belirt, statik kontrolleri yap ve çalıştırılamayan testleri **geçmiş gibi gösterme**.

**Önce mevcut repo durumunu incele:** `pwd`, `git status --short`, `find . -maxdepth 4 -type f | sort`, MATLAB/Octave var mı, hangi dosyalar mevcut, hangi kodlar uygulanmış. Mevcut kullanıcı kodlarını, raporları, verilere ait dosyaları ve git geçmişini koru. **`git reset --hard`, `git clean -fd`, tüm dizini silme, izinsiz overwrite, otomatik commit/push yapma.** Yeni klasör veya dosya gerekiyorsa ekle. Var olan iskelet fonksiyonları gerçekten çalışan implementasyonlarla değiştir. Kullanıcıdan temel detayları sormadan makul tercihleri uygula ve varsayımları belgele.

## 1. Ödev şartları — bağlayıcı spesifikasyon

Sistem akışı:

`Audio Source -> mu-law PCM Encoder -> (8,4) Channel Encoder -> Gray QPSK Modulator -> Complex AWGN -> ML QPSK Demodulator -> Syndrome Channel Decoder -> PCM Decoder + Reconstruction -> Audio Sink`

- Giriş: MATLAB mikrofon kaydı **8 kHz, 10 saniye**; ayrıca kursun verdiği herhangi bir WAV ses dosyasını giriş olarak kullanabilmeli. WAV sample rate farklıysa açıkça ve kaliteli bir yeniden örnekleme yöntemi uygula; çok kanallı ses için mono dönüşümü açıkla; 10 saniyeyi aşan dosya için kırpma veya seçilebilir bölüm, kısa dosya için açık politika uygula.
- PCM: **mu-law companding, mu=255**, seçilebilir **3, 4, 8 bit** uniform quantization *compressed domain* üzerinde. Doğru bit paketleme/açma, normalization ve quantizer convention; SQNR ölçümü ve geri açma. Sesin tamamını bilgi kaybı olmadan paketlenmiş bit dizisi halinde sakla (kuantalama kaybı hariç). Kayıplı kanalın oluşturduğu hataları ayrıca ölç.
- Opsiyon değil, ödevin ara görevi: **Delta Modulation (DM) ve Adaptive Delta Modulation (ADM)** için birbirinden bağımsız encoder ve decoder fonksiyonları; sinüzoidal test, step-size/slope overload/granular noise karşılaştırması. ADM adaptasyon kuralını ve sınırlarını belgelerde belirt. Ana final iletişim zinciri PCM kullanır; DM/ADM ayrı karşılaştırma bölümüdür.
- Channel coding: Fotoğrafta verilen `(8,4)` parity-check matrisi tam olarak:

  ```matlab
  H = [1 0 1 1 1 0 0 0;
       1 1 1 0 0 1 0 0;
       0 1 1 1 0 0 1 0;
       1 1 0 1 0 0 0 1];
  ```

  Bu H'nin son dört kolonu `I4` oluşturur. `P=H(:,1:4).'`, `G=[eye(4),P]`. `mod(G*H.',2)` sıfır olmalı. Mesajlar 4 bitlik satır gruplarına ayrılır, `c=mod(m*G,2)`. Tek bit hataları syndrome ile düzeltilebilmeli, iki bit hataları tespit edilip **yanlışlıkla düzeltilmiş gibi etiketlenmemeli**. Sıfır syndrome tek başına hatasızlık garantisi değildir. SECDED özelliklerini test et. Extended Hamming (8,4) için syndrome eşlemesini güvenilir kur; tüm 16 geçerli codeword'ü ve her bit konumundaki hata örüntülerini incele. Çoklu bit hatalarında tespit edilemeyen veya yanlış karar verebilen durumları dürüstçe belgeleyerek çıktılarda `status` ver.
- QPSK: Gray mapping, iki bilgi/kodlu bit başına bir kompleks QPSK sembolü. **Tam olarak bir tutarlı Gray haritası seç ve hem mod hem demod'da kullan.** Önerilen eşleme: `00 -> (+1+j)/sqrt(2)`, `01 -> (-1+j)/sqrt(2)`, `11 -> (-1-j)/sqrt(2)`, `10 -> (+1-j)/sqrt(2)`. Eşleme testi ve constellation plot. Alıcı: AWGN altında nearest-neighbor/maximum likelihood karar; `argmin(abs(r-s).^2)`. RF taşıyıcı dalga modeli gerekmiyor; complex baseband yeterli.
- Kanal: Kendi AWGN fonksiyonunu `randn` ile uygula. Complex noise için **I ve Q'nin varyansını doğru ayır**: `n=sqrt(N0/2)*(randn(...)+1j*randn(...))`. *Sinyal sembol gücü sabit tutulurken* SNR ayarlanır. Ana ödev parametresi **0:1:10 dB**, log BER ekseni. **SNR tanımını özellikle açıkla**: `Es/N0` mu, `Eb/N0` mu? Birincil grafikte SNR kullan; başka grafiklerde enerji eşitliği ve code rate nedeniyle dönüşümü net belgele. Coded vs uncoded adil karşılaştırmasında aynı **information-bit energy** ve code rate `R=1/2` dikkate alınmalı; farklı tanımları aynı etikete koyma.
- BER: Bit hataları / karşılaştırılan toplam bit. En azından demod sonrası *coded-bit* BER (transmitted coded bits vs demodulated bits) ve kanal decoding sonrası *information-bit* BER (source info bits vs decoder outputs) hesapla. Bunları tek başına eşdeğer ölçümmüş gibi sunma. Mümkünse ayrı **uncoded QPSK baseline** oluştur ve BER teorisi ile karşılaştır. SNR=0..10 her biri için veri üret, bit sayısı / seed / simülasyon durumunu kayıt altına al. `BER=0` log eksende çizilemez; sıfır hata için görselleştirme/upper-bound yaklaşımını açıkça göster ve ölçülen gerçek BER'i **sıfır** olarak raporla. Sahte pozitif BER değerleri yazma.
- Grafikler: orijinal/kuantalanmış/alınan ses dalga şekilleri; SQNR–bit sayısı; temiz/gürültülü QPSK constellation; BER–SNR (`semilogy`); DM/ADM karşılaştırması. Üretilen grafiklerde tüm eksen, birim, legend, figür açıklamaları yer alsın.
- GUI: Kullanıcı WAV seçebilmeli, mikrofon kaydı yapabilmeli (destek yoksa anlaşılır hata), PCM bits seçebilmeli, SNR seçebilmeli, tek SNR simülasyonu ve 0..10 dB sweep başlatabilmeli, BER/SQNR/plots gösterebilmeli, original/received audio dinleyebilmeli ve sonucu dışa aktarabilmeli. Uzun işlemde ilerleme göstergesi ve input validation; hata alınırsa GUI çökmesin.
- Final: Açıklayıcı teknik rapor (teori, design, varsayımlar, testler ve MATLAB listing), **A0 poster** için düzenlenebilir içerik/şablon ve grafik/numerik çıktılar. Gerçek test çalıştırılmadan sonuç uydurma. GUI + fonksiyonlar + dokümanlar birlikte teslim edilebilir olsun.
- **Communication Toolbox'ın hazır implementasyonları yasak:** `pskmod`, `pskdemod`, `awgn`, `comm.*`, `encode`, `decode`, `biterr`, `berawgn`, `qammod`, `qamdemod` vb. **Kullanma.** MATLAB temel aritmetik, matris, `randn`, `audioread`, `audiowrite`, `audiorecorder`, `plot`, `semilogy` vb. serbest. Kullanılan her bağımlılığı belgele. DSP/Signal Processing toolbox gerektirmeyen uygulanabilir çözümü tercih et.

## 2. Repo organizasyonu ve sahiplik

Mevcut taslakları kullan; dosya isimlerini mümkün olduğunca koru. Gerekirse yeni yardımcı `.m` dosyaları ekle:

```text
~/digital-com-project/
├── main.m
├── README.md
├── .gitignore
├── src/
│   ├── person1_audio/
│   │   ├── audio_input.m
│   │   ├── pcm_encoder.m
│   │   ├── pcm_decoder.m
│   │   ├── calculate_sqnr.m
│   │   ├── dm_encoder.m
│   │   ├── dm_decoder.m
│   │   ├── adm_encoder.m
│   │   └── adm_decoder.m
│   ├── person2_channel_coding/
│   │   ├── generate_matrices.m
│   │   ├── channel_encoder.m
│   │   └── channel_decoder.m
│   ├── person3_modulation/
│   │   ├── qpsk_mod.m
│   │   ├── qpsk_demod.m
│   │   ├── add_awgn.m
│   │   ├── calculate_ber.m
│   │   └── ber_simulation.m
│   └── common/                 # only if needed
├── gui/
├── tests/
│   ├── test_pcm.m
│   ├── test_dm_adm.m
│   ├── test_channel_coding.m
│   ├── test_qpsk.m
│   ├── test_awgn.m
│   └── test_full_system.m
├── data/input/
├── data/output/
├── results/figures/
├── results/tables/
├── reports/
├── poster/
└── docs/
```

Geliştirme sahipliği (raporda ve README'de belirt):

- Kişi 1: ses girişi, μ-law PCM, quantization, SQNR, DM/ADM, reconstruction, GUI layout katkısı.
- Kişi 2: H/G, encoding, syndrome SECDED decoding, hata düzeltme testleri, decoder veri/istatistik katkısı.
- Kişi 3: QPSK, AWGN, ML demod, BER/SNR simülasyonu, GUI entegrasyonu, uçtan uca ana sistem.
- Belgeler/entegrasyon testleri ortak. Bu görev dağılımı **dosyaları birbirinden koparmamalı**: ortak arayüz sözleşmesi kullan.

## 3. Zorunlu fonksiyon API sözleşmeleri

Bu arayüzleri temel al; gerekiyorsa ekstra input/output ekle ama çağrıları tutarlı güncelle ve `docs/API.md` yaz:

```matlab
[audio, fs, metadata] = audio_input(source, fsTarget, durationSec);
[bits, pcmMeta, quantizedSignal] = pcm_encoder(audio, nBits, mu);
[reconstructedAudio, recoveredLevels] = pcm_decoder(bits, pcmMeta);
sqnrDB = calculate_sqnr(referenceAudio, reconstructedAudio);
[encodedBits, padInfo] = channel_encoder(infoBits, G);
[decodedBits, decodeStats] = channel_decoder(receivedBits, H, padInfo);
[G, H] = generate_matrices();
txSymbols = qpsk_mod(bits);
[rxBits, detectedSymbols] = qpsk_demod(rxSymbols);
[rxSymbols, channelMeta] = add_awgn(txSymbols, snrDB, snrDefinition, codeRate);
ber = calculate_ber(referenceBits, receivedBits);
results = ber_simulation(config);
results = run_full_system(config); % create this helper or use an equivalent stable API
```

**Arayüz veri tipleri:** bitler `double` türünde `N x 1` sütun vektörü; yalnızca 0/1. Ses `N x 1` sütun vektörü. Kompleks semboller `N x 1`. Fonksiyonlar satır/sütun inputlarına dayanıklı olabilir ama çıktılar bir standarda uysun. Her API boyut/doğruluk validasyonu yapmalı. Bit sayısı 4/2 ile tam bölünmezse `padding` metadata taşı ve decode sonrasında **sadece eklenen padding bitlerini çıkar**; input boyutu muhafaza edilmeli. Sese ait normalization bilgisi ve sample count PCM metadata içinde tutulmalı. Hiçbir aşama başlık, pad veya başka metadata'yı yanlışlıkla iletim bitleri gibi saymamalı. GUI ve tests aynı API'yi çağırmalı; iki ayrı haberleşme implementasyonu yazma.

## 4. Matematiksel doğruluk / uygulama ayrıntıları

### μ-law PCM

- `mu=255`, ses `[-1,1]` aralığında. Normalize ederken mutlak maksimum sıfır ise bölme yapma; orijinal scale gerektiğinde metadata üzerinden geri kazan.
- Kompresyon: `y=sign(x).*log(1+mu*abs(x))/log(1+mu)`.
- Kuantalama seviyeleri: `L=2^nBits`; orta noktalı *mid-rise uniform quantizer* gibi açık ve tekrarlanabilir bir konvansiyon seç. `x==1` ve `x==-1` saturasyonu doğru; endeks `0 ... L-1`. Endeks-bit dönüşümü için MATLAB `de2bi/bi2de` gibi toolbox fonksiyonlarına bağımlı olmadan `bitget`, `bitshift`, `bitand` veya temel işlemler uygula; MSB/LSB sırasını tanımla ve round-trip test et.
- İnvers `xhat=sign(yhat).*((1+mu).^abs(yhat)-1)/mu`.
- SQNR karşılaştırmasını **kanal eklenmeden önce** orijinal ses ve PCM-reconstructed ses arasında yap. Ölçüm 0 sinyal / 0 hata özel durumlarını tanımla.
- `sinc` reconstruction: sample values'in anlamını bozacak veya 80.000 örnek için `O(N^2)` dev matris çıkaracak uygulama yapma. Çıktıyı örnekleme gridinde koruyarak isteğe bağlı kısa pencere sinc interpolasyonunu **sınırlı örnekli grafik/upsampling** için uygula; reconstruction ve interpolation ayrımını belgele.

### SECDED

- `G` ve `H` için assert kontrolleri.
- 16 bilgi bloğu x 8 kod biti test, valid codewords syndrome 0.
- Tüm `16*8` tek bit flip durumları -> özgün mesajın geri kazanımı.
- Tüm `16*nchoosek(8,2)` iki bit flip durumları -> detect/don't miscorrect, sonuç status ile bildirilsin.
- H'deki sütunların benzersiz ve sıfırdan farklı olmasını doğrula. Bu H için standart SECDED syndrome/parity ayrımını matematikle türet; **sadece sütunla eşleşmeyen syndrome'u körlemesine tek bit diye düzeltme**.
- Blokların uncorrectable bayrağını raporla, gizleme. Kodun belirli 3+ hataları teşhis edemeyebileceğini belgede belirt.

### QPSK, kanal ve BER

- Birim ortalama sembol enerjisi `Es=1`; test et.
- İki bitlik Gray mapping ve demapping tam ters işlemler. Test `all pairs` ve binlerce random bit.
- `add_awgn` gürültü varyansı tanımını açıkça matematiksel olarak belgelemeli. Eğer `snrDefinition='EsN0'`: `N0=Es/10^(snrDB/10)`. Eğer `'EbN0'` tanımı bilgi-bit enerjisi içinse `Es/N0 = (k_mod * R_c) * Eb_info/N0` ile tutarlı ilişkiyi uygula (`k_mod=2`, `R_c=1/2`); kodlamasız durumda `R_c=1`. Üretilen gürültü güç ölçümünü yeterli örnekle doğrula.
- BER simülasyonunu GUI'den bağımsız çalıştır. Random seed yapılandırılabilir; sayısal sonuçlar reproducible. Çok büyük ses verisinde körlemesine sonsuz Monte Carlo yapma; konfigürasyonla bit bütçesi, tekrar sayısı ve minimum hata hedefi seçilebilir. Default ayarlar bilgisayarı kilitlemesin; daha doğru BER için yüksek bit bütçesi opsiyonu olsun.
- Teorik uncoded Gray-QPSK/AWGN BER (`0.5*erfc(sqrt(EbN0linear))`) MATLAB temel `erfc` kullanarak hesaplanabilir; referans için isteğe bağlı çiz. Tanımların birebir eşleştiğini doğrula.
- Gerçek ölçülen 0 BER değerini veri tablosunda 0 tut; log grafikte 0 yerine işaret koymama veya açıkça etiketli uygun upper bound göster. Ölçülmeyen değer üretme.

### DM/ADM

- Deterministik sinüs örneği, `fs`, `fSignal`, amplitude, `delta`, `minDelta`, `maxDelta` ayarlanabilir olsun.
- DM'de tek bitlik yön kararı ve sabit step ile geri kurma.
- ADM'de dokümante edilmiş kontrol politikası (örn. tekrar eden yön bitlerinde adım artışı, yön değişiminde azalış) ve adım clamp uygula. Kodun sender/receiver step güncelleme sırası aynı olsun ki round-trip mümkün olsun.
- Zaman dalga şekilleri, error ve istenirse MSE/SQNR karşılaştırması üret.

## 5. GUI — gerçek çalışan ekran

MATLAB sürümü/App Designer erişimini araştır. **Sahte `.mlapp` oluşturma** (dosyaya metin yazıp uzantı değiştirme). Programatik `uifigure`, `uigridlayout`, `uiaxes`, `uibutton`, `uidropdown`, `uislider` ile tek bir çalışır `gui/Project7_GUI.m` GUI oluşturmak sağlam temel seçenek. Eğer ortamda geçerli `.mlapp` üretimi mümkünse ek olarak oluştur; mümkün değilse `.m` GUI'yi teslim et, README'de nedenini açıkça belirt. Toolboxes gerektirmesin.

GUI minimum:

1. File picker + mikrofon (gerekli izin/cihaz yoksa uyarı).
2. Input waveform / reconstructed waveform `uiaxes`.
3. PCM bit seçimi 3,4,8; μ=255 sabit/değiştirilemez ya da açıkça 255 varsayılan.
4. SNR girişi 0..10, 1 dB çözünürlük; tek çalıştırma ve sweep.
5. Orijinal/alınan ses oynatma, isteğe bağlı WAV export.
6. BER vs SNR `semilogy`-uyumlu log eksen; BER bilgisi, SQNR, corrected/uncorrectable block sayıları.
7. QPSK clean/noisy constellation plot, sınırlı sayıda sembol ile performans.
8. Uygun progress/wait UI, disable/enable, hataları `try/catch` + kullanıcıya anlaşılır bildirim.
9. Sonuçların CSV/PNG/MAT olarak export edilmesi; yazma yetkisi yoksa GUI çökmesin.
10. Test ses dosyasının kolay seçilmesi ve kullanıcı gerektirmeyen **sentetik test mode**.

GUI callback'leri DSP matematiğini kopyalamamalı; `run_full_system` ve `ber_simulation` gibi fonksiyonları kullanmalı.

## 6. Uçtan uca davranış

`main.m` programı dışarıdan ses dosyası olmadan çalışabilecek **deterministik synthetic input** ile smoke-test moduna sahip olmalı. Ayrıca `data/input/` içindeki user WAV dosyasını seçme veya parametre geçme seçeneği olsun. Sadece 8 kHz/10 sec ses uygulaması mevcutsa kullanıcıdan yeni veri isteme. Aşağıdaki pipeline'ı uygula:

1. Ses al/yükle + mono/resampling/normalization metadata.
2. PCM quantize → bitstream + quantization-only reconstructed audio + SQNR.
3. Channel encode, padded bits metadata.
4. QPSK map; `Es=1`.
5. SNR gürültüsü; seed kayıt.
6. ML demod.
7. Coded-bit errors say.
8. Syndrome decode → correction stats, uncorrectable flags.
9. Padding'i atıp PCM bitstream'i eski uzunluğuna döndür; PCM decode.
10. Original vs decoded bit error rate, audio waveforms, optionally MSE and recovered WAV.
11. All SNR 0..10 sweep; log BER grafikleri; result CSV/MAT and figures.

Baştan sona üretim aşamasında herhangi bir hata olursa hangi blokta, hangi testte ve nasıl düzeltildiğini izlenebilir şekilde belirt.

## 7. Test stratejisi (kritik: gerçek çalıştırma)

Repodaki `tests/test_*.m` placeholder'larını gerçek assert tabanlı testlere dönüştür. Ayrıca `tests/run_all_tests.m` oluştur.

- `test_pcm`: silence, full scale ±1, nBits=3,4,8, random audio, clipping, dimension/padding, roundtrip index conversions, finite SQNR.
- `test_dm_adm`: constant signal, sinusoids, deterministic outputs, encoder-decoder synchronization, boundaries.
- `test_channel_coding`: `H`/`G`; 16 messages; all 128 single-bit flips; all 448 double-bit flips; exact `status` / corrections; padding behavior.
- `test_qpsk`: 4 bit pairs, 10k+ random bits, no noise BER 0, unit energy, nearest-neighbor validation.
- `test_awgn`: empirical complex noise power across adequately large generated sample, EsN0/EbN0 conversion, reproducibility with seed.
- `test_full_system`: PCM bits 3,4,8; noise-free coded-bit BER=0 and decoded info-bit BER=0; audio reconstruction equals quantization-only PCM audio up to numerical tolerance; noisy run yields finite metrics; 0..10 sweep returns 11 points; correct output sizes.
- Stress: 80k samples ×8-bit PCM -> 640k info bits -> 1.28M coded bits -> 640k QPSK symbols; implement vectorized memory-conscious computations, no avoidable quadratic algorithms.
- Demo mode must run under reasonable resources.

**Run actual tests** if MATLAB available; e.g. `matlab -batch "addpath(genpath(pwd)); run('tests/run_all_tests.m')"` (adjust MATLAB path legitimately). If only GNU Octave available, check supported subset and run headless core tests; GUI may not be compatible, be honest. For packages absent, do not install privileged system packages without authorization. If no runtime is available, at least run file existence, API consistency, obvious syntax scans, tests script check; document **NOT EXECUTED** clearly rather than PASS.

Every changed code path should receive a test. Do not declare complete while an essential test fails. Fix failures; rerun tests.

## 8. Sonuç çıktıları ve rapor

Create/finish:

- `README.md`: what the project does, dependency rules, MATLAB version, quick start (`main`, GUI launch, tests), command examples, folder layout, GUI screenshots if actually available, how to use own WAV, how to reproduce results, known limitations.
- `docs/ARCHITECTURE.md`: block diagram, data types, coding rate, time/frequency assumptions, signal and noise energy bookkeeping.
- `docs/API.md`: function signature, units, bit order, metadata, errors, example usage.
- `docs/MATHEMATICS.md`: μ-law, quantizer, SQNR, PCM bitstream, H/G and syndrome, SECDED limits, Gray QPSK, ML detector, complex AWGN, BER, SNR/EsN0/EbN0 relation, DM/ADM, sinc interpolation.
- `docs/TEAM_TASKS.md`: 3 kişilik iş bölümü ve entegrasyon sorumlulukları.
- `docs/TEST_PLAN.md` and `docs/TEST_RESULTS.md`: assertion list, commands, actual PASS/FAIL/NOT RUN and environment. Do not invent test outcomes.
- `reports/Final_Report.md`: **English** detailed academic report draft: Abstract, Introduction, System Design, Theoretical Foundation, Implementation, Experiments and Methodology, Results, Discussion, Limitations, Conclusions, References, Appendix (MATLAB file inventory/listings or links). Only include numerical results if actually measured; otherwise TODO placeholders clearly labeled. Use actual figure file paths if present. Do not fabricate experimental curves.
- `poster/A0_Poster_Content.md`: **English** A0 portrait or landscape design spec with headline, overview diagram, equations, methods, major plots, small performance tables, findings, credits, QR placeholder. Include exact dimensions: **A0 = 841 × 1189 mm**; say chosen orientation. Graphic export can be added if tooling permits, but do not claim actual final A0 PDF without generating one.
- `results/tables/`: actual BER/SQNR and other measured outputs as CSV, no synthetic pretend-real results.
- `results/figures/`: PNG/PDF charts generated from actual simulation (not manually invented illustrations posed as measurements).

Prefer runnable plot/report export scripts (`scripts/export_results.m`, `scripts/generate_figures.m`, etc.) over hand-edited numbers.

## 9. Tamamlama stratejisi — otonom uygula

Do the following in order, marking real progress in `docs/IMPLEMENTATION_PROGRESS.md`:

**Phase A — Audit:** Inspect repo state and runtime; record environment. Identify actual skeleton function signatures, changes already made. Set API conventions; update `.gitignore` without breaking existing tracked assets.

**Phase B — Core independent modules:** PCM+DM/ADM, H/G encoder+decoder, QPSK+AWGN+BER. Implement unit tests for each as you go.

**Phase C — Integration:** Write `run_full_system(config)` and `main.m`. Ensure clean, deterministic, testable no-audio-file run. Implement numerical exports.

**Phase D — GUI:** Implement functional `.m` GUI, not a visual-only mockup. Run it if environment permits; otherwise label GUI manual verification required.

**Phase E — Experiments:** Actual BER SNR sweep, SQNR bit-depth comparison, test waveforms, constellation and DM/ADM experiment; save result files. Carefully distinguish test-generated synthetic audio from course-provided audio.

**Phase F — Documentation:** Complete README, math/architecture/API docs, test evidence, draft final English report and editable A0 poster content.

**Phase G — Final review:** Check required files, forbidden toolbox calls, all tests, output presence, GUI callback API consistency, git status. Provide user with concise list of completed items, exact run commands, test outcomes, remaining caveats, files changed. No automatic git commit/push.

## 10. Çalışma protokolü

- **Gerçek kod yaz, sadece yapılacaklar listesi çıkarıp durma.** Planı kısa sunup işleme geç.
- Ayrı kişiler dosyaları üzerinde çalışacağı için `src/person1_audio`, `src/person2_channel_coding`, `src/person3_modulation` ayrımını koru.
- MATLAB fonksiyonlarını `function` dosyalarına uygun isimlerle koy. Fonksiyon içi yorumlar İngilizce, açıklama belgeleri tercihen İngilizce; kullanıcıya terminal durum özetini Türkçe verebilirsin.
- Her modül için küçük çalıştırılabilir örnek + test hazırla.
- Kodda gizli otomatik internet indirme, dış servis bağlantısı, ücretli tool aktivasyonu, kullanıcı dosyalarını silme yok.
- Sahte `.mlapp`, sahte `.mat`, sahte test sonucu, sahte ölçüm grafiği üretme.
- Son durumda kullanıcı şu komutlarla başlayabilsin:

  ```matlab
  cd('~/digital-com-project'); % MATLAB sürümünde ~ genişlemiyorsa full path kullan
  addpath(genpath(pwd));
  main
  run_all_tests
  Project7_GUI
  ```

  README'de MATLAB için tam ve doğru dizin komutunu ver. GUI `gui/` altında, test runner `tests/` altında bulunsa da `addpath(genpath(pwd))` ile bulunmalıdır.
- En sonda her ana proje şartı için **Implemented / Tested / Not tested / Blocked** durum tablosu sun. Güncel gerçek runtime durumunu dürüst bildir.

**Şimdi repo denetimiyle başla ve tüm aşamaları dosyaları gerçekten oluşturarak uygula.**
