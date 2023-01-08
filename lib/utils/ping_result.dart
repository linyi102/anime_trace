class PingStatus {
  bool pinging; // 正在ping
  bool needPing; // 需要ping
  bool connectable; // 可以连接
  int time;

  PingStatus(
      {this.connectable = false,
      this.time = -1,
      this.pinging = false,
      this.needPing = true});

  @override
  String toString() {
    return "PingStatus[ok=$connectable, time=$time]";
  }
}
