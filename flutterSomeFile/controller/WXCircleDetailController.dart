import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:get/get.dart';
import 'package:tiens_im_flutter/common/utils/language/translation.dart';
import 'package:tiens_im_flutter/common/utils/user_info.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/same_user.dart';

import '../../../common/utils/dio/http_utils.dart';
import '../../../common/utils/toast_util.dart';
import '../entity/circle_comment_model.dart';
import '../entity/circle_praises_model.dart';
import '../entity/wx_friends_circle_model.dart';
import '../until/time_util.dart';
import '../widgets/wx_circle.dart';

class WXCircleDetailController extends GetxController {
  WXCircleDetailController();

  ///获取位置
  GlobalKey key = GlobalKey();

  ///----------------------键盘输入部分---------------------------
// 是否显示评论输入框
  RxBool isShowInput = false.obs;

  // 是否展开表情列表
  RxBool isShowEmoji = false.obs;

  // 是否输入内容
  RxBool isInputWords = false.obs;

  ///已经被删除
  RxBool deleteOrNo = false.obs;

  // 评论输入框
  final TextEditingController textCommentEditingController =
      TextEditingController();

  // 输入框焦点
  final Rx<FocusNode> focusNode = FocusNode().obs;

  // 键盘高度
  final double keyboardHeight = 200;

  ///点赞部分弹窗，动画
  // 更多按钮位置 offset
  Rx<Offset> btnOffset = Offset.zero.obs;

  // 动画控制器
  late AnimationController animationController;

  // 动画 tween
  late Animation<double> sizeTween;

  //评论类型
  CircleCommentModel? commentModel;
  COMMENTTYPE? commenttype;
  int currentPage = 1;

  ///刷新用
  EasyRefreshController easyRefreshController = EasyRefreshController(controlFinishLoad: true,controlFinishRefresh: true);

