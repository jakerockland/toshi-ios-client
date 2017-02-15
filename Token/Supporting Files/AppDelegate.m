#import "AppDelegate.h"

#import "Token-Swift.h"

#import "NotificationsManager.h"
#import "PushManager.h"

#import <SignalServiceKit/TSOutgoingMessage.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/TSStorageManager+keyingMaterial.h>
#import <SignalServiceKit/OWSSyncContactsMessage.h>
#import <SignalServiceKit/NSDate+millisecondTimeStamp.h>
#import <SignalServiceKit/TextSecureKitEnv.h>
#import <SignalServiceKit/OWSIncomingMessageReadObserver.h>
#import <SignalServiceKit/TSSocketManager.h>

@interface AppDelegate ()
@property (nonnull, nonatomic) Cereal *cereal;
@property (nonnull, nonatomic) ChatAPIClient *chatAPIClient;
@property (nonnull, nonatomic) IDAPIClient *idAPIClient;

@property (nonatomic) OWSIncomingMessageReadObserver *incomingMessageReadObserver;
//@property (nonatomic) OWSStaleNotificationObserver *staleNotificationObserver;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.cereal = [[Cereal alloc] init];
    [[TSStorageManager sharedManager] storePhoneNumber:self.cereal.address];

    self.chatAPIClient = [[ChatAPIClient alloc] initWithCereal:self.cereal];
    self.idAPIClient = [[IDAPIClient alloc] initWithCereal:self.cereal];

    [self setupBasicAppearance];
    [self setupTSKitEnv];

    // Not sure what to make of this. Looks like it only handles RedPhone stuff, not sure.
    // Will investigate some more.
    // [[PushManager sharedManager] registerPushKitNotificationFuture];

    self.window = [[UIWindow alloc] init];
    self.window.backgroundColor = [Theme viewBackgroundColor];
    self.window.rootViewController = [[TabBarController alloc] initWithChatAPIClient:self.chatAPIClient idAPIClient:self.idAPIClient];

    [self.window makeKeyAndVisible];

    if (User.current == nil) {
        [self.idAPIClient registerUserIfNeeded:^{
            [self.chatAPIClient registerUserIfNeeded];
        }];
    } else {
        [self.idAPIClient retrieveUserWithUsername:[User.current username] completion:^(User * _Nullable user) {
            NSLog(@"%@", user);
            if (user == nil) {
                [self.idAPIClient registerUserIfNeeded:^{
                    [self.chatAPIClient registerUserIfNeeded];
                }];
            }
        }];
    }

    [TSSocketManager becomeActiveFromForeground];

    return YES;
}

- (void)setupBasicAppearance {
    NSDictionary *attributtes = @{NSForegroundColorAttributeName: [Theme navigationTitleTextColor], NSFontAttributeName: [Theme boldWithSize:17]};

    UINavigationBar *navBarAppearance = [UINavigationBar appearance];
    [navBarAppearance setTitleTextAttributes:attributtes];
    [navBarAppearance setTintColor:[Theme navigationTitleTextColor]];

    attributtes = @{NSForegroundColorAttributeName: [Theme navigationTitleTextColor], NSFontAttributeName: [Theme regularWithSize:17]};
    UIBarButtonItem *barButtonAppearance = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]];
    [barButtonAppearance setTitleTextAttributes:attributtes forState:UIControlStateNormal];
}

- (void)setupTSKitEnv {
    [TextSecureKitEnv sharedEnv].contactsManager = [[ContactsManager alloc] init];
    TSStorageManager *storageManager = [TSStorageManager sharedManager];
    [storageManager setupDatabase];
    [TextSecureKitEnv sharedEnv].notificationsManager = [[NotificationsManager alloc] init];

    self.networkManager = [TSNetworkManager sharedManager];
    self.contactsManager = [[ContactsManager alloc] init];
    self.contactsUpdater = [[ContactsUpdater alloc] init];

    self.messageSender = [[OWSMessageSender alloc] initWithNetworkManager:self.networkManager storageManager:storageManager contactsManager:self.contactsManager contactsUpdater:self.contactsUpdater];

    self.incomingMessageReadObserver = [[OWSIncomingMessageReadObserver alloc] initWithStorageManager:storageManager messageSender:self.messageSender];
    [self.incomingMessageReadObserver startObserving];

//    self.staleNotificationObserver = [OWSStaleNotificationObserver new];
//    [self.staleNotificationObserver startObserving];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end