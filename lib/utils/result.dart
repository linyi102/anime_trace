class Result {
  int code;
  dynamic data;
  String msg;

  Result(this.code, this.data, {this.msg = ""});

  static Result success(Object data) {
    return Result(200, data);
  }

  static Result failure(int code, String msg) {
    return Result(code, "", msg: msg);
  }

  @override
  String toString() {
    return "code=$code, data=$data, msg=$msg";
  }
}
