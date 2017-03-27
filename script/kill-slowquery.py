#!/usr/bin/python
import logging
import MySQLdb
from subprocess import call

# log
logger = logging.getLogger('slowquery')
fomatter = logging.Formatter('[%(levelname)s|%(filename)s:%(lineno)s] %(asctime)s > %(message)s')
fileHandler = logging.FileHandler('/tmp/get-slowquery.log')
streamHandler = logging.StreamHandler()
fileHandler.setFormatter(fomatter)
streamHandler.setFormatter(fomatter)
logger.addHandler(fileHandler)
logger.addHandler(streamHandler)
logger.setLevel(logging.DEBUG)

db_host = 'localhost'
db_user = 'root'
db_pass = 'database_pass'
db_name = 'information_schema'

query = """
SELECT *
FROM   information_schema.PROCESSLIST
WHERE  `TIME` > 300 AND COMMAND <> 'Sleep' AND STATE <> 'updating'
"""

db = MySQLdb.connect(db_host, db_user, db_pass, db_name)
cursor = db.cursor()

cursor.execute(query)
results = cursor.fetchall()
for row in results:
    pid = row[0]
    user = row[1]
    dbname = row[4]
    time = row[5]
    state = row[6]
    info = row[7]
    logger.info('===== %s =====' % pid)
    logger.info('user: %s, db: %s' % (user, dbname))
    logger.info('query: %s' % info)
    logger.info('time: %ss' % time)
    logger.info('state: %s' % state)
    cursor.execute('kill %s' % pid)

db.close()

logger.info('running')
