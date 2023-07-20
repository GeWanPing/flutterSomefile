import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:get/get.dart';
import 'package:tiens_im_flutter/common/utils/utils.dart';
import 'package:tiens_im_flutter/pages/square/views/report_page.dart';
import 'package:tiens_im_flutter/pages/wx_zone/entity/circle_comment_model.dart';
import 'package:tiens_im_flutter/pages/wx_zone/entity/circle_praises_model.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/ImageUtil.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/jh_color_utils.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/jh_string_utils.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/same_user.dart';
import 'package:tiens_im_flutter/pages/wx_zone/widgets/praise_comment_widget.dart';
import 'package:tiens_im_flutter/pages/wx_zone/widgets/wx_circle.dart';
import 'dart:convert' as convert;
import '../../../common/widgets/empty.dart';
import '../config/colors.dart';
import '../controllers/WXCircleDetailController.dart';
import '../until/time_util.dart';
import 'dialogWidget.dart';
import 'jh_bottom_sheet.dart';
import 'jh_nine_picture.dart';

///点赞头像宽度
final double praiseWidth = 35.px;
final double praiseMargin = 5.px;

class CircleDetailPage extends StatefulWidget {
  const CircleDetailPage({Key? key, this.uniqueId, this.arguments})
      : super(key: key);

  final String? uniqueId;
  final Object? arguments;

  @override
  State<CircleDetailPage> createState() => _CircleDetailPageState();
}

