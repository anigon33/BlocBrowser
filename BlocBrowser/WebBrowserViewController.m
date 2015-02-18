//
//  WebBrowserViewController.m
//  BlocBrowser
//
//  Created by Nigon's on 2/16/15.
//  Copyright (c) 2015 Adam Nigon. All rights reserved.
//

#import "WebBrowserViewController.h"
#import "AwesomeFloatingToolbar.h"
#define WebBrowserBackString NSLocalizedString(@"Back", @"Back command")
#define WebBrowserForwardString NSLocalizedString(@"Forward", @"Forward command")
#define WebBrowserStopString NSLocalizedString(@"Stop", @"Stop command")
#define WebBrowserRefreshString NSLocalizedString(@"Refresh", @"Reload command")


@interface WebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, AwesomeFloatingToolbarDelegate>
@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign) NSUInteger framecount;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) AwesomeFloatingToolbar *awesomeToolbar;
@end

@implementation WebBrowserViewController

#pragma mark - UIViewController
- (void) resetWebView {
    [self.webview removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webview = newWebView;
    
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
}
- (void)loadView {
    UIView *mainView = [UIView new];
    
    self.webview = [[UIWebView alloc] init];
    self.webview.delegate = self;
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Website URL", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.delegate = self;
    
    self.awesomeToolbar = [[AwesomeFloatingToolbar alloc] initWithFourTitles:@[WebBrowserBackString, WebBrowserForwardString, WebBrowserStopString, WebBrowserRefreshString]];
    self.awesomeToolbar.delegate = self;
    
    
     for (UIView *viewToAdd in @[self.webview, self.textField, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    self.view = mainView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome!", @"Welcome title")
                                                    message:NSLocalizedString(@"Get excited to use the best web browser ever!", @"Welcome comment")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK, I'm excited!", @"Welcome button title") otherButtonTitles:nil];
    [alert show];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.textField.placeholder = @"Google Search Here or URL Here";
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];


    // Do any additional setup after loading the view.
}
- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    // First, calculate some dimensions.
    static const CGFloat itemHeight = 50;
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    CGFloat width = CGRectGetWidth(self.view.bounds);
  
   

    // Now, assign the frames
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webview.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
     self.awesomeToolbar.frame = CGRectMake(40, 400, 280, 100);
    //make the webview fill the main view
    
    
    
}
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *URLString = textField.text;
    
    NSURL *URL = [NSURL URLWithString:URLString];
    
    if (!URL.scheme) {
        
        // The user didn't type http: or https:
        URLString = [URLString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://google.com/search?q=%@", URLString]];
        
    }
    if (URL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [self.webview loadRequest:request];
    }
    return NO;
}
#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.framecount++;
    
    [self updateButtonsAndTitle];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.framecount--;

    [self updateButtonsAndTitle];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code != -999) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    [self updateButtonsAndTitle];
    self.framecount--;
}

#pragma mark - Miscellaneous

- (void) updateButtonsAndTitle {
    NSString *webpageTitle = [self.webview stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    if (webpageTitle) {
        self.title = webpageTitle;
    } else {
        self.title = self.webview.request.URL.absoluteString;
    }
    if (self.framecount > 0) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    [self.awesomeToolbar setEnabled:[self.webview canGoBack] forButtonWithTitle:WebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webview canGoForward] forButtonWithTitle:WebBrowserForwardString];
    [self.awesomeToolbar setEnabled:self.framecount > 0 forButtonWithTitle:WebBrowserStopString];
    [self.awesomeToolbar setEnabled:self.webview.request.URL && self.framecount == 0 forButtonWithTitle:WebBrowserRefreshString];

    
}
#pragma mark - BLCAwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:WebBrowserBackString]) {
        [self.webview goBack];
    } else if ([title isEqual:WebBrowserForwardString]) {
        [self.webview goForward];
    } else if ([title isEqual:WebBrowserStopString]) {
        [self.webview stopLoading];
    } else if ([title isEqual:WebBrowserRefreshString]) {
        [self.webview reload];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
