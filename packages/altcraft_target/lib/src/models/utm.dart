/// UTM tags for attribution tracking.
class UTM {
  final String? source;
  final String? medium;
  final String? campaign;
  final String? content;
  final String? keyword;
  final String? temp;

  const UTM({
    this.source,
    this.medium,
    this.campaign,
    this.content,
    this.keyword,
    this.temp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (source != null) 'source': source,
      if (medium != null) 'medium': medium,
      if (campaign != null) 'campaign': campaign,
      if (content != null) 'content': content,
      if (keyword != null) 'keyword': keyword,
      if (temp != null) 'temp': temp,
    };
  }
}
