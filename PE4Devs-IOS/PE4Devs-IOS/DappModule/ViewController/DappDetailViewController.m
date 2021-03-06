//
//  DAppDetailViewController.m
//  pocketEOS
//
//  Created by oraclechain on 09/05/2018.
//  Copyright © 2018 oraclechain. All rights reserved.
//

#define JS_CONTRACT_METHOD_PUSH @"push"
#define JS_CONTRACT_METHOD_PUSHACTION @"pushAction"
#define JS_CONTRACT_METHOD_PUSHACTIONS @"pushActions"

#import "DappDetailViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "TransferService.h"
#import "SelectAccountView.h"
#import "TransferAbi_json_to_bin_request.h"
#import "Abi_json_to_binRequest.h"
#import "DappTransferModel.h"
#import "DappTransferResult.h"
#import "DAppExcuteMutipleActionsBaseView.h"
#import "DappExcuteActionsDataSourceService.h"
#import "DAppExcuteMutipleActionsResult.h"
#import "ExcuteMultipleActionsService.h"
#import <WebKit/WebKit.h>
#import "CDZPicker.h"

@interface DappDetailViewController ()<UIGestureRecognizerDelegate,WKUIDelegate,WKScriptMessageHandler, WKUIDelegate , TransferServiceDelegate, LoginPasswordViewDelegate, SelectAccountViewDelegate, UIScrollViewDelegate, DAppExcuteMutipleActionsBaseViewDelegate, ExcuteMultipleActionsServiceDelegate>
@property(nonatomic, strong) WKWebView *webView;
@property(nonatomic, strong) WKUserContentController *userContentController;
@property(nonatomic, strong) LoginPasswordView *loginPasswordView;
@property(nonatomic, strong) TransferService *mainService;
@property(nonatomic, copy) NSString *WKScriptMessageName; // recieve WKScriptMessage.name
@property(nonatomic, strong) NSDictionary *WKScriptMessageBody;// recieve WKScriptMessage.body
@property(nonatomic, strong) SelectAccountView *selectAccountView;
@property(nonatomic , strong) TransferAbi_json_to_bin_request *transferAbi_json_to_bin_request;
@property(nonatomic , strong) Abi_json_to_binRequest *abi_json_to_binRequest;
@property (nonatomic , strong) DappTransferResult *dappTransferResult;
@property(nonatomic , strong) DappTransferModel *dappTransferModel;
@property(nonatomic , strong) DAppExcuteMutipleActionsResult *dAppExcuteMutipleActionsResult;
@property(nonatomic , strong) WKProcessPool *sharedProcessPool;
@property (nonatomic , strong) UIBarButtonItem *backItem;
@property (nonatomic , strong) UIBarButtonItem *closeItem;

@property(nonatomic , strong) DappExcuteActionsDataSourceService *dappExcuteActionsDataSourceService;
@property(nonatomic , strong) ExcuteMultipleActionsService *excuteMultipleActionsService;
@property(nonatomic , strong) DAppExcuteMutipleActionsBaseView *dAppExcuteMutipleActionsBaseView;
@property(nonatomic, strong) NSString *choosedAccountName;
@end

@implementation DappDetailViewController

- (WKWebView *)webView{
    if (!_webView) {
        //配置环境
        WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc]init];
        
        self.userContentController =[[WKUserContentController alloc]init];
        configuration.userContentController = self.userContentController;
        
        self.sharedProcessPool = [[WKProcessPool alloc]init];
        configuration.processPool = self.sharedProcessPool;
        
        self.webView = [[WKWebView alloc]initWithFrame:CGRectMake(0, NAVIGATIONBAR_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT - NAVIGATIONBAR_HEIGHT) configuration:configuration];
        self.webView.UIDelegate = self;
        self.webView.navigationDelegate = self;
        if (@available(iOS 9.0, *)) {
            self.webView.customUserAgent = @"PocketEosIos";
        } else {
            // Fallback on earlier versions
        }
        
    }
    return _webView;
}

