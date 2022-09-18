//
//  Mocks.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 9/2/22.
//

let synologyAPI = APIDescriptor(
    name: "Synology 3.2",
    endpoint: .init(
        path: ["webapi"],
        queryItems: [
            .init(
                name: "_sid",
                value: .parameter(.token)
            )
        ]
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
        .requestToken: .init(
            expected: .json(
                .object([
                    "data": .object([
                        "sid": .token
                    ])
                ])
            ),
            request: .init(
                method: .get,
                relativeEndpoint: .init(
                    path: ["auth.cgi"],
                    queryItems: .init(
                        queryItems: [
                            .init(name: "api", value: "SYNO.API.Auth"),
                            .init(name: "version", value: "2"),
                            .init(name: "method", value: "login"),
                            .init(name: "account", value: .parameter(.username)),
                            .init(name: "passwd", value: .parameter(.password)),
                            .init(name: "session", value: "Magnetar"),
                            .init(name: "format", value: "sid")
                        ]
                    )
                )
            )
        )
    ]
)
