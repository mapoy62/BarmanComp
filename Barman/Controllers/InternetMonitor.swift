import Foundation
import Network

class InternetMonitor: NSObject {
    static let shared = InternetMonitor()
    
    var isConnected: Bool = true
    var conectionTypeWifi: Bool = false
    private var monitor = NWPathMonitor()
    
    private override init() {
        super.init()
        
        self.monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            self.conectionTypeWifi = path.usesInterfaceType(.wifi)
            
            NotificationCenter.default.post(name: NSNotification.Name("ConnectionStatusChanged"), object: nil)
        }
        
        monitor.start(queue:DispatchQueue.global(qos: .background))
    }