class _CircleDetailPageState extends State<CircleDetailPage>
    with SingleTickerProviderStateMixin, PageVisibilityObserver {
  ///getX绑定数据
  final controller = Get.put(WXCircleDetailController());

  ///----------------------评论点赞弹窗部分---------------------------
  // overlay 浮动层管理（管理多个遮罩）
  OverlayState? _overlayState;

  // overlay 遮罩层
  OverlayEntry? _shadeOverlayEntry;

  @override
  void initState() {
    super.initState();

    ///获取数据convert.jsonDecode(jsonStr)
    Map<String, dynamic> jsonMap = widget.arguments as Map<String, dynamic>;
    String contentId = jsonMap["contentId"] ?? "";
    controller.contentId = contentId;

    ///弹出点赞，评论小窗口部分
    ///初始化 overlay
    _overlayState = Overlay.of(context);

    /// 初始化动画控制器
    controller.animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    /// 设置动画取值范围
    SameUser.realWidth = TimeUtil.commentMaxWidth(
        "moment_moments_00005".tl, "moment_moments_00004".tl);
    controller.sizeTween =
        Tween(begin: 0.0.px, end: SameUser.realWidth).animate(
      CurvedAnimation(
          parent: controller.animationController, curve: Curves.easeInOut),
    );

    loadData();
  }

  loadData() {
    ///提交pv值
    controller.updatePv();

    ///获取详情数据
    controller.loadDeatailData();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<WXCircleDetailController>(
        init: controller,
        builder: (controller) {
          return Scaffold(
              appBar: AppBar(
                actions: [
                  InkWell(
                    child:
                        controller.model.value.publisherId == UserInfo().accid
                            ? const SizedBox()
                            : Center(
                                child: Text(
                                "${'moment_square_00062'.tl}   ",
                                style: TextStyle(fontSize: 16.px),
                              )),
                    onTap: () {
                      BoostNavigator.instance.push(ReportPage.routerName,
                          arguments: {
                            "contentId": controller.contentId,
                            "type": 1
                          });
                    },
                  )
                ],
                elevation: 0,
                centerTitle: true,
                title: Text("moment_moments_00011".tl),
                backgroundColor: JhColorUtils.hexColor("#EDEDED"),
                leading: IconButton(
                  icon: ImageIcon(const AssetImage(
                      'assets/images/wxzone/ic_nav_back_white.png')),
                  iconSize: 18,
                  padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                  onPressed: () {
                    BoostNavigator.instance
                        .pop({"back": controller.model.value.toJson() ?? {}});
                  },
                ),
              ),
              body: controller.deleteOrNo.value == true
                  ? Container(
                      child: Center(
                        child: Text(
                          "server_00008".tl,
                          style: TextStyle(fontSize: 18.px),
                        ),
                      ),
                    )
                  : getHaveCommentWidget(controller.model.value.commentList)
              // bottomNavigationBar:
              //     controller.isShowInput.value ? _buildCommentBar() : null,
              );
        });
  }

  ///获取评论相关数据
  Widget getHaveCommentWidget(List<CircleCommentModel>? commentList) {
    return Container(
      color: Colors.white,
      child: EasyRefresh.builder(
          fit: StackFit.expand,
          controller: controller.easyRefreshController,
          onRefresh: () async {
            controller.onRefresh();
          },
          onLoad: () async {
            controller.onLoad();
          },

          childBuilder: (BuildContext context, ScrollPhysics physics) {
            if (commentList != null) {
              return ListView.builder(
                  physics: physics,

                  ///全部展示内容
                  itemCount: (commentList.length ?? 0) + 1,
                  itemBuilder: (BuildContext context, int index) {
                    ///顶部
                    if (index == 0) {
                      return getHeaderWidget();
                    }

                    ///评论列表
                    CircleCommentModel? commentModel = commentList?[index - 1];
                    return _onCommentWidget(commentModel, index - 1);
                  });
            } else {
              return Empty(physics: physics);
            }
          }),
    );
  }

  ///头部
  Widget getHeaderWidget() {
    return Container(
      color: Colors.white,

      ///装饰器
      child: Column(
        children: [
          ///头像，图片，内容
          Row(
            ///水平排列
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 头像
              InkWell(
                onTap: () {
                  headerClick(controller.model?.value.publisherId ?? "");
                },
                child: Container(
                  margin:
                      EdgeInsets.only(left: 11.px, top: 11.px, right: 11.px),
                  height: 42.px,
                  clipBehavior: Clip.hardEdge,
                  width: 42.px,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.px),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: controller.model?.value.headImg ?? "",
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                    placeholder: (context, url) => ImageUtil.placeholderImage(),
                    errorWidget: (context, url, error) =>
                        ImageUtil.placeholderImage(),
                  ),
                ),
              ),

              ///占满剩余空间，多个可以比例分割空间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ///名字
                    Row(
                      children:[
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              headerClick(controller.model?.value.publisherId ?? "");
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 13.px),
                              child: Text(
                                controller.model?.value.nickname ?? "", 
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: KColors.wxTextBlueColor,
                                    fontSize: 16.px,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.5.px,)
                      ] 

                    ),

                    ///内容
                    Offstage(
                      offstage:
                          (controller.model?.value.contentText ?? "").length <=
                              0,
                      child: Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 15.px, 5.px),
                          child: Text(controller.model?.value.contentText ?? "",
                              style: TextStyle(fontSize: 16.px))),
                    ),

                    ///九宫格
                    SizedBox(
                      height:
                          (controller.model?.value.contentText ?? "").length <=
                                  0
                              ? 7.px
                              : 5.rpx,
                    ),
                    _imagesWidget(context),

                    ///时间等
                    Container(
                      height: 32.px,
                      margin: EdgeInsets.fromLTRB(0, 5.px, 11.px, 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ///时间
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                TimeUtil.dateTimeFormat(controller
                                        .model?.value.createTime?.jhNullSafe ??
                                    ""),
                                style: TextStyle(
                                    color: KColors.wxTextGrayColor,
                                    fontSize: 14.px),
                              ),
                              Offstage(
                                offstage: !(SameUser.isSame(
                                    controller.model.value.publisherId ?? "")),
                                child: InkWell(
                                    onTap: () {
                                      dialogWidget tool = dialogWidget(
                                        context: context,
                                        onClickCancelBtn: () {},
                                        onClickTrueBtn: () {
                                          controller.delteOneCircleData();
                                        },
                                      );
                                      tool.showCupertinoAlertDialog(context);
                                    },
                                    child: Container(
                                      width: 29.px,
                                      child: Center(
                                        child: Container(
                                          height: 13.px,
                                          width: 13.px,
                                          child: Image.asset(
                                            "assets/images/wxzone/delete.png",
                                          ),
                                        ),
                                      ),
                                    )),
                              )
                            ],
                          ),

                          ///开始评论按钮
                          InkWell(
                              key: controller.key,
                              child: Container(
                                width: 32.px,
                                height: 20.px,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3.px),
                                    color: KColors.kBackGreyColor),
                                child: Image.asset(
                                  'assets/images/wxzone/ic_diandian.png',
                                  color: KColors.wxTextBlueColor,
                                ),
                              ),
                              onTap: () {
                                /// 获取组件屏幕位置
                                var offset = _getOffset(controller.key);

                                ///弹出评论点赞窗口
                                controller.btnOffset.value = offset;

                                /// 通过 Overlay 显示菜单
                                _onShowMenu(onTap: () => _onCloseMenu(-1));
                              })
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          ///点赞
          Offstage(
            offstage: (controller.model?.value.likeList?.length ?? 0) <= 0,
            child: Column(children: [
              Container(
                  margin: EdgeInsets.fromLTRB(22.rpx, 6.px, 22.rpx, 0.px),
                  decoration: BoxDecoration(
                      color: KColors.kBackGreyColor,
                      borderRadius:
                          (controller.model?.value.commentList?.length ?? 0) > 0
                              ? BorderRadius.only(
                                  topRight: Radius.circular(3.px),
                                  topLeft: Radius.circular(3.px))
                              : BorderRadius.circular(3.px)),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 5.px, 0, 5.px),
                    child: Row(
                      ///水平排列
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ///点赞图标
                        Container(
                            // margin: EdgeInsets.only(right: praiseMargin),
                            height: praiseWidth,
                            width: praiseWidth,
                            child: Center(
                              child: Container(
                                  height: 15.px,
                                  width: 15.px,
                                  child: Image.asset(
                                      "assets/images/wxzone/like.png",
                                      fit: BoxFit.cover)),
                            )),
                        Expanded(
                            child: Wrap(
                          spacing: praiseMargin,
                          runSpacing: praiseMargin,
                          children: [
                            for (final asset
                                in (controller.model?.value.likeList ?? []))
                              _buildPhotoItem(asset, praiseWidth),
                          ],
                        ))
                      ],
                    ),
                  )),
              Offstage(
                offstage:
                    (controller.model.value.commentList?.length ?? 0) <= 0,
                child: Container(
                  margin: EdgeInsets.fromLTRB(22.rpx, 0.px, 22.rpx, 0.px),
                  height: 0.5.px,
                  color: KColors.commentPraiseLineColor,
                ),
              )
            ]),
          ),
        ],
      ),
    );
  }

  ///九宫格图片view
  Widget _imagesWidget(context) {
    return JhNinePicture(
      model: controller.model!.value,
      withContainer: false,
      lRSpace: (80.0 + 20.0),
      onLongPress: (int index, dynamic imgArr) {
        JhBottomSheet.showText(context, dataArr: ['保存图片']);
      },
    );
  }

  /// 获取组件屏幕位置 offset
  Offset _getOffset(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    final Offset offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    return offset;
  }

  ///创建一个点赞头像
  _buildPhotoItem(Praises asset, double praiseWidth) {
    return InkWell(
      onTap: () {
        headerClick(asset.userId ?? "");
      },
      child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(3.px)),
          clipBehavior: Clip.hardEdge,
          height: praiseWidth,
          width: praiseWidth,
          child: CachedNetworkImage(
            imageUrl: asset?.headImg ?? "",
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
            placeholder: (context, url) => ImageUtil.placeholderImage(),
            //CircularProgressIndicator(),
            errorWidget: (context, url, error) => ImageUtil.placeholderImage(),
          )),
    );
  }

  ///创建评论cell
  Widget _onCommentWidget(CircleCommentModel? commentModel, int commentIndex) {
    return Container(
      margin: EdgeInsets.only(left: 22.rpx, right: 22.rpx),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: getCommentRadius(commentModel, commentIndex),
            color: KColors.kBackGreyColor),
        child: Row(

            ///水平排列
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///评论图标
              Container(
                margin: EdgeInsets.only(top: 9.px, right: 0.rpx, left: 0.px),
                height: praiseWidth,
                width: praiseWidth,
                child: Offstage(
                    offstage: commentIndex > 0,
                    child: Center(
                      child: Container(
                          height: 15.px,
                          width: 15.px,
                          child: Image.asset(
                              "assets/images/wxzone/commentIcon.png",
                              fit: BoxFit.cover)),
                    )),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(0, 1.px, 9.px, 1.px),
                  decoration: BoxDecoration(
                    border:
                        (controller.model?.value.commentList?.length ?? 0) ==
                                (commentIndex + 1)
                            ? null
                            : Border(
                                bottom: BorderSide(
                                    width: 0.5.px,
                                    color: KColors.commentPraiseLineColor)),
                  ),
                  child: Row(
                    ///水平排列
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 头像
                      InkWell(
                        onTap: () {
                          headerClick(commentModel?.userId ?? "");
                        },
                        child: Container(
                            margin: EdgeInsets.only(
                                top: 9.px, left: 0, right: praiseMargin),
                            height: praiseWidth,
                            width: praiseWidth,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3.px),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: commentModel?.userHeadImg ?? "",
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: imageProvider, fit: BoxFit.cover),
                                ),
                              ),
                              placeholder: (context, url) =>
                                  ImageUtil.placeholderImage(),
                              //CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  ImageUtil.placeholderImage(),
                            )),
                      ),

                      ///占满剩余空间，多个可以比例分割空间
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ///判断本人
                            if (SameUser.isSame(commentModel?.userId ?? "")) {
                              ///保存当前model
                              controller.commentModel = commentModel;
                              JhBottomSheet.showText(context,
                                  dataArr: ["moment_moments_00010".tl],
                                  clickCallback:
                                      (int selectIndex, String selectText) {
                                if (selectIndex == 1) {
                                  controller.deleteCommentData(
                                      controller.model.value, commentModel!);
                                }
                              });
                            } else {
                              ///type=0是点击评论者， type=1点击被评论者
                              controller.commentModel = commentModel;
                              controller.commenttype = COMMENTTYPE.people;

                              ///显示键盘
                              _onSwitchCommentBar();
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ///名字和时间
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ///名字
                                  Container(
                                    width: 205.px,
                                    margin: EdgeInsets.only(top: 9.px),
                                    child: RichText(
                                      text: TextSpan(
                                        children: getOneComment(commentModel),
                                      ),
                                    ),
                                  ),

                                  ///时间
                                  Container(
                                    margin: EdgeInsets.only(top: 9.px),
                                    child: Text(
                                      TimeUtil.dateTimeFormat(
                                          commentModel?.createTime.jhNullSafe ??
                                              ""),
                                      style: TextStyle(
                                          color: KColors.unselectTextColor,
                                          fontSize: 12.px),
                                    ),
                                  ),
                                ],
                              ),

                              ///内容
                              Container(
                                  margin:
                                      EdgeInsets.fromLTRB(0, 3.px, 15.px, 5.px),
                                  child: Text(commentModel?.content ?? "",
                                      style: TextStyle(fontSize: 14.px))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
      ),
    );
  }

  ///获取名称字符串
  List<InlineSpan> getOneComment(CircleCommentModel? comment) {
    List<InlineSpan> listView = [];

    ///评论者
    int haveToName = comment?.replyUserNickname?.length ?? 0;

    if (haveToName <= 0) {
      listView.add(
        TextSpan(
          text: (comment?.userNickname ?? ""),
          style: TextStyle(
              color: KColors.wxTextBlueColor,
              fontSize: 14.px,
              fontWeight: FontWeight.w600),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              headerClick(comment?.userId ?? "");
            },
        ),
      );
    }

    ///存在被评论者
    if (haveToName > 0) {
      listView.add(TextSpan(
          text: "moment_moments_00014".tl,
          style: TextStyle(color: Colors.black, fontSize: 14.px)));
      listView.add(TextSpan(
        text: (comment?.replyUserNickname ?? ""),
        style: TextStyle(
            color: KColors.wxTextBlueColor,
            fontSize: 14.px,
            fontWeight: FontWeight.w600),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            ///回复评论
            headerClick(comment?.replyUserId ?? "");
          },
      ));
    }

    return listView;
  }

  ///-------------------------------遮罩部分------------------------------
  // 显示遮罩
  void _onShowMenu({Function()? onTap}) {
    _shadeOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0.0,
        right: 0.0,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              // 背景色渐变动画
              AnimatedContainer(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                duration: const Duration(milliseconds: 200),
                color: Colors.transparent,
              ),

              // 点赞菜单
              AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) {
                  return Positioned(
                    left: controller.btnOffset.value.dx -
                        12.px -
                        controller.sizeTween.value,
                    top: controller.btnOffset.value.dy - 10.px,
                    child: SizedBox(
                      width: controller.sizeTween.value,
                      height: 40.px,
                      child: PraiseCommentWidget(
                        onClickPraiseBtn: () async {
                          await Future.delayed(Duration(milliseconds: 310));

                          ///点赞
                          _onLike();
                        },
                        onClickCommentBtn: () async {
                          ///发表评论
                          controller.commenttype = COMMENTTYPE.common;

                          /// 关闭菜单
                          _onCloseMenu(-1);
                          await Future.delayed(Duration(milliseconds: 300));

                          ///显示键盘
                          _onSwitchCommentBar();
                        },
                      ).buildIsLikeMenu(controller.model?.value),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    _overlayState?.insert(_shadeOverlayEntry!);

    // 延迟显示菜单
    Future.delayed(const Duration(milliseconds: 100), () {
      if (controller.animationController.status == AnimationStatus.dismissed) {
        controller.animationController.forward();
      }
    });
  }

  /// 关闭 like 菜单
  Future<void> _onCloseMenu(int? type) async {
    if (controller.animationController.status == AnimationStatus.completed) {
      if (type != null && type == 0) {
        controller.model.value.isLike =
            controller.model?.value.isLike == 1 ? 0 : 1;
      }
      await controller.animationController.reverse();
      // if (type != null && type == 0){
      //   controller.model.value.isLike = controller.model?.value.isLike == 1 ? 0 : 1;
      // }
      _shadeOverlayEntry?.remove();
      _shadeOverlayEntry?.dispose();
    }
  }

  ///点击头像
  headerClick(String? userid) {
    BoostNavigator.instance.push("mine", arguments: {
      "accId": userid ?? "",
    });
  }

  /// 点赞操作
  void _onLike() {
    // 安全检查
    if (controller.model?.value == null) return;

    ///设置点赞列表
    if (controller.model?.value.isLike == 1) {
      ///取消点赞
      controller.delteLikeData();
    } else {
      ///没点赞了
      controller.saveLikeData();
    }

    // 关闭菜单
    _onCloseMenu(0);
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
      String content = value;
      if (content.length > 0) {
        _onComment(content);
      }
    });
  }

  /// 评论操作
  void _onComment(String text) {
    // 安全检查
    if (controller.model?.value == null) return;

    ///发送接口
    controller.saveCommentData(text);
  }

  ///页面消失
  @override
  void onPageHide() {
    SameUser.modelMap = {"back": controller.model.value.toJson()};
    _onCloseMenu(-1);
    super.onPageHide();
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

  ///获取评论的圆角
  getCommentRadius(CircleCommentModel? commentModel, int commentIndex) {
    bool haveLike = (controller.model?.value.likeList?.length ?? 0) > 0;
    bool lastComment = (controller.model?.value.commentList?.length ?? 0) ==
        (commentIndex + 1);

    ///第一行，也是最后一行
    if (!haveLike && lastComment) {
      return BorderRadius.circular(3.px);
    } else if (!haveLike) {
      return BorderRadius.only(
          topLeft: Radius.circular(3.px), topRight: Radius.circular(3.px));
    } else if (lastComment) {
      return BorderRadius.only(
          bottomLeft: Radius.circular(3.px),
          bottomRight: Radius.circular(3.px));
    } else {
      return null;
    }
  }
}
