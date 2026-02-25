/// Example application with mode-based configuration.

@@@mode dev
const bool kDebugMode = true;
const String kApiUrl = 'http://localhost:8080';
const String kEnvironment = 'development';
@@@mode release
const bool kDebugMode = false;
const String kApiUrl = 'https://api.production.com';
const String kEnvironment = 'production';
@@@mode default
const bool kDebugMode = false;
const String kApiUrl = 'https://api.default.com';
const String kEnvironment = 'unknown';
@@@endmode

void main() {
  print('Running in $kEnvironment mode');
  print('API URL: $kApiUrl');
  print('Debug mode: $kDebugMode');
  
@@@mode dev
  print('Development mode - verbose logging enabled');
  runDevServer();
@@@mode release, staging
  print('Production mode - optimized for performance');
  runProdServer();
@@@endmode
}

void runDevServer() {
  print('Starting development server...');
}

void runProdServer() {
  print('Starting production server...');
}
