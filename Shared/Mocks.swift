//
//  Mocks.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import Foundation

let transmissionEndpoint = EndpointDescriptor(path: ["transmission", "rpc"])

let qBittorrentAPI = APIDescriptor(
    name: "qBittorrent v2.8.3",
    endpoint: .init(path: ["api", "v2"]),
    authentication: [
        .password(invalidCodes: [403])
    ],
    jobs: .init(
        status: [
            .seedQueued: ["queuedUP", "stalledUP"],
            .paused: ["pausedDL", "pausedUP"],
            .downloading: ["downloading", ""],
            .downloadQueued: ["queuedDL", "allocating", "metaDL", "stalledDL"],
            .checkingFiles: ["checkingDL", "checkingUP", "checkingResumeData"],
            .unknown: ["unknown", "moving"],
        ]
    ),
    commands: [
        .fetch: .init(
            expected: .json(
                .array([])
            ),
            request: .jsonrpc(
                .post(
                    relativeEndpoint: .init(path: ["torrents", "info"]),
                    payload: .object([:])
                )
            )
        )
    ]
)

let synologyAPI = APIDescriptor(
    name: "Synology",
    endpoint: .init(path: ["webapi", "v2"]),
    supportedURIs: [
        .scheme(.init(value: "magnet", nameLocation: .queryItem("dn"))),
        .scheme(.init(value: "ftp", nameLocation: .lastPathComponent)),
        .scheme(.init(value: "thunder")),
        .scheme(.init(value: "qqdl")),
        .scheme(.init(value: "flashget")),
        .scheme(.init(value: "ed2k"))
    ],
    supportedPathExtensions: [
        .init(value: "torrent", encoding: .bencoding),
        .init(value: "nzb", encoding: .xml),
        .init(value: "txt", encoding: .newLineSeparated),
    ],
    authentication: [
    ],
    jobs: .init(
        status: [
            .seedQueued: [],
            .paused: [],
            .downloading: ["downloading"],
            .downloadQueued: [],
            .checkingFiles: [],
            .unknown: [],
        ]
    ),
    commands: [
        :
    ]
)

let transmissionAPI = APIDescriptor(
    name: "Transmission v17",
    endpoint: .init(path: ["transmission", "rpc"]),
    supportedURIs: [
        .scheme(.init(value: "magnet", nameLocation: .queryItem("dn"))),
    ],
    supportedPathExtensions: [
        .init(value: "torrent", encoding: .bencoding),
    ],
    authentication: [
        .password(invalidCodes: [401]),
        .token(
            .header(
                field: "X-Transmission-Session-Id",
                code: 409,
                request: .jsonrpc(.post(
                    payload: .object(["method": .string("port-test")])
                ))
            )
        )
    ],
    jobs: .init(
        status: [
            .stopped: [0],
            .seeding: [6],
            .downloading: [4],
            .downloadQueued: [3],
            .seedQueued: [5],
            .checkingFiles: [2],
            .fileCheckQueued: [1]
        ]
    ),
    commands: [
        .start: .init(
            expected: .json(.object([
                "arguments": .object([:])
            ])),
            request: .jsonrpc(.post(
                payload: .object([
                    "method": .string("torrent-start-now"),
                    "arguments": .object([
                        "ids": .forEach(.id)
                    ])
                ])
            ))
        ),
        .stop: .init(
            expected: .json(.object([
                "arguments": .object([:])
            ])),
            request: .jsonrpc(.post(
                payload: .object([
                    "method": .string("torrent-stop"),
                    "arguments": .object([
                        "ids": .forEach(.id)
                    ])
                ])
            ))
        ),
        .remove: .init(
            expected: .json(.object([
                "arguments": .object([:])
            ])),
            request: .jsonrpc(.post(
                payload: .object([
                    "method": .string("torrent-remove"),
                    "arguments": .object([
                        "ids": .forEach(.id)
                    ])
                ])
            ))
        ),
        .deleteData: .init(
            expected: .json(.object([
                "arguments": .object([:])
            ])),
            request: .jsonrpc(.post(
                payload: .object([
                    "method": .string("torrent-remove"),
                    "arguments": .object([
                        "ids": .forEach(.id),
                        "delete-local-data": .bool(true)
                    ])
                ])
            ))
        ),
        .fetch: .init(
            expected: .json(.object([
                "arguments": .object([
                    "torrents": .forEach([
                        .object([
                            "hashString": .field(.preset(.id)),
                            "name": .field(.preset(.name)),
                            "status": .field(.preset(.status)),
                            "rateUpload": .field(.preset(.uploadSpeed)),
                            "rateDownload": .field(.preset(.downloadSpeed)),
                            "uploadedEver": .field(.preset(.uploaded)),
                            "downloadedEver": .field(.preset(.downloaded)),
                            "sizeWhenDone": .field(.preset(.size)),
                            "eta": .field(.preset(.eta)),
                            "errorString": .field(.adHoc(.init(name: "Error", type: .string))),
                            "addedDate": .field(.adHoc(.init(name: "Date Added", type: .unixDate))),
                            "doneDate": .field(.adHoc(.init(name: "Date Finished", type: .unixDate))),
                            "downloadDir": .field(.adHoc(.init(name: "Download Directory", type: .string))),
                            "isStalled": .field(.adHoc(.init(name: "Stalled", type: .bool))),
                            "queuePosition": .field(.adHoc(.init(name: "Queue Position", type: .int))),
                            "comment": .field(.adHoc(.init(name: "Comment", type: .string))),
                        ])
                    ])
                ])
            ])),
            request: .jsonrpc(.post(
                payload: .object([
                    "method": .string("torrent-get"),
                    "arguments": .object([
                        "ids": .forEach(.id),
                        "fields": .array([
                            .string("hashString"),
                            .string("name"),
                            .string("status"),
                            .string("rateUpload"),
                            .string("rateDownload"),
                            .string("uploadedEver"),
                            .string("downloadedEver"),
                            .string("sizeWhenDone"),
                            .string("eta"),
                            .string("errorString"),
                            .string("addedDate"),
                            .string("doneDate"),
                            .string("downloadDir"),
                            .string("isStalled"),
                            .string("queuePosition"),
                            .string("comment"),
                        ])
                    ])
                ])
            ))
        ),
        .addURI: .init(
            expected: .json(.object([
                "result": .string("success")
            ])),
            request: .jsonrpc(.post(
                payload: .object([
                    "method": .string("torrent-add"),
                    "arguments": .object([
                        "filename": .uri,
                        "download-dir": .location
                    ])
                ])
            ))
        ),
        .addFile: .init(
            expected: .json(.object([
                "result": .string("success")
            ])),
            request: .jsonrpc(.post(
                payload: .object([
                    "method": .string("torrent-add"),
                    "arguments": .object([
                        "metainfo": .file(.base64),
                        "download-dir": .location
                    ])
                ])
            ))
        )
    ]
)

let transmissionServer = Server(
    url: URL(string: "http://192.168.20.21")!,
    user: "lotte",
    password: "lol",
    port: 9091,
    name: "Home",
    downloadDirectories: [
        "/Volumes/Storage/Entertainment/Series",
        "/Volumes/Storage/Entertainment/Movies"
    ],
    api: transmissionAPI,
    lastSeen: .init(underlying: nil)
)

let transmissionServer2 = Server(
    url: URL(string: "http://192.168.20.21")!,
    user: "lotte",
    password: "lol",
    port: 9091,
    name: "Away",
    api: transmissionAPI,
    lastSeen: .init(underlying: nil)
)
