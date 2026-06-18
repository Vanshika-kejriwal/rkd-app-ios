import 'dart:async';
import 'package:http/http.dart' as http;

class ProgressMultipartRequest extends http.MultipartRequest {
  final Function(int bytesTransferred, int totalBytes) onProgress;
  ProgressMultipartRequest(super.method, super.url, {required this.onProgress});

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final totalLength = contentLength;
    int bytesTransferred = 0;
    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytesTransferred += data.length;
        onProgress(bytesTransferred, totalLength);
        sink.add(data);
      },
    );
    return http.ByteStream(byteStream.transform(transformer));
  }
}