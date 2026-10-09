class TokenHolder {
  String? accessToken;
  String? refreshToken;
  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}

final globalTokens = TokenHolder();