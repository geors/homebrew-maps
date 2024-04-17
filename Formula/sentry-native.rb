class SentryNative < Formula
  desc "Sentry C++ library"
  homepage "https://sentry.io"
  url "https://github.com/getsentry/sentry-native.git", :using => :git, :tag => "0.7.2"
  version "0.7.2"

  depends_on "cmake" => :build

  def install
    system "cmake", "-B", "build", "-DCMAKE_OSX_ARCHITECTURES='arm64;x86_64'", *std_cmake_args
    system "cmake", "--build", "build"
    system "lipo", "-info", "build/libsentry.dylib"
    system "cmake", "--install", "build"
  end

  test do
    system "false"
  end
end