- (TransferService *)mainService{
    if (!_mainService) {
        _mainService = [[TransferService alloc] init];
        _mainService.delegate = self;
    }
    return _mainService;
}

- (SelectAccountView *)selectAccountView{
    if (!_selectAccountView) {
        _selectAccountView = [[[NSBundle mainBundle] loadNibNamed:@"SelectAccountView" owner:nil options:nil] firstObject];
        _selectAccountView.frame = self.view.bounds;
        _selectAccountView.delegate = self;
    }
    return _selectAccountView;
}

- (LoginPasswordView *)loginPasswordView{
    if (!_loginPasswordView) {
        _loginPasswordView = [[[NSBundle mainBundle] loadNibNamed:@"LoginPasswordView" owner:nil options:nil] firstObject];
        _loginPasswordView.frame = self.view.bounds;
        _loginPasswordView.delegate = self;
    }
    return _loginPasswordView;
}


- (TransferAbi_json_to_bin_request *)transferAbi_json_to_bin_request{
    if (!_transferAbi_json_to_bin_request) {
        _transferAbi_json_to_bin_request = [[TransferAbi_json_to_bin_request alloc] init];
    }
    return _transferAbi_json_to_bin_request;
}

- (Abi_json_to_binRequest *)abi_json_to_binRequest{
    if (!_abi_json_to_binRequest) {
        _abi_json_to_binRequest = [[Abi_json_to_binRequest alloc] init];
    }
    return _abi_json_to_binRequest;
}

-(UIBarButtonItem *)backItem{
    if (!_backItem) {
        _backItem = [[UIBarButtonItem alloc] init];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [btn setTitle:NSLocalizedString(@"back", nil) forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
        [btn addTarget:self action:@selector(backNative) forControlEvents:UIControlEventTouchUpInside];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:17]];
        //左对齐
        //让返回按钮内容继续向左边偏移15，如果不设置的话，就会发现返回按钮离屏幕的左边的距离有点儿大，不美观
        btn.frame = CGRectMake(0, -40, 60, 40);
        _backItem.customView = btn;
    }
    return _backItem;
}

-(UIBarButtonItem *)closeItem{
    if (!_closeItem) {
        _closeItem = [[UIBarButtonItem alloc] init];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:NSLocalizedString(@"close", nil) forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
        [btn addTarget:self action:@selector(backNative) forControlEvents:UIControlEventTouchUpInside];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:17]];
        btn.frame = CGRectMake(0, 0, 30, 40);
        _closeItem.customView = btn;
    }
    return _closeItem;
}


- (DAppExcuteMutipleActionsBaseView *)dAppExcuteMutipleActionsBaseView{
    if (!_dAppExcuteMutipleActionsBaseView) {
        _dAppExcuteMutipleActionsBaseView = [[DAppExcuteMutipleActionsBaseView alloc] init];
        _dAppExcuteMutipleActionsBaseView.frame = CGRectMake(0, SCREEN_HEIGHT-380, SCREEN_WIDTH, 380 );
        _dAppExcuteMutipleActionsBaseView.delegate = self;
    }
    return _dAppExcuteMutipleActionsBaseView;
}

- (DappExcuteActionsDataSourceService *)dappExcuteActionsDataSourceService{
    if (!_dappExcuteActionsDataSourceService) {
        _dappExcuteActionsDataSourceService = [[DappExcuteActionsDataSourceService alloc] init];
    }
    return _dappExcuteActionsDataSourceService;
}

