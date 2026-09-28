import UIKit
import Network
import UniformTypeIdentifiers

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = MainTabController()
        window = w
        w.makeKeyAndVisible()
        return true
    }
}

final class MainTabController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let dashboard = UINavigationController(rootViewController: DashboardVC())
        dashboard.tabBarItem = UITabBarItem(title: "概览", image: UIImage(systemName: "iphone"), tag: 0)
        let network = UINavigationController(rootViewController: NetworkVC())
        network.tabBarItem = UITabBarItem(title: "网络", image: UIImage(systemName: "network"), tag: 1)
        let devices = UINavigationController(rootViewController: DevicesVC())
        devices.tabBarItem = UITabBarItem(title: "局域网", image: UIImage(systemName: "dot.radiowaves.left.and.right"), tag: 2)
        let files = UINavigationController(rootViewController: FilesVC())
        files.tabBarItem = UITabBarItem(title: "文件", image: UIImage(systemName: "folder"), tag: 3)
        let tools = UINavigationController(rootViewController: ToolsVC())
        tools.tabBarItem = UITabBarItem(title: "工具", image: UIImage(systemName: "wrench.and.screwdriver"), tag: 4)
        viewControllers = [dashboard, network, devices, files, tools]
    }
}

final class DashboardVC: UIViewController {
    private let text = UITextView()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WW 玩机工具"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(refresh))
        text.isEditable = false
        text.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        text.backgroundColor = .secondarySystemGroupedBackground
        text.layer.cornerRadius = 18
        text.textContainerInset = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        view.addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            text.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            text.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            text.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        ])
        refresh()
    }
    @objc private func refresh() {
        let d = UIDevice.current
        d.isBatteryMonitoringEnabled = true
        let p = ProcessInfo.processInfo
        let f = FileManager.default
        let a = try? f.attributesOfFileSystem(forPath: NSHomeDirectory())
        let total = (a?[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free = (a?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        let battery = d.batteryLevel >= 0 ? String(format: "%.0f%%", d.batteryLevel * 100) : "未知"
        let thermal: String
        switch p.thermalState {
        case .nominal: thermal = "正常"
        case .fair: thermal = "轻微升温"
        case .serious: thermal = "温度较高"
        case .critical: thermal = "温度警告"
        @unknown default: thermal = "未知"
        }
        let uptime = Int(p.systemUptime)
        text.text = """
        WW 玩机工具箱
        ══════════════════════════════
        【设备】
        型号       \(d.model)
        系统       \(d.systemName) \(d.systemVersion)
        电池       \(battery)
        温度状态   \(thermal)
        物理内存   \(bytes(p.physicalMemory))
        存储空间   \(bytes(free)) 可用 / \(bytes(total)) 总计
        运行时间   \(uptime / 86400)d \((uptime % 86400) / 3600)h \((uptime % 3600) / 60)m

        【应用环境】
        Bundle ID  \(Bundle.main.bundleIdentifier ?? "-")
        Home       \(NSHomeDirectory())
        Documents  \(f.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "-")
        Library    \(f.urls(for: .libraryDirectory, in: .userDomainMask).first?.path ?? "-")
        tmp        \(f.temporaryDirectory.path)

        【这不是伪越狱】
        WW 使用 UIKit、Foundation、Network、Files 等
        系统公开接口。不会伪造 root，也不会声称能
        直接访问系统 /var、/private、其他 App 沙盒。

        【配套玩法】
        • 局域网设备发现
        • 本地 TCP 服务
        • HTTPS / DNS / IPv4 / IPv6 诊断
        • 文件选择、导入、导出
        • URL Scheme 外部工具联动
        • 剪贴板与系统分享
        """
    }
}

final class NetworkVC: UIViewController {
    private let text = UITextView()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ww.path")
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "网络 / VPN 配套"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "HTTPS", style: .plain, target: self, action: #selector(testHTTP))
        setup()
        monitor.pathUpdateHandler = { [weak self] p in
            DispatchQueue.main.async {
                let iface = p.usesInterfaceType(.wifi) ? "Wi-Fi" : p.usesInterfaceType(.cellular) ? "蜂窝" : p.usesInterfaceType(.wiredEthernet) ? "有线" : "其他"
                self?.text.text = """
                网络状态
                ══════════════════════════════
                总体       \(p.status == .satisfied ? "已连接" : "不可用")
                接口       \(iface)
                DNS        \(p.supportsDNS ? "支持" : "不支持")
                IPv4       \(p.supportsIPv4 ? "支持" : "不支持")
                IPv6       \(p.supportsIPv6 ? "支持" : "不支持")
                低数据模式 \(p.isConstrained ? "开启" : "关闭")
                计费网络   \(p.isExpensive ? "是" : "否")

                【VPN / 本地工具说明】
                iOS 第三方 App 可以观察网络路径、发起网络
                请求和连接局域网服务，但不能无授权接管系统
                VPN。真正的 VPN 控制需要 Network Extension
                能力、系统授权以及相应 entitlement。

                WW 提供的是“配套层”：可以发现局域网设备、
                连接本地服务、测试 HTTPS，并通过 URL Scheme
                把操作交给 LocalDevVPN 等专用工具。
                """
            }
        }
        monitor.start(queue: queue)
    }
    private func setup() {
        text.isEditable = false
        text.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        text.backgroundColor = .secondarySystemGroupedBackground
        text.layer.cornerRadius = 18
        text.textContainerInset = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        view.addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            text.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            text.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            text.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        ])
    }
    @objc private func testHTTP() {
        text.text = "正在测试 https://www.apple.com/ …"
        let started = Date()
        var r = URLRequest(url: URL(string: "https://www.apple.com/")!)
        r.timeoutInterval = 8
        URLSession.shared.dataTask(with: r) { [weak self] _, response, error in
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            DispatchQueue.main.async {
                if let h = response as? HTTPURLResponse {
                    self?.text.text = "HTTPS 连通性测试\n══════════════════════════════\nURL     https://www.apple.com/\nHTTP    \(h.statusCode)\nRTT     \(ms) ms\n结果    成功\n\n如果你正在使用 VPN / 本地代理，\n这个 RTT 可以作为基础连通性参考。"
                } else {
                    self?.text.text = "HTTPS 测试失败\n\(error?.localizedDescription ?? "未知错误")"
                }
            }
        }.resume()
    }
}

