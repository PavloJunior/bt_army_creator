require "test_helper"

class MulClientTest < ActiveSupport::TestCase
  setup do
    # Reset memoized connection between tests
    MulClient.instance_variable_set(:@connection, nil)
  end

  test "fetch_card_image returns body and content_type for valid image response" do
    fake_body = file_fixture("test_card.jpg").read

    conn = build_fake_connection(
      body: fake_body,
      headers: { "content-type" => "image/jpg" }
    )

    with_connection(conn) do
      result = MulClient.fetch_card_image(7433, skill: 4)
      assert_equal fake_body, result[:body]
      assert_equal "image/jpg", result[:content_type]
    end
  end

  test "fetch_card_image raises ApiError for non-image content type" do
    conn = build_fake_connection(
      body: "<html>error</html>",
      headers: { "content-type" => "text/html" }
    )

    with_connection(conn) do
      assert_raises(MulClient::ApiError) do
        MulClient.fetch_card_image(9999, skill: 4)
      end
    end
  end

  test "fetch_card_image raises ApiError on Faraday error" do
    conn = Object.new
    conn.define_singleton_method(:get) { |*_args| raise Faraday::ConnectionFailed, "connection refused" }

    with_connection(conn) do
      assert_raises(MulClient::ApiError) do
        MulClient.fetch_card_image(7433, skill: 4)
      end
    end
  end

  test "fetch_card_image passes skill parameter in request" do
    received_params = nil
    fake_body = file_fixture("test_card.jpg").read

    conn = Object.new
    conn.define_singleton_method(:get) do |path, params|
      received_params = params
      Struct.new(:body, :headers).new(fake_body, { "content-type" => "image/jpg" })
    end

    with_connection(conn) do
      MulClient.fetch_card_image(7433, skill: 2)
    end

    assert_equal({ skill: 2 }, received_params)
  end

  private

  def build_fake_connection(body:, headers:)
    response = Struct.new(:body, :headers).new(body, headers)
    conn = Object.new
    conn.define_singleton_method(:get) { |*_args| response }
    conn
  end

  def with_connection(conn)
    MulClient.instance_variable_set(:@connection, conn)
    yield
  ensure
    MulClient.instance_variable_set(:@connection, nil)
  end
end
