import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import '../../config/secrets.dart';

/// Google AdMob 배너 광고를 화면에 표시하는 스테이트풀 위젯입니다.
/// 플랫폼별(Android/iOS) 광고 ID를 자동으로 선택하며 로드 성공 시에만 화면에 노출됩니다.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  /// AdMob 배너 광고 객체
  BannerAd? _bannerAd;
  /// 광고 로드 완료 여부
  bool _isLoaded = false;

  /// 현재 플랫폼에 맞는 AdMob 배너 광고 유닛 ID를 반환합니다.
  /// 웹 환경에서는 빈 문자열을 반환하여 광고를 건너뜁니다.
  String get _adUnitId {
    if (kIsWeb) return ''; // 웹에서는 광고 생략
    if (Platform.isAndroid) {
      return Secrets.adMobAndroidBannerId;
    } else {
      return Secrets.adMobIosBannerId;
    }
  }

  @override
  void initState() {
    super.initState();
    // 웹이 아닌 경우에만 광고 로드 프로세스 시작
    if (!kIsWeb) {
      _loadAd();
    }
  }

  /// 광고를 설정하고 서버로부터 광고 데이터를 로드합니다.
  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // 광고 로드 성공 시 화면을 갱신합니다.
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        // 광고 로드 실패 시 메모리 누수 방지를 위해 객체를 해제합니다.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    // 위젯 파괴 시 광고 객체도 함께 파괴하여 리소스 해제
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로드 중이거나 웹 환경, 혹은 광고 객체가 없는 경우 아무것도 표시하지 않음
    if (kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    
    // 광고가 성공적으로 로드된 경우 정해진 사이즈의 컨테이너에 광고 위젯 표시
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
