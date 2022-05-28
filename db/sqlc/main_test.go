package db

import (
	"database/sql"
	"log"
	"os"
	"testing"

	_ "github.com/go-sql-driver/mysql"
)

const (
	dbDriver = "mysql"
	dbSource = "dev:123456@tcp(localhost:3308)/simple_bank?parseTime=true"
)

var testQuries *Queries

func TestMain(m *testing.M) {
	conn, err := sql.Open(dbDriver, dbSource)
	if err != nil {
		log.Fatal("cannot connect to database: ", err)
	}

	testQuries = New(conn)

	os.Exit(m.Run())
}
