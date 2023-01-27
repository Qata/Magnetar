//
//  rTorrent.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 15/12/2022.
//

let rTorrentXmlRpcApi = APIDescriptor(
    name: "rTorrent",
    endpoint: .init(path: ["RPC2"]),
    supportedJobLocators: [
        .scheme("magnet"),
        .pathExtension("torrent"),
    ],
    authentication: [],
    errors: [],
    jobs: .init(
//        { PAUSING = 0,
//               STARTED = 1,
//               PAUSED = 1 << 1,
//               CHECKING = 1 << 2,
//               HASHING = 1 << 3,
//               ERROR = 1 << 4 }
        status: [
            .paused: [0, 2],
            .seeding: [],
            .downloading: [1],
            .queued: [],
            .checkingFiles: [4],
            .fileCheckQueued: []
        ]
    ),
    commands: [
        .fetch: .init(
            expected: .xmlRpc(.params([
                .forEach([
                    .array([
                        .parameter(.field(.preset(.id))),
                        .parameter(.field(.preset(.status))),
                        .parameter(.field(.preset(.name))),
                        .parameter(.field(.preset(.downloadSpeed))),
                        .parameter(.field(.preset(.uploadSpeed))),
                        .parameter(.field(.preset(.downloaded))),
                        .parameter(.field(.preset(.uploaded))),
                        .parameter(.field(.preset(.size))),
                        .parameter(.field(.adHoc(.init(name: "Creation Date", type: .unixDate))))
                    ])
                ])
            ])),
            request: .init(
                method: .post(
                    payload: .xmlRpc(
                        method: "d.multicall",
                        params: [
                            .string("main"),
                            .string("d.get_hash="),
                            .string("d.get_state="),
                            .string("d.get_name="),
                            .string("d.get_down_rate="),
                            .string("d.get_up_rate="),
                            .string("d.get_bytes_done="),
                            .string("d.get_up_total="),
                            .string("d.get_size_bytes="),
                            .string("d.get_creation_date="),
                        ]
                    )
                )
            )
        ),
    ]
)