final class DevicesVC: UIViewController {
    private let text = UITextView()
    private var browser: NWBrowser?
    private var results: [NWBrowser.Result] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "局域网设备"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "扫描", style: .plain, target: self, action: #selector(scan))
        text.isEditable = false
        text.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        text.backgroundColor = .secondarySystemGroupedBackground
        text.layer.cornerRadius = 18
        text.textContainerInset = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        view.addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            text.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            text.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            text.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        ])
        text.text = """
        局域网设备发现
        ══════════════════════════════
        这里不是假的“扫描 IP”。

        WW 使用 Network.framework 的 NWBrowser
        发现局域网 Bonjour 服务。

        这适合：
        • LocalDevVPN / 本地开发工具
        • 手机、电脑上的 Bonjour 服务
        • NAS / 开发服务器
        • 自己运行的 HTTP / SSH / API 服务

        点击右上角“扫描”开始。
        """
    }
    @objc private func scan() {
        browser?.cancel()
        results.removeAll()
        text.text = "正在发现 _services._dns-sd._udp.local …\n\n首次使用时 iOS 可能询问“本地网络”权限。"
        let params = NWParameters()
        let b = NWBrowser(for: .bonjour(type: "_services._dns-sd._udp", domain: "local."), using: params)
        browser = b
        b.browseResultsChangedHandler = { [weak self] r, _ in
            DispatchQueue.main.async {
                self?.results = Array(r)
                self?.render()
            }
        }
        b.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                if case .failed(let e) = state {
                    self?.text.text = "局域网扫描失败：\(e)\n\n请确认“设置 → 隐私与安全性 → 本地网络”已允许 WW。"
                }
            }
        }
        b.start(queue: DispatchQueue(label: "ww.browser"))
    }
    private func render() {
        var s = "局域网 Bonjour 服务\n══════════════════════════════\n发现 \(results.count) 个服务\n\n"
        if results.isEmpty {
            s += "暂时没有发现服务。\n\n注意：很多设备不会广播 Bonjour。"
        } else {
            for (i, r) in results.enumerated() { s += "[\(i + 1)] \(r.endpoint)\n    \(r.metadata)\n\n" }
        }
        text.text = s
    }
}

