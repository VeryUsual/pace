package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	_ "modernc.org/sqlite" // pure go sqlite library because c is annoying
)

func BasicAuthWithDB(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		username, password, ok := c.Request.BasicAuth()
		if !ok {
			c.Header("WWW-Authenticate", `Basic realm="Restricted"`)
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		var user_id int
		err := db.QueryRow(`SELECT user_id FROM users WHERE username = ? AND password = ?`, username, password,).Scan(&user_id)
		if err != nil {
			c.Header("WWW-Authenticate", `Basic realm="Restricted"`)
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		c.Set(gin.AuthUserKey, username)
		c.Next()
	}
}

func main() {

	// Opens database, creates new if not exists
	db, opendberr := sql.Open("sqlite", "pacedatabase.db")
	if opendberr != nil {
		log.Fatal(opendberr)
	}
	defer db.Close()

	// Creates the users table if it doesnt exist
	_, userstableerr := db.Exec(`
	CREATE TABLE IF NOT EXISTS users (
		user_id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT NOT NULL,
		password TEXT NOT NULL
	);
	CREATE TABLE IF NOT EXISTS sessions (
		session_id INTEGER PRIMARY KEY AUTOINCREMENT,
		length_minutes INTEGER NOT NULL,
		description TEXT NOT NULL,
		user_id INTEGER NOT NULL
	)
	`)
	if userstableerr != nil {
		log.Fatal(userstableerr)
	}


	router := gin.Default()

	basicauthrouter := router.Group("/", BasicAuthWithDB(db))

	router.LoadHTMLGlob("templates/*")

	basicauthrouter.GET("/dashboard", func(c *gin.Context) {
		user := c.MustGet(gin.AuthUserKey).(string) // gets the user from the basicauthrouter middleware
		
		type Session struct {
			Session_id string
			Length_minutes string
			Description string
			User_id string
		}

		rows, err := db.Query(`SELECT session_id, length_minutes, description, user_id FROM sessions`)
		if err != nil {
			log.Fatal(err)
		}
		defer rows.Close()

		var sessions []Session

		for rows.Next() {
			var s Session
			if err := rows.Scan(&s.Session_id, &s.Length_minutes, &s.Description, &s.User_id); err != nil {
				log.Fatal(err)
			}
			sessions = append(sessions, s)
		}

		c.HTML(http.StatusOK, "index.html", gin.H{"user": user, "sessions": sessions,})
	})
	router.GET("/", func(c *gin.Context) {
		var usercount int
		err := db.QueryRowContext(c, "SELECT COUNT(*) FROM users").Scan(&usercount)
		if err != nil {
			log.Fatal(err)
		}
		if usercount == 0 {	
			c.HTML(http.StatusOK, "setupfirstuser.html", nil)
		} else {
			c.Redirect(http.StatusFound, "/dashboard")
		}
	})
	router.POST("/createfirstuser", func(c *gin.Context) {
		var usercount int
		err := db.QueryRowContext(c, "SELECT COUNT(*) FROM users").Scan(&usercount)
		if err != nil {
			log.Fatal(err)
		}
		if usercount == 0 {
			username := string(c.PostForm("username"))
			password := string(c.PostForm("password"))

			db.Exec(`INSERT INTO users (username, password) VALUES (?, ?)`, username, password)

			c.JSON(200, gin.H{"success": true})
		} else {
			c.JSON(400, gin.H{"success": false, "message": "First_User_Already_Created"})
		}
	})
	basicauthrouter.GET("/api/session/create", func(c *gin.Context) {
		_, err := db.Exec(`INSERT INTO sessions (length_minutes, description, user_id) VALUES (?, ?, ?)`, c.Query("length"), c.Query("desc"), 1)
		if err != nil {
			log.Fatal(err)
		}
		c.JSON(200, gin.H{"success": true})
	})
	router.Run()
}