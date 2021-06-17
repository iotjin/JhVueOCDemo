//
//  ViewController.m
//  JhVueOCDemo
//
//  Created by Jh on 2021/6/17.
//

#import "ViewController.h"
#import "UIView+JhView.h"
#import <WebKit/WebKit.h>

#define kSendDataToIOS @"SendDataToApp" //与后台约定的方法名
#define kReceiveAPPData @"receiveAPPData"

@interface ViewController ()<WKScriptMessageHandler,WKNavigationDelegate,WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation ViewController

- (void)dealloc {
    NSLog(@" VueViewController - dealloc ");
}

// 注意: 不是在dealloc中移除, 因为已经循环引用了, 不会执行dealloc方法.
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    // 视图即将消失的时候, 移除 防止循环引用
    // self-->webView-->configuration-->userContentControll-->self 循环引用
    if (self.webView) {
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:kSendDataToIOS];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setButton];
    [self configWebView];
}

- (void)setButton {
    UIButton *button = [[UIButton alloc]init];
    button.frame = CGRectMake(20, 700, 300, 80);
    button.backgroundColor = UIColor.yellowColor;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(ClickButton) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"往JS传值（点击到About页面）" forState:UIControlStateNormal];
    [self.view addSubview:button];
}

- (void)ClickButton {
    [self eventHandle];
}

- (void)configWebView {
    [self.view addSubview:self.webView];
    self.webView.Jh_height = 600;
    NSString *path = @"dist/index.html";
    NSURL *url = [[NSBundle mainBundle] URLForResource:path withExtension:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

#pragma mark - 交互处理

- (void)eventHandle {
    //OC往js发送信息
    NSString *name = kReceiveAPPData;
    NSString *params = @"2222";
    NSString *jsStr = [NSString stringWithFormat:@"%@('%@')",name,params];
    [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        NSLog(@" response %@ ",response);
        NSLog(@" error %@ ",error);
    }];
}

//接收js传过来的数据
#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"message.name = %@；message.body=%@", message.name,message.body);
    if ([message.name isEqualToString:kSendDataToIOS]) {
        NSDictionary *jsData = message.body;
    }
}

#pragma mark - WKNavigationDelegate
// WKNavigationDelegate主要处理一些跳转、加载处理操作，WKUIDelegate主要处理JS脚本，确认框，警告框等

// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@" 页面开始加载时调用 ");
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@" 页面开始加载时调用 ");
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@" 页面加载完毕时调用 ");
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@" 页面加载失败时调用 ");
}

#pragma mark -- WKUIDelegate
// 提醒 对应js的Alert方法
/**
 *  web界面中有弹出警告框时调用
 *
 *  @param webView           实现该代理的webview
 *  @param message           警告框中的内容
 *  @param frame             主窗口
 *  @param completionHandler 警告框消失调用
 */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    NSLog(@" message %@ ",message);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vue接收的数据:" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

// 确认提交 对应js的confirm方法
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    // 按钮
    UIAlertAction *alertActionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // 返回用户选择的信息
        completionHandler(NO);
    }];
    UIAlertAction *alertActionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }];
    // alert弹出框
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:alertActionCancel];
    [alertController addAction:alertActionOK];
    [self presentViewController:alertController animated:YES completion:nil];
}

// 文本框输入 对应js的prompt方法
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    // alert弹出框
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:nil preferredStyle:UIAlertControllerStyleAlert];
    // 输入框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText;
    }];
    // 确定按钮
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 返回用户输入的信息
        UITextField *textField = alertController.textFields.firstObject;
        completionHandler(textField.text);
    }]];
    // 显示
    [self presentViewController:alertController animated:YES completion:nil];
}

- (WKWebView *)webView {
    if (!_webView) {
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        /** JS往iOS传递消息，iOS需要先注册JS消息
         然后 JS发送信息： window.webkit.messageHandlers.<对象名>.postMessage(<数据>);
         */
        //注册JS消息，name必须JS发送消息时的名字一致
        [userContentController addScriptMessageHandler:self name:kSendDataToIOS];

        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.userContentController = userContentController;
        WKWebView *webView = [[WKWebView alloc]initWithFrame:self.view.frame configuration:config];
        webView.navigationDelegate = self;
        webView.UIDelegate = self;
        _webView = webView;
    }
    return _webView;
}

@end
