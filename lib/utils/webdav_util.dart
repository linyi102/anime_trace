import 'package:animetrace/controllers/remote_controller.dart';
import 'package:animetrace/utils/error_format_util.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:webdav_client/webdav_client.dart';
import 'package:animetrace/utils/log.dart';

class WebDavUtil {
  static WebDavUtil? _webDavUtil;

  WebDavUtil._();

  static WebDavUtil getInstance() {
    return _webDavUtil ??= WebDavUtil._();
  }

  static late Client client;

  static Future<bool> initWebDav(
      String uri, String user, String password) async {
    client = newClient(
      uri,
      user: user,
      password: password,
      debug: false,
    );
    if (!(await pingWebDav())) {
      AppLog.info("WebDav初始化失败！");
      return false;
    }
    // Set the public request headers
    client.setHeaders({'accept-charset': 'utf-8'});

    // Set the connection server timeout time in milliseconds.
    client.setConnectTimeout(8000);

    // Set send data timeout time in milliseconds.
    client.setSendTimeout(8000);

    // Set transfer data time in milliseconds.
    client.setReceiveTimeout(8000);
    AppLog.info("WebDav初始化成功！");
    return true;
  }

  static Future<bool> pingWebDav() async {
    try {
      await client.ping();
    } catch (e) {
      // 不应该设置为false，应该假设login为true，这样每次进入应用都会init重新连接
      // SPUtil.setBool("login", false); // 如果之前成功，但现在失败了，所以需要覆盖
      // 应该用online=true表示在线还是
      RemoteController.to.setOnline(false);
      ErrorFormatUtil.formatError(e);
      return false;
    }
    RemoteController.to.setOnline(true);
    SPUtil.setBool("login", true); // 表示用户想要登录，第一次登录后永远为true
    AppLog.info("ping ok");
    return true;
  }

  static Future<void> upload(String localPath, String remotePath) async {
    return client.writeFromFile(
      localPath,
      remotePath,
    );
  }

  static Future<String> getRemoteDirPath() async {
    if (RemoteController.to.isOffline) {
      ToastUtil.showText("请先连接帐号，再进行备份");
      return "";
    }
    String backupDir = "/animetrace";
    // readDir('/')遍历判断是否存在animetrace目录，不如直接创建，如果存在则会跳过
    await client.mkdir(backupDir);
    return backupDir;
  }

  static Future<String> getRemoteAutoDirPath(String backupDir) async {
    String autoDir = "$backupDir/automatic";
    // TeraCloud直接执行readDir时，如果目录不存在并不会自动创建，因此会抛出异常DioError [DioErrorType.response]: Not Found
    await WebDavUtil.client.mkdir(autoDir);
    return autoDir;
  }
}
