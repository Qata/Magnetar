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
    supportedJobLocators: [
        .scheme("magnet"),
        .pathExtension("torrent"),
    ],
    authentication: [
        .basic,
        .token(
            .header(
                field: "X-Transmission-Session-Id",
                code: 409
            )
        )
    ],
    errors: [
        .init(
            type: .password,
            codes: [401]
        ),
        .init(
            type: .forbidden,
            codes: [403]
        )
    ],
    jobs: .init(
        status: [
            .stopped: [0],
            .seeding: [6],
            .downloading: [4],
            .queued: [3, 5],
            .checkingFiles: [2],
            .fileCheckQueued: [1]
        ]
    ),
    commands: [
        .login: .init(
            request: .init(
                method: .post(
                    payload: .json(
                        .object(["method": .string("port-test")])
                    )
                )
            )
        ),
        .start: .init(
            request: .init(
                method: .post(
                    payload: .json(
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
                    payload: .json(
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
                    payload: .json(
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
                    payload: .json(
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
                            "hashString": .parameter(.field(.preset(.id))),
                            "name": .parameter(.field(.preset(.name))),
                            "status": .parameter(.field(.preset(.status))),
                            "rateUpload": .parameter(.field(.preset(.uploadSpeed))),
                            "rateDownload": .parameter(.field(.preset(.downloadSpeed))),
                            "uploadedEver": .parameter(.field(.preset(.uploaded))),
                            "downloadedEver": .parameter(.field(.preset(.downloaded))),
                            "sizeWhenDone": .parameter(.field(.preset(.size))),
                            "eta": .parameter(.field(.preset(.eta))),
                            "errorString": .parameter(.field(.adHoc(.init(name: "Error", type: .string)))),
                            "addedDate": .parameter(.field(.adHoc(.init(name: "Date Added", type: .unixDate)))),
                            "doneDate": .parameter(.field(.adHoc(.init(name: "Date Finished", type: .unixDate)))),
                            "downloadDir": .parameter(.field(.adHoc(.init(name: "Download Directory", type: .string)))),
                            "isStalled": .parameter(.field(.adHoc(.init(name: "Stalled", type: .bool)))),
                            "queuePosition": .parameter(.field(.adHoc(.init(name: "Queue Position", type: .int)))),
                            "comment": .parameter(.field(.adHoc(.init(name: "Comment", type: .string)))),
                        ])
                    ])
                ])
            ])),
            request: .init(
                method: .post(
                    payload: .json(
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
                payload: .json(
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
                payload: .json(
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
    url: URL(string: "http://mini.local")!,
    user: "lotte",
    password: "lol",
    port: 9091,
    name: "Home2",
    destinations: [
        "/Volumes/Storage/Entertainment/Series",
        "/Volumes/Storage/Entertainment/Movies"
    ],
    api: transmissionAPI
)
