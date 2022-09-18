//
//  Synology.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/9/2022.
//

import Foundation

let transmissionAPI = APIDescriptor(
    name: "Transmission v17",
    endpoint: .init(path: ["transmission", "rpc"]),
    supportedURIs: [
        .scheme(.init(value: "magnet", nameLocation: .queryItem("dn"))),
    ],
    supportedFilePathExtensions: [
        .init(value: "torrent", encoding: .bencoding),
    ],
    authentication: [
        .password(invalidCodes: [401]),
        .token(
            .header(
                field: "X-Transmission-Session-Id",
                code: 409
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
        .requestToken: .init(
            request: .init(
                method: .post(
                    payload: .jsonrpc(
                        .object(["method": .string("port-test")])
                    )
                )
            )
        ),
        .start: .init(
            request: .init(
                method: .post(
                    payload: .jsonrpc(
                        .object([
                            "method": .string("torrent-start-now"),
                            "arguments": .object([
                                "ids": .parameter(.forEach(.id))
                            ])
                        ])
                    )
                )
            )
        ),
        .stop: .init(
            request: .init(
                method: .post(
                    payload: .jsonrpc(
                        .object([
                            "method": .string("torrent-stop"),
                            "arguments": .object([
                                "ids": .parameter(.forEach(.id))
                            ])
                        ])
                    )
                )
            )
        ),
        .remove: .init(
            request: .init(
                method: .post(
                    payload: .jsonrpc(
                        .object([
                            "method": .string("torrent-remove"),
                            "arguments": .object([
                                "ids": .parameter(.forEach(.id))
                            ])
                        ])
                    )
                )
            )
        ),
        .deleteData: .init(
            request: .init(
                method: .post(
                    payload: .jsonrpc(
                        .object([
                            "method": .string("torrent-remove"),
                            "arguments": .object([
                                "ids": .parameter(.forEach(.id)),
                                "delete-local-data": .bool(true)
                            ])
                        ])
                    )
                )
            )
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
            request: .init(
                method: .post(
                    payload: .jsonrpc(
                        .object([
                            "method": .string("torrent-get"),
                            "arguments": .object([
                                "ids": .parameter(.forEach(.id)),
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
                    )
                )
            )
        ),
        .addURI: .init(
            expected: .json(.object([
                "result": .string("success")
            ])),
            request: .init(method: .post(
                payload: .jsonrpc(
                    .object([
                        "method": .string("torrent-add"),
                        "arguments": .object([
                            "filename": .parameter(.uri),
                            "download-dir": .parameter(.location)
                        ])
                    ])
                )
            ))
        ),
        .addFile: .init(
            expected: .json(.object([
                "result": .string("success")
            ])),
            request: .init(method: .post(
                payload: .jsonrpc(
                    .object([
                        "method": .string("torrent-add"),
                        "arguments": .object([
                            "metainfo": .parameter(.file(.base64)),
                            "download-dir": .parameter(.location)
                        ])
                    ])
                )
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