- (ExcuteMultipleActionsService *)excuteMultipleActionsService{
    if (!_excuteMultipleActionsService) {
        _excuteMultipleActionsService = [[ExcuteMultipleActionsService alloc] init];
        _excuteMultipleActionsService.delegate = self;
    }
    return _excuteMultipleActionsService;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // 禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"pushAction"];
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"push"];
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"pushActions"];
    if (IsStrEmpty(self.webView.title)) {
        [self.webView reload];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 开启返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    // 因此这里要记得移除handlers
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"pushAction('%@','%@')"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"pushActions('%@','%@')"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"push('%@','%@','%@','%@','%@')"];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 解决顶部出现空白
    self.automaticallyAdjustsScrollViewInsets=NO;//自动滚动调整，默认为YES
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = self.model.applyName;
    [self.view addSubview:self.selectAccountView];
    self.navigationItem.leftBarButtonItems =@[self.backItem , self.closeItem];
    
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self passEosAccountNameToJS];
    [self passWalletInfoToJS];
    WS(weakSelf);
    // 确保js 能收到 eosAccountName
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf passEosAccountNameToJS];
        [weakSelf passWalletInfoToJS];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf passEosAccountNameToJS];
        [weakSelf passWalletInfoToJS];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf passEosAccountNameToJS];
        [weakSelf passWalletInfoToJS];
    });
    
}


//DAppExcuteMutipleActionsBaseViewDelegate
- (void)excuteMutipleActionsConfirmBtnDidClick{
    // 验证密码输入是否正确
    Wallet *current_wallet = CURRENT_WALLET;
    if (![WalletUtil validateWalletPasswordWithSha256:current_wallet.wallet_shapwd password:self.dAppExcuteMutipleActionsBaseView.passwordTF.text]) {
        [TOASTVIEW showWithText:NSLocalizedString(@"密码输入错误!", nil)];
        [self feedbackToJsWithSerialNumber:self.dAppExcuteMutipleActionsResult.serialNumber andMessage:@"ERROR:Password is invalid. Please check it."];
        return;
    }
    [self pushActions];
}

- (void)excuteMutipleActionsCloseBtnDidClick{
    [self.dAppExcuteMutipleActionsBaseView removeFromSuperview];
    self.dAppExcuteMutipleActionsBaseView = nil;
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"提示", nil)message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:NSLocalizedString(@"确认", nil)style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    [TOASTVIEW showWithText: [ error localizedDescription]];
}



-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    [webView reload];
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"name:%@\\\\n body:%@\\\\n frameInfo:%@\\\\n",message.name,message.body,message.frameInfo);
    self.WKScriptMessageName = (NSString *)message.name;
    self.WKScriptMessageBody = (NSDictionary *)message.body;
    if ([self.WKScriptMessageName isEqualToString:@"pushAction"] || [self.WKScriptMessageName isEqualToString:@"push"]) {
        self.dappTransferResult = [DappTransferResult mj_objectWithKeyValues:self.WKScriptMessageBody];
        self.dappTransferModel = (DappTransferModel *)[DappTransferModel mj_objectWithKeyValues:[self.dappTransferResult.message mj_JSONObject ] ];
        [self.view addSubview:self.loginPasswordView];
    }else if ([self.WKScriptMessageName isEqualToString:@"pushActions"]){
        self.dAppExcuteMutipleActionsResult = [DAppExcuteMutipleActionsResult mj_objectWithKeyValues:self.WKScriptMessageBody];
        [self buildExcuteActionsDataSource];
    }
}

- (void)buildExcuteActionsDataSource{
    WS(weakSelf);
    self.dappExcuteActionsDataSourceService.actionsResultDict = self.dAppExcuteMutipleActionsResult.actionsDetails;
    [self.dappExcuteActionsDataSourceService buildDataSource:^(id service, BOOL isSuccess) {
        if (isSuccess) {
            [weakSelf.view addSubview:weakSelf.dAppExcuteMutipleActionsBaseView];
            [weakSelf.dAppExcuteMutipleActionsBaseView updateViewWithArray:weakSelf.dappExcuteActionsDataSourceService.dataSourceArray];
        }
    }];
    
}


