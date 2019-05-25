#include <JavaScriptCore/JSContextRef.h>
#include <dlfcn.h>

@interface WKBrowsingContextController : NSObject
- (void *)_pageRef; // WKPageRef
@end

@interface WKContentView : NSObject
@property (nonatomic, readonly) WKBrowsingContextController *browsingContextController;
@end

// WKWebView -> ivar _contentView

// Logging
#define XENlog(args...) XenHTMLBatteryManagerLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);

#if defined __cplusplus
extern "C" {
#endif
    
    void XenHTMLBatteryManagerLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
    
#if defined __cplusplus
};
#endif

void XenHTMLBatteryManagerLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...) {
    // Type to hold information about variable arguments.
    
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    if (![format hasSuffix:@"\n"]) {
        format = [format stringByAppendingString:@"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    // End using variable argument list.
    va_end(ap);
    
    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    
    NSLog(@"Xen HTML (BatteryManager) :: (%s:%d) %s",
          [fileName UTF8String],
          lineNumber, [body UTF8String]);
}

// Hooks

/*static void (*$WKContextPostMessageToInjectedBundle)(void *contextRef, void *messageNameRef, void *messageBodyRef);
static void* (*$WKPageGetContext)(void *pageRef);
static void* (*$WKStringCreateWithUTF8CString)(const char *c_str);
static void* (*$WKMutableDictionaryCreate)(void);
static void (*$WKDictionarySetItem)(void *dict, void *key, void *value);*/

%group SpringBoard

#pragma mark DEBUG

%hook WKWebView

- (void)_didFinishLoadForMainFrame {
    %orig;
    
    XENlog(@"_didFinishLoadForMainFrame");
    
    // Send a test injected bundle message
    void* messageName = $WKStringCreateWithUTF8CString("TESTING XH");
    void* messageBody = $WKMutableDictionaryCreate();
    $WKDictionarySetItem(messageBody, $WKStringCreateWithUTF8CString("test"), $WKStringCreateWithUTF8CString("pause"));
    
    // Get the WKContextRef for this webview
    WKContentView *contentView = MSHookIvar<WKContentView*>(self, "_contentView");
    void *pageRef = [contentView.browsingContextController _pageRef];
    void *contextRef = $WKPageGetContext(pageRef);
    
    $WKContextPostMessageToInjectedBundle(contextRef, messageName, messageBody);
    
    XENlog(@"Sent injected bundle message");
}

%end

%end

static JSGlobalContextRef (*WebFrame$jsContext)(void *_this);
static bool (*WebFrame$isMainFrame)(void *_this);
static CFStringRef (*WTF$String$createCFString)(void *_this);
static void* (*WTF$String$fromUTF8)(const char* literal);
static void* (*API$Dictionary$getNumber)(void *_this, void *key);
static void* (*API$Dictionary$getString)(void *_this, void *key);

// JSGlobalContextRef WebKit::WebFrame::jsContext();

__ZN6WebKit20RemoteWebInspectorUI20sendMessageToBackendERKN3WTF6StringE
// RemoteWebInspectorUI (?)::sendMessageToBackend(WTF::String &message)
// https://chromedevtools.github.io/devtools-protocol/1-2/Debugger/
// { \
    "id": 10, // <-- command sequence number generated by the caller \
    "method": "pause" | "resume", // <-- protocol method \
    }

// WebInspectorProxy* WebPageProxy::inspector()
//

//
// JSGlobalObjectScriptDebugServer(JSGlobalObject&)
/*!
 @function
 @abstract Sets the remote debugging name for a context.
 @param ctx The JSGlobalContext that you want to name.
 @param name The remote debugging name to set on ctx.
 */
// JS_EXPORT void JSGlobalContextSetName(JSGlobalContextRef ctx, JSStringRef name) JSC_API_AVAILABLE(macos(10.10), ios(8.0));

// JSC::Debugger::Debugger(JSC::VM&)
// JSC::Debugger::setPauseOnNextStatement(bool)
// JSC::Debugger::continueProgram()

static void* getVMFromGlobalContextRef(JSGlobalContextRef context) {
    JSC::ExecState* execState = reinterpret_cast<JSC::ExecState*>(context);
    JSC::VM* vm = execState->lexicalGlobalObject();
    
    return vm;
}

static void pauseVM(JSC::VM *vm) {
    
}

static void startVM(JSC::VM *vm) {
    
}

/*
inline JSC::ExecState* toJS(JSGlobalContextRef c)
{
    ASSERT(c);
    return reinterpret_cast<JSC::ExecState*>(c);
}
 */

/*
 @implementation JSContext (Internal)
 
 - (instancetype)initWithGlobalContextRef:(JSGlobalContextRef)context
 {
 self = [super init];
 if (!self)
 return nil;
 
 JSC::JSGlobalObject* globalObject = toJS(context)->lexicalGlobalObject();
 m_virtualMachine = [[JSVirtualMachine virtualMachineWithContextGroupRef:toRef(&globalObject->vm())] retain];
 ASSERT(m_virtualMachine);
 m_context = JSGlobalContextRetain(context);
 [self ensureWrapperMap];
 
 self.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue) {
 context.exception = exceptionValue;
 };
 
 toJSGlobalObject(m_context)->setAPIWrapper((__bridge void*)self);
 
 return self;
 }
*/

/*
 JSVirtualMachine
 
 - (void)shrinkFootprintWhenIdle
 {
 JSC::VM* vm = toJS(m_group);
 JSC::JSLockHolder locker(vm);
 vm->shrinkFootprintWhenIdle();
 }
 */

%group WebContent

%hookf(void, "__ZN6WebKit10WebProcess27handleInjectedBundleMessageERKN3WTF6StringERKNS_8UserDataE", void* _this, void* messageName /* const WTF::String& */, void* messageBody /* WebKit::UserData& */) {

    %orig(_this, messageName, messageBody);
    
    XENlog(@"UGH: messageName %p, messageBody %p", messageName, messageBody);
    
    void* key = WTF$String$fromUTF8("test");
    void* thing = API$Dictionary$getString(messageBody, key);
    
    XENlog(@"Did recieve an injected bundle message, with test: %p", thing);
    
    CFStringRef _messageNameRef = WTF$String$createCFString(messageName);
    //XENlog(@"Did recieve an injected bundle message, with name: %@", (__bridge NSString*)_messageNameRef);
}

%hookf(void, "__ZN6WebKit10WebProcess11addWebFrameEyPNS_8WebFrameE", void* _this, uint64_t frameId, void* /*WebFrame**/ webFrame) {
    %orig(_this, frameId, webFrame);
    
    bool isMainFrame = WebFrame$isMainFrame(webFrame);
    
    XENlog(@"Frame created with ID: %d, isMain: %d", frameId, isMainFrame);
    
    // JSGlobalContextRef jsContext = WebFrame$jsContext(var2);
}

%end

static bool _xenhtml_bm_validate(void *pointer, NSString *name) {
    XENlog(@"DEBUG :: %@ is%@ a valid pointer", name, pointer == NULL ? @" NOT" : @"");
    return pointer != NULL;
}


%ctor {
    %init;
    
    BOOL sb = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"];
    
    if (sb) {
        // Load stuff needed to send messages to the WebContent process
        $WKContextPostMessageToInjectedBundle = (void (*)(void*, void*, void*)) MSFindSymbol(NULL, "_WKContextPostMessageToInjectedBundle");
        $WKPageGetContext = (void* (*)(void*)) MSFindSymbol(NULL, "_WKPageGetContext");
        $WKStringCreateWithUTF8CString = (void* (*)(const char*)) MSFindSymbol(NULL, "_WKStringCreateWithUTF8CString");
        $WKMutableDictionaryCreate = (void* (*)(void)) MSFindSymbol(NULL, "_WKMutableDictionaryCreate");
        $WKDictionarySetItem = (void (*)(void*, void*, void*)) MSFindSymbol(NULL, "_WKDictionarySetItem");
        
        if (!_xenhtml_bm_validate((void*)$WKContextPostMessageToInjectedBundle, @"WKContextPostMessageToInjectedBundle"))
            return;
        if (!_xenhtml_bm_validate((void*)$WKPageGetContext, @"WKPageGetContext"))
            return;
        if (!_xenhtml_bm_validate((void*)$WKStringCreateWithUTF8CString, @"WKStringCreateWithUTF8CString"))
            return;
        if (!_xenhtml_bm_validate((void*)$WKMutableDictionaryCreate, @"WKMutableDictionaryCreate"))
            return;
        if (!_xenhtml_bm_validate((void*)$WKDictionarySetItem, @"WKDictionarySetItem"))
            return;
        
        %init(SpringBoard);
    } else {
        // WebFrame and WebPage
        WebFrame$jsContext = (JSGlobalContextRef (*)(void*)) MSFindSymbol(NULL, "__ZN6WebKit8WebFrame9jsContextEv");
        WebFrame$isMainFrame = (bool (*)(void*)) MSFindSymbol(NULL, "__ZNK6WebKit8WebFrame11isMainFrameEv");
        
        // WTF text support
        WTF$String$createCFString = (CFStringRef (*)(void*)) MSFindSymbol(NULL, "__ZNK3WTF6String14createCFStringEv");
        WTF$String$fromUTF8 = (void* (*)(const char*)) MSFindSymbol(NULL, "__ZN3WTF6String8fromUTF8EPKh");
        
        API$Dictionary$getNumber = (void* (*)(void*, void*)) MSFindSymbol(NULL, "__ZNK3API10Dictionary3getINS_6NumberIyLNS_6Object4TypeE33EEEEEPT_RKN3WTF6StringE");
        API$Dictionary$getString = (void* (*)(void*, void*)) MSFindSymbol(NULL, "__ZNK3API10Dictionary3getINS_6StringEEEPT_RKN3WTF6StringE");
        
        if (!_xenhtml_bm_validate((void*)WTF$String$createCFString, @"WTF::String::createCFString()"))
            return;
        if (!_xenhtml_bm_validate((void*)WTF$String$fromUTF8, @"WTF::String::fromUTF8"))
            return;
        if (!_xenhtml_bm_validate((void*)API$Dictionary$getNumber, @"API::Dictionary::get<number>(WTF::String)"))
            return;
        if (!_xenhtml_bm_validate((void*)API$Dictionary$getString, @"API::Dictionary::get<string>(WTF::String)"))
            return;
        
        %init(WebContent);
    }
}