  ///获取数据
  String contentId = "";
  Rx<WxFriendsCircleModel> model = new WxFriendsCircleModel().obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    /// 监控键盘是否输入内容
    textCommentEditingController.addListener(() {
      isInputWords.value = textCommentEditingController.text.isNotEmpty;
    });
  }

  ///提交pv数值
  updatePv() async {
    ///访问朋友圈，增加PV值
    HttpUtils.getInstance
        .post(
          "/imcircle/community/common/number",
          data: {"contentId": contentId.toString() ?? ""},
          isShowHud: false,
        )
        .then((value) {});
  }

  ///加载数据部分
  onRefresh() async {
    currentPage = 1;
    loadCommentData(currentPage);
    loadPraiseData();

    ///回复上拉
    easyRefreshController.resetFooter();
  }

  onLoad() async {
    loadCommentData(currentPage);
  }

  ///评论列表数据
  void loadCommentData(int currentIndex) async {
    HttpUtils.getInstance
        .post(
      "/imcircle/community/comment/friendlist",
      data: {"page": currentIndex, "pageSize": 20, "contentId": contentId},
      isShowHud: true,
    )
        .then(
      (value) {

        if(value.isSuccess){

          ///获取评论列表数据
          List<dynamic> listData = value.data["data"] ?? [];

          ///如果有数据
          if (listData.length > 0) {
            ///第一页清除数据
            if (currentPage == 1) {
              model.value.commentList?.clear();
            };

            currentPage == 1
                ? easyRefreshController.finishRefresh(IndicatorResult.success)
                : easyRefreshController.finishLoad(IndicatorResult.success);

            currentPage++;

            listData.forEach((element) {
              model.value.commentList?.add(
                  CircleCommentModel.fromJson(element as Map<String, dynamic>));
            });

            WxFriendsCircleModel newModel =
            WxFriendsCircleModel.fromJson(model.toJson());
            model.value = newModel;

            ///刷新界面
            update();

          }else{

            ///第一页没数据
            if (currentPage == 1){
              model.value.commentList?.clear();
            }

            update();

            ///没有更多数据
            if (currentPage == 1){
              easyRefreshController.finishRefresh(IndicatorResult.success);
              easyRefreshController.finishLoad(IndicatorResult.noMore);
            }else{
              easyRefreshController.finishLoad(IndicatorResult.noMore);
            }
          }

        }else{

          ///网络错误
          currentPage == 1
              ? easyRefreshController.finishRefresh(IndicatorResult.fail)
              : easyRefreshController.finishLoad(IndicatorResult.fail);
        }

      },
    );
  }

  ///加载详情数据
  void loadDeatailData() async {
    HttpUtils.getInstance
        .post(
      "/imcircle/community/friend/detail",
      data: {"contentId": contentId},
      isShowHud: true,
    )
        .then(
      (value) {


        if (value.isSuccess){

          Map deleteMap = value.data as Map;
          if (deleteMap is Map && deleteMap.isEmpty) {
            deleteOrNo.value = true;

            ///刷新界面
            update();
          } else {
            Map<String, dynamic> dataMap = value.data;
            model.value = WxFriendsCircleModel.fromJson(dataMap);
            if (model.value.contentId == null) {
              model.value.contentId = int.parse(contentId ?? "");
            }

            ///刷新用户数据
            UserInfo().userInfoMap[model.value.publisherId ?? ""] = {"nickname": model.value.nickname ?? "", "headImg" : model.value.headImg ?? ""};

            ///刷新界面
            update();

            ///获取评论列表
            loadCommentData(currentPage);

            ///加载点赞列表
            loadPraiseData();
          }

        }else{

          ///网络错误
          ToastUtil.showText(text: "moment_moments_00029".tl);

        }

      },
    );
  }

  ///加载点赞列表数据
  void loadPraiseData() async {
    HttpUtils.getInstance
        .post(
      "/imcircle/community/likes/friendlist",
      data: {"contentId": contentId},
      isShowHud: true,
    )
        .then(
      (value) async{


        if(value.isSuccess){

          List<dynamic> dataList = value.data;

          ///清空数据
          model.value.likeList?.clear();

          ///添加数据
          dataList.forEach((element) {
            model.value.likeList
                ?.add(Praises.fromJson(element as Map<String, dynamic>));
          });
          model.value.isLike = model.value.getIslike(model.value.likeList ?? []);

          WxFriendsCircleModel oldModel =
          WxFriendsCircleModel.fromJson(model.toJson());
          model.value = oldModel;

          ///刷新界面
          update();
        }else{

          ///网络错误
          ToastUtil.showText(text: "moment_moments_00029".tl);

        }
      },
    );
  }

  ///点赞接口
  void saveLikeData() async {
    ///请求朋友圈数据
    HttpUtils.getInstance
        .post(
      "/imcircle/community/likes/change",
      data: {"userId": model.value.publisherId, "contentId": contentId},
      isShowHud: true,
    )
        .then(
      (value) {

        if(value.isSuccess){

          model?.value.likeList?.add(
            Praises(
                userId: SameUser.getUserID(),
                nickname: SameUser.getUserName().length == 0
                    ? "我"
                    : SameUser.getUserName(),
                headImg: SameUser.getUserImage()),
          );
          model.value = WxFriendsCircleModel.fromJson(model.toJson());
          model.value.isLike = 1;

          update();

        }else{
          model.value.isLike = 0;
          ///网络错误
          ToastUtil.showNotClickText(text: "moment_moments_00006".tl);

        }
      },
    );
  }

  ///取消点赞接口
  void delteLikeData() async {
    ///请求朋友圈数据
    HttpUtils.getInstance
        .post(
      "/imcircle/community/likes/unchange",
      data: {"contentId": contentId},
      isShowHud: true,
    )
        .then(
      (value) {
        if (value.isSuccess) {
          ///取消点赞

          List<Praises> praise = <Praises>[];
          model?.value.likeList?.forEach((element) {
            if (element.userId != SameUser.getUserID()) {
              praise.add(element);
            }
          });
          model?.value.likeList = praise;
          model.value = WxFriendsCircleModel.fromJson(model.toJson());
          model?.value.isLike = 0;

          ///刷新界面
          update();

        }else{
          ///网络错误
          model?.value.isLike = 1;
          ToastUtil.showNotClickText(text: "moment_moments_00036".tl);

        }
      },
    );
  }

  ///评论接口
  void saveCommentData(String content) async {

    ///未知用户类型
    if (SameUser.userType == ""){
      SameUser.getUserType().then((value){
        ///获取到了用户信息
        if (value is String && value.length > 0){
          saveCommentDataTwo(content);
        }
      });
    }else{
      saveCommentDataTwo(content);
    }

  }

  void saveCommentDataTwo(String content) async{
    ///请求参数
    Map<String, dynamic> params = {};
    //文章发布人accid
    params["publisherid"] = model?.value.publisherId ?? "";
    //评论人accid
    params["userid"] = SameUser.getUserID();
    //内容ID
    params["contentid"] = contentId.toString() ?? "";
    //内容
    params["content"] = content;
    //被回复人ID
    params["replyuserid"] = commenttype == COMMENTTYPE.common
        ? null
        : (commenttype == COMMENTTYPE.people
        ? commentModel?.userId
        : commentModel?.replyUserId);

    //被回复评论id
    params["commentid"] = commenttype == COMMENTTYPE.common ? null : commentModel?.id;
    //0 PGC  1普通用户
    params["usertype"] = SameUser.userType;

    ///发布评论
    HttpUtils.getInstance
        .post(
      "/imcircle/community/comment/save",
      data: params,
      isShowHud: true,
    )
        .then(
          (value) {

        if(value.isSuccess){

          CircleCommentModel conmmet = CircleCommentModel(
            id: value.data,
            userId: SameUser.getUserID(),
            userNickname:
            SameUser.getUserName().length == 0 ? "我" : SameUser.getUserName(),
            userHeadImg: SameUser.getUserImage(),
            replyUserNickname: commenttype == COMMENTTYPE.common
                ? ""
                : (commenttype == COMMENTTYPE.people
                ? commentModel?.userNickname
                : commentModel?.replyUserNickname),
            replyUserId: commenttype == COMMENTTYPE.common
                ? ""
                : (commenttype == COMMENTTYPE.people
                ? commentModel?.userId
                : commentModel?.replyUserId),
            content: content,
            createTime: TimeUtil.getTimeFormat(TimeUtil.getNowSecond()),
          );

          model.value.commentList?.add(conmmet);
          model.value = WxFriendsCircleModel.fromJson(model.toJson());

          ///刷新界面
          update();
        }else{
          ///网络错误
          ToastUtil.showNotClickText(text: "moment_moments_00007".tl);

        }

      },
    );
  }

  ///删除评论
  void deleteCommentData(
      WxFriendsCircleModel model, CircleCommentModel comment) async {
    ///请求朋友圈数据
    HttpUtils.getInstance
        .post(
      "/imcircle/community/comment/delete/${comment?.id.toString()}",
      data: {},
      isShowHud: true,
    )
        .then(
      (value) {

        if (value.isSuccess){
          model.commentList?.remove(comment);
          this.model.value = WxFriendsCircleModel.fromJson(model.toJson());

          ///刷新界面
          update();
        }else{
          ///网络错误
          ToastUtil.showNotClickText(text: "moment_moments_00035".tl);

        }

      },
    );
  }

  ///删除朋友圈动态
  void delteOneCircleData() async {
    ///请求朋友圈数据
    var httpResponseData = await HttpUtils.getInstance.get(
      "/imcircle/community/friend/delete/${contentId}",
      queryParameters: {},
      isShowHud: true,
    );
    if (httpResponseData.isSuccess) {
      ///返回上一页
      BoostNavigator.instance.pop({"delete": contentId ?? ""});

      ///刷新界面
      update();
    }else{

      ///网络错误
      ToastUtil.showNotClickText(text: "moment_moments_00038".tl);

    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    ///键盘相关释放
    textCommentEditingController.dispose();
    focusNode.value.dispose();

    ///评论弹窗释放
    animationController.dispose();
    super.dispose();
  }
}
