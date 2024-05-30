locals {
  app = "${path.module}/../webapp" ## path to the static website.
  mime_types = {
    "html" : "text/html",
    "htm" : "text/html", # Some older sites might still use .htm
    "css" : "text/css",
    "js" : "text/javascript",
    "json" : "application/json",
    "ico" : "image/vnd.microsoft.icon",
    "txt" : "text/plain",
    "svg" : "image/svg+xml",                 # Scalable vector graphics
    "woff" : "font/woff",                    # Web Open Font Format
    "woff2" : "font/woff2",                  # WOFF 2.0
    "ttf" : "font/ttf",                      # TrueType Font
    "eot" : "application/vnd.ms-fontobject", # Embedded OpenType (older IE)
    "otf" : "font/otf",                      # OpenType Font
    "jpg" : "image/jpeg",
    "jpeg" : "image/jpeg",
    "png" : "image/png",
    "gif" : "image/gif",
    "webp" : "image/webp",     # Newer image format for better compression
    "mp4" : "video/mp4",       # Video format
    "webm" : "video/webm",     # Video format
    "ogv" : "video/ogg",       # Video format
    "mp3" : "audio/mpeg",      # Audio format
    "wav" : "audio/wav",       # Audio format
    "ogg" : "audio/ogg",       # Audio format
    "pdf" : "application/pdf", # PDF documents
    "xml" : "application/xml", # XML data
    "zip" : "application/zip", # Zip archives (if you offer downloads)
  }
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "my-static-website-bucket" # Bucket name
}

resource "aws_s3_bucket_public_access_block" "access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.website_bucket.arn}",
      "${aws_s3_bucket.website_bucket.arn}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn,
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json

  depends_on = [aws_s3_bucket_public_access_block.access]
}

resource "aws_s3_bucket_cors_configuration" "website_cors" {
  bucket = aws_s3_bucket.website_bucket.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["Content-Type", "ETag"]
  }
}

resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "website_asset" {
  for_each = fileset("${local.app}", "**")

  content_type = lookup(local.mime_types, regex("([^.]+)$", each.value)[0], null)

  bucket = aws_s3_bucket.website_bucket.id
  etag   = filemd5("${local.app}/${each.value}")
  key    = each.value
  source = "${local.app}/${each.value}"
}