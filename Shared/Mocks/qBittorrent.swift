//
//  qBittorrent.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/9/2022.
//

import Foundation

let qBittorrentAPI = APIDescriptor(
    name: "qBittorrent v2.8.3",
    endpoint: .init(path: ["api", "v2"]),
    authentication: [
        .password(invalidCodes: [403])
    ],
    jobs: .init(
        status: [
            .seeding: ["uploading", "forcedUP"],
            .seedQueued: ["queuedUP", "stalledUP"],
            .paused: ["pausedDL", "pausedUP"],
            .downloading: ["allocating", "downloading", "metaDL"],
            .downloadQueued: ["queuedDL", "stalledDL"],
            .checkingFiles: ["checkingDL", "checkingUP", "checkingResumeData"],
            .unknown: ["unknown", "moving"],
        ]
    ),
    commands: [
        .requestToken: .init(
            request: .init(
                method: .post(
                    payload: .queryItems([
                        .init(name: "username", value: .parameter(.username)),
                        .init(name: "password", value: .parameter(.password)),
                    ])
                ),
                relativeEndpoint: .init(path: ["auth", "login"])
            )
        ),
        .fetch: .init(
            expected: .json(
                .forEach([
                    .object([
                        "added_on": .field(.adHoc(.init(name: "Date Added", type: .unixDate))),
                        "dlspeed": .field(.preset(.downloadSpeed)),
                        "downloaded": .field(.preset(.downloaded)),
                        "eta": .field(.preset(.eta)),
                        "hash": .field(.preset(.id)),
                        "name": .field(.preset(.name)),
                        "state": .field(.preset(.status)),
                        "total_size": .field(.preset(.size)),
                        "uploaded": .field(.preset(.uploaded)),
                        "upspeed": .field(.preset(.uploadSpeed)),
                    ])
                ])
            ),
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["torrents", "info"]
                )
            )
        )
    ]
)


let qBittorrentServer = Server(
    url: URL(string: "http://localhost")!,
    user: "admin",
    password: "adminadmin",
    port: 8080,
    name: "qBit",
    api: qBittorrentAPI,
    lastSeen: .init(underlying: nil)
)
