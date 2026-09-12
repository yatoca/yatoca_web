resource "aws_cloudfront_function" "static_rewrite" {
  name    = "${var.project_name}-static-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite extensionless Next.js static-export routes to index.html"
  publish = true

  code = <<-JS
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      if (uri.indexOf('/api/') === 0) {
        return request;
      }

      if (uri.endsWith('/')) {
        request.uri = uri + 'index.html';
      } else if (uri.indexOf('.') === -1) {
        request.uri = uri + '/index.html';
      }

      return request;
    }
  JS
}
