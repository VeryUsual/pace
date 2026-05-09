package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	_ "modernc.org/sqlite" // pure go because c is annoying
)

func main() {

	db, opendberr := sql.Open("sqlite", "pacedatabase.db")
	if opendberr != nil {
		log.Fatal(opendberr)
	}
	defer db.Close()

	_, userstableerr := db.Exec(`
	CREATE TABLE IF NOT EXISTS users (
		user_id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT NOT NULL,
		password TEXT NOT NULL
	);
	`)
	if userstableerr != nil {
		log.Fatal(userstableerr)
	}


	router := gin.Default()

	basicauthrouter := router.Group("/", gin.BasicAuth(gin.Accounts{
		"hardcodeduser": "password",
		"anotherhardcodeduser": "password",
	}))

	router.LoadHTMLGlob("templates/*")

	basicauthrouter.GET("/", func(c *gin.Context) {
		user := c.MustGet(gin.AuthUserKey).(string) // gets the user from the basicauthrouter middleware
		c.HTML(http.StatusOK, "index.html", gin.H{"user": user,})
	})
	router.Run()
}