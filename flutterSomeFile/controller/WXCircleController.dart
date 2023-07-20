import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:tiens_im_flutter/common/utils/size_fit.dart';
import 'package:tiens_im_flutter/common/utils/utils.dart';
import 'package:tiens_im_flutter/pages/wx_zone/entity/userHeaderNameModel.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/same_user.dart';
import 'package:tiens_im_flutter/pages/wx_zone/widgets/dialogWidget.dart';

import '../../../common/utils/dio/http_utils.dart';
import '../../../common/utils/toast_util.dart';
import '../entity/circle_comment_model.dart';
import '../entity/circle_praises_model.dart';
import '../entity/wx_friends_circle_model.dart';
import '../until/sp_util.dart';
import '../until/time_util.dart';
import '../widgets/wx_circle.dart';

class WXCircleController extends GetxController {
  ///----------------------键盘输入部分---------------------------
  // 是否显示评论输入框
  RxBool isShowInput = false.obs;

  // 是否展开表情列表
  bool isShowEmoji = false;

  // 是否输入内容
  RxBool isInputWords = false.obs;

  // 评论输入框
  TextEditingController textCommentEditingController = TextEditingController();

  // 输入框焦点
  final Rx<FocusNode> focusNode = FocusNode().obs;

  // 键盘高度
  final double keyboardHeight = 200;

  ///----------------------评论点赞弹窗部分---------------------------
  // overlay 浮动层管理（管理多个遮罩）
  OverlayState? overlayState;

  // overlay 遮罩层
  OverlayEntry? shadeOverlayEntry;

  // 更多按钮位置 offset
  Rx<Offset> btnOffset = Offset.zero.obs;

  // 动画控制器
  late AnimationController animationController;

  // 动画 tween
  late Animation<double> sizeTween;

  // 当前操作的 item
  WxFriendsCircleModel currentModel = WxFriendsCircleModel();

  //评论类型
  CircleCommentModel? commentModel;
  COMMENTTYPE? commenttype;

  ///朋友圈列表数据
  int currentPage = 1;
  RxList<WxFriendsCircleModel> dataArr = <WxFriendsCircleModel>[].obs;

  ///评论列表数据
  int _commentPage = 2;
  int _commentPageNum = 20;

  int get commentPage {
    int commentsNum = currentModel.commentList?.length ?? 0;
    // int page = (commentsNum/20).toInt();
    // int other = (commentsNum % 20).toInt();
    _commentPage = 2;
    _commentPageNum = commentsNum;

    return _commentPage;
  }

  set commentPage(int page) {
    _commentPage = page;
  }

  ///刷新用
  EasyRefreshController easyRefreshController = EasyRefreshController(
      controlFinishLoad: true, controlFinishRefresh: true);



  ///滚动控制器
  ScrollController? listScrollController;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    ///保存用户的ID,以及加载举报
    SpUtil.getInstance().then((value){
      SameUser.getUserID();
      SameUser.loadReports();
    });

    ///获取用户的类型
    SameUser.getUserType();

    /// 监控键盘是否输入内容
    textCommentEditingController.addListener(() {
      isInputWords.value = textCommentEditingController.text.isNotEmpty;
    });


