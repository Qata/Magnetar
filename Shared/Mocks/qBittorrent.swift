//
//  qBittorrent.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 16/9/2022.
//

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
            request: .post(
                relativeEndpoint: .init(path: ["torrents", "info"]),
                payload: .jsonrpc(
                    .object([:])
                )
            )
        )
    ]
)
