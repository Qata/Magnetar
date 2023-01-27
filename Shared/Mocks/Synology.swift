//
//  Mocks.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

import Foundation

let synologyAPI = APIDescriptor(
    name: "Synology",
    endpoint: .init(
        path: ["webapi"]
    ),
    supportedJobLocators: [
        .scheme("magnet"),
        .scheme("ftp"),
        .scheme("thunder"),
        .scheme("qqdl"),
        .scheme("flashget"),
        .scheme("ed2k"),
        .pathExtension("torrent"),
        .pathExtension("nzb"),
        .pathExtension("txt"),
    ],
    authentication: [
        
    ],
    errors: [
    ],
    jobs: .init(
        status: [
            .seeding: ["seeding"],
            .queued: ["waiting"],
            .paused: ["paused", "finished"],
            .downloading: ["downloading"],
            .checkingFiles: [],
            .unknown: [],
        ]
    ),
    commands: [
        // https://github.com/Sonarr/Sonarr/issues/3943#issuecomment-706807653
        .login: .init(
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
        .info: .init(
            expected: .json(
                .object([
                    "data": .object([
                        "default_destination": .parameter(.destination)
                    ]),
                    "success": .bool(true)
                ])
            ),
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["DownloadStation", "info.cgi"],
                    queryItems: [
                        .init(name: "api", value: "SYNO.DownloadStation.Info"),
                        .init(name: "version", value: "1"),
                        .init(name: "method", value: "getconfig"),
                    ]
                )
            )
        ),
        .start: .init(
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["DownloadStation", "task.cgi"],
                    queryItems: [
                        .init(name: "api", value: "SYNO.DownloadStation.Task"),
                        .init(name: "version", value: "1"),
                        .init(name: "method", value: "resume"),
                        .init(name: "id", value: .parameter(.forEach(.id, separator: ","))),
                    ]
                )
            )
        ),
        .pause: .init(
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["DownloadStation", "task.cgi"],
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
                    path: ["DownloadStation", "task.cgi"]
                )
            )
        ),
        .addFile: .init(
            request: .init(
                method: .post(
                    payload: .multipartFormData(
                        .init(
                            fields: [
                                .init(name: "api", value: "SYNO.DownloadStation2.Task"),
                                .init(name: "method", value: "create"),
                                .init(name: "version", value: "2"),
                                .init(name: "type", value: .quoted(value: .string("file"), quotationMark: #"""#)),
                                .init(name: "file", value: #"["torrent"]"#),
                                .init(name: "destination", value: .quoted(value: .location, quotationMark: #"""#)),
                                .init(name: "create_list", value: .bool(false)),
                                .init(
                                    name: "torrent",
                                    value: .file(.data(fileName: .random(extension: "torrent"))),
                                    mimeType: "application/x-bitfileType"
                                )
                            ]
                        )
                    )
                ),
                relativeEndpoint: .init(
                    path: ["entry.cgi", "SYNO.DownloadStation2.Task"]
                )
            )
        ),
        .remove: .init(
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["DownloadStation", "task.cgi"],
                    queryItems: [
                        .init(name: "api", value: "SYNO.DownloadStation.Task"),
                        .init(name: "version", value: "1"),
                        .init(name: "method", value: "delete"),
                        .init(name: "force_complete", value: "false"),
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
                                "id": .parameter(.field(.preset(.id))),
                                "title": .parameter(.field(.preset(.name))),
                                "size": .parameter(.field(.preset(.size))),
                                "status": .parameter(.field(.preset(.status))),
                                "additional": .object([
                                    "detail": .object([
                                        "create_time": .parameter(
                                            .field(
                                                .adHoc(.init(
                                                    name: "Date Added",
                                                    type: .unixDate
                                                ))
                                            )
                                        )
                                    ]),
                                    "transfer": .object([
                                        "size_downloaded": .parameter(.field(.preset(.downloaded))),
                                        "size_uploaded": .parameter(.field(.preset(.uploaded))),
                                        "speed_download": .parameter(.field(.preset(.downloadSpeed))),
                                        "speed_upload": .parameter(.field(.preset(.uploadSpeed))),
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
                        .init(name: "additional", value: "detail,transfer")
                    ]
                )
            )
        )
    ]
)
