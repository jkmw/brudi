BINARY_NAME = brudi
COMMIT_HASH = $(shell git rev-parse --verify HEAD)
CURDIR = $(shell pwd)

all: test lint build

build:
	go build \
		-ldflags " \
			-s \
			-w \
			-X \
				'github.com/mittwald/brudi/cmd.tag=$(COMMIT_HASH)' \
		" \
		-o $(BINARY_NAME) \
		-a main.go

test:
	go test -v ./...

lintpull:
	docker pull -q golangci/golangci-lint

lint: lintpull
	docker run --rm -v $(CURDIR):/app -w /app golangci/golangci-lint golangci-lint run -v

lintfix: lintpull
	docker run --rm -v $(CURDIR):/app -w /app golangci/golangci-lint golangci-lint run -v --fix

goreleaser:
	curl -sL https://git.io/goreleaser | bash -s -- --snapshot --skip-publish --rm-dist

upTestMongo: downTestMongo
	trap 'cd $(CURDIR) && make downTestMongo' 0 1 2 3 6 9 15
	docker-compose --file example/docker-compose/mongo.yml --env-file "nothing" up -d

downTestMongo:
	docker-compose --file example/docker-compose/mongo.yml --env-file "nothing" down -v

upTestMysql: downTestMysql
	trap 'cd $(CURDIR) && make downTestMysql' 0 1 2 3 6 9 15
	docker-compose --file example/docker-compose/mysql.yml --env-file "nothing" up -d

downTestMysql:
	docker-compose --file example/docker-compose/mysql.yml --env-file "nothing" down -v