final class FilesVC: UIViewController, UIDocumentPickerDelegate {
    private let text = UITextView()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文件 / 沙盒"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "导出", style: .plain, target: self, action: #selector(export)),
            UIBarButtonItem(title: "选择", style: .plain, target: self, action: #selector(pick))
        ]
        text.isEditable = false
        text.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        text.backgroundColor = .secondarySystemGroupedBackground
        text.layer.cornerRadius = 18
        text.textContainerInset = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        text.text = """
        文件工具
        ══════════════════════════════
        【App 沙盒】
        Documents：可持久化用户文件
        Library：应用配置和缓存相关目录
        tmp：临时文件

        【系统 Files】
        “选择”会调用 UIDocumentPickerViewController。
        用户主动选择文件后，WW 获得对应 security-scoped
        URL 的访问权限。

        【重要】
        非越狱 App 不能因为自己想访问就打开其他 App
        的沙盒，也不能直接读取系统根目录。
        """
        view.addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            text.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            text.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            text.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        ])
    }
    @objc private func pick() {
        let p = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: false)
        p.allowsMultipleSelection = true
        p.delegate = self
        present(p, animated: true)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var s = "已选择 \(urls.count) 项\n══════════════════════════════\n"
        for u in urls {
            let access = u.startAccessingSecurityScopedResource()
            defer { if access { u.stopAccessingSecurityScopedResource() } }
            let v = try? u.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            s += "\(v?.isDirectory == true ? "DIR " : "FILE")  \(v?.fileSize.map { bytes(Int64($0)) } ?? "-")  \(u.path)\n"
        }
        text.text = s
    }
    @objc private func export() {
        let d = UIDevice.current
        let s = "WW 玩机诊断\nDevice: \(d.model)\nSystem: \(d.systemName) \(d.systemVersion)\nHome: \(NSHomeDirectory())\nGenerated: \(Date())\n"
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("WW-Diagnostics.txt")
        try? s.data(using: .utf8)?.write(to: u)
        present(UIActivityViewController(activityItems: [u], applicationActivities: nil), animated: true)
    }
}

final class ToolsVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "实用工具"
        view.backgroundColor = .systemGroupedBackground
        let buttons = [
            button("启动 LocalDevVPN", "network.badge.shield.half.filled", #selector(localVPN)),
            button("打开自定义 URL Scheme", "arrow.up.forward.app", #selector(customURL)),
            button("读取剪贴板", "doc.on.clipboard", #selector(paste)),
            button("复制设备诊断", "doc.on.doc", #selector(copyInfo)),
            button("分享 WW 信息", "square.and.arrow.up", #selector(share)),
            button("关于 WW", "info.circle", #selector(about))
        ]
        let s = UIStackView(arrangedSubviews: buttons)
        s.axis = .vertical
        s.spacing = 12
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 20
        card.addSubview(s)
        s.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            s.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            s.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14)
        ])
    }
    private func button(_ title: String, _ icon: String, _ action: Selector) -> UIButton {
        var c = UIButton.Configuration.tinted()
        c.title = title
        c.image = UIImage(systemName: icon)
        c.imagePadding = 10
        c.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14)
        let b = UIButton(configuration: c)
        b.contentHorizontalAlignment = .leading
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }
    @objc private func localVPN() {
        let alert = UIAlertController(title: "LocalDevVPN 联动", message: "WW 会尝试通过 localdevvpn:// 把控制权交给 LocalDevVPN。\n\n注意：WW 自己不能绕过 Network Extension 权限接管系统 VPN。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "打开", style: .default) { _ in
            if let u = URL(string: "localdevvpn://") { UIApplication.shared.open(u) }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    @objc private func customURL() {
        let a = UIAlertController(title: "URL Scheme", message: "输入其他工具提供的 URL Scheme，例如 mytool://。", preferredStyle: .alert)
        a.addTextField { $0.placeholder = "mytool://" }
        a.addAction(UIAlertAction(title: "打开", style: .default) { [weak self, weak a] _ in
            guard let raw = a?.textFields?.first?.text, let u = URL(string: raw) else { return }
            UIApplication.shared.open(u)
            self?.view.endEditing(true)
        })
        a.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(a, animated: true)
    }
    @objc private func paste() { show("剪贴板", UIPasteboard.general.string ?? "没有文本") }
    @objc private func copyInfo() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        UIPasteboard.general.string = "WW Tool\nDevice: \(UIDevice.current.model)\nSystem: \(UIDevice.current.systemVersion)\nHome: \(NSHomeDirectory())"
        show("完成", "诊断信息已经复制。")
    }
    @objc private func share() {
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("WW-Info.txt")
        let s = "WW 玩机工具\nVersion 1.1.0\n\(UIDevice.current.model) / iOS \(UIDevice.current.systemVersion)\n"
        try? s.data(using: .utf8)?.write(to: u)
        present(UIActivityViewController(activityItems: [u], applicationActivities: nil), animated: true)
    }
    @objc private func about() {
        show("WW 玩机工具 1.1.0", "面向非越狱 iOS 的实用工具箱。\n\n公开 API：UIKit / Foundation / Network / Files\n\n目标：把系统真正允许第三方 App 做的事情集中到一个工具里，并与 LocalDevVPN 等工具协作。")
    }
    private func show(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "好", style: .default))
        present(a, animated: true)
    }
}

func bytes(_ value: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
}
