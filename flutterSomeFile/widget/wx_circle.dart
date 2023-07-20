import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:tiens_im_flutter/common/utils/language/translation.dart';
import 'package:tiens_im_flutter/common/utils/size_fit.dart';
import 'package:tiens_im_flutter/pages/wx_zone/controllers/WXCircleController.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/same_user.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/time_util.dart';
import 'package:tiens_im_flutter/pages/wx_zone/widgets/wx_friends_circle_cell.dart';
import '../../../common/widgets/empty.dart';
import '../../square/views/report_page.dart';
import '../entity/wx_friends_circle_model.dart';

///全局变量
bool withContainer = true;

enum COMMENTTYPE { common, people, toPeople }

///调试可以直接跳转 BoostNavigator.instance.push("wxZone");
class WxCircle extends StatefulWidget {
  const WxCircle({super.key});

  @override
  State<StatefulWidget> createState() {
    return WxCircleState();
  }
}

class WxCircleState extends State<WxCircle>
    with
        SingleTickerProviderStateMixin,
        PageVisibilityObserver,
        AutomaticKeepAliveClientMixin {
  ///getX绑定数据
  late WXCircleController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = Get.put(WXCircleController());

    ///初始化 overlay
    controller.overlayState = Overlay.of(context);


    /// 初始化动画控制器
    controller.animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    /// 设置动画取值范围
    SameUser.realWidth = TimeUtil.commentMaxWidth("moment_moments_00005".tl, "moment_moments_00004".tl);
    controller.sizeTween = Tween(begin: 0.0.px, end: SameUser.realWidth).animate(
      CurvedAnimation(
          parent: controller.animationController, curve: Curves.easeInOut),
    );

    ///获取用户数据
    SameUser.savUserInfo();

  }

  @override
  Widget build(BuildContext context) {

    return GetX<WXCircleController>(
      init: controller,
      builder: (controller) {
        return Scaffold(
          body: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: GestureDetector(
                onTap: () {
                  if (controller.isShowInput.value) {}
                },
                child: getCuttentWight(controller.dataArr.value.length)),
          ),
          // 底部评论栏
          // bottomNavigationBar:
          //     controller.isShowInput.value ? _buildCommentBar() : null,
        );
      },
    );
  }

  Widget getCuttentWight(int length) {

    return  EasyRefresh.builder(
            controller: controller.easyRefreshController,
            fit: StackFit.expand,
            onRefresh: () {
              controller.onRefresh();
            },
            onLoad: () {
              controller.onLoad();
            },
            childBuilder:(BuildContext context, ScrollPhysics physics){

              if (length > 0){
                return _body(controller.dataArr.value,physics);
              }else{
                return Empty(physics: physics);
              }
            }
          );
  }

  ///页面主题
  _body(List dataArr, ScrollPhysics physics) {


    return ListView.builder(

        controller: controller.listScrollController,
        physics: physics,
        ///设置滑动效果
        itemCount: dataArr.length,
        itemBuilder: (BuildContext context, int index) {
          ///列表
          WxFriendsCircleModel oneModel = controller.dataArr.value[index];
          return WxFriendsCircleCell(
            model: oneModel,
            onClickCell: (model) {

              SameUser.needRefresh = false;
              _clickCell(oneModel);
            },

            ///点击头像
            onClickHeadPortrait: (userid) {

              SameUser.needRefresh = false;
              BoostNavigator.instance
                  .push("mine", withContainer: withContainer, arguments: {
                "accId": userid ?? "",
              });
            },

            ///评论点赞弹出窗口
            onClickComment: (model, offset) {

              SameUser.needRefresh = false;
              ///设置数据
              controller.btnOffset.value = offset;
              controller.currentModel = oneModel;

              /// 通过 Overlay 显示菜单
              _onShowMenu(onTap: () => _onCloseMenu());
            },

            ///回复评论
            onBackComment: (comment, type) {

              SameUser.needRefresh = false;
              ///type=0是点击评论者， type=1点击被评论者
              controller.currentModel = oneModel;
              controller.commentModel = comment;
              if (type == 0) {
                controller.commenttype = COMMENTTYPE.people;
              } else {
                controller.commenttype = COMMENTTYPE.toPeople;
              }

              ///显示键盘
              _onSwitchCommentBar();
            },

            ///点击了删除朋友圈
            onClickDeleteBtn: (model) {

              SameUser.needRefresh = false;
              Future<int> backIndex = BoostNavigator.instance.push(
                  "CustomDialogWidget",
                  withContainer: withContainer,
                  opaque: false,
                  arguments: {"isPresent": true, "isAnimated": false});
              backIndex.then((value) {
                if (value == 1) {
                  controller.delteOneCircleData(model);
                }
              });

              ///这里暂时注释，防止再用
              // dialogWidget tool = dialogWidget(
              //     context: context,
              //     onClickCancelBtn: () {},
              //     onClickTrueBtn: () {
              //       controller.delteOneCircleData(model);
              //     });
              // tool.showCupertinoAlertDialog(context);
            },

            ///跟多评论按钮
            onClickMoreBtn: (model) {
              controller.currentModel = model;

              ///点击更多
              controller.loadCommentData(controller.commentPage);
            },

            ///删除评论
            onDeleteCommentBtn: (model, comment) {
              ///保存当前model
              controller.currentModel = model;
              controller.commentModel = comment;

              SameUser.needRefresh = false;
              Future<int> backIndex = BoostNavigator.instance.push(
                  "DeleteComment",
                  withContainer: withContainer,
                  opaque: false,
                  arguments: {"isPresent": true, "isAnimated": false});
              backIndex.then((value) {
                if (value == 1) {
                  controller.deleteCommentData(model, comment);
                }
              });
            },

            ///举报按钮点击
            onClickReportShowBtn: (WxFriendsCircleModel model){
               controller.reportRefresh(model);
            },
            ///举报
            onClickReportBtn: (model){
              ///跳到举报页面
              BoostNavigator.instance.push(ReportPage.routerName,withContainer: true,
                  arguments: {
                    "contentId": model.contentId,
                    "type": 1
                  });
              // controller.deleteReport(model);
            },
          );
        });
  }

  // 点击cell
  _clickCell(WxFriendsCircleModel model) {

    ///隐藏键盘convert.jsonEncode(Map<String,dynamic>);

    Future future = BoostNavigator.instance.push("CircleDetailPage",
        withContainer: withContainer,
        arguments: {"contentId": model.contentId.toString()});

    future.then((value) {

      ///如果返回map
      if (value is Map) {

        ///来自删除后的返回（移除列表数据）
        Map mapValue = value as Map;
        if (mapValue["delete"] != null) {
          String contentId = mapValue["delete"];
          controller.dataArr.value.removeWhere((element) {
            return element.contentId == int.parse(contentId);
          });
        }

      }
    });
  }

  ///刷新列表
  void updateModels(Map map, List<WxFriendsCircleModel> list){

    ///正常返回(刷新列表)
    if (map["back"] != null) {
      Map<String, dynamic> backMap = map["back"];

      ///返回的model
      WxFriendsCircleModel model = WxFriendsCircleModel.fromJson(backMap);
      // if ((model.commentList?.length ?? 0) > 20) {
      //   model.commentList?.removeWhere((element) {
      //     return (model.commentList?.indexOf(element) ?? 0) >= 20;
      //   });
      // }

      ///移除位置
      int index = -1;
      list.removeWhere((element) {
        ///获取移除的位置
        bool remove = (element.contentId == model.contentId);
        if (remove) {
          ///确定索引
          index = list.indexOf(element);

          ///判断点赞，评论是否相符
          // if ((element.likeList?.length ?? 0) != (model.likeList?.length ?? 0)){
          //   model.likeList = element.likeList;
          // }
          // if ((element.commentList?.length ?? 0) != (model.commentList?.length ?? 0)){
          //   model.commentList = element.commentList;
          // }
        }
        return remove;
      });
      ///修改所有头像
      for (int i = 0; i < list.length ; i++){
        WxFriendsCircleModel circleModel = list[i];
        ///修改用户头像和昵称
        if(circleModel.publisherId == model.publisherId){
          circleModel.nickname = model.nickname;
          circleModel.headImg = model.headImg;
        }
      }
      if (index >= 0) {
        list.insert(index, model);
        setState(() {});
      }
    }
  }

  ///-------------------------------键盘部分------------------------------
  ///显示隐藏键盘
  void _onSwitchCommentBar() {

    Map<String, dynamic> map = {"isPresent": true, "isAnimated": false};
    if (controller.commenttype == COMMENTTYPE.people) {
      map["userName"] = controller.commentModel?.userNickname ?? "";
    }
    Future<String> future = BoostNavigator.instance.push("KeyBoardWidget",
        withContainer: withContainer, opaque: false, arguments: map);
    future.then((value) {
      if (value.length > 0) {
        _onComment(value as String);
      }
    });
  }

  /// 评论操作
  void _onComment(String text) {
    // 安全检查
    if (controller.currentModel == null) return;
    // 执行请求 异步处理
    controller.saveCommentData(text);
  }


  ///-------------------------------遮罩部分------------------------------
  // 显示遮罩
  void _onShowMenu({
    Function()? onTap,
  }) {
    ///返回后不刷新界面
    SameUser.needRefresh = false;

    ///跳转点赞评论
    Future<dynamic> backIndex = BoostNavigator.instance.push(
        "CommentPraiseWidget",
        withContainer: withContainer,
        opaque: false,
        arguments: {"isPresent": true, "isAnimated": false});
    backIndex.then((value) async {

      if (value is String && value.length > 0) {

        _onComment(value as String);
      } else if (value == 0) {
        ///点赞
        _onLike();
      } else if (value == 1) {
        ///评论
        controller.commenttype = COMMENTTYPE.common;

        ///显示键盘

        _onSwitchCommentBar();
      }
    });
    return;

  }

  /// 关闭 like 菜单
  Future<void> _onCloseMenu() async {
    if (controller.animationController.status == AnimationStatus.completed) {
      await controller.animationController.reverse();
      controller.shadeOverlayEntry?.remove();
      controller.shadeOverlayEntry?.dispose();
    }
  }

  /// 点赞操作
  void _onLike() {
    // 安全检查
    if (controller.currentModel == null) return;

    // 设置状态
    ///设置点赞列表
    if (controller.currentModel?.isLike == 1) {
      controller.delteLikeData();
    } else {
      ///没点赞了
      controller.saveLikeData();
    }

    // 关闭菜单
    _onCloseMenu();
  }


  @override
  void onPageHide() {
    // TODO: implement onPageHide
    super.onPageHide();
  }

  @override
  void onPageShow() {
    // TODO: implement onPageShow
    super.onPageShow();

    if (SameUser.needRefresh == true) {

      ///请求数据刷新
      Future.delayed(Duration(milliseconds: 500), (){
        controller.onRefresh();

      });
    } else {

      SameUser.needRefresh = true;

      ///手动刷新列表
      if (SameUser.modelMap is Map ){
         updateModels(SameUser.modelMap, controller.dataArr.value);
         SameUser.modelMap = {};
      }


    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    ///注册监听器
    PageVisibilityBinding.instance
        .addObserver(this, ModalRoute.of(context) as Route);
  }

  ///释放相关内容
  @override
  void dispose() {
    ///移除监听器
    PageVisibilityBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
