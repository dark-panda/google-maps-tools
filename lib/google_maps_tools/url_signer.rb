
require 'openssl'
require 'base64'

module GoogleMapsTools
  class UrlSigner
    def initialize(secret)
      @secret = secret
    end

    def generate(url, options = {})
      signature = generate_signature(url)
      "#{url}&signature=#{signature}"
    end

    def verify(signed_url)
      url, signature = signed_url.split(/&signature=/, 2)

      url.present? &&
        signature.present? &&
        secure_compare(signature, generate_signature(url))
    end

    # To ensure we don't accidentally leak our secret key in error messages and
    # such...
    def inspect
      "#<GoogleMapsTools::UrlSigner>"
    end
    alias :to_s :inspect

    private
      def generate_signature(url) #:nodoc:
        query_string = "/#{url.split('/', 4).last}"

        digest = OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          Base64.decode64(@secret.tr('-_','+/')),
          query_string
        )

        Base64.encode64(digest).tr('+/','-_').strip
      end

      # Constant-time comparison to avoid timing attacks. Borrowed from
      # ActiveSupport.
      def secure_compare(a, b) #:nodoc:
        return false unless a.bytesize == b.bytesize

        l = a.unpack "C#{a.bytesize}"

        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
      end
  end
end
