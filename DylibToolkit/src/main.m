#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <sys/utsname.h>

@interface DTController : UIViewController @end
@implementation DTController {
    UITextView *_text;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16,10,300,36)];
    title.text = @"Dylib Toolkit";
    title.font = [UIFont boldSystemFontOfSize:24];
    [self.view addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(self.view.bounds.size.width-58,10,44,36);
    close.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:close];

    NSArray *names = @[@"Runtime",@"Images",@"Logs"];
    for (NSInteger i=0;i<3;i++) {
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
        b.frame=CGRectMake(14+i*112,54,104,34);
        b.tag=i+1; b.layer.cornerRadius=9;
        b.backgroundColor=UIColor.secondarySystemBackgroundColor;
        [b setTitle:names[i] forState:UIControlStateNormal];
        [b addTarget:self action:@selector(tab:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:b];
    }

    _text=[[UITextView alloc] initWithFrame:CGRectMake(12,98,self.view.bounds.size.width-24,self.view.bounds.size.height-110)];
    _text.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _text.editable=NO;
    _text.font=[UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    _text.backgroundColor=UIColor.secondarySystemBackgroundColor;
    _text.layer.cornerRadius=12;
    [self.view addSubview:_text];
    [self runtime];
}
- (void)tab:(UIButton *)b { if(b.tag==1)[self runtime]; else if(b.tag==2)[self images]; else [self logs]; }
- (void)runtime {
    NSBundle *bundle=NSBundle.mainBundle; struct utsname u; uname(&u);
    NSString *machine=[NSString stringWithUTF8String:u.machine] ?: @"Unknown";
    _text.text=[NSString stringWithFormat:@"APP\n%@\n\nBUNDLE ID\n%@\n\nVERSION\n%@ (%@)\n\niOS\n%@\n\nDEVICE\n%@\n\nPROCESS\n%@\n\nPID\n%d",
      bundle.infoDictionary[@"CFBundleDisplayName"] ?: bundle.infoDictionary[@"CFBundleName"] ?: @"Unknown",
      bundle.bundleIdentifier ?: @"Unknown",
      bundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"Unknown",
      bundle.infoDictionary[@"CFBundleVersion"] ?: @"Unknown",
      UIDevice.currentDevice.systemVersion,machine,NSProcessInfo.processInfo.processName,getpid()];
}
- (void)images {
    NSMutableString *s=[NSMutableString string]; uint32_t n=_dyld_image_count();
    for(uint32_t i=0;i<n;i++){const char *p=_dyld_get_image_name(i); if(p)[s appendFormat:@"%s\n",p];}
    _text.text=s;
}
- (void)logs {
    _text.text=[NSString stringWithFormat:@"Dylib Toolkit loaded successfully.\nProcess: %@\nPID: %d",NSProcessInfo.processInfo.processName,getpid()];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
@end

__attribute__((constructor))
static void DTInit(void) {
    NSLog(@"[DylibToolkit] dylib loaded");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
        UIViewController *root=nil;
        for(UIWindow *w in UIApplication.sharedApplication.windows) if(w.isKeyWindow){root=w.rootViewController;break;}
        if(!root)return;
        DTController *vc=[DTController new];
        vc.modalPresentationStyle=UIModalPresentationPageSheet;
        [root presentViewController:vc animated:YES completion:nil];
    });
}
