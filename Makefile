.PHONY: mariadb createdb dropdb migrateup migratedown

mariadb:
	docker run --detach --name mariadb -p 3308:3306 -e MARIADB_USER=dev -e MARIADB_PASSWORD=123456 -e MARIADB_ROOT_PASSWORD=QazMlp123  mariadb:latest

createdb:
	docker exec -it mariadb mysql -u root -pQazMlp123 -e "CREATE DATABASE simple_bank; GRANT ALL PRIVILEGES ON simple_bank.* TO dev@'%' IDENTIFIED BY '123456';"

dropdb:
	docker exec -it mariadb mysql -u dev -p123456 -e "DROP DATABASE simple_bank"

migrateup:
	migrate -path db/migration -database "mysql://dev:123456@tcp(localhost:3308)/simple_bank" -verbose up

migratedown:
	migrate -path db/migration -database "mysql://dev:123456@tcp(localhost:3308)/simple_bank" -verbose down
