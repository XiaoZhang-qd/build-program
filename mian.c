#include <stdio.h>
#include <stdlib.h>
#include <objc/runtime.h>
#include <objc/message.h>

// 简单宏，方便调用objc消息
#define OBJC_CALL(obj, sel) ((id(*)(id,SEL))objc_msgSend)(obj, sel)
#define OBJC_CALL1(obj, sel, a1) ((id(*)(id,SEL,id))objc_msgSend)(obj,sel,a1)
#define OBJC_CALL2(obj, sel, a1,a2) ((id(*)(id,SEL,id,id))objc_msgSend)(obj,sel,a1,a2)

static void buttonClicked(id self, SEL _cmd, id sender)
{
    id UIAlertController = objc_getClass("UIAlertController");
    id alert = OBJC_CALL1(UIAlertController, sel_registerName("alertControllerWithTitle:message:preferredStyle:"),
        OBJC_CALL(objc_getClass("NSString"), sel_registerName("stringWithUTF8String:"), "Hello C‑GUI"),
        OBJC_CALL(objc_getClass("NSString"), sel_registerName("stringWithUTF8String:"), "This iOS GUI written in pure C"),
        (id)1);

    id okAction = OBJC_CALL1(objc_getClass("UIAlertAction"), sel_registerName("actionWithTitle:style:handler:"),
        OBJC_CALL(objc_getClass("NSString"), sel_registerName("stringWithUTF8String:"), "OK"),
        (id)0, NULL);

    OBJC_CALL1(alert, sel_registerName("addAction:"), okAction);

    id app = OBJC_CALL(objc_getClass("UIApplication"), sel_registerName("sharedApplication"));
    id win = OBJC_CALL(OBJC_CALL(app, sel_registerName("keyWindow")), sel_registerName("rootViewController"));
    OBJC_CALL1(win, sel_registerName("presentViewController:animated:completion:"), alert, (id)1, NULL);
}

int main(int argc, char *argv[])
{
    @autoreleasepool {
        // UIApplicationMain
        id UIApplication = objc_getClass("UIApplication");
        id appDelegateClass = objc_allocateClassPair(objc_getClass("NSObject"), "AppDelegate", 0);
        objc_registerClassPair(appDelegateClass);

        // AppDelegate: didFinishLaunchingWithOptions
        SEL launchSel = sel_registerName("application:didFinishLaunchingWithOptions:");
        class_addMethod(appDelegateClass, launchSel, imp_implementationWithBlock(^(id _self, id _app, id opts){
            // window
            id UIScreen = objc_getClass("UIScreen");
            id mainScreen = OBJC_CALL(UIScreen, sel_registerName("mainScreen"));
            id bounds = OBJC_CALL(mainScreen, sel_registerName("bounds"));

            id UIWindow = objc_getClass("UIWindow");
            id window = OBJC_CALL(UIWindow, sel_registerName("alloc"));
            window = OBJC_CALL1(window, sel_registerName("initWithFrame:"), bounds);

            id UIViewController = objc_getClass("UIViewController");
            id rootVC = OBJC_CALL(OBJC_CALL(UIViewController, sel_registerName("alloc")), sel_registerName("init"));

            // Button
            id UIButton = objc_getClass("UIButton");
            id btn = OBJC_CALL1(UIButton, sel_registerName("buttonWithType:"), (id)1);

            OBJC_CALL1(btn, sel_registerName("setFrame:"),
                OBJC_CALL(objc_getClass("NSValue"), sel_registerName("valueWithCGRect:"), (CGRect){{100,200},{160,50}}));

            OBJC_CALL1(btn, sel_registerName("setTitle:forState:"),
                OBJC_CALL(objc_getClass("NSString"), sel_registerName("stringWithUTF8String:"), "Click Me"),
                (id)0);

            // button action
            IMP btnImp = imp_implementationWithBlock(^{ buttonClicked(NULL,0,NULL); });
            class_addMethod(objc_getClass("NSObject"), sel_registerName("onTap:"), btnImp, "v@:@");
            OBJC_CALL2(btn, sel_registerName("addTarget:action:forControlEvents:"), btn, sel_registerName("onTap:"), (id)1<<12);

            OBJC_CALL1(OBJC_CALL(rootVC, sel_registerName("view")), sel_registerName("addSubview:"), btn);

            OBJC_CALL1(window, sel_registerName("setRootViewController:"), rootVC);
            OBJC_CALL1(window, sel_registerName("makeKeyAndVisible:"), (id)1);
            return (BOOL)1;
        }), "B@:@");

        id appDelegate = OBJC_CALL(OBJC_CALL(appDelegateClass, sel_registerName("alloc")), sel_registerName("init"));
        int ret = objc_msgSend(UIApplication, sel_registerName("UIApplicationMain"), argc, argv, NULL, appDelegate);
        return ret;
    }
}
