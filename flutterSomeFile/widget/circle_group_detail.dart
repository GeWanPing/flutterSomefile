import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:tiens_im_flutter/common/utils/language/translation.dart';
import 'package:tiens_im_flutter/common/utils/logger.dart';
import 'package:tiens_im_flutter/pages/circle_group/controller/circle_group_detail_controller.dart';
import 'package:tiens_im_flutter/pages/circle_group/entity/server_model_id.dart';
import 'package:tiens_im_flutter/pages/circle_group/views/top_title_widget.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/ImageUtil.dart';
import 'package:tiens_im_flutter/pages/wx_zone/until/same_user.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../common/utils/dio/loading_utils.dart';
import '../../../common/utils/native_message_manager.dart';
import '../../../common/utils/size_fit.dart';
import '../../../common/utils/toast_util.dart';
import '../../../common/utils/user_info.dart';
import '../../../common/values/native_jump.dart';
import '../../post_moments/utils/picker_text_locale_delegate.dart';
import '../../square/views/report_page.dart';
import '../../wx_zone/config/colors.dart';
import '../../wx_zone/until/jh_screen_utils.dart';
import '../../wx_zone/widgets/jh_bottom_sheet.dart';
import '../../wx_zone/widgets/jh_photo_browser.dart';
import '../entity/circle_group_detail.dart';
import '../entity/server_member_model.dart';
import 'empty.dart';

enum MEMBERTYPE { main, manager, member }

class CircleGroupDetail extends StatefulWidget {
  const CircleGroupDetail({super.key, this.arguments});

  final Object? arguments;

  @override
  State<CircleGroupDetail> createState() => CircleGroupDetailState();
}

