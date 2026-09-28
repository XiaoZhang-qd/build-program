import UIKit
import Network
import UniformTypeIdentifiers
import SystemConfiguration

final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

final class MainViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .systemBlue
        let a = UINavigationController(rootViewController: DashboardViewController())
        a.tabBarItem = UITabBarItem(title: "设备", image: UIImage(systemName: "iphone"), tag: 0)
        let b = UINavigationController(rootViewController: NetworkViewController())
        b.tabBarItem = UITabBarItem(title: "网络", image: UIImage(systemName: "network"), tag: 1)
        let c = UINavigationController(rootViewController: FilesViewController())
        c.tabBarItem = UITabBarItem(title: "文件", image: UIImage(systemName: "folder"), tag: 2)
        let d = UINavigationController(rootViewController: ToolsViewController())
        d.tabBarItem = UITabBarItem(title: "工具", image: UIImage(systemName: "wrench.and.screwdriver"), tag: 3)
        viewControllers = [a,b,c,d]
    }
}

final class DashboardViewController: UIViewController {
    let textView = UITextView()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WW 玩机工具"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName:"arrow.clockwise"), style:.plain, target:self, action:#selector(refresh))
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = 16
        textView.textContainerInset = UIEdgeInsets(top:18,left:16,bottom:18,right:16)
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:16),
            textView.leadingAnchor.constraint(equalTo:view.leadingAnchor,constant:14),
            textView.trailingAnchor.constraint(equalTo:view.trailingAnchor,constant:-14),
            textView.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor,constant:-16)
        ])
        refresh()
    }
    @objc func refresh() {
        let d = UIDevice.current
        d.isBatteryMonitoringEnabled = true
        let battery = d.batteryLevel >= 0 ? String(format:"%.0f%%",d.batteryLevel*100) : "未知"
        let f = FileManager.default
        let attr = try? f.attributesOfFileSystem(forPath:NSHomeDirectory())
        let total = (attr?[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free = (attr?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        let p = ProcessInfo.processInfo
        let thermal: String
        switch p.thermalState {
        case .nominal: thermal = "Nominal"
        case .fair: thermal = "Fair"
        case .serious: thermal = "Serious"
        case .critical: thermal = "Critical"
        @unknown default: thermal = "Unknown"
        }
        let up = Int(p.systemUptime)
        textView.text = """
        WW TOOLBOX
        ────────────────────────
        设备        \(d.model)
        系统        \(d.systemName) \(d.systemVersion)
        电池        \(battery)
        热状态      \(thermal)
        物理内存    \(formatBytes(Int64(p.physicalMemory)))
        存储        \(formatBytes(free)) 可用 / \(formatBytes(total))
        运行时间    \(up/3600)h \((up%3600)/60)m

        Sandbox Home
        \(NSHomeDirectory())

        Documents
        \(f.urls(for:.documentDirectory,in:.userDomainMask).first?.path ?? "-")

        Library
        \(f.urls(for:.libraryDirectory,in:.userDomainMask).first?.path ?? "-")

        tmp
        \(f.temporaryDirectory.path)

        ────────────────────────
        非越狱模式：使用公开 iOS API。
        不假装拥有 /bin/sh、根目录或系统守护进程权限。
        """
    }
}

final class NetworkViewController: UIViewController {
    let textView = UITextView()
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label:"ww.net")
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "网络诊断"
        view.backgroundColor = .systemGroupedBackground
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize:14,weight:.regular)
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = 16
        textView.textContainerInset = UIEdgeInsets(top:18,left:16,bottom:18,right:16)
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:16),
            textView.leadingAnchor.constraint(equalTo:view.leadingAnchor,constant:14),
            textView.trailingAnchor.constraint(equalTo:view.trailingAnchor,constant:-14),
            textView.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor,constant:-16)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(title:"HTTPS 测试",style:.plain,target:self,action:#selector(test))
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let type = path.usesInterfaceType(.wifi) ? "Wi‑Fi" : path.usesInterfaceType(.cellular) ? "蜂窝" : "其他"
                self?.textView.text = """
                NETWORK DIAGNOSTICS
                ────────────────────────
                状态        \(path.status == .satisfied ? "可用" : "不可用")
                接口        \(type)
                DNS         \(path.supportsDNS ? "支持" : "不支持")
                IPv4        \(path.supportsIPv4 ? "支持" : "不支持")
                IPv6        \(path.supportsIPv6 ? "支持" : "不支持")
                Low Data    \(path.isConstrained ? "ON" : "OFF")
                Expensive   \(path.isExpensive ? "YES" : "NO")
                """
            }
        }
        monitor.start(queue:queue)
    }
    @objc func test() {
        textView.text = "正在测试 HTTPS…"
        let start = Date()
        var r = URLRequest(url:URL(string:"https://www.apple.com/")!)
        r.timeoutInterval = 8
        URLSession.shared.dataTask(with:r){[weak self]_,resp,err in
            let ms = Int(Date().timeIntervalSince(start)*1000)
            DispatchQueue.main.async {
                if let h = resp as? HTTPURLResponse {
                    self?.textView.text = "HTTPS TEST\n──────────────────────\nHTTP \(h.statusCode)\nRTT  \(ms) ms\nResult OK"
                } else {
                    self?.textView.text = "HTTPS TEST\n失败：\(err?.localizedDescription ?? "Unknown")"
                }
            }
        }.resume()
    }
}

