import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tiens_im_flutter/common/utils/toast_util.dart';
import 'package:tiens_im_flutter/pages/post_moments/constant/moment_constant.dart';
import 'package:tiens_im_flutter/pages/square/views/square_page.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/same_user.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/time_util.dart';

import 'package:tiens_im_flutter/pages/wx_zone/widgets/my_underline_indicator.dart';

import 'package:tiens_im_flutter/pages/wx_zone/widgets/wx_circle.dart';

import '../../common/utils/utils.dart';
import '../square/utils/time_util.dart';
import 'config/colors.dart';

///调试可以直接跳转 BoostNavigator.instance.push("wxZone");
class WxZone extends StatefulWidget {
  const WxZone({super.key});

  @override
  State<StatefulWidget> createState() {
    return WxZoneState();
  }
}

class WxZoneState extends State<WxZone> with TickerProviderStateMixin {
  ///导航栏高度
  double _navH = MediaQueryData.fromWindow(window).padding.top + kToolbarHeight;
  TabController? pageController;

  ///当前索引
  int currentPage = 0;

  bool _isShowPostMoment = false;

  ///标记是否刷新
  bool refreshAppbar = false;
  double result = 0.0;
  double _imgWH = 22.0; // 右侧图片宽高

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    ///控制器
    pageController = TabController(initialIndex: 0, length: 2, vsync: this)
      ..addListener(() {
        if (pageController?.index == pageController?.animation?.value) {
          switch (pageController?.index) {
            case 0:
              TimeUtils.showIndex(0);
              TimeUtils.hideIndex(1);
              break;
            case 1:
              TimeUtils.showIndex(1);
              TimeUtils.hideIndex(0);
              break;
          }
        }
      });
  }

  @override
  void dispose() {
    pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: customAppBar(),
        body: SafeArea(
          child: Container(
              child: Column(
            // crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TabBarView(
                  controller: pageController,
                  children: [
                    ///朋友圈
                    WxCircle(),
                    SquarePage(
                      key: ValueKey('1'),
                      type: 1,
                      isPlugin: true,
                    )
                  ],
                ),
              )
            ],
          )),
        ));
  }

  AppBar customAppBar() {
    ///获取appear宽度
    TimeUtil.appbarWidth().then((value) {
      if (refreshAppbar == true) {
        return;
      }
      refreshAppbar = true;
      setState(() {
        result = value;

        pageController = TabController(initialIndex: 0, length: 2, vsync: this)
          ..addListener(() {
            if (pageController?.index == pageController?.animation?.value) {
              switch (pageController?.index) {
                case 0:
                  TimeUtils.showIndex(0);
                  TimeUtils.hideIndex(1);
                  break;
                case 1:
                  TimeUtils.showIndex(1);
                  TimeUtils.hideIndex(0);
                  break;
              }
            }
          });
      });
    });

    return AppBar(
      backgroundColor: KColors.getColor(KColors.navBackColor),
      elevation: 0.0,
      // centerTitle: true,
      // flexibleSpace: widget.flexibleSpace,
      actions: [
        IconButton(
          icon: Image.asset("assets/images/wxzone/xiangji.png",
              width: _imgWH, height: _imgWH),
          onPressed: () => _clickNav(),
        ),
      ],
      flexibleSpace: SafeArea(
        child: Container(
          child: Center(
              child: Container(
            width: result > 212.px ? result : 212.px,
            child: TabBar(
              // labelPadding: EdgeInsets.only(left: 5.0.px, right: 5.px),
              controller: pageController,
              tabs: [
                Tab(text: "moment_moments_00001".tl),
                Tab(text: "moment_moments_00002".tl)
              ],
              indicatorColor: KColors.redLineColor,
              indicatorPadding: EdgeInsets.all(5.px),
              indicatorSize: TabBarIndicatorSize.label,
              indicator: MyUnderlineTabIndicator(
                borderSide:
                    BorderSide(width: 5.rpx, color: KColors.redLineColor),
                borderRadius: BorderRadius.all(Radius.circular(3.rpx)),
              ),
              physics: const BouncingScrollPhysics(),
              labelColor: Colors.black,
              labelStyle:
                  TextStyle(fontSize: 18.px, fontWeight: FontWeight.w600),
              unselectedLabelColor: KColors.unselectTextColor,
              unselectedLabelStyle:
                  TextStyle(fontSize: 16.px, fontWeight: FontWeight.normal),
            ),
          )),
        ),
      ),
    );
  }

  ///点击相机
  _clickNav() async {
    // // TODO
    // BoostNavigator.instance.push("qchatcreateserve");
    // return;

    SameUser.needRefresh = false;

    if (_isShowPostMoment) {
      debugPrint("😬😬😬😬😬😬😬😬😬😬😬😬重复点击😬😬😬😬😬😬😬😬😬😬😬😬");
      return;
    }
    debugPrint("😀😀😀😀😀😀😀😀选择照片或者拍照开始😀😀😀😀😀😀😀😀");
    _isShowPostMoment = true;
    Future.delayed(Duration(seconds: 1))
        .then((value) => _isShowPostMoment = false);
    //朋友圈是8 广场是9
    dynamic result;
    if (Platform.isIOS) {
      result = await BoostNavigator.instance.push("postmomentbridgepage",
          withContainer: true, opaque: false, arguments: {"isAnimated": false});
    } else {
      result = await BoostNavigator.instance
          .push("postmomentbridgepage", withContainer: true, opaque: false);
    }
    if (result.runtimeType == int && result == -1) {
      ToastUtil.showText(
          text: MomentConstant.momentPhotoNoPermissionTip, showTime: 3);
    }
    if (result.runtimeType == int && result == 8) {
      //发布朋友圈成功
      SameUser.needRefresh = true;
      debugPrint("发布朋友圈成功");
    } else if (result.runtimeType == int && result == 9) {
      //发布广场成功
      debugPrint("发布广场成功");
    }

    print("result:${result}");
    _isShowPostMoment = false;
    debugPrint("😂😂😂😂😂😂😂😂选择照片或者拍照结束😂😂😂😂😂😂😂😂");
  }
}
