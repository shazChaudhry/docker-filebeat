[![Build Status on Travis](https://travis-ci.org/shazChaudhry/docker-filebeat.svg?branch=master "CI build on Travis")](https://travis-ci.org/shazChaudhry/docker-filebeat)
[![Docker Repository on Quay](https://quay.io/repository/shazchaudhry/docker-filebeat/status "Docker Repository on Quay")](https://quay.io/repository/shazchaudhry/docker-filebeat)

**User story:**<br>
As a member of DevOps team, I want to send application log files to Elastic stack so that Ops team can diagnose production issues
by analyzing all available logs in a central logging system.

Here’s how Filebeat works: When you start Filebeat, it starts one or more prospectors that look in the local paths you’ve specified for log files. For each log file that the prospector locates, Filebeat starts a harvester. Each harvester reads a single log file for new content and sends the new log data to libbeat, which aggregates the events and sends the aggregated data to the output that you’ve configured for Filebeat

<p align="center">
  <img src="./pics/filebeat.png" alt="Filebeat" style="width: 250px;"/>
</p>

**Assumptions:**
* In this scenario, Jenkins build logs will be sent to Elasticsearch. However, no logs are written to the host file system where Jenkins is running

**Requirements:**
* ELK v6.0 (Elasticsearch, Logstash and Kibana) is up and running
* Elasticsearch port 9200 is published for filebeat to send logs to
* Latest version of Docker is installed
* Both Jenkins and Filebeat are running on the same host

**Lightweight log data shipper for local files:**<br>
If required, edit filebeat configuration as appropriate for your system. However, filebeat behaviour is controlled with environment values in docker run command below. Should you need additional parameters configured then configurations are located at _config/filebeat.yml_.

Start a jenkins container, create some jobs and run some builds. This will create build logs that filebeat will read and then forward them to Elasticsearch:
```
docker run -d --rm --name jenkins --publish 8080:8080 jenkins/jenkins
```
_**NOTE:** for this Jenkins containder nothing is mounted from the host file system_

Build filebeat image ensurinig that config/filebeat.yml is configured as appropriate for your system or as requirements:
```
docker build \
  --rm --no-cache \
  --tag quay.io/shazchaudhry/docker-filebeat:6.0.0 .
```
Start filebeat container that will forward Jenkins build logs to Elastic search. In order to persist filebeat state,
mount a hsot directory. Otherwise, following a container crash / restart, filebeat might start reading & forwarding logs
that have already been processed:
```
docker container run -d --rm \
--name filebeat \
--volumes-from jenkins:ro \
--network=host \
quay.io/shazchaudhry/docker-filebeat:6.0.0
```

If not already available in Kibana, create an index called "filebeat-*" to view Jenkins' build logs.

**Issue:**<br>
If jenkins container is stopped, removed and run again, filebeat will not be able to read jenkins' log files. This is
due to the fact that jenkins container ID would have changed and filebeat would have lost the visibility of log files
inside jenkins' volume.

**Solution**<br>
filebeat has a dependency on jenkins being up and running. So, if jenkins goes down, filebeat has to go down at the same
time and both these services have to be brought up agin; jenkins first and filebeat second
1. Copy all files from the systemd directory in this repo and place them in `/etc/systemd/system` dirctory on the host
file system
2. Stop and remove both jenkins and filebeat containers if they are running
3. Run the following commands: <br>
 `sudo systemctl daemon-reload`<br>
 `sudo systemctl start jenkins.service`<br>
 `sudo systemctl start filebeat.service`<br>
 `docker container ps -a` to check if filebeat and jenkins are up and running. <br>
 `docker container exec -it filebeat ls -latr /var/jenkins_home` to see if jenkins volume is visible from within filebeat's container

**Test**
- Create and run a job in jenkins
- Create an index called `filebeat-*` in Kibana and check the logs in discovery tab


**Filebeat overview, docs and FAQ:**
- https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-overview.html
- https://www.elastic.co/guide/en/beats/filebeat/current/faq.html
