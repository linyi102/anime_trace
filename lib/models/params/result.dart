class Result {
  int code;
  dynamic data;
  String msg;

  Result(this.code, this.data, {this.msg = ""});

  static Result success(Object data, {String msg = ""}) {
    return Result(200, data, msg: msg);
  }

  static Result failure(int code, String msg) {
    return Result(code, "", msg: msg);
  }

  bool get isSuccess => code == 200;

  @override
  String toString() {
    return "code=$code, data=$data, msg=$msg";
  }
}
