package main

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

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
		password TEXT NOT NULL,
		gold_amount INTEGER NOT NULL DEFAULT 0
	);
	CREATE TABLE IF NOT EXISTS sessions (
		session_id INTEGER PRIMARY KEY AUTOINCREMENT,
		length_minutes INTEGER NOT NULL,
		description TEXT NOT NULL,
		user_id INTEGER NOT NULL,
		datetime TEXT NOT NULL DEFAULT (datetime('now'))
	);
	CREATE TABLE IF NOT EXISTS purchases (
		purchase_id INTEGER PRIMARY KEY AUTOINCREMENT,
		item TEXT NOT NULL,
		user_id INTEGER NOT NULL,
		price INTEGER NOT NULL,
		when_purchased TEXT NOT NULL DEFAULT (datetime('now'))
	);
	`)
	if userstableerr != nil {
		log.Fatal(userstableerr)
	}

	type Session struct {
		Session_id string
		Length_minutes string
		Description string
		User_id string
		Datetime string
	}

	type Purchase struct {
		Purchase_id string
		Item string
		User_id string
		Price string
		When_purchased string
	}

	router := gin.Default()

	basicauthrouter := router.Group("/", BasicAuthWithDB(db))

	router.LoadHTMLGlob("templates/*")

	basicauthrouter.GET("/dashboard", func(c *gin.Context) {
		user := c.MustGet(gin.AuthUserKey).(string) // gets the user from the basicauthrouter middleware
			
		rows, err := db.Query(`SELECT session_id, length_minutes, description, user_id, datetime FROM sessions`)
		if err != nil {
			log.Fatal(err)
		}
		defer rows.Close()

		var sessions []Session

		for rows.Next() {
			var s Session
			if err := rows.Scan(&s.Session_id, &s.Length_minutes, &s.Description, &s.User_id, &s.Datetime); err != nil {
				log.Fatal(err)
			}
			sessions = append(sessions, s)
		}

		today := time.Now().Format("2006-01-02")
		var todaySessions []Session
		var totalTimeToday int = 0
		for _, session := range sessions {
			if strings.HasPrefix(session.Datetime, today) {
				todaySessions = append(todaySessions, session)
				l, _ := strconv.Atoi(session.Length_minutes)
				totalTimeToday += l
			}
		}

		c.HTML(http.StatusOK, "index.html", gin.H{"user": user, "sessions": sessions, "totalTimeToday": totalTimeToday})
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
		user := c.MustGet(gin.AuthUserKey).(string) 
		var user_id int
		db.QueryRow(`SELECT user_id FROM users WHERE username = ?`, user,).Scan(&user_id)
		_, err := db.Exec(`INSERT INTO sessions (length_minutes, description, user_id) VALUES (?, ?, ?)`, c.Query("length"), c.Query("desc"), user_id)
		if err != nil {
			log.Fatal(err)
		}
		c.JSON(200, gin.H{"success": true})
	})
	basicauthrouter.GET("/api/sessions", func(c *gin.Context) {
		rows, err := db.Query(`SELECT session_id, length_minutes, description, user_id, datetime FROM sessions`)
		if err != nil {
			log.Fatal(err)
		}
		defer rows.Close()

		var sessions []Session

		for rows.Next() {
			var s Session
			if err := rows.Scan(&s.Session_id, &s.Length_minutes, &s.Description, &s.User_id, &s.Datetime); err != nil {
				log.Fatal(err)
			}
			sessions = append(sessions, s)
		}
		c.JSON(200, gin.H{"sessions": sessions})
	})
	basicauthrouter.GET("/api/gold", func(c *gin.Context) {
		user := c.MustGet(gin.AuthUserKey).(string) 
		var goldAmount int
		err := db.QueryRow(`SELECT gold_amount FROM users WHERE username = ?`, user,).Scan(&goldAmount)
		if err != nil {
			log.Fatal(err)
		}		
		c.JSON(200, gin.H{"gold_amount": goldAmount})
	})
	basicauthrouter.GET("/api/gold/add", func (c *gin.Context)  {
		user := c.MustGet(gin.AuthUserKey).(string)
		_, err := db.Exec(`UPDATE users SET gold_amount = gold_amount + ? WHERE username = ?;`, c.Query("amount"), user)
		if err != nil {
			log.Fatal(err)
		}
		c.JSON(200, gin.H{"success": true})
	})
	basicauthrouter.GET("/api/purchase", func(c *gin.Context) {
		user := c.MustGet(gin.AuthUserKey).(string)
		var user_id int
		db.QueryRow(`SELECT user_id FROM users WHERE username = ?`, user,).Scan(&user_id)
		var original_gold_amount int
		db.QueryRow(`SELECT gold_amount FROM users WHERE username = ?`, user,).Scan(&original_gold_amount)
		
		price, _ := strconv.Atoi(c.Query("price"))

		if original_gold_amount < price {
			c.JSON(400, gin.H{"success": false, "error": "Insufficient_Balance"})
			return
		}

		_, err := db.Exec(`UPDATE users SET gold_amount = gold_amount - ? WHERE username = ?;`, c.Query("price"), user)
		if err != nil {
			log.Fatal(err)
		}
		_, err2 := db.Exec(`INSERT INTO purchases (item, price, user_id) VALUES (?, ?, ?)`, c.Query("item"), price, user_id)
		if err2 != nil {
			log.Fatal(err)
		}
		c.JSON(200, gin.H{"success": true})
	})
	basicauthrouter.GET("/api/purchases", func(c *gin.Context) {
		rows, err := db.Query(`SELECT purchase_id, item, user_id, price, when_purchased FROM purchases`)
		if err != nil {
			log.Fatal(err)
		}
		defer rows.Close()

		var purchases []Purchase

		for rows.Next() {
			var p Purchase
			if err := rows.Scan(&p.Purchase_id, &p.Item, &p.User_id, &p.Price, &p.When_purchased); err != nil {
				log.Fatal(err)
			}
			purchases = append(purchases, p)
		}
		c.JSON(200, gin.H{"purchases": purchases})
	})

	router.Run()
}