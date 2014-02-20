import sqlite3

db = sqlite3.connect(':memory:')
cur = db.cursor()
cur.execute("Create table users(id INTEGER PRIMARY KEY, name TEXT, phone TEXT)")
users = [
    ('John', '5557241'),
    ('Adam', '5547874'),
    ('Jack', '5484522'),
    ('Monthy', '6656565')
]
cur.execute("Insert into users(name, phone) values(?, ?)", ('Ely','3994928'))
cur.executemany("Insert into users(name, phone) values(?,?)", users)
db.commit()

# print the users
cur.execute("Select * from users")
for row in cur:
    print row

db.close()
