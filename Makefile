DB_URL=postgresql://local:local_secret07@postgresql-primary.codeplayer.org:5432/simple_bank_dev?sslmode=disable
DB_URL_CI=postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable

.PHONY: postgres createdb dropdb redis docker migrateup migratedown migrateup1 migratedown1 new_migration db_docs db_schema sqlc test server mock proto evans

postgres:
	docker run --name postgres --network bank-network -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:latest

createdb:
	docker exec -it postgres createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres dropdb simple_bank

redis:
	docker run  --name redis -p 6379:6379 -d redis:7-alpine

docker:
	docker buildx build --push --platform linux/amd64,linux/arm64 -t patrickz07/simple-bank:latest .

migrateup:
	migrate -path db/migration -database "${DB_URL}" -verbose up

migrateup_ci:
	migrate -path db/migration -database "${DB_URL_CI}" -verbose up

migrateup1:
	migrate -path db/migration -database "${DB_URL}" -verbose up 1

migratedown:
	migrate -path db/migration -database "${DB_URL}" -verbose down

migratedown1:
	migrate -path db/migration -database "${DB_URL}" -verbose down 1

new_migration:
	migrate create -ext sql -dir db/migration -seq $(name)

db_docs:
	dbdocs build doc/db.dbml

db_schema:
	dbml2sql --postgres -o doc/schema.sql doc/db.dbml

sqlc:
	sqlc generate

test:
	go test -v -cover -short ./...

server:
	go run main.go

mock:
	mockgen --build_flags=--mod=mod -package mockdb -destination db/mock/store.go github.com/PetrusZ/simplebank/db/sqlc Store
	mockgen --build_flags=--mod=mod -package mockwk -destination worker/mock/distributor.go github.com/PetrusZ/simplebank/worker TaskDistributor

evans:
	evans -r repl --host localhost --port 9090

proto:
	rm -rf pb/*.go
	rm -f doc/swagger/*.swagger.json
	protoc --proto_path=proto --go_out=pb --go_opt=paths=source_relative \
    --go-grpc_out=pb --go-grpc_opt=paths=source_relative \
	--grpc-gateway_out=pb --grpc-gateway_opt=paths=source_relative \
	--openapiv2_out=doc/swagger --openapiv2_opt=allow_merge=true,merge_file_name=simple_bank \
    proto/*.proto
	statik -src=./doc/swagger -dest=./doc
