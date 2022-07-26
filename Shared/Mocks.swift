//
//  Mocks.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import Foundation

let transmissionEndpoint = EndpointDescriptor(path: ["transmission", "rpc"])

let transmissionAPI = APIDescriptor(
    authentication: [
        .password(invalidCode: 401),
        .token(
            .header(
                field: "X-Transmission-Session-Id",
                code: 409,
                request: .jsonrpc(.post(
                    endpoint: transmissionEndpoint,
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
                endpoint: transmissionEndpoint,
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
                endpoint: transmissionEndpoint,
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
                endpoint: transmissionEndpoint,
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
                endpoint: transmissionEndpoint,
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
                            "doneDate": .field(.adHoc(.init(name: "Done Date", type: .unixDate))),
                        ])
                    ])
                ])
            ])),
            request: .jsonrpc(.post(
                endpoint: transmissionEndpoint,
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
                            .string("doneDate"),
                            .string("errorString"),
                        ])
                    ])
                ])
            ))
        ),
    ]
)

let transmissionServer = Server(
    url: URL(string: "http://mini.local")!,
    user: "lotte",
    password: "lol",
    port: 9091,
    name: "Home",
    api: transmissionAPI
)
