///  wx_friends_circle_cell.dart
///
///  Created by iotjin on 2020/09/14.
///  description: 朋友圈 cell


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:tiens_im_flutter/common/utils/size_fit.dart';
import 'package:tiens_im_flutter/common/utils/toast_util.dart';
import 'package:tiens_im_flutter/common/utils/user_info.dart';
import 'package:tiens_im_flutter/common/utils/utils.dart';
import 'package:tiens_im_flutter/pages/wx_zone/entity/circle_comment_model.dart';
import 'package:tiens_im_flutter/pages/wx_zone/entity/circle_praises_model.dart';
import 'package:tiens_im_flutter/pages/wx_zone/entity/userHeaderNameModel.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/ImageUtil.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/same_user.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/time_util.dart';
import '../../square/views/report_page.dart';
import '../config/colors.dart';
import '../entity/wx_friends_circle_model.dart';
import '../until/jh_color_utils.dart';
import '../until/jh_string_utils.dart';
import 'jh_bottom_sheet.dart';
import 'jh_nine_picture.dart';

class WxFriendsCircleCell extends StatefulWidget {
  final WxFriendsCircleModel model;

  ///点击整个cell
  final Function(dynamic model)? onClickCell;

  ///点击头像
  final Function(String userid)? onClickHeadPortrait;
  final Function(dynamic model)? onClickDeleteBtn;
  final Function(dynamic model)? onClickMoreBtn;
  final Function(WxFriendsCircleModel model)? onClickReportBtn;
  final Function(WxFriendsCircleModel model)? onClickReportShowBtn;
  final Function(dynamic currentCirlModel, dynamic commentModel)?
      onDeleteCommentBtn;
  final Function(dynamic model, Offset offset)? onClickComment;

  ///type=0是点击评论者， type=1点击被评论者
  final Function(dynamic model, int type)? onBackComment;

  // const WxFriendsCircleCell({super.key});
  const WxFriendsCircleCell({
    Key? key,
    this.onClickCell,
    this.onClickHeadPortrait,
    this.onClickDeleteBtn,
    this.onClickComment,
    required this.model,
    this.onBackComment,
    this.onClickMoreBtn,
    this.onDeleteCommentBtn,
    this.onClickReportBtn,
    this.onClickReportShowBtn,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return WxFriendsCircleCellState();
  }
}

///显示评论点赞
bool havePraise = false;

class WxFriendsCircleCellState extends State<WxFriendsCircleCell> {
  ///获取位置
  GlobalKey keyy = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return _cell(context);
  }

