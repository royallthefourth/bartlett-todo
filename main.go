package main

import (
	"database/sql"
	_ "github.com/go-sql-driver/mysql"
	m "github.com/golang-migrate/migrate"
	"github.com/golang-migrate/migrate/database/mysql"
	psh "github.com/platformsh/gohelper"
	"github.com/royallthefourth/bartlett"
	"github.com/royallthefourth/bartlett/mariadb"
	"log"
	"math/rand"
	"net/http"
	"os"
	"time"
)

func main() {
	rand.Seed(time.Now().UnixNano())
	i, _ := psh.NewPlatformInfo()
	dsn, _ := i.SqlDsn(`todo`)

	db, err := sql.Open(`mysql`, dsn)
	if err != nil {
		panic(err)
	}

	switch os.Args[0] {
	case `serve`:
		serve(db, i.Port)
	case `truncate`:
		truncate(db)
	case `migrate`:
		migrate(db)
	default:
		log.Fatalln(`You must specify serve, truncate, or migrate`)
	}
}

func serve(db *sql.DB, port string) {
	tables := []bartlett.Table{
		{
			Name:   `students`,
			UserID: `user_id`, // Requests will only return rows corresponding to their ID for this table.
		},
	}

	routes, handlers := bartlett.
		Bartlett{DB: db, Driver: &mariadb.MariaDB{}, Tables: tables, Users: dummyUserProvider}.
		Routes()
	for i, route := range routes {
		http.HandleFunc(`/api`+route, handlers[i]) // Adds /api/students to the server.
	}

	http.Handle(`/`, http.FileServer(http.Dir(`static`)))
	log.Println(`starting server`)
	log.Fatal(http.ListenAndServe(`:`+port, nil))
}

func truncate(conn *sql.DB) {
	_, err := conn.Exec(`TRUNCATE TABLE todo`)
	if err != nil {
		log.Fatalf(`truncate failed: %s`, err.Error())
	}
	log.Println(`Truncated todo table.`)
}

func migrate(conn *sql.DB) {
	drv, err := mysql.WithInstance(conn, &mysql.Config{})
	if err != nil {
		log.Fatalf(`could not create migration driver: %s`, err.Error())
	}

	migrator, err := m.NewWithDatabaseInstance("file://migrations", "mysql", drv)
	if err != nil {
		log.Fatalf(`could not create migration system: %s`, err.Error())
	}

	err = migrator.Up()
	if err != nil {
		log.Fatalf(`could not run migrations: %s`, err.Error())
	}
}

const letters = `abcdefghijklmnopqrstuvwxyz1234567890`

func newID() string {
	b := make([]byte, 12)
	for i := range b {
		b[i] = letters[rand.Intn(36)]
	}
	return string(b)
}
