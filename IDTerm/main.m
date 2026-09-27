#import <UIKit/UIKit.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
extern char **environ;

static NSString *runShell(NSString *command) {
    int pipefd[2];
    if (pipe(pipefd) != 0) return [NSString stringWithFormat:@"pipe: %s\n", strerror(errno)];
    pid_t pid = 0;
    const char *sh = "/bin/sh";
    char *const argv[] = {"sh", "-c", (char *)command.UTF8String, NULL};

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&actions, pipefd[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&actions, pipefd[0]);
    posix_spawn_file_actions_addclose(&actions, pipefd[1]);

    int rc = posix_spawn(&pid, sh, &actions, NULL, argv, environ);
    posix_spawn_file_actions_destroy(&actions);
    close(pipefd[1]);
    if (rc != 0) {
        close(pipefd[0]);
        return [NSString stringWithFormat:@"posix_spawn: %s\n", strerror(rc)];
    }

    NSMutableData *data = [NSMutableData data];
    char buf[4096]; ssize_t n;
    while ((n = read(pipefd[0], buf, sizeof(buf))) > 0) [data appendBytes:buf length:(NSUInteger)n];
    close(pipefd[0]);
    int status = 0; waitpid(pid, &status, 0);

    NSString *out = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!out) out = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    if (!out) out = @"<non-text output>\n";
    if (WIFEXITED(status) && WEXITSTATUS(status) != 0) out = [out stringByAppendingFormat:@"\n[exit %d]\n", WEXITSTATUS(status)];
    if (WIFSIGNALED(status)) out = [out stringByAppendingFormat:@"\n[killed by signal %d]\n", WTERMSIG(status)];
    return out;
}

@interface TerminalVC : UIViewController <UITextFieldDelegate>
@property(nonatomic,strong) UITextView *output;
@property(nonatomic,strong) UITextField *input;
@end

@implementation TerminalVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;

    self.output = [UITextView new];
    self.output.translatesAutoresizingMaskIntoConstraints = NO;
    self.output.editable = NO;
    self.output.backgroundColor = UIColor.blackColor;
    self.output.textColor = [UIColor colorWithRed:.65 green:1 blue:.65 alpha:1];
    self.output.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.output.text = @"IDTerm — iOS shell terminal\nUses the device /bin/sh inside the app sandbox.\nType 'help' for local commands.\n\n";
    [self.view addSubview:self.output];

    UILabel *prompt = [UILabel new];
    prompt.translatesAutoresizingMaskIntoConstraints = NO;
    prompt.text = @"$"; prompt.textColor = UIColor.greenColor;
    prompt.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightBold];
    [self.view addSubview:prompt];

    self.input = [UITextField new];
    self.input.translatesAutoresizingMaskIntoConstraints = NO;
    self.input.backgroundColor = [UIColor colorWithWhite:.08 alpha:1];
    self.input.textColor = UIColor.whiteColor;
    self.input.tintColor = UIColor.greenColor;
    self.input.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightRegular];
    self.input.autocorrectionType = UITextAutocorrectionTypeNo;
    self.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.input.returnKeyType = UIReturnKeyGo;
    self.input.delegate = self;
    [self.view addSubview:self.input];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.output.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [self.output.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8],
        [self.output.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
        [self.output.bottomAnchor constraintEqualToAnchor:self.input.topAnchor constant:-8],
        [prompt.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:10],
        [prompt.bottomAnchor constraintEqualToAnchor:self.input.bottomAnchor constant:-8],
        [prompt.widthAnchor constraintEqualToConstant:20],
        [self.input.leadingAnchor constraintEqualToAnchor:prompt.trailingAnchor constant:4],
        [self.input.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
        [self.input.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8],
        [self.input.heightAnchor constraintEqualToConstant:42]
    ]];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *cmd = textField.text; textField.text = @"";
    if (!cmd.length) return YES;
    if ([cmd isEqualToString:@"clear"]) { self.output.text = @""; return YES; }
    if ([cmd isEqualToString:@"help"]) {
        self.output.text = [self.output.text stringByAppendingString:@"Built-ins: clear, help\nAll other commands go to /bin/sh -c.\n\n"];
        return YES;
    }
    self.output.text = [self.output.text stringByAppendingFormat:@"$ %@\n", cmd];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *result = runShell(cmd);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.output.text = [self.output.text stringByAppendingFormat:@"%@\n", result];
            [self.output scrollRangeToVisible:NSMakeRange(self.output.text.length, 0)];
        });
    });
    return YES;
}
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [TerminalVC new];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
int main(int argc, char *argv[]) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class])); }
}