    ///listview控制器
    listScrollController = ScrollController();

  }

  ///刷新数据部分
  onRefresh() async {
    ///刷新后，评论回到第二页
    commentPage = 2;
    currentPage = 1;
    loadData(currentPage);

    ///回复上拉
    easyRefreshController.resetFooter();
  }

  onLoad() async {
    loadData(currentPage);
  }

  ///加载数据
  void loadData(int currentIndex) async {
    ///请求朋友圈数据
    HttpUtils.getInstance
        .get(
      "/imcircle/community/friend/list",
      queryParameters: {
        "pageNumber": currentIndex.toString(),
        "pageSize": "10"
      },
      isShowHud: false,
    )
        .then(
      (value) {
        if (value.isSuccess) {


          ///后台返回数据
          List mapList = value.data["data"] ?? [];

          if (mapList is List && mapList.length > 0) {
            ///配置头像
            searchIconAndName(mapList).then((value) {
              currentPage == 1
                  ? easyRefreshController.finishRefresh()
                  : easyRefreshController.finishLoad();

              ///页数增加
              currentPage++;

              ///刷新界面
              update();

              ///如果第一页滚动顶部（以后可能要用）
              // if(currentPage == 2){
              //   if (listScrollController?.hasClients ?? false) {
              //     final position = listScrollController?.position.minScrollExtent;
              //     // listScrollController?.jumpTo(position!);
              //     listScrollController?.animateTo(
              //       position!,
              //       duration: Duration(milliseconds: 300),
              //       curve: Curves.easeOut,
              //     );
              //   }
              // }


            });
          } else {
            ///第一页没数据
            if (currentPage == 1) {
              dataArr.clear();
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
        } else {
          ///网络错误
          currentPage == 1
              ? easyRefreshController.finishRefresh(IndicatorResult.fail)
              : easyRefreshController.finishLoad(IndicatorResult.fail);
        }
      },
    );
  }

  Future<void> searchIconAndName(List mapList) async {
    ///第一页清除数据
    if (currentPage == 1) {
      dataArr.clear();
    }

    ///添加后台返回数据
    for (int i = 0; i < mapList.length; i++) {
      Map dict = mapList[i];
      WxFriendsCircleModel circleModel =
          WxFriendsCircleModel.fromJson(dict as Map<String, dynamic>);
      if(!SameUser.reportList.contains(circleModel.contentId.toString())){

        await SameUser.getOneUser(circleModel.publisherId ?? "").then(
              (value) {
            UserHeaderName userIcon = value as UserHeaderName;
            circleModel.nickname = userIcon.nickname;
            circleModel.headImg = userIcon.customHeadImage;
            dataArr.add(circleModel);
          },
        );

        ///查询评论头像和点赞名称
        await searchCommentAndPraiseIcon(circleModel);
      }

    }
  }

  Future<void> searchCommentAndPraiseIcon(
      WxFriendsCircleModel circleModel) async {
    ///获取评论信息
    List<CircleCommentModel> commentList = circleModel.commentList ?? [];
    for (int i = 0; i < commentList.length; i++) {
      CircleCommentModel comment = commentList[i];
      await SameUser.getOneUser(comment.userId ?? "").then((value) {
        UserHeaderName userIcon = value as UserHeaderName;
        comment.userHeadImg = userIcon.customHeadImage;
        comment.userNickname = userIcon.nickname;
      });

      if ((comment.replyUserId ?? "").length > 0) {
        await SameUser.getOneUser(comment.replyUserId ?? "").then((value) {
          UserHeaderName userIcon = value as UserHeaderName;
          comment.replyUserNickname = userIcon.nickname;
        });
      }
    }

    ///获取点赞信息
    List<Praises> praises = circleModel.likeList ?? [];
    for (int i = 0; i < praises.length; i++) {
      Praises praise = praises[i];
      await SameUser.getOneUser(praise.userId ?? "").then((value) {
        UserHeaderName userIcon = value as UserHeaderName;
        praise.headImg = userIcon.customHeadImage;
        praise.nickname = userIcon.nickname;
      });
    }
  }

  ///判断是否点赞
  bool gerPraise(List<Praises> praises) {
    bool flag = false;

    praises.forEach((element) {
      if (element.userId == SameUser.getUserID()) {
        flag = true;
      }
    });
    return flag;
  }

  ///评论接口
  void saveCommentData(String content) async {
    ///未知用户类型
    if (SameUser.userType == "") {
      SameUser.getUserType().then((value) {
        ///获取到了用户信息
        if (value is String && value.length > 0) {
          saveCommentDataTwo(content);
        }
      });
    } else {
      saveCommentDataTwo(content);
    }
  }

  void saveCommentDataTwo(String content) async {
    ///请求参数
    Map<String, dynamic> params = {};
    //文章发布人accid
    params["publisherid"] = currentModel?.publisherId ?? "";
    //评论人accid
    params["userid"] = UserInfo().accid ?? "";
    //内容ID
    params["contentid"] = currentModel.contentId.toString() ?? "";
    //内容
    params["content"] = content;
    //被回复人ID
    params["replyuserid"] = commenttype == COMMENTTYPE.common
        ? null
        : (commenttype == COMMENTTYPE.people
            ? commentModel?.userId
            : commentModel?.replyUserId);
    //被回复评论id
    params["commentid"] =
        commenttype == COMMENTTYPE.common ? null : commentModel?.id;

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
        if (value.isSuccess){

          Future<UserHeaderName?> result = SameUser.getOneUser(SameUser.getUserID());
          result.then((oneUser){

            ///评论成功
            CircleCommentModel conmmet = CircleCommentModel(
              id: value.data,
              userId: SameUser.getUserID(),
              userNickname: oneUser?.nickname?.length == 0
                  ? "我"
                  : oneUser?.nickname,
              userHeadImg: SameUser.getUserImage(),
              replyUserId: commenttype == COMMENTTYPE.common
                  ? ""
                  : (commenttype == COMMENTTYPE.people
                  ? commentModel?.userId
                  : commentModel?.replyUserId),
              replyUserNickname: commenttype == COMMENTTYPE.common
                  ? ""
                  : (commenttype == COMMENTTYPE.people
                  ? commentModel?.userNickname
                  : commentModel?.replyUserNickname),
              content: content,
              createTime: TimeUtil.getTimeFormat(TimeUtil.getNowSecond()),
            );

            if ((currentModel.commentList?.length ?? 0) < 20) {
              int index = dataArr.value.indexOf(currentModel);
              dataArr.remove(currentModel);
              currentModel.commentList?.add(conmmet);
              dataArr.insert(index, currentModel);

              ///刷新界面
              update();
            }
          });

        } else {
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
        if (value.isSuccess) {
          ///删除成功
          int index = dataArr.value.indexOf(model);
          dataArr.remove(model);
          model?.commentList?.remove(comment);
          dataArr.insert(index, model);

          ///刷新界面
          update();
        } else {
          ///网络错误
          ToastUtil.showNotClickText(text: "moment_moments_00035".tl);
        }
      },
    );
  }

  ///评论列表数据
  void loadCommentData(int currentIndex) async {
    HttpUtils.getInstance
        .post(
      "/imcircle/community/comment/friendlist",
      data: {
        "page": currentIndex,
        "pageSize": _commentPageNum,
        "contentId": currentModel.contentId
      },
      isShowHud: true,
    )
        .then(
      (value) {
        if (value.isSuccess) {
          ///获取评论列表数据
          List<dynamic> listData = value.data["data"] ?? [];

          ///如果有数据
          if (listData.length > 0) {
            commentPage++;
            listData.forEach((element) {
              currentModel.commentList?.add(
                  CircleCommentModel.fromJson(element as Map<String, dynamic>));
            });

            int index = dataArr.value.indexOf(currentModel);
            dataArr.remove(currentModel);
            dataArr.insert(index, currentModel);

            ///刷新界面
            update();
          } else {
            ToastUtil.showText(
                text: "moment_moments_00022".tl);
          }
        } else {
          ///网络失败
          ToastUtil.showText(
              text: value.error?.msg ?? "moment_moments_00029".tl);
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
      data: {
        "userId": currentModel.publisherId,
        "contentId": currentModel.contentId
      },
      isShowHud: false,
    )
        .then(
      (value) {
        if (value.isSuccess) {
          ///点赞成功
          int index = dataArr.value.indexOf(currentModel);
          dataArr.remove(currentModel);
          currentModel?.likeList?.add(
            Praises(
                userId: SameUser.getUserID(),
                nickname: SameUser.getUserName().length == 0
                    ? "我"
                    : SameUser.getUserName(),
                headImg: SameUser.getUserImage()),
          );
          currentModel?.isLike = 1;
          dataArr.insert(index, currentModel);

          update();
        } else {
          ///网络错误
          currentModel?.isLike = 0;
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
      data: {"contentId": currentModel.contentId},
      isShowHud: true,
    )
        .then(
      (value) {
        if (value.isSuccess) {
          ///取消点赞
          int index = dataArr.value.indexOf(currentModel);
          dataArr.remove(currentModel);

          List<Praises> praise = <Praises>[];
          currentModel.likeList?.forEach((element) {
            if (element.userId != SameUser.getUserID()) {
              praise.add(element);
            }
          });
          currentModel?.likeList = praise;
          currentModel?.isLike = 0;
          dataArr.insert(index, currentModel);

          ///刷新界面
          update();
        } else {
          ///网络错误
          currentModel?.isLike = 1;
          ToastUtil.showNotClickText(text: "moment_moments_00036".tl);
        }
      },
    );
  }

  ///删除朋友圈动态
  void delteOneCircleData(WxFriendsCircleModel model) async {
    ///请求朋友圈数据
    var httpResponseData = await HttpUtils.getInstance.get(
      "/imcircle/community/friend/delete/${model.contentId}",
      queryParameters: {},
      isShowHud: true,
    );
    if (httpResponseData.isSuccess) {
      dataArr.remove(model);

      ///刷新界面
      update();
    } else {
      ///网络错误
      ToastUtil.showNotClickText(text: "moment_moments_00038".tl);
    }
  }

  ///小按钮
  void reportRefresh(WxFriendsCircleModel model){
    ///修改数据并刷新
    List<WxFriendsCircleModel> newDataArr = <WxFriendsCircleModel>[];
    int index =  dataArr.value.indexOf(model);
    dataArr.value.remove(model);
    dataArr.value.forEach((element) {
      element.showFlag = false;
      newDataArr.add(element);
    });
    newDataArr.insert(index, model);
    dataArr.value = newDataArr;
    update();

  }

  ///点举报按钮
  void deleteReport(WxFriendsCircleModel model) {

    List<WxFriendsCircleModel> newDataArr = <WxFriendsCircleModel>[];
    dataArr.value.forEach((element) {
      if (element.contentId != model.contentId){
        newDataArr.add(element);
      }
    });
    dataArr.value = newDataArr;
    update();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    ///键盘相关释放
    textCommentEditingController.dispose();
    focusNode.value.dispose();

    ///评论弹窗释放
    animationController.dispose();
    listScrollController?.dispose();
    super.dispose();
  }

  //双击底部tablebar刷新
  void doubleClickRefresh() {
    easyRefreshController.callRefresh();
  }


}
