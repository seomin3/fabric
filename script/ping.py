import os

hosts = []

for num in range(51,75):
        hostname = "150.24.212." + str(num)
        response = os.system("ping -c1 -w1 " + hostname + ">/dev/null")

        print 'checking to', hostname, '...'
        #and then check the response...
        if response == 0:
          hosts.append(hostname)

for num in range(101,120):
        hostname = "150.24.212." + str(num)
        response = os.system("ping -c1 -w1 " + hostname + ">/dev/null")

        print 'checking to', hostname, '...'
        #and then check the response...
        if response == 0:
          hosts.append(hostname)          

for num in range(151,153):
        hostname = "150.24.212." + str(num)
        response = os.system("ping -c1 -w1 " + hostname + ">/dev/null")

        print 'checking to', hostname, '...'
        #and then check the response...
        if response == 0:
                hosts.append(hostname)

try:
        file = open('hosts.txt', 'w')
        for data in hosts:
                file.write(data + "\n")
        file.close()
except IOError as ioerr:
        print('file error: ' + str(ioerr))