// LoginPasswordViewDelegate
-(void)cancleBtnDidClick:(UIButton *)sender{
    [self removeLoginPasswordView];
    [self feedbackToJsWithSerialNumber:self.dappTransferResult.serialNumber andMessage:@"ERROR:Cancel"];
}

-(void)confirmBtnDidClick:(UIButton *)sender{
    // 验证密码输入是否正确
    Wallet *current_wallet = CURRENT_WALLET;
    if (![WalletUtil validateWalletPasswordWithSha256:current_wallet.wallet_shapwd password:self.loginPasswordView.inputPasswordTF.text]) {
        [TOASTVIEW showWithText:NSLocalizedString(@"密码输入错误!", nil)];
        [self feedbackToJsWithSerialNumber:self.dappTransferResult.serialNumber andMessage:@"ERROR:Password is invalid. Please check it."];
        return;
    }
    if ([self.WKScriptMessageName isEqualToString:JS_CONTRACT_METHOD_PUSH]) {
        [self push];
    }else if ([self.WKScriptMessageName isEqualToString:JS_CONTRACT_METHOD_PUSHACTION]){
        [self pushAction];
    }else if ([self.WKScriptMessageName isEqualToString:JS_CONTRACT_METHOD_PUSHACTIONS]){
        [self pushActions];
    }
}

- (void)push{
    self.abi_json_to_binRequest.code = self.dappTransferResult.contract;
    self.mainService.code = self.dappTransferResult.contract;
    self.abi_json_to_binRequest.action = self.dappTransferResult.action;
    self.mainService.action = self.dappTransferResult.action;
    self.abi_json_to_binRequest.args = [self.dappTransferResult.message mj_JSONObject];
    
    WS(weakSelf);
    [self.abi_json_to_binRequest postOuterDataSuccess:^(id DAO, id data) {
#pragma mark -- [@"data"]
        NSLog(@"approve_abi_to_json_request_success: --binargs: %@",data[@"data"][@"binargs"] );
        //        if (![data[@"code"] isEqualToNumber:@0]) {
        //            [weakSelf feedbackToJsWithSerialNumber:weakSelf.dappTransferModel.serialNumber andMessage:data[@"data"]];
        //            return ;
        //        }
        AccountInfo *accountInfo = [[AccountsTableManager accountTable] selectAccountTableWithAccountName:weakSelf.choosedAccountName];
        weakSelf.mainService.available_keys = @[VALIDATE_STRING(accountInfo.account_owner_public_key) , VALIDATE_STRING(accountInfo.account_active_public_key)];
        weakSelf.mainService.sender = weakSelf.choosedAccountName;
        weakSelf.mainService.binargs = data[@"data"][@"binargs"];
        weakSelf.mainService.pushTransactionType = PushTransactionTypeTransfer;
        weakSelf.mainService.password = weakSelf.loginPasswordView.inputPasswordTF.text;
        [weakSelf.mainService pushTransaction];
        [weakSelf removeLoginPasswordView];
    } failure:^(id DAO, NSError *error) {
        NSLog(@"%@", error);
    }];
    
    
}

