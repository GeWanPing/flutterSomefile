import 'dart:convert';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:get/get.dart';
import 'package:tiens_im_flutter/common/utils/dio/http_response_data.dart';
import 'package:tiens_im_flutter/common/utils/language/translation.dart';
import 'package:tiens_im_flutter/common/utils/native_qchat_auth.dart';
import 'package:tiens_im_flutter/pages/circle_group/entity/server_model_id.dart';
import 'package:tiens_im_flutter/pages/qchat_auth/controller/ServerRoleInfoBean.dart';
import 'package:tiens_im_flutter/pages/qchat_auth/controller/auth_enum.dart';
import 'package:tiens_im_flutter/pages/qchat_auth/controller/qchat_auth_controller.dart';
import '../../../common/utils/logger.dart';
import '../../../common/utils/dio/http_utils.dart';
import '../../../common/utils/toast_util.dart';
import '../entity/circle_group_detail.dart';
import '../entity/server_member_model.dart';

class CircleGroupDetailController extends GetxController {
  RxInt index = 1.obs;
  bool? canModifyServerInfo = false;

  //服务ID模型
  ServerModelId serverModelId = ServerModelId();

  ///头像列表
  List<ServerMemberModel> resultList = <ServerMemberModel>[];

  ///详情
  Rx<CircleGroupDetailModel> circleGroupDetail = CircleGroupDetailModel().obs;

  ///网络加载判断
  bool? netWorkResult = true;

  ServerRoleInfo? ownerRoleInfo;
  ServerRoleInfo? managerRoleInfo;

  void getCircleData() async {
    var future =
        await Future.wait([checkOneCircleGroup(), getManagerMembers()]);
    showDetailMembers(future[1] as List<ServerMemberModel>);

    ///刷新界面
    update();

    checkCanModifyInfo();
  }

  ///获取圈组详情
  Future<dynamic> checkOneCircleGroup() async {
    if (serverModelId.serviedId == null) {
      return;
    }

    ///请求朋友圈数据
    var httpResponseData = await HttpUtils.getInstance.get(
      "/imchat/circle/group/get/one",
      queryParameters: {
        "serverId": serverModelId.serviedId ?? "",
        "channelId": serverModelId.channelId ?? ""
      },
      isShowHud: true,
    );
    if (httpResponseData.isSuccess) {
      Map<String, dynamic> detailMap = httpResponseData.data;
      circleGroupDetail.value = CircleGroupDetailModel.fromJson(detailMap);

      return Future(() => "");
    } else {
      ///网络错误
      netWorkResult = false;
      ToastUtil.showNotClickText(
          text: (httpResponseData.error?.msg ?? "moment_moments_00029").tl);
      return Future(() => "");
    }
  }

  void showDetailMembers(List<ServerMemberModel> future) {
    if (circleGroupDetail.value.owner == null ||
        circleGroupDetail.value.owner?.isEmpty == true) {
      return;
    }

    ///清空数据
    resultList.clear();

    ///添加群主
    Map<String, dynamic> map = <String, dynamic>{};
    map["serverId"] = num.parse(serverModelId.serviedId ?? "");
    map["roleId"] = num.parse("0");
    map["accid"] = circleGroupDetail.value.owner;
    map["nick"] = circleGroupDetail.value.owner;
    map["avatar"] = circleGroupDetail.value.headImg;
    map["type"] = num.parse("1");
    map["custom"] = "-1";
    resultList.add(ServerMemberModel.fromJson(map));

    resultList.addAll(future
        .where((element) => circleGroupDetail.value.owner != element.accid));

    ///获取管理员和成员
  }

  void outCircleGroup() async {
    HttpResponseData httpResponseData = await HttpUtils.getInstance.post(
      "/imchat/circle/group/exitCircleGroup",
      data: {
        "serverId": circleGroupDetail.value.serverId ?? 0,
        "owner": circleGroupDetail.value.owner ?? "",
      },
      isShowHud: true,
    );
    if (httpResponseData.isSuccess) {
      BoostNavigator.instance
          .pop({"delete": circleGroupDetail.value.serverId ?? ""});
    } else {
      ///网络错误
      ToastUtil.showNotClickText(text: "moment_moments_00029".tl);
    }
  }

  void changeCircleGroupName(
      int? serverId, String? name, String? headImage) async {
    HttpResponseData httpResponseData = await HttpUtils.getInstance.post(
        "/imchat/circle/group/groupModificationName",
        data: {
          "serverId": serverId ?? 0,
          "name": name ?? "",
          "icon": headImage ?? ""
        },
        isShowHud: true);
    if (httpResponseData.isSuccess) {
      if (headImage != null) {
        // CircleGroupDetailModel detail =
        //     CircleGroupDetailModel.fromJson(circleGroupDetail.value.toJson());
        // detail.icon = headImage;
        // circleGroupDetail.value = detail;
        // update();
      } else {
        BoostNavigator.instance.pop({"name": name ?? ""});
        ToastUtil.showNotClickText(text: "moment_qchat_00073".tl);
      }
    } else {
      ///网络错误
      ToastUtil.showNotClickText(text: "moment_moments_00029".tl);
    }
  }

  Future<List<ServerMemberModel>> getManagerMembers() async {
    var result = await NativeQChatAuth.getInstance.channel.invokeMethod(
        "getManagerServerMembers", {"serverId": serverModelId.serviedId ?? ""});
    logger.d("getManagerMembers $result");

    ///有数据
    String jsonStr = result as String;
    if (jsonStr.contains("error") || jsonStr.isEmpty) {
      return [];
    }
    List<ServerMemberModel> raw = [];
    List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    if (list.isNotEmpty) {
      for (Map<String, dynamic> oneMap in list) {
        raw.add(ServerMemberModel.fromJson(oneMap));
      }
    }
    return Future(() => raw);
  }

  void getServerRoleInfo() async {
    logger.d("getServerRoleInfo ${serverModelId.serviedId}");

    var result = await NativeQChatAuth.getInstance.channel
        .invokeMethod<String>("getServerRoleInfo", {
      "serverId": serverModelId.serviedId,
    });

    logger.d(result);
    var decode = json.decode(result ?? "") as List;
    for (var item in decode) {
      var authBean = ServerRoleInfo.fromJson(item);
      if (authBean.type == 1) {
        ownerRoleInfo = authBean;
      } else {
        managerRoleInfo = authBean;
      }
    }
  }

  void checkCanModifyInfo() async {
    canModifyServerInfo = await QChatAuthController.checkPermission(
        QChatAuthEnum.MANAGE_SERVER.name,
        num.tryParse(serverModelId.serviedId ?? "0"));
    CircleGroupDetailModel detail =
        CircleGroupDetailModel.fromJson(circleGroupDetail.value.toJson());
    circleGroupDetail.value = detail;
    update();
  }
}
