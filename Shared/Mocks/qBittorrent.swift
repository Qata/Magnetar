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
    supportedURIs: [
        .scheme(.init(value: "magnet", nameLocation: .queryItem("dn"))),
    ],
    supportedFilePathExtensions: [
        .init(value: "torrent", encoding: .bencoding),
    ],
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
        .start: .init(
            request: .init(
                method: .post(
                    payload: .queryItems([
                        .init(
                            name: "hashes",
                            value: .parameter(
                                .forEach(.id, separator: "|")
                            )
                        )
                    ])
                ),
                relativeEndpoint: .init(
                    path: ["torrents", "resume"]
                )
            )
        ),
        .pause: .init(
            request: .init(
                method: .post(
                    payload: .queryItems([
                        .init(
                            name: "hashes",
                            value: .parameter(
                                .forEach(.id, separator: "|")
                            )
                        )
                    ])
                ),
                relativeEndpoint: .init(
                    path: ["torrents", "pause"]
                )
            )
        ),
        .remove: .init(
            request: .init(
                method: .post(
                    payload: .queryItems([
                        .init(
                            name: "hashes",
                            value: .parameter(
                                .forEach(.id, separator: "|")
                            )
                        ),
                        .init(
                            name: "deleteFiles",
                            value: .parameter(
                                .bool(false)
                            )
                        )
                    ])
                ),
                relativeEndpoint: .init(path: ["torrents", "delete"])
            )
        ),
        .deleteData: .init(
            request: .init(
                method: .post(
                    payload: .queryItems([
                        .init(
                            name: "hashes",
                            value: .parameter(
                                .forEach(.id, separator: "|")
                            )
                        ),
                        .init(
                            name: "deleteFiles",
                            value: .parameter(
                                .bool(true)
                            )
                        )
                    ])
                ),
                relativeEndpoint: .init(path: ["torrents", "delete"])
            )
        ),
        .addURI: .init(
            request: .init(
                method: .post(
                    payload: .multipartFormData(
                        .init(
                            fields: [
                                .init(name: "savepath", value: .location),
                                .init(name: "urls", value: .uri),
                            ]
                        )
                    )
                ),
                relativeEndpoint: .init(path: ["torrents", "add"])
            )
        ),
        .addFile: .init(
            request: .init(
                method: .post(
                    payload: .multipartFormData(
                        .init(
                            fields: [
                                .init(name: "savepath", value: .location),
                                .init(
                                    name: "torrents",
                                    value: .file(.data(fileName: .random(extension: "torrent"))),
                                    mimeType: "application/x-bittorrent"
                                ),
                            ]
                        )
                    )
                ),
                relativeEndpoint: .init(path: ["torrents", "add"])
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
                        "save_path": .field(.adHoc(.init(name: "Location", type: .string))),
                        "state": .field(.preset(.status)),
                        "size": .field(.preset(.size)),
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
    downloadDirectories: ["/Users/charlie/Videos"],
    api: qBittorrentAPI,
    lastSeen: .init(underlying: nil)
)
