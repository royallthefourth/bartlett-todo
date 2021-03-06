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
	var maxConns, waitTime int
	var col string
	err = db.QueryRow(`SHOW VARIABLES LIKE 'max_connections'`).Scan(&col, &maxConns)
	if err != nil {
		panic(err)
	}
	db.SetMaxIdleConns(maxConns/2)
	db.SetMaxOpenConns(maxConns)

	err = db.QueryRow(`SHOW VARIABLES LIKE 'wait_timeout'`).Scan(&col, &waitTime)
	if err != nil {
		panic(err)
	}
	db.SetConnMaxLifetime(time.Second * time.Duration(waitTime))

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
	routes := b.Routes()
	for _, route := range routes {
		http.HandleFunc(`/api`+route.Path, sessWrap(route.Handler)) // Adds /api/todo to the server.
	}

	http.Handle(`/`, http.FileServer(http.Dir(`static`)))
	log.Println(`starting server on ` + port)
	log.Fatal(http.ListenAndServe(`:`+port, logger.Handler(http.DefaultServeMux, os.Stdout, logger.DevLoggerType)))
}

func truncate(conn *sql.DB) {
	var count int
	row := conn.QueryRow(`SELECT COUNT(*) FROM todo`)
	err := row.Scan(&count)
	if err != nil {
		log.Fatalf(`count failed: %s`, err.Error())
	}

	if count > 2048 {
		_, err = conn.Exec(`TRUNCATE TABLE todo`)
		if err != nil {
			log.Fatalf(`truncate failed: %s`, err.Error())
		}
		log.Printf(`Truncated todo table at length %d.`, count)
	}
}

type migrationLogger struct{}

func (migrationLogger) Printf(format string, v ...interface{}) {
	log.Printf(format, v...)
}

func (migrationLogger) Verbose() bool {
	return true
}

func migrate(conn *sql.DB) {
	drv, err := mysql.WithInstance(conn, &mysql.Config{})
	if err != nil {
		log.Fatalf(`could not create migration driver: %s`, err.Error())
	}

	migrator, err := m.NewWithDatabaseInstance("file://migrations", "mysql", drv)
	migrator.Log = migrationLogger{}
	if err != nil {
		log.Fatalf(`could not create migration system: %s`, err.Error())
	}

	err = migrator.Up()
	if err != nil && err != m.ErrNoChange {
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
