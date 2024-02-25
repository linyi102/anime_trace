import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';

class CategoryIntroPage extends StatelessWidget {
  const CategoryIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('类别介绍')),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItem(context, '剧场版',
                  url: 'https://mzh.moegirl.org.cn/%E5%89%A7%E5%9C%BA%E7%89%88',
                  desc: [
                    '剧场版是指在影院公映的特摄与动画作品，专指脱胎于其他媒体（剧集动画或游戏或真人特摄）的电影衍生版。为动画与特摄电影的一种。独立动画电影不包括在内。',
                    '剧场版作品是日本特摄与动画按传播方式分类的一种，剧场版一词本身并不局限原本的媒体为何，但通常会用在先前已有日本电视剧或日本动画的作品再度改编为电影版本的情况。通常片长为90分钟，制作成本一般高于OVA及TV动画。不论在人物动作的流畅感，还是使用的分色数，甚至每秒的帧数上，都比电视版动画和原创动画录影带有明显的提升。因此画面精度是三者中最高的。另外，剧场版动画会根据需要临时加入一些非TV剧情角色，这些角色往往对剧情发展起着重要作用。'
                  ]),
              _buildItem(context, 'OVA',
                  url: 'https://mzh.moegirl.org.cn/OVA',
                  desc: [
                    'OVA是Original Video Animation的缩写，中文译作原始视频动画。一般指通过DVD，蓝光光盘等影碟发行的方式为主的动画剧集，也指一些相较原著篇幅较小且内容不一的动画剧集。',
                    '相较于在电视或者电影院播放的电视动画、动画电影、剧场版不同，OVA则是从发行渠道来划分的，一般通过DVD等影碟的形式发行。一般的OVA不见得广为人知，选材一般是应某个特定作品的爱好者的要求而出的，一般是将情节补完，以满足爱好者收藏的需要。也有的OVA是作为实验期的作品，如果反响不错，就很有可能做成电视动画。近年来也有一类剧场上映OVA，即在正式发售碟片之前先进行剧场上映（通常为小规模上映和/或期间限定上映）。其制作流程、展现形式、时长一般异于动画电影，不过有时也被广义地归类为剧场动画。'
                  ]),
              _buildItem(context, 'OAD',
                  url: 'https://mzh.moegirl.org.cn/OAD',
                  desc: [
                    'OAD是Original Animation Disc或Original Animation DVD的缩写。中文称原始光盘动画或捆绑光盘动画。在DVD等光碟储存媒体普及后的用语。一般在漫画、小说中捆绑发售，媒介包括DVD及蓝光光盘。',
                    'OAD的内容一般为原创，也有将TV版本再编辑后制作而成，看似和在大荧幕上映的剧场版动画一样，其实不一样。剧场版都有一个规定的影片时间，且由于赚的是入场观众的钱，制作阵容均偏向大型，而且作品质量远超越TV版，而OAD则只面向原作fans制作，也是新人监督和编剧的试练场，故销量不会太高。'
                  ]),
              _buildSource(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildSource(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            margin: const EdgeInsets.only(top: 20, bottom: 5),
            width: 50,
            child: const Divider()),
        Text.rich(TextSpan(
          children: [
            const TextSpan(text: '本文引自萌娘百科 ('),
            WidgetSpan(
                child: GestureDetector(
                    onTap: () => LaunchUrlUtil.launch(
                        context: context, uriStr: 'https://mzh.moegirl.org.cn'),
                    child: const Text(
                      'https://mzh.moegirl.org.cn',
                      style: TextStyle(color: Colors.blue),
                    ))),
            const TextSpan(text: ')'),
          ],
        )),
        const Text('文字内容默认使用《知识共享 署名-非商业性使用-相同方式共享 3.0 中国大陆》协议。'),
      ],
    );
  }

  _buildItem(BuildContext context, String text,
      {String? url, List<String> desc = const []}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          _buildTitle(context, text, url: url),
          _buildDesc(desc),
        ],
      ),
    );
  }

  _buildTitle(BuildContext context, String text, {String? url}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            // color: url != null && url.isNotEmpty ? Colors.blue : null,
          ),
        ),
        const Spacer(),
        if (url != null && url.isNotEmpty)
          IconButton(
              splashRadius: 20,
              onPressed: () =>
                  LaunchUrlUtil.launch(context: context, uriStr: url),
              icon: const Icon(Icons.open_in_new, size: 18))
      ],
    );
  }

  _buildDesc(List<String> textList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final text in textList)
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
      ],
    );
  }
}
