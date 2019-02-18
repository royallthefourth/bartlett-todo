package main

import (
	"database/sql"
	"fmt"
	"github.com/alexedwards/scs"
	"github.com/alexedwards/scs/stores/memstore"
	"github.com/go-http-utils/logger"
	_ "github.com/go-sql-driver/mysql"
	m "github.com/golang-migrate/migrate"
	"github.com/golang-migrate/migrate/database/mysql"
	_ "github.com/golang-migrate/migrate/source/file"
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
	var dsn, port string
	if os.Getenv(`PLATFORM_PROJECT`) != `` {
		i, _ := psh.NewPlatformInfo()
		dsn, _ = i.SqlDsn(`database`)
		port = i.Port
	} else {
		dsn = fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8", os.Getenv(`DB_USER`), os.Getenv(`DB_PASS`), `127.0.0.1`, 3306, `todo`)
		port = `8080`
	}

	db, err := sql.Open(`mysql`, dsn)
	if err != nil {
		panic(err)
	}
	db.SetConnMaxLifetime(time.Minute * 2)

	switch os.Args[1] {
	case `serve`:
		serve(db, port)
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
			Name:     `todo`,
			UserID:   `user_id`, // Requests will only return rows corresponding to their ID for this table.
			Writable: true,
		},
	}

	sess := scs.NewManager(memstore.New(time.Hour * 48))
	userProvider := func(r *http.Request) (interface{}, error) {
		return sess.Load(r).GetString(`user_id`)
	}

	sessWrap := func(h func(http.ResponseWriter, *http.Request)) func(http.ResponseWriter, *http.Request) {
		return func(w http.ResponseWriter, r *http.Request) {
			s := sess.Load(r)
			ex, err := s.Exists(`user_id`)

			if err != nil {
				log.Println(err.Error())
			}

			if !ex {
				err = s.PutString(w, `user_id`, newID())
				if err != nil {
					log.Println(err.Error())
				}
			}

			h(w, r)
		}
	}

	b := bartlett.Bartlett{DB: db, Driver: &mariadb.MariaDB{}, Tables: tables, Users: userProvider}
	routes, handlers := b.Routes()
	for i, route := range routes {
		http.HandleFunc(`/api`+route, sessWrap(handlers[i])) // Adds /api/todo to the server.
	}

	http.Handle(`/`, http.FileServer(http.Dir(`static`)))
	log.Println(`starting server on ` + port)
	log.Fatal(http.ListenAndServe(`:`+port, logger.DefaultHandler(http.DefaultServeMux)))
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
