/// شماره ساخت؛ ربات هنگام ساخت مقدارش را می‌گذارد
const String kBuild =
    String.fromEnvironment('BUILD_NUMBER', defaultValue: 'محلی');
