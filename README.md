# Clair Shell

Just some shell scripts to use [CoreOS' Clair](https://github.com/coreos/clair) on your local
Linux system. Do not use for serious production environments ;-)

## Usage

At first, index a tag that you want to be scanned:

    ./index-image.sh

Second, check the results:

    ./check-image.sh

## Running Clair locally

Notes how to run Clair locally with Docker:

    docker run -d --name postgres postgres:9.4

Get a default configuration for Clair:

    curl https://github.com/coreos/clair/blob/master/config.example.yaml > config.local.yaml

Figure out your linked PostgreSQL IP:

    docker run --link postgres ubuntu env | grep POSTGRES_PORT_5432_TCP_ADDR

Configure the `config.local.yaml` with the above IP:

    source: postgres://172.17.0.2:5432/postgres?user=postgres&sslmode=disable

Run Clair:

    docker run --link postgres -d -p 6060-6061:6060-6061 -v $(pwd):/config quay.io/coreos/clair -config=/config/config.local.yaml

Now you can use your local Clair for the analysis:

    ./index-image.sh http://localhost:6060 registry.opensource.zalan.do stups openjdk 8u77-b03-1-20
    ./check-image.sh http://localhost:6060 registry.opensource.zalan.do stups openjdk 8u77-b03-1-20

## License

Copyright (c) 2016, Tobias Sarnowski

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted,
provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
