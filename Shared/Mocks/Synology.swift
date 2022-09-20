//
//  Mocks.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import Foundation

let synologyAPI = APIDescriptor(
    name: "Synology ",
    endpoint: .init(
        path: ["webapi"]
    ),
    supportedURIs: [
        .scheme(.init(value: "magnet", nameLocation: .queryItem("dn"))),
        .scheme(.init(value: "ftp", nameLocation: .lastPathComponent)),
        .scheme(.init(value: "thunder")),
        .scheme(.init(value: "qqdl")),
        .scheme(.init(value: "flashget")),
        .scheme(.init(value: "ed2k"))
    ],
    supportedFilePathExtensions: [
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
//        .requestToken: .init(
//            request: .init(
//                method: .get,
//                relativeEndpoint: .init(
//                    path: ["query.cgi"],
//                    queryItems: .init(
//                        queryItems: [
//                            .init(name: "api", value: "SYNO.API.Info"),
//                            .init(name: "version", value: "1"),
//                            .init(name: "method", value: "query"),
//                            .init(name: "query", value: "SYNO.API.Auth,SYNO.DownloadStation.Task"),
//                        ]
//                    )
//                )
//            )
//        ),
        // https://github.com/Sonarr/Sonarr/issues/3943#issuecomment-706807653
        .requestToken: .init(
            expected: .json(
                .object(["success": .bool(true)])
            ),
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["entry.cgi"],
                    queryItems: .init(
                        queryItems: [
                            .init(name: "api", value: "SYNO.API.Auth"),
                            .init(name: "version", value: "3"),
                            .init(name: "method", value: "login"),
                            .init(name: "account", value: .parameter(.username)),
                            .init(name: "passwd", value: .parameter(.password)),
                            .init(name: "session", value: "DownloadStation"),
                        ]
                    )
                )
            )
        ),
        .start: .init(
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["task.cgi"],
                    queryItems: [
                        .init(name: "api", value: "SYNO.DownloadStation.Task"),
                        .init(name: "version", value: "1"),
                        .init(name: "method", value: "resume"),
                        .init(name: "id", value: .parameter(.forEach(.id, separator: ","))),
                    ]
                )
            )
        ),
        .stop: .init(
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["task.cgi"],
                    queryItems: [
                        .init(name: "api", value: "SYNO.DownloadStation.Task"),
                        .init(name: "version", value: "1"),
                        .init(name: "method", value: "pause"),
                        .init(name: "id", value: .parameter(.forEach(.id, separator: ","))),
                    ]
                )
            )
        ),
        .addURI: .init(
            request: .init(
                method: .post(
                    payload: .queryItems([
                        .init(name: "api", value: "SYNO.DownloadStation.Task"),
                        .init(name: "version", value: "3"),
                        .init(name: "method", value: "create"),
                        .init(name: "uri", value: .parameter(.uri)),
                        .init(name: "destination", value: .parameter(.location)),
                    ])
                ),
                relativeEndpoint: .init(
                    path: ["task.cgi"]
                )
            )
        ),
        .remove: .init(
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["task.cgi"],
                    queryItems: [
                        .init(name: "api", value: "SYNO.DownloadStation.Task"),
                        .init(name: "version", value: "1"),
                        .init(name: "method", value: "delete"),
                        .init(name: "id", value: .parameter(.forEach(.id, separator: ","))),
                    ]
                )
            )
        ),
        .fetch: .init(
            expected: .json(
                .object([
                    "data": .object([
                        "tasks": .forEach([
                            .object([
                                "id": .field(.preset(.id)),
                                "title": .field(.preset(.name)),
                                "size": .field(.preset(.size)),
                                "status": .field(.preset(.status)),
                                "additional": .object([
                                    "detail": .object([
                                        "create_time": .field(
                                            .adHoc(.init(
                                                name: "Date Added",
                                                type: .unixDate
                                            ))
                                        )
                                    ]),
                                    "transfer": .object([
                                        "size_downloaded": .field(.preset(.downloaded)),
                                        "size_uploaded": .field(.preset(.uploaded)),
                                        "speed_download": .field(.preset(.downloadSpeed)),
                                        "speed_upload": .field(.preset(.uploadSpeed)),
                                    ])
                                ]),
                            ])
                        ])
                    ])
                ])
            ),
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["DownloadStation", "task.cgi"],
                    queryItems: [
                        .init(name: "api", value: "SYNO.DownloadStation.Task"),
                        .init(name: "version", value: "1"),
                        .init(name: "method", value: "list"),
                        .init(name: "additional", value: "detail,transfer,file")
                    ]
                )
            )
        )
    ]
)

let synologyServer = Server(
    url: URL(string: "http://atextech.com")!,
    user: "Magnetar",
    password: "Sixcyf-7dehwa-jabvex",
    port: 6192,
    name: "Synology",
    api: synologyAPI
)
