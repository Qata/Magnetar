//
//  Server.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 18/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation

protocol Server {
    var url: URL { get }
    var name: String { get }
    func start(_ torrent: Torrent)
    func stop(_ torrent: Torrent)
}

struct AnyServer: Server {
    private let _start: (Torrent) -> Void
    private let _stop: (Torrent) -> Void
    let url: URL
    let name: String
    
    init<Base: Server>(_ base: Base) {
        url = base.url
        _start = base.start
        _stop = base.stop
        name = base.name
    }
    
    func start(_ torrent: Torrent) {
        _start(torrent)
    }
    
    func stop(_ torrent: Torrent) {
        _stop(torrent)
    }
}