  _cell(context) {
    ///获取用户

    return InkWell(
      onTap: () => widget.onClickCell?.call(widget.model),
      child: Container(
        ///装饰器
        decoration: BoxDecoration(
          color: Colors.white,
          // border: Border.all(color: KColors.kLineColor, width: 1),
          border: Border(
            bottom: BorderSide(
              width: 0.5,
              color: KColors.commentPraiseLineColor,
            ), // 下边框
          ),
        ),
        child: Row(
          ///水平排列
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 头像
            InkWell(
              onTap: () => widget.onClickHeadPortrait
                  ?.call(widget.model.publisherId ?? ""),
              child: Container(
                margin: EdgeInsets.all(11.px),
                height: 42.px,
                width: 42.px,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.px),
                ),
                child: CachedNetworkImage(
                    imageUrl: widget.model?.headImg ?? "",
                    imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.cover),
                          ),
                        ),
                    placeholder: (context, url) => ImageUtil.placeholderImage(),
                    //CircularProgressIndicator(),
                    errorWidget: (context, url, error) {
                      return ImageUtil.placeholderImage();
                    }),
              ),
            ),

            ///占满剩余空间，多个可以比例分割空间
            Expanded(
              child: Stack(
                children:[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ///名字
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => widget.onClickHeadPortrait
                                    ?.call(widget.model.publisherId ?? ""),
                                child: Container(
                                  width: 238.px,
                                  margin: EdgeInsets.only(top: 8.px),
                                  child: Text(
                                    maxLines:1,
                                    overflow: TextOverflow.ellipsis,
                                    widget.model.nickname ?? "",
                                    style: TextStyle(
                                        color: KColors.wxTextBlueColor,
                                        fontSize: 16.px,
                                        fontWeight: FontWeight.w600),
                                  ), //ImageUtil.getNameView(widget.model.publisherId ?? "")
                                ),
                              ),
                            ),
                            SizedBox(
                              width:(widget.model.publisherId ?? "") == SameUser.getUserID() ? 48.px : 16,
                            ),
                            ///举报按钮
                            InkWell(
                                child: Offstage(
                                  offstage: (widget.model.publisherId ?? "") == SameUser.getUserID(),
                                  child: Container(
                                    margin: EdgeInsets.only(top:5.px, right: 9.px),
                                    width: 32.px,
                                    height: 20.px,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3.px),
                                      color: KColors.kBackGreyColor,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 9.px,
                                        height: 5.5.px,
                                        child: Image.asset(
                                          'assets/images/wxzone/jubao.png',
                                          color: KColors.wxTextBlueColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                    widget.model.showFlag = widget.model.showFlag == true ? false : true;
                                  widget.onClickReportShowBtn?.call(widget.model);
                                })

                          ]
                      ),


                      ///内容
                      Offstage(
                        offstage:  widget.model.contentText.jhNullSafe.length <= 0,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 5.px, 15.px, 5.px),
                          child: LayoutBuilder(builder: (context, size) {

                            String str = widget.model.contentText.jhNullSafe;
                            bool out = TimeUtil.outOrNoWith(str, size.maxWidth, 4);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  str,
                                  style: TextStyle(fontSize: 16.px),
                                  maxLines: 4,
                                  // overflow: TextOverflow.ellipsis,
                                ),
                                Offstage(
                                  offstage: !out,
                                  child: Container(
                                    margin: EdgeInsets.fromLTRB(0, 10.px, 0, 8.px),
                                    child: Text(
                                      "moment_moments_00034".tl,
                                      style: TextStyle(
                                        fontSize: 16.px,
                                        color: KColors.wxTextBlueColor,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            );
                          }),
                        ),
                      ),

                      ///九宫格
                      SizedBox(height:widget.model.contentText.jhNullSafe.length <= 0 ? 7.px : 5.px),
                      _imagesWidget(context),

                      ///时间等
                      Container(
                        height: 47.px,
                        margin: EdgeInsets.fromLTRB(0, 0.px, 8.px, 0.px),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ///时间
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  TimeUtil.dateTimeFormat(
                                      widget.model.createTime.jhNullSafe),
                                  style: TextStyle(
                                      color: KColors.wxTextGrayColor,
                                      fontSize: 14.px),
                                ),
                                // SizedBox(
                                //   width: 8.px,
                                // ),
                                Offstage(
                                  offstage: !(SameUser.isSame(
                                      widget.model.publisherId ?? "")),
                                  child: InkWell(

                                    ///删除朋友圈
                                      onTap: () {
                                        widget.onClickDeleteBtn?.call(widget.model);
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
                                child: Container(
                                  width: 80.px,
                                  child: Container(
                                    margin: EdgeInsets.only(top: 13.px,bottom: 13.px, right: 0, left: 48.px),
                                    width: 32.px,
                                    height: 20.px,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3.px),
                                      color: KColors.kBackGreyColor,
                                    ),
                                    child: Image.asset(
                                      key: keyy,
                                      'assets/images/wxzone/ic_diandian.png',
                                      color: KColors.wxTextBlueColor,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  /// 获取组件屏幕位置
                                  var offset = _getOffset(keyy);

                                  ///弹出评论点赞窗口
                                  widget.onClickComment?.call(widget.model, offset);
                                })
                          ],
                        ),
                      ),

                      ///点赞评论
                      getPraiseAndCommentView()
                    ],
                  ),

                  Positioned(
                    right: 10.px,
                    top: 38.px,
                    width: TimeUtil.textWidth("moment_square_00062".tl, 16.px) + 40.px,
                    height: 30.px,
                    child:Offstage(
                      offstage: !(widget.model.showFlag ?? false),
                      child: InkWell(
                        onTap: (){
                          ///隐藏
                          setState(() {
                            widget.model.showFlag = false;
                          });

                          ///举报回调
                          widget.onClickReportBtn?.call(widget.model);
                          //
                          // ///保存ID
                          // SameUser.reportContentId(widget.model.contentId.toString());
                          // ///提示
                          // ToastUtil.showNotClickText(text: "moment_square_00060".tl,showTime: 2);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3.px),
                            color: KColors.kBackGreyColor,
                          ),
                          child: Center(
                            child: Text(
                              "moment_square_00062".tl,
                              style: TextStyle(fontSize: 16.px, color: KColors.wxTextBlueColor),
                            ),
                          )
                        ),
                      ),
                    )
                  )
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///九宫格图片view
  Widget _imagesWidget(context) {
    return JhNinePicture(
      withContainer: true,
      model: widget.model,
      lRSpace: (80.0 + 20.0),
      onLongPress: (int index, dynamic imgArr) {
        JhBottomSheet.showText(context, dataArr: ['保存图片']);
      },
    );
  }

  ///评论点赞列表
  Widget getPraiseAndCommentView() {
    return Offstage(
      offstage: widget.model.getNum() <= 0,
      child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.px),
            color: KColors.kBackGreyColor,
          ),
          margin: EdgeInsets.fromLTRB(0, 5.rpx, 8.px, 11.px),
          child: ListView.builder(

              ///全部展示内容
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),

              ///判断是否等于20条评论
              itemCount: (widget.model.commentList?.length ?? 0) >= 20
                  ? widget.model.getNum() + 1
                  : widget.model.getNum(),
              itemBuilder: (BuildContext context, int index) {
                ///点赞
                if (index == 0 && (widget.model.likeList?.length ?? 0) > 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        clipBehavior: Clip.hardEdge,
                        constraints: BoxConstraints(
                          minHeight: 68.rpx,
                        ),
                        decoration: containerBottomLine(0),
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 10.px,
                              top: 8.px,
                              right: 5.px,
                              bottom: 5.px),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                WidgetSpan(
                                    // alignment: PlaceholderAlignment.middle,
                                    child: Container(
                                  height: 30.rpx,
                                  width: 30.rpx,
                                  child: Image.asset(
                                      "assets/images/wxzone/like.png",
                                      fit: BoxFit.cover),
                                )),
                                TextSpan(
                                  children: getPraiseStr(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Offstage(
                        offstage: (widget.model.commentList?.length ?? 0) <= 0,
                        child: Container(
                          height: 0.5.px,
                          color: KColors.commentPraiseLineColor,
                        ),
                      )
                    ],
                  );
                }

                ///cell
                if (index != widget.model.getNum()) {
                  ///评论
                  return InkWell(
                    onTap: (){

                      ///没有点赞从0开始
                      int numIndex =
                      (widget.model?.likeList?.length ?? 0) > 0 ? (index - 1) : index;
                      CircleCommentModel? comment = widget.model?.commentList?[numIndex];
                      ///判断本人
                      if (SameUser.isSame(comment?.userId ?? "")) {
                        widget.onDeleteCommentBtn?.call(widget.model, comment);
                      } else {
                        ///type=0是点击评论者， type=1点击被评论者
                        widget.onBackComment?.call(comment, 0);
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 10.px, right: 8.px),
                      constraints: BoxConstraints(
                        minHeight: 50.rpx,
                      ),
                      alignment: Alignment.centerLeft,

                      ///装饰器
                      decoration:containerBottomLine(0),
                      child: RichText(
                        text: TextSpan(children: getOneComment(index)),
                      ),
                    ),
                  );
                }

                ///最后一行
                if (index == widget.model.getNum()) {
                  return Container(
                    constraints: BoxConstraints(
                      minHeight: 70.rpx,
                    ),
                    alignment: Alignment.centerRight,

                    ///装饰器
                    decoration: containerBottomLine(1),
                    child: InkWell(
                        onTap: () {
                          ///点击了展开获取更多
                          widget.onClickMoreBtn?.call(widget.model);
                        },
                        child: Container(
                            margin:
                                EdgeInsets.only(bottom: 16.rpx, right: 30.rpx),
                            width: 64.rpx,
                            height: 40.rpx,
                            decoration: BoxDecoration(
                                color: KColors.kBtnBackGreyColor,
                                borderRadius: BorderRadius.circular(6.rpx)),
                            child: Center(
                              child: Container(
                                height: 18.rpx,
                                width: 18.rpx,
                                child: Image.asset(
                                  "assets/images/wxzone/circleMore.png",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ))),
                  );
                }
              })),
    );
  }

  ///获取点赞字符串
  List<InlineSpan> getPraiseStr() {
    List<InlineSpan> listView = [];

    List<Praises> praises = widget.model.likeList ?? [];
    String str = " ";
    praises.forEach((element, {index}) {
      int index = praises.indexOf(element);
      listView.add(TextSpan(
        text: index == 0
            ? (" " + (element?.nickname ?? ""))
            : (", " + (element?.nickname ?? "")),
        style: TextStyle(color: KColors.wxTextBlueColor, fontSize: 28.rpx),
        recognizer: TapGestureRecognizer()
          ..onTap =
              () => widget.onClickHeadPortrait?.call(element.userId ?? ""),
      ));
    });

    return listView;
  }

  ///获取一条评论了
  List<InlineSpan> getOneComment(int index) {
    ///没有点赞从0kai
    int numIndex =
        (widget.model?.likeList?.length ?? 0) > 0 ? (index - 1) : index;
    CircleCommentModel? comment = widget.model?.commentList?[numIndex];

    List<InlineSpan> listView = [];

    ///评论者
    listView.add(
      TextSpan(
        text: (comment?.userNickname ?? ""),
        style: TextStyle(
            color: KColors.wxTextBlueColor,
            fontSize: 28.rpx,
            fontWeight: FontWeight.w600),
        recognizer: TapGestureRecognizer()
          ..onTap =
              () => widget.onClickHeadPortrait?.call(comment?.userId ?? ""),
      ),
    );

    ///存在被评论者
    int haveToName = comment?.replyUserNickname?.length ?? 0;
    if (haveToName > 0) {
      listView.add(TextSpan(
          text: "moment_moments_00014".tl,
          style: TextStyle(
              color: Colors.black,
              fontSize: 28.rpx)));
      listView.add(TextSpan(
        text: (comment?.replyUserNickname ?? "") + ": ",
        style: TextStyle(
            color: KColors.wxTextBlueColor,
            fontSize: 28.rpx,
            fontWeight: FontWeight.w600),
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              widget.onClickHeadPortrait?.call(comment?.replyUserId ?? ""),
      ));
    } else {
      listView.add(TextSpan(
          text: ": ",
          style: TextStyle(
              color: Colors.black,
              fontSize: 28.rpx,
              fontWeight: FontWeight.w600)));
    }
    listView.add(
      TextSpan(
          text: (comment?.content ?? ""),
          style: TextStyle(color: Colors.black, fontSize: 28.rpx),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              ///判断本人
              if (SameUser.isSame(comment?.userId ?? "")) {
                widget.onDeleteCommentBtn?.call(widget.model, comment);
              } else {
                ///type=0是点击评论者， type=1点击被评论者
                widget.onBackComment?.call(comment, 0);
              }
            }),
    );

    return listView;
  }

  /// 获取组件屏幕位置 offset
  Offset _getOffset(GlobalKey key) {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    final Offset offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    return offset;
  }
}

///Container创建下划线
BoxDecoration containerBottomLine(int index) {
  return BoxDecoration(
    color: KColors.kBackGreyColor,
  );
}
