**User story** <br>
As a member of DevOps team I want to send Jenkins build logs to Elastic stack so that Ops team can diagnose issue
by analysing all available logs in a central logging system.

**Requirements:**
- Ensure Elasticsearch, (Logstash optional) and Kibana are up and running
- Both jenkins and filebeat are running on the same host

**Assumptions:**
- No Jenkins' logs can be written to the host file system

Edit filebeat configuration as appropriate for your system. The configurations are at _config/filebeat.yml_:
```
  paths:
    # for regular jenkins jobs
    - /var/jenkins_home/jobs/*/builds/*/log
    # for jenkins blue ocean pipeline jobs
    - /var/jenkins_home/jobs/*/jobs/*/branches/*/builds/*/log

  output.elasticsearch:
    # Array of hosts to connect to.
    hosts: ["HOST_NAME:9200"]

    # Optional protocol and basic auth credentials.
    protocol: "http"
    username: "USER_NAME"
    password: "PASSWORD"
```

Run a jenkins container: <br>
```docker run -d --rm --name jenkins -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock jenkinsci/jenkins```


Build filebeat image ensurinig that config/filebeat.yml is configured as appropriate for your system: <br>
```docker build --rm --no-cache -t shazchaudhry/docker-filebeat .```

Start filebeat container that will forward Jenkins build logs to Elastic search. In order to persist filebeat state,
mount a hsot volume. Otherwise, following a container crash / restart, filebeat will start reading & forwarding logs
that have already been processed: <br>
```docker run -d --rm --name filebeat --volume filebeat_data:/data --volumes-from jenkins:ro shazchaudhry/docker-filebeat```

In Kibana, create an index called "filebeat-*" to view Jenkins' build logs<br>

**Issue:**
- If jenkins container is stopped, removed and run again, filebeat will not be able to read jenkins' log files. This is
due to the fact that jenkins container ID would have changed and filebeat would have lost the visibility of log files
inside jenkins' volume _(see assumptions above)_.

**Resolusion**<br>
filebeat has a dependency on jenkins being up and running. So, if jenkins goes down, filebeat has to go down at the same
time and both these services have to be brough up agin; jenkins first and filebeat second
1. Copy all files from the systemd directory in this repo and place them in `/etc/systemd/system` dirctory on the host
file system
2. Stop both jenkins and filebeat containers
3. Run the following command: <br>
 `sudo systemctl daemon-reload`<br>
 `sudo systemctl start jenkins.service`<br>
 `sudo systemctl start filebeat.service`<br>
 `docker ps -a` to check if filebeat and jenkins are up and running. <br>
  `docker exec -it filebeat ls -latr /var/jenkins_home` to see if jenkins volume is visible from within filebeat's
  container<br>

**Test**
- _Testing of this user story was done on Ubuntu 16.04_
- Create and run a job in jenkins
- Create an index called `filebeat-*` in Kibana and check the logs in discovery tab


**Filebeat overview, docs and FAQ:**
- https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-overview.html
- https://www.elastic.co/guide/en/beats/filebeat/current/faq.html
