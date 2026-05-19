#!/bin/bash



echo "Esperando a que el sistema libere los candados de APT..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 5
done



apt-get update
apt-get install -y docker.io openjdk-21-jdk wget gnupg curl maven



echo "deb [trusted=yes] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list


apt-get update
apt-get install -y jenkins


usermod -aG docker jenkins
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["${registry_ip}:5000"]
}
EOF
systemctl restart docker


curl -L https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.13/jenkins-plugin-manager-2.12.13.jar -o /opt/jenkins-plugin-manager.jar
mkdir -p /var/lib/jenkins/plugins


java -jar /opt/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-download-directory /var/lib/jenkins/plugins \
  --plugins docker-workflow ssh-agent git github blueocean || echo "Aviso: Error menor en plugins"

chown -R jenkins:jenkins /var/lib/jenkins



echo "${registry_ip}" > /var/lib/jenkins/registry_ip.txt
chown jenkins:jenkins /var/lib/jenkins/registry_ip.txt



REPO_URL="${repo_url}"
JOB_NAME="SpringBoot-CI-Test-Registry"

mkdir -p /var/lib/jenkins/jobs/$JOB_NAME


cat <<EOF > /var/lib/jenkins/jobs/$JOB_NAME/config.xml
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Automatizado: Pipeline desde Jenkinsfile</description>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty>
      <projectUrl>$${REPO_URL}</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>$${REPO_URL}</url>
          <credentialsId>github-token</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/develop</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers>
    <com.cloudbees.jenkins.GitHubPushTrigger plugin="github">
      <spec></spec>
    </com.cloudbees.jenkins.GitHubPushTrigger>
  </triggers>
</flow-definition>
EOF

chown -R jenkins:jenkins /var/lib/jenkins/jobs


systemctl enable jenkins
systemctl restart jenkins

echo "¡INFRAESTRUCTURA Y PROYECTO LISTOS!"





mkdir -p /var/lib/jenkins/init.groovy.d/


cat <<EOF > /var/lib/jenkins/init.groovy.d/setup-credentials.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def githubCredentials = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  "github-token", 
  "Token generado por Terraform",
  "${git_user}", 
  "${git_token}"
)

store.addCredentials(domain, githubCredentials)
Jenkins.instance.save()
EOF


systemctl restart jenkins