final class FilesViewController: UIViewController, UIDocumentPickerDelegate {
    let textView = UITextView()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文件工具"
        view.backgroundColor = .systemGroupedBackground
        let pick = UIButton(type:.system)
        pick.configuration = .filled()
        pick.configuration?.title = "选择文件 / 文件夹"
        pick.addTarget(self,action:#selector(openPicker),for:.touchUpInside)
        let export = UIButton(type:.system)
        export.configuration = .tinted()
        export.configuration?.title = "导出诊断信息"
        export.addTarget(self,action:#selector(exportInfo),for:.touchUpInside)
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize:13,weight:.regular)
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = 16
        textView.textContainerInset = UIEdgeInsets(top:18,left:16,bottom:18,right:16)
        textView.text = "系统文件接口\n\n• 自己的 Documents / Library / tmp\n• Files / File Provider 文档选择器\n• 用户主动授权后访问外部文件\n• 安全作用域 URL\n\n不会绕过 iOS 沙盒。"
        let s = UIStackView(arrangedSubviews:[pick,export,textView])
        s.axis = .vertical; s.spacing = 12
        view.addSubview(s); s.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            s.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:16),
            s.leadingAnchor.constraint(equalTo:view.leadingAnchor,constant:14),
            s.trailingAnchor.constraint(equalTo:view.trailingAnchor,constant:-14),
            s.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor,constant:-16)
        ])
    }
    @objc func openPicker() {
        let p = UIDocumentPickerViewController(forOpeningContentTypes:[UTType.item],asCopy:false)
        p.allowsMultipleSelection = true; p.delegate = self; present(p,animated:true)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController,didPickDocumentsAt urls:[URL]) {
        var out = "SELECTED ITEMS\n──────────────────────\n"
        for u in urls {
            let access = u.startAccessingSecurityScopedResource()
            defer { if access { u.stopAccessingSecurityScopedResource() } }
            let v = try? u.resourceValues(forKeys:[.fileSizeKey,.isDirectoryKey])
            out += "\(v?.isDirectory == true ? "DIR " : "FILE")  \(v?.fileSize.map{formatBytes(Int64($0))} ?? "-")  \(u.path)\n"
        }
        textView.text = out
    }
    @objc func exportInfo() {
        let s = "WW Toolbox\nDevice: \(UIDevice.current.model)\nSystem: \(UIDevice.current.systemVersion)\nHome: \(NSHomeDirectory())\n"
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("WW-Diagnostics.txt")
        try? s.data(using:.utf8)?.write(to:u)
        present(UIActivityViewController(activityItems:[u],applicationActivities:nil),animated:true)
    }
}

final class ToolsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "工具"
        view.backgroundColor = .systemGroupedBackground
        let a = button("LocalDevVPN / 外部工具","arrow.up.forward.app",#selector(openExternal))
        let b = button("读取剪贴板","doc.on.clipboard",#selector(readPaste))
        let c = button("复制设备诊断","doc.on.doc",#selector(copyInfo))
        let d = button("应用信息","info.circle",#selector(info))
        let s = UIStackView(arrangedSubviews:[a,b,c,d]); s.axis = .vertical; s.spacing = 14
        let card = UIView(); card.backgroundColor = .secondarySystemGroupedBackground; card.layer.cornerRadius = 18; card.addSubview(s)
        s.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([s.topAnchor.constraint(equalTo:card.topAnchor,constant:16),s.leadingAnchor.constraint(equalTo:card.leadingAnchor,constant:16),s.trailingAnchor.constraint(equalTo:card.trailingAnchor,constant:-16),s.bottomAnchor.constraint(equalTo:card.bottomAnchor,constant:-16)])
        view.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([card.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:16),card.leadingAnchor.constraint(equalTo:view.leadingAnchor,constant:14),card.trailingAnchor.constraint(equalTo:view.trailingAnchor,constant:-14)])
    }
    func button(_ t:String,_ icon:String,_ a:Selector)->UIButton {
        var c = UIButton.Configuration.tinted(); c.title = t; c.image = UIImage(systemName:icon); c.imagePadding = 10
        let b = UIButton(configuration:c); b.contentHorizontalAlignment = .leading; b.addTarget(self,action:a,for:.touchUpInside); return b
    }
    @objc func openExternal() {
        let a = UIAlertController(title:"外部工具",message:"将尝试打开 localdevvpn://。如果 LocalDevVPN 使用其他 Scheme，可在后续版本配置。",preferredStyle:.alert)
        a.addAction(UIAlertAction(title:"打开",style:.default){_ in
            if let u = URL(string:"localdevvpn://") { UIApplication.shared.open(u) }
        })
        a.addAction(UIAlertAction(title:"取消",style:.cancel))
        present(a,animated:true)
    }
    @objc func readPaste(){ show("剪贴板",UIPasteboard.general.string ?? "(无文本)") }
    @objc func copyInfo(){
        UIDevice.current.isBatteryMonitoringEnabled = true
        UIPasteboard.general.string = "Device: \(UIDevice.current.model)\nSystem: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)\nHome: \(NSHomeDirectory())"
        show("完成","设备诊断已复制。")
    }
    @objc func info(){ show("WW 玩机工具","Version 1.0.0\nBundle ID: \(Bundle.main.bundleIdentifier ?? "-")") }
    func show(_ t:String,_ m:String){let a = UIAlertController(title:t,message:m,preferredStyle:.alert);a.addAction(UIAlertAction(title:"好",style:.default));present(a,animated:true)}
}
func formatBytes(_ n:Int64)->String { ByteCountFormatter.string(fromByteCount:n,countStyle:.file) }

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
