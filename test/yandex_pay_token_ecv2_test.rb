require "test_helper"

module R2D2
  class YandexPayTokenV2 < Minitest::Test

    def setup
      @recipient_id = 'merchant:12345678901234567890'
      @fixtures = __dir__ + "/fixtures/"
      @token = JSON.parse(File.read(@fixtures + "ec_v2/tokenized_card.json"))
      @private_key = File.read(@fixtures + "google_pay_token_private_key.pem")
      @verification_keys = JSON.parse(File.read(@fixtures + "verification_keys/google_verification_key_test.json"))
      Timecop.freeze(Time.at(1595000067))
    end

    def teardown
      Timecop.return
    end

    def test_wrong_signature
      @token['signature'] = "MEQCIDxBoUCoFRGReLdZ/cABlSSRIKoOEFoU3e27c14vMZtfAiBtX3pGMEpnw6mSAbnagCCgHlCk3NcFwWYEyxIE6KGZVA\u003d\u003d"

      assert_raises R2D2::SignatureInvalidError do
        new_token.decrypt(@private_key)
      end
    end

    def test_invalid_intermediate_signing_key
      @token['intermediateSigningKey']['signatures'] = ["MEQCIDxBoUCoFRGReLdZ/cABlSSRIKoOEFoU3e27c14vMZtfAiBtX3pGMEpnw6mSAbnagCCgHlCk3NcFwWYEyxIE6KGZVA\u003d\u003d"]

      assert_raises R2D2::SignatureInvalidError do
        new_token.decrypt(@private_key)
      end
    end

    def test_wrong_verification_key
      @verification_keys = JSON.parse(File.read(@fixtures + "verification_keys/google_verification_key_production.json"))

      assert_raises R2D2::SignatureInvalidError do
        new_token.decrypt(@private_key)
      end
    end

    def test_unknown_verification_key_version
      @verification_keys = JSON.parse(File.read(@fixtures + "verification_keys/bad_google_verification_key_test.json"))

      assert_raises R2D2::SignatureInvalidError do
        new_token.decrypt(@private_key)
      end
    end

    def test_intermediate_key_expired
      ### token["intermediateSigningKey"]["signedKey"]["keyExpiration"] => "1595702501149"
      Timecop.freeze(Time.at(1595702502)) do
        assert_raises R2D2::SignatureInvalidError do
          new_token.decrypt(@private_key)
        end
      end
    end

    private

    def new_token
      R2D2::YandexPayToken.new(
        @token,
        recipient_id: @recipient_id,
        verification_keys: @verification_keys
      )
    end
  end
end