// adapt old version
- (void)pushAction{
    
    if ([self.dappTransferModel.quantity containsString:@"EOS"]) {
        self.transferAbi_json_to_bin_request.code = ContractName_EOSIOTOKEN;
        self.mainService.code = ContractName_EOSIOTOKEN;
    }else if ([self.dappTransferModel.quantity containsString:@"OCT"]){
        self.transferAbi_json_to_bin_request.code = ContractName_OCTOTHEMOON;//octoneos
        self.mainService.code = ContractName_OCTOTHEMOON;
    }else{
        [TOASTVIEW showWithText:@"Symbols not find!Please check it!"];
        return;
    }
    self.transferAbi_json_to_bin_request.action = ContractAction_TRANSFER;
    
    self.transferAbi_json_to_bin_request.quantity = self.dappTransferModel.quantity;
    self.transferAbi_json_to_bin_request.action = ContractAction_TRANSFER;
    self.transferAbi_json_to_bin_request.from = self.dappTransferModel.from;
    self.transferAbi_json_to_bin_request.to = self.dappTransferModel.to;
    self.transferAbi_json_to_bin_request.memo = self.dappTransferModel.memo;
    WS(weakSelf);
    [self.transferAbi_json_to_bin_request postOuterDataSuccess:^(id DAO, id data) {
#pragma mark -- [@"data"]
        NSLog(@"approve_abi_to_json_request_success: --binargs: %@",data[@"data"][@"binargs"] );
        
        //        if (![data[@"code"] isEqualToNumber:@0]) {
        //            [weakSelf feedbackToJsWithSerialNumber:weakSelf.dappTransferModel.serialNumber andMessage:data[@"data"]];
        //            return ;
        //        }
        AccountInfo *accountInfo = [[AccountsTableManager accountTable] selectAccountTableWithAccountName:weakSelf.choosedAccountName];
        weakSelf.mainService.available_keys = @[VALIDATE_STRING(accountInfo.account_owner_public_key) , VALIDATE_STRING(accountInfo.account_active_public_key)];
        weakSelf.mainService.action = ContractAction_TRANSFER;
        weakSelf.mainService.sender = weakSelf.choosedAccountName;
        weakSelf.mainService.binargs = data[@"data"][@"binargs"];
        weakSelf.mainService.pushTransactionType = PushTransactionTypeTransfer;
        weakSelf.mainService.password = weakSelf.loginPasswordView.inputPasswordTF.text;
        [weakSelf.mainService pushTransaction];
        [weakSelf removeLoginPasswordView];
    } failure:^(id DAO, NSError *error) {
        NSLog(@"%@", error);
    }];
    
}

- (void)pushActions{
    AccountInfo *accountInfo = [[AccountsTableManager accountTable] selectAccountTableWithAccountName:self.choosedAccountName];
    if (accountInfo) {
        [self.excuteMultipleActionsService excuteMultipleActionsWithSender:accountInfo.account_name andExcuteActionsArray:self.dappExcuteActionsDataSourceService.dataSourceArray andAvailable_keysArray:@[VALIDATE_STRING(accountInfo.account_owner_public_key) , VALIDATE_STRING(accountInfo.account_active_public_key)] andPassword: self.dAppExcuteMutipleActionsBaseView.passwordTF.text];//self.loginPasswordView.inputPasswordTF.text
    }else{
        [TOASTVIEW showWithText: NSLocalizedString(@"您钱包中暂无操作账号~", nil)];
    }
    [self removeLoginPasswordView];
}

// TransferServiceDelegate
-(void)pushTransactionDidFinish:(TransactionResult *)result{
    if ([result.code isEqualToNumber:@0 ]) {
        //        [TOASTVIEW showWithText:NSLocalizedString(@"交易成功!", nil)];
        [self feedbackToJsWithSerialNumber:self.dappTransferResult.serialNumber andMessage:VALIDATE_STRING(result.transaction_id)];
    }else{
        [TOASTVIEW showWithText: result.message];
        [self feedbackToJsWithSerialNumber:self.dappTransferResult.serialNumber andMessage: [NSString stringWithFormat:@"ERROR:%@", result.message]];
    }
}

//ExcuteMultipleActionsServiceDelegate
- (void)excuteMultipleActionsDidFinish:(TransactionResult *)result{
    if ([result.code isEqualToNumber:@0 ]) {
        [TOASTVIEW showWithText:NSLocalizedString(@"签名成功", nil)];
        [self.dAppExcuteMutipleActionsBaseView removeFromSuperview];
        self.dAppExcuteMutipleActionsBaseView = nil;
        [self feedbackToJsWithSerialNumber:self.dAppExcuteMutipleActionsResult.serialNumber andMessage:VALIDATE_STRING(result.transaction_id)];
    }else{
        [TOASTVIEW showWithText: result.message];
        [self feedbackToJsWithSerialNumber:self.dAppExcuteMutipleActionsResult.serialNumber andMessage: [NSString stringWithFormat:@"ERROR:%@", result.message]];
    }
    [self removeLoginPasswordView];
    [SVProgressHUD dismiss];
}

