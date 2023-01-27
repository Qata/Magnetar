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
    supportedJobLocators: [
        .scheme("magnet"),
        .pathExtension("torrent"),
    ],
    authentication: [
    ],
    errors: [
        .init(type: .password, codes: [403])
    ],
    jobs: .init(
        status: [
            .seeding: ["uploading", "forcedUP"],
            .queued: ["queuedUP", "stalledUP", "queuedDL", "stalledDL"],
            .paused: ["pausedDL", "pausedUP"],
            .downloading: ["allocating", "downloading", "metaDL"],
            .checkingFiles: ["checkingDL", "checkingUP", "checkingResumeData"],
            .unknown: ["unknown", "moving"],
        ]
    ),
    commands: [
        .login: .init(
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
                        "added_on": .parameter(.field(.adHoc(.init(name: "Date Added", type: .unixDate)))),
                        "dlspeed": .parameter(.field(.preset(.downloadSpeed))),
                        "downloaded": .parameter(.field(.preset(.downloaded))),
                        "eta": .parameter(.field(.preset(.eta))),
                        "hash": .parameter(.field(.preset(.id))),
                        "name": .parameter(.field(.preset(.name))),
                        "save_path": .parameter(.field(.adHoc(.init(name: "Location", type: .string)))),
                        "state": .parameter(.field(.preset(.status))),
                        "size": .parameter(.field(.preset(.size))),
                        "uploaded": .parameter(.field(.preset(.uploaded))),
                        "upspeed": .parameter(.field(.preset(.uploadSpeed))),
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
    destinations: ["/Users/charlie/Videos"],
    api: qBittorrentAPI,
    lastSeen: .init(underlying: nil)
)
