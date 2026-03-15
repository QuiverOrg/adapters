class RouteConfig {
  final String src;
  final String dest;
  final List<String>? methods;
  final Map<String, String>? headers;
  final int? status;

  const RouteConfig({
    required this.src,
    required this.dest,
    this.methods,
    this.headers,
    this.status,
  });

  Map<String, dynamic> toJson() => {
    'src': src,
    'dest': dest,
    'methods': ?methods,
    'headers': ?headers,
    'status': ?status,
  };
}
