class FmtAT10 < Formula
  desc "Open-source formatting library for C++"
  homepage "https://fmt.dev/"
  url "https://github.com/fmtlib/fmt.git", :using => :git, :tag => "10.2.1"
  license "MIT"

  depends_on "cmake" => :build

  # Fix handling of static separator; cherry-picked from:
  # https://github.com/fmtlib/fmt/commit/44c3fe1ebb466ab5c296e1a1a6991c7c7b51b72e
  # Remove when included in a release.
  patch :DATA

  def install
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=TRUE", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    system "cmake", "-S", ".", "-B", "build-static", "-DBUILD_SHARED_LIBS=FALSE", *std_cmake_args
    system "cmake", "--build", "build-static"
    lib.install "build-static/libfmt.a"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <iostream>
      #include <string>
      #include <fmt/format.h>
      int main()
      {
        std::string str = fmt::format("The answer is {}", 42);
        std::cout << str;
        return 0;
      }
    EOS

    system ENV.cxx, "test.cpp", "-std=c++11", "-o", "test",
                  "-I#{include}",
                  "-L#{lib}",
                  "-lfmt"
    assert_equal "The answer is 42", shell_output("./test")
  end
end

__END__
diff --git a/include/fmt/format-inl.h b/include/fmt/format-inl.h
index 9fc87ecf2027df0346935e7666ea80ec70e65575..872aa9802df1ffa8572a2f0d29f58bdb2b171a1a 100644
--- a/include/fmt/format-inl.h
+++ b/include/fmt/format-inl.h
@@ -110,7 +110,11 @@ template <typename Char> FMT_FUNC Char decimal_point_impl(locale_ref) {
 
 FMT_FUNC auto write_loc(appender out, loc_value value,
                         const format_specs<>& specs, locale_ref loc) -> bool {
-#ifndef FMT_STATIC_THOUSANDS_SEPARATOR
+#ifdef FMT_STATIC_THOUSANDS_SEPARATOR
+  value.visit(loc_writer<>{
+      out, specs, std::string(1, FMT_STATIC_THOUSANDS_SEPARATOR), "\3", "."});
+  return true;
+#else
   auto locale = loc.get<std::locale>();
   // We cannot use the num_put<char> facet because it may produce output in
   // a wrong encoding.
@@ -119,7 +123,6 @@ FMT_FUNC auto write_loc(appender out, loc_value value,
     return std::use_facet<facet>(locale).put(out, value, specs);
   return facet(locale).put(out, value, specs);
 #endif
-  return false;
 }
 }  // namespace detail