// pushActionResultFeedback
- (void)feedbackToJsWithSerialNumber:(NSString *)serialNumber andMessage:(NSString *)message{
    NSString *jsStr = [NSString stringWithFormat:@"pushActionResult('%@', '%@')", serialNumber, message];
    [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"%@----%@",result, error);
    }];
}

- (void)passEosAccountNameToJS{
    NSString *js = [NSString stringWithFormat:@"getEosAccount('%@')", self.choosedAccountName];
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        //TODO
        NSLog(@"%@ ",response);
    }];
}

- (void)passWalletInfoToJS{
    Wallet *wallet = CURRENT_WALLET;
    NSMutableDictionary *walletDict = [[NSMutableDictionary alloc] init];
    [walletDict setValue:self.choosedAccountName forKey:@"account"];
    [walletDict setValue:wallet.wallet_uid forKey:@"uid"];
    [walletDict setValue:wallet.wallet_name forKey:@"wallet_name"];
    [walletDict setValue:wallet.wallet_avatar forKey:@"image"];
    NSString *js = [NSString stringWithFormat:@"getWalletWithAccount('%@')",[walletDict mj_JSONString]];
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        //TODO
        NSLog(@"%@ ",response);
    }];
}

//SelectAccountViewDelegate
- (void)selectAccountBtnDidClick:(UIButton *)sender{
    CDZPickerBuilder *builder = [CDZPickerBuilder new];
    builder.showMask = YES;
    builder.cancelTextColor = UIColor.redColor;
    WS(weakSelf);
    
    NSArray *accountNameArr = [[AccountsTableManager accountTable] selectAllNativeAccountName];
    if (accountNameArr.count == 0) {
        [TOASTVIEW showWithText:NSLocalizedString(@"暂无账号!", nil)];
        return;
    }
    
    [CDZPicker showSinglePickerInView:self.view withBuilder:builder strings:[[AccountsTableManager accountTable] selectAllNativeAccountName] confirm:^(NSArray<NSString *> * _Nonnull strings, NSArray<NSNumber *> * _Nonnull indexs) {
        weakSelf.selectAccountView.accountChooseLabel.text = [NSString stringWithFormat:@"%@" , strings[0]];
        weakSelf.choosedAccountName = VALIDATE_STRING(strings[0]);
    }cancel:^{
        [weakSelf.selectAccountView removeFromSuperview];
    }];
    
}

- (void)understandBtnDidClick:(UIButton *)sender{
    if (IsStrEmpty(self.choosedAccountName)) {
        [TOASTVIEW showWithText:NSLocalizedString(@"请选择您将选择的账号!", nil)];
        return;
    } else{
        [self.selectAccountView removeFromSuperview];
        [self loadWebView];
    }
}

- (void)loadWebView{
    //       xgame http://47.74.145.111 self.model.url
    //        http://www.cheerfifa.com //  http://192.168.3.151:8081
    [self.webView loadRequest: [NSURLRequest requestWithURL:String_To_URL(self.model.url)]];
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    self.webView.scrollView.delegate = self;
    [self.view addSubview:self.webView];
}

-(void)backgroundViewDidClick{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)backNative {
    if([self.webView canGoBack]) {
        //如果有则返回
        [self.webView goBack];
        //同时设置返回按钮和关闭按钮为导航栏左边的按钮
        self.navigationItem.leftBarButtonItems = @[self.backItem, self.closeItem];
    }else{
        [self closeNative];
    }
}

- (void)closeNative {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)removeLoginPasswordView{
    if (self.loginPasswordView) {
        [self.loginPasswordView removeFromSuperview];
        self.loginPasswordView = nil;
    }
}


@end