class CircleGroupDetailState extends State<CircleGroupDetail>
    with PageVisibilityObserver {
  ///getX绑定数据
  late CircleGroupDetailController controller;

  ///头像
  // File _file;

  @override
  void initState() {
    super.initState();

    ///创建controller
    controller = Get.put(CircleGroupDetailController(),
        tag: "${widget.arguments?.toString()}${UserInfo().accid}",
        permanent: true);

    controller.serverModelId =
        ServerModelId.fromJson(widget.arguments as Map<String, dynamic>);
    controller.netWorkResult = true;
  }

  @override
  void onPageShow() {
    // TODO: implement onPageShow
    super.onPageShow();
    controller.getServerRoleInfo();

    ///获取详情
    controller.getCircleData();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleGroupDetailController>(
      init: controller,
      global: false,
      builder: (controller) {
        return Scaffold(
          appBar: controller.netWorkResult == false
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: ImageIcon(const AssetImage(
                        'assets/images/wxzone/ic_nav_back_white.png')),
                    iconSize: 18,
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    onPressed: () {
                      BoostNavigator.instance.pop();
                    },
                  ),
                )
              : null,
          extendBodyBehindAppBar: true,
          body: controller.netWorkResult == true
              ? MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView(
                    children: [
                      headerView(),
                      membersView(),
                      circleGroupMessage(),
                      circleGroupManager(),
                      otherSetting()
                    ],
                  ),
                )
              : InkWell(
                  child: CircleEmpty(
                      "moment_qchat_00080".tl,
                      (MediaQuery.of(context).size.height -
                              150.px -
                              JhScreenUtils.navigationBarHeight) *
                          0.5),
                  onTap: () {
                    controller.getCircleData();
                  },
                ),
        );
      },
    );
  }

  ///头像
  Widget headerView() {
    double headHeight = 220.px;
    double nameHeiht = 73.px;
    return Container(
      height: headHeight,
      child: Stack(
        children: [
          Column(
            children: [
              Image(
                image:
                    AssetImage("assets/images/circleGroup/detailTopBack.png"),
                height: headHeight - nameHeiht,
                width: TSSizeFit.screenWidth,
                fit: BoxFit.cover,
              ),
              Container(
                color: Colors.white,
                height: nameHeiht,
              )
            ],
          ),
          Positioned(
            left: 12.px,
            bottom: 127.px,
            child: IconButton(
              icon: ImageIcon(
                  const AssetImage(
                      'assets/images/circleGroup/circleGroupDetailBack.png'),),
              iconSize: 18.px,
              padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
              onPressed: () {
                BoostNavigator.instance.pop();
              },
            ),
          ),
          Positioned(
              left: 14.px,
              bottom: 25.px,
              child: Row(
                children: [
                  Container(
                    width: 80.px,
                    height: 80.px,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.px),
                      border:Border.all(color: KColors.GRAY_ICON_LINE, width: 1.5.px),
                    ),
                    child: InkWell(
                      onTap: () {
                        ///有权限修改
                        if (controller.canModifyServerInfo == true) {
                          onTapPickFromGallery(context);
                        } else {
                          ///展示头像放大
                          JhPhotoBrowser.show(context,
                              data: [
                                controller.circleGroupDetail.value.icon ??
                                    "assets/images/wxzone/placeHolder.png"
                              ],
                              index: 0,
                              onLongPress: null,
                              isHiddenClose: true,
                              withContainer: false);
                        }
                      },
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23.px),
                        ),
                        child: ImageUtil.getHeadNetWorkImage(
                            controller.circleGroupDetail.value.icon ?? "",
                           80.px,
                            80.px),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 12.5.px,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 41.px,
                      ),
                      Container(
                        width: 232.px,
                        child: Text(
                          maxLines:1,
                          overflow: TextOverflow.ellipsis,
                          controller.circleGroupDetail.value.name ?? "",
                          style: TextStyle(fontSize: 16.px, color: Colors.black),
                        ),
                      ),
                      SizedBox(
                        height: 4.px,
                      ),
                      RightImageTextWidget(
                          fontSize: 12.px,
                          title:
                              "ID：${controller.circleGroupDetail.value.serverId ?? ""}   ",
                          localImage: "assets/images/circleGroup/copyid.png",
                          imageClick: () {
                            //复制
                            Clipboard.setData(ClipboardData(
                                text: (controller
                                        .circleGroupDetail.value.serverId
                                        ?.toString() ??
                                    "")));
                            ToastUtil.showNotClickText(text: "moment_qchat_00059".tl);
                          }),
                    ],
                  )
                ],
              )),
          Positioned(
              bottom: 0.px, left: 0.px, right: 0.px, child: BottomGrayLine())
        ],
      ),
    );
  }

  ///成员
  membersView() {
    return Container(
      height: 152.px,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopClickWidget(
            haveRight: true,
            title:
               "moment_qchat_00060".tlParams({"****":"${getNum(controller.circleGroupDetail.value.memberNumber ?? 0)}"}),
            click: () {
              BoostNavigator.instance
                  .push("ServerMemberList", withContainer: true, arguments: {
                "serverId": controller.serverModelId.serviedId,
                "channelId": controller.serverModelId.channelId
              });
            },
          ),
          Container(
            padding: EdgeInsets.only(left: 12.px),
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 9.px,
              runSpacing: 10.px,
              children: controller.resultList.take(4).map(
                (e) {
                  return customAvatar(e);
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
  String getNum(int members){
    int num = members;
    if(num < 1000){
      return num.toString();
    }else{
      double newNum = (num / 1000);
      return formatNum(newNum, 1) + "K";
    }
  }

  String formatNum(double num, int location) {
    if ((num.toString().length - num.toString().lastIndexOf(".") - 1) <
        location) {
      //小数点后有几位小数
      return num.toStringAsFixed(location)
          .substring(0, num.toString().lastIndexOf(".") + location + 1)
          .toString();
    } else {
      return num.toString()
          .substring(0, num.toString().lastIndexOf(".") + location + 1)
          .toString();
    }
  }

  ///一个成员头像
  Widget customAvatar(ServerMemberModel model) {
    double avatarHeight = 47.px;

    return InkWell(
      onTap: () {
        SameUser.circleMemberCardFlutter = true;
        BoostNavigator.instance.push("QChatUserInfo1",
            withContainer: false,
            opaque: true,
            arguments: {
              "accId": model.accid,
              "flutterFlag": 1,
              "serverId": model.serverId,
              "isPresent": false,
              "isAnimated": false
            });
      },
      child: Container(
        height: 90.px,
        width: 70.px,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.px),
          color: KColors.AVARTAR_BACK,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 7.5.px,
              right: 7.5.px,
              child: Offstage(
                offstage: model.custom != "-1",
                child: Image(
                  image: AssetImage("assets/images/circleGroup/groupmain.png"),
                  height: 26.px,
                  width: 26.px,
                ),
              ),
            ),
            Center(
              child: Container(
                width: 48.px,
                height: 48.px,
                decoration: BoxDecoration(
                  border: Border.all(color: KColors.GRAY_ICON_LINE,width: 1.5.px),
                  borderRadius: BorderRadius.circular(24.px)
                ),
                child: ClipOval(
                    // borderRadius: BorderRadius.circular(24.px),
                    child: ImageUtil.getHeadNetWorkImage(
                        model.avatar ?? "", avatarHeight, avatarHeight)),
              ),
            ),
            Positioned(
              bottom: 13.px,
              right: 9.px,
              child: Offstage(
                offstage: model.custom != "2",
                child: Image(
                  image:
                      AssetImage("assets/images/circleGroup/groupManager.png"),
                  height: 23.px,
                  width: 23.px,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///圈组信息
  Widget circleGroupMessage() {
    return Column(
      children: [
        TopTitleWidget(title: "moment_qchat_00061".tl),
        SizedBox(
          height: 5.px,
        ),
        TopClickWidget(
          haveRight: controller.canModifyServerInfo == true,
          title: "moment_qchat_00037".tl,
          click: () {
            if (controller.canModifyServerInfo == true) {
              BoostNavigator.instance.push("CircleGroupNameChange", arguments: {
                "serverId": controller.circleGroupDetail.value.serverId ?? "",
                "name": controller.circleGroupDetail.value.name ?? ""
              }).then((value) {
                if (value is Map && value["name"] != null) {
                  CircleGroupDetailModel circleDetail =
                      CircleGroupDetailModel.fromJson(
                          controller.circleGroupDetail.value.toJson());
                  circleDetail.name = value["name"];
                  controller.circleGroupDetail.value = circleDetail;
                  controller.update();
                }
              });
            }
          },
        ),
        DetailGrayText(
          fontSize: 14.px,
          detail: controller.circleGroupDetail.value.name ?? "",
        ),
        SizedBox(
          height: 21.px,
        ),
        BottomGrayLine(),
        TopClickWidget(
          haveRight: controller.canModifyServerInfo == true,
          title: "moment_qchat_00041".tl,
          click: () {
            if (controller.canModifyServerInfo == true) {
              BoostNavigator.instance
                  .push("CircleGroupProfileChange", arguments: {
                "serverId": controller.circleGroupDetail.value.serverId ?? "",
                "profile":
                    controller.circleGroupDetail.value.groupIntroduction ?? ""
              }).then(
                (value) {
                  if (value is Map && value["profile"] != null) {
                    CircleGroupDetailModel circleDetail =
                        CircleGroupDetailModel.fromJson(
                            controller.circleGroupDetail.value.toJson());
                    circleDetail.groupIntroduction = value["profile"];
                    controller.circleGroupDetail.value = circleDetail;
                    controller.update();
                  }
                },
              );
            }
          },
        ),
        DetailGrayText(
          fontSize: 14.px,
          detail: ((controller.circleGroupDetail.value.groupIntroduction?.length ?? 0) > 0 ? (controller.circleGroupDetail.value.groupIntroduction ?? "") :  "moment_qchat_00092".tl),
        ),
        SizedBox(
          height: 19.px,
        ),
        BottomGrayLine(),
        TopClickWidget(
          haveRight: controller.canModifyServerInfo == true,
          title: "moment_qchat_00062".tl,
          click: () {
            if (controller.canModifyServerInfo == true) {
              BoostNavigator.instance
                  .push("QchatCreatServerLablePage", arguments: {
                "selectedTag": controller.circleGroupDetail.value.tagList ?? [],
                "serverId": controller.serverModelId.serviedId,
                "serverName": "",
                "serverAvatar": "",
                "intro": "",
                "flag": 3
              });
            }
          },
        ),
        DetailGrayText(
          fontSize: 11.px,
          detail: getTags(),
        ),
      ],
    );
  }

  String getTags() {
    String result = "";
    String tags = controller.circleGroupDetail.value.customTags ?? "";
    if (tags.contains("]") || tags.contains("[")) {
      tags = tags.replaceAll("]", "");
      tags = tags.replaceAll("[", "");
    }
    if (tags.contains("]") || tags.contains("[")) {
      tags = tags.replaceAll("]", "");
      tags = tags.replaceAll("[", "");
    }
    if (tags.contains("\"")) {
      tags = tags.replaceAll("\"", "");
    }

    if (tags.contains(",") && tags.length > 0) {
      List<String> list = tags.split(",");

      ///传给标签页用
      controller.circleGroupDetail.value.tagList = list;
      list.forEach((element) {
        String oneStr = "#${element.trim().tl}";
        result = result + oneStr + " ";
      });
    } else {
      controller.circleGroupDetail.value.tagList = [tags];
      if (tags.length > 0) {
        tags = tags.trim();
        result = "#${tags.tl}";
      }
    }

    if (result.length == 0){
      result = "moment_qchat_00092".tl;
    }
    return result;
  }

  ///圈组管理
  Widget circleGroupManager() {
    return Offstage(
      offstage:
          SameUser.getUserID() != controller.circleGroupDetail.value.owner,
      child: Column(
        children: [
          SizedBox(
            height: 19.5.px,
          ),
          TopTitleWidget(title: "moment_qchat_00063".tl),
          SizedBox(
            height: 5.px,
          ),
          TopClickWidget(
            haveRight: true,
            title: "moment_qchat_00064".tl,
            click: () {
              var ownerRoleInfo = controller.ownerRoleInfo;
              if (ownerRoleInfo != null) {
                BoostNavigator.instance
                    .push("QChatAuth", withContainer: false, arguments: {
                  "type": ownerRoleInfo.type,
                  "serverId": ownerRoleInfo.serverId,
                  "roleId": ownerRoleInfo.roleId,
                });
              }
            },
          ),
          SizedBox(
            height: 5.px,
          ),
          BottomGrayLine(),
          SizedBox(
            height: 5.px,
          ),
          TopClickWidget(
            haveRight: true,
            title: "moment_qchat_00052".tl,
            click: () {
              var managerRoleInfo = controller.managerRoleInfo;
              if (managerRoleInfo != null) {
                BoostNavigator.instance
                    .push("QChatAuth", withContainer: false, arguments: {
                  "type": managerRoleInfo.type,
                  "serverId": managerRoleInfo.serverId,
                  "roleId": managerRoleInfo.roleId,
                });
              }
            },
          ),
          SizedBox(
            height: 5.px,
          ),
          BottomGrayLine(),
          SizedBox(
            height: 5.px,
          ),
          TopClickWidget(
            haveRight: true,
            title: "moment_qchat_00065".tl,
            click: () {
              BoostNavigator.instance
                  .push("CircleGroupWellComeChange", arguments: {
                "serverId": controller.circleGroupDetail.value.serverId ?? "",
                "welcome":
                    controller.circleGroupDetail.value.welcomeMessage ?? ""
              }).then((value) {
                if (value is Map && value["welcome"] != null) {
                  CircleGroupDetailModel circleDetail =
                      CircleGroupDetailModel.fromJson(
                          controller.circleGroupDetail.value.toJson());
                  circleDetail.welcomeMessage = value["welcome"];
                  controller.circleGroupDetail.value = circleDetail;
                  controller.update();
                }
              });
            },
          ),
          DetailGrayText(
            fontSize: 14.px,
            detail: ((controller.circleGroupDetail.value.welcomeMessage?.length ?? 0) > 0 ? (controller.circleGroupDetail.value.welcomeMessage ?? "") :  "moment_qchat_00091".tl),
          ),
        ],
      ),
    );
  }

  ///其他设置
  Widget otherSetting() {
    return Column(
      children: [
        SizedBox(
          height: 19.5.px,
        ),
        TopTitleWidget(title: "moment_qchat_00066".tl),
        SizedBox(
          height: 5.px,
        ),
        TopClickWidget(
          haveRight: false,
          title: "moment_qchat_00067".tl,
          click: () {
            ///跳到举报页面
            BoostNavigator.instance.push(ReportPage.routerName,
                withContainer: true, arguments: {"contentId": "1", "type": 1});
          },
        ),
        SizedBox(
          height: 5.px,
        ),
        BottomGrayLine(),
        SizedBox(
          height: 20.px,
        ),
        BtnTool.buildMaterialButton(
          height: 50.px,
          width: MediaQuery.of(context).size.width - 30.px,
          child: Text(
            "moment_qchat_00068".tl,
            style: TextStyle(fontSize: 16.px, color: Colors.black),
          ),
          backColor: Colors.white,
          lineColor: KColors.GRAY_TEXT,
          lineWidth: 1.px,
          click: () {
            ///群主
            String alertStr = "moment_qchat_00071".tl;
            if (SameUser.getUserID() ==
                controller.circleGroupDetail.value.owner) {
              alertStr = "moment_qchat_00072".tl;
            }

            JhBottomSheet.showText(context, dataArr: [alertStr],
                clickCallback: (int selectIndex, String selectText) {
              if (selectIndex == 1) {
                ///点击了删除弹出删除框
                controller.outCircleGroup();
              }
            });
          },
        ),
        SizedBox(
          height: 25.px,
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    logger.d("didChangeDependencies");

    ///注册监听器
    PageVisibilityBinding.instance
        .addObserver(this, ModalRoute.of(context) as Route);
  }

  @override
  void dispose() {
    ///移除监听器
    logger.d("dispose");
    PageVisibilityBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> onTapPickFromGallery(BuildContext context) async {
    try {
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          selectedAssets: [],
          textDelegate: AssetPickerAllTextDelegate(),
          requestType: RequestType.image,
          maxAssets: 1,
          locale: Get.locale,
          pathNameBuilder: null,
        ),
      );
      if (assets != null &&
          assets.isNotEmpty &&
          assets.first.type == AssetType.image) {
        var _file = await assets.first.file;
        debugPrint("文件路径${_file?.path}");
        _cropImage(_file);
      }
    } catch (e) {
      debugPrint(e.toString());
      ToastUtil.showText(text: "moment_comm_00074".tl);
    }
  }

  Future<void> _cropImage(var _file) async {
    if (_file != null) {
      String? path = _file?.path;
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path!,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        cropStyle: CropStyle.rectangle,
        maxWidth: 256,
        maxHeight: 256,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: '',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              hideBottomControls: true,
              lockAspectRatio: true),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
            showActivitySheetOnDone: false,
            showCancelConfirmationDialog: false,
            rotateClockwiseButtonHidden: true,
            hidesNavigationBar: true,
            rotateButtonsHidden: true,
            resetButtonHidden: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            aspectRatioLockDimensionSwapEnabled: true,
            aspectRatioLockEnabled: true,
            title: '',
            doneButtonTitle: "moment_login_00072".tl,
            cancelButtonTitle: "moment_login_00056".tl,
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort:
                const CroppieViewPort(width: 480, height: 480, type: 'square'),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );
      if (croppedFile != null) {
        debugPrint("------------------->:${croppedFile.path}");

        // if (widget.avatarCallBack != null) {
        print("裁剪回调：${croppedFile.path}");
        _uploadImage(croppedFile.path);
      }
    } else {
      debugPrint("------------------->:裁剪失败");
      ToastUtil.showText(text: "获取裁剪的图片为空");
    }
  }

  void _uploadImage(String path) async {
    debugPrint(path);
    LoadingUtils.getInstance.toast();
    try {
      final arg = {"imagePath": path};
      Map<Object?, Object?> result = await NativeMessageManager
          .getInstance.channel
          .invokeMethod(NativeJump.qchatUploadImage, arg);
      LoadingUtils.getInstance.dismiss();
      debugPrint("上传图片回调:${result}");
      dynamic errorMsg = result["errorMsg"];
      dynamic uploadURLStr = result["uploadURLStr"];

      if (errorMsg == null && (uploadURLStr is String)) {
        debugPrint("上传成功:${uploadURLStr}");

        ///上传头像
        controller.changeCircleGroupName(
            controller.circleGroupDetail.value.serverId, null, uploadURLStr);
      } else {
        debugPrint("上传失败:${errorMsg}");
        ToastUtil.showText(text: "moment_qchat_00034".tl);
      }
    } catch (e) {
      LoadingUtils.getInstance.dismiss();
      ToastUtil.showText(text: "moment_qchat_00034".tl);
      return;
    } finally {
      setState(() {});
    }
  }
}
