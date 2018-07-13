# PE4Devs-IOS
Adaptation tool for PocketEOS dapps developers.

进入页面需要检测User-Agent（android为：“PocketEosAndroid”，ios为“PocketEosIos”）判断加载页面来源是PocketEosAndroid或者是PocketEosIos

Android端：

整个交互JsInterface name（the name used to expose the object in JavaScript） 为：DappJsBridge

1-1：Dapp进入需要用户选择eos账号

JS端声明方法，传递数据。方法名：getEosAccountDetails（String account）

备注:该方法，无论采用什么前端框架，都需要暴露在window全局下。account以String形式传递

eg：

//获取移动端选择的eos账号

function getEosAccount(String account){

}

1-2：Dapp进入获取钱包信息以及选中账号

JS端声明方法，传递数据。方法名：getWalletWithAccount（String detail）

备注:该方法，无论采用什么前端框架，都需要暴露在window全局下。detail以json形式传递

eg：

//获取钱包信息以及选中账号

function getWalletWithAccount(String detail){

}

detail： { "phone": "13900000000", "account": "oraclechain4", "uid": "46eec3f33e3d86a40c914a591922f420", "wallet_name": "haha", "image": "" }

2-1：签名实现OCT或者EOS转账

合约调用操作流程:在移动端进行完成，由移动端声明方法，传递数据。

方法：pushAction（String serialNumber,String message, String permissionAccount）

备注：dapp合约调用封装完成 传递message（合约message，以json形式传递），permissionAccount(交易发起者账号),serialNumber(发起交易流水号，用于同时发起多条交易txid的对应检测 , 该字段可以随意定制保持唯一性即可),

eg：

message：

{ "from": "eosio", "to": "eosio.token", "quantity": "1 EOS",（注意空格,token为大写） "memo": "test" }

调用：

Android端： window.DappJsBridge. pushAction(serialNumber，message, permissionAccount)

ios端：window.webkit.messageHandlers.pushAction.postMessage({serialNumber：'测试',message:'测试',permissionAccount:'测试'});

2-2：签名实现智能合约调用（也可以进行transfer交易）

合约调用操作流程:在移动端进行完成，由移动端声明方法，传递数据。

方法：push（String serialNumber，String contract, String action, String message, String permissionAccount）

备注：dapp合约调用 传递serialNumber（发起交易流水号，用于同时发起多条交易txid的对应检测 , 该字段可以随意定制保持唯一性即可），contract(调用合约名字),action(合约action), message（合约message，以json形式传递），permissionAccount(交易发起者账号),

eg：

contract:eosio.token

action:transfer

message： { "from": "eosio", "to": "eosio.token", "quantity": "1 EOS",（注意空格,token为大写） "memo": "test" } permissionAccount:eosio

调用：

Android端： window.DappJsBridge. push(serialNumber，contract，action，message, permissionAccount)

ios端：window.webkit.messageHandlers.push.postMessage({serialNumber：'测试',contract：'测试',action：'测试',message:'测试',permissionAccount:'测试'});

3:获取txid

JS端声明方法，传递数据。方法名：pushActionResult（String serialNumber,String result） 备注:该方法，无论采用什么前端框架，都需要暴露在window全局下。 eg：
//获取交易txid以及对应的流水号，用于帮助检测交易信息。 function pushActionResult(String serialNumber,String result) {

} 交易中断或者异常：

如果serialNumber为js端传进来的serialNumber，result为“ERROR:{"code":3050003,"what":"eosio_assert_message assertion failure","name":"eosio_assert_message_exception","details":[]}”，此时result为链上错误信息(所有错误信息都会以ERROR开头，可以通过检测ERROR来判断交易是否出错。)

如果serialNumber为js端传进来的serialNumber，result为“ERROR:您的密码输入错误,请核对后再次输入~”,或者result为“ERROR:Password is invalid. Please check it.”说明密码错误。

如果serialNumber为js端传进来的serialNumber，result为“ERROR:取消”,或者result为“ERROR:Cancel”用户取消交易。
交易正常进行：

如果serialNumber为js端传进来的serialNumber，result为txid(eg:5cf2841c9f1d610d4aac2b8d586da21e2057f4188fdcc02dc4187f0f2
