#    Licensed to the Apache Software Foundation (ASF) under one or more
#    contributor license agreements.  See the NOTICE file distributed with
#    this work for additional information regarding copyright ownership.
#    The ASF licenses this file to You under the Apache License, Version 2.0
#    (the "License"); you may not use this file except in compliance with
#    the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'nokogiri'

# The ODE version to bundle with Tomcat:
ODE_WAR = "org.apache.ode:ode-axis2-war:war:1.3.8-SNAPSHOT"

# the Tomcat version to bundle ODE with:
TOMCAT_ZIP = "org.apache.tomcat:tomcat:zip:8.5.16"

# BTM + dependencies
BITRONIX = group("btm", "btm-tomcat55-lifecycle", :under=>"org.codehaus.btm", :version=>"2.1.4")
SLF4J = ['org.slf4j:slf4j-api:jar:1.7.12', 'org.slf4j:jcl-over-slf4j:jar:1.7.12']
JTA = 'org.jboss.spec.javax.transaction:jboss-transaction-api_1.2_spec:jar:1.0.0.Final'
HIBERNATE = ["org.hibernate:hibernate-core:jar:4.3.11.Final", "org.javassist:javassist:jar:3.18.1-GA", "antlr:antlr:jar:2.7.7",
                        "dom4j:dom4j:jar:1.6.1", "org.hibernate.common:hibernate-commons-annotations:jar:4.0.5.Final", 
                        "org.jboss:jandex:jar:1.1.0.Final",  "org.jboss.logging:jboss-logging:jar:3.1.3.GA" , 
                        "org.jboss.logging:jboss-logging-annotations:jar:1.2.0.Beta1",
                        "org.hibernate.javax.persistence:hibernate-jpa-2.1-api:jar:1.0.0.Final"]

repositories.remote << "http://repo1.maven.org/maven2"

desc "The Apache ODE Tomcat Bundle project"
define "apache-ode-tomcat-bundle" do

  project.version = artifact(ODE_WAR).version
  project.group = 'de.taval.ode'

  exploded_tomcat = unzip(_("target/tomcat") => artifact(TOMCAT_ZIP)).from_path("apache-tomcat-8.5.16").target
  exploded_ode = unzip(_(:target, 'tomcat/webapps/ode') => artifact(ODE_WAR)).target

  # filter resources
  resources.filter.using(:ruby, Buildr.settings.profile['filter'])

  resources.enhance [exploded_tomcat]
  resources.enhance do
      # explode ODE
      exploded_ode.invoke

      # copy filtered resources to Tomcat
      cp_r 'target/resources/tomcat/.', _(:target, "tomcat")

      # copy BTM libs and JDBC driver to Tomcat
      cp artifacts(BITRONIX, SLF4J, JTA, Buildr.settings.profile['filter']['jdbc.gav']).collect { |t| t.invoke; t.to_s }, _(:target, 'tomcat/lib')

      if Buildr.settings.profile['filter']['ode.dao'] and Buildr.settings.profile['filter']['ode.dao'].include? "daohib"
        cp artifacts(HIBERNATE).collect { |t| t.invoke; t.to_s }, _(:target, 'tomcat/webapps/ode/WEB-INF/lib')
      end

      # remove unneeded webapps
      rm_rf _(:target, "tomcat/webapps/examples")
      rm_rf _(:target, "tomcat/webapps/docs")

      # remove conflicting jar
      rm _(:target, "tomcat/webapps/ode/WEB-INF/lib/geronimo-jta_1.1_spec-1.1.1.jar")
      rm _(:target, "tomcat/webapps/ode/WEB-INF/lib/geronimo-transaction-3.1.3.jar")
      rm _(:target, "tomcat/webapps/ode/WEB-INF/lib/geronimo-jpa_2.0_spec-1.1.jar")


      # add resources to web.xml
      resourcesxml  = Nokogiri::XML <<-eos
    <resource-ref>
        <res-ref-name>jdbc/ode</res-ref-name>
        <res-type>javax.sql.DataSource</res-type>
        <res-auth>Container</res-auth>
        <res-sharing-scope>Shareable</res-sharing-scope>
    </resource-ref>
eos
      webxml = Nokogiri::XML(File.open(_(:target, "tomcat/webapps/ode/WEB-INF/web.xml")))
      webxml.xpath('//xmlns:web-app').first.add_child(resourcesxml.root)
      File.open(_(:target, "tomcat/webapps/ode/WEB-INF/web.xml"),'w') {|f| webxml.write_xml_to f}

      # add TomcatFactory to ode-axis2.properties
      File.open(_(:target, "tomcat/webapps/ode/WEB-INF/conf/ode-axis2.properties"), 'a') do |file|
        file.puts "\node-axis2.tx.factory.class=org.apache.ode.axis2.util.TomcatFactory"
        file.puts "ode-axis2.db.mode=EXTERNAL"
        file.puts "ode-axis2.db.ext.dataSource=java:comp/env/jdbc/ode"
        file.puts "ode-axis2.dao.factory=#{Buildr.settings.profile['filter']['ode.dao']}" if Buildr.settings.profile['filter']['ode.dao']
      end
  end
  package(:zip).include _("target/tomcat"), :as=>"apache-ode-tomcat-bundle-#{project.version}"
end
