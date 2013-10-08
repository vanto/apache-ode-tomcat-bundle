Apache ODE Tomcat Bundle
========================

Buildr-based packaging script that bundles a pre-configured Apache ODE with Tomcat 7 and Bitronix.

Database configuration can be placed in profiles.yaml:

	filter: &common
	  bitronix.minPoolSize: 10
	  bitronix.maxPoolSize: 50

	mysql:
	  filter:
	    <<: *common
	    jdbc.driverClassName: "com.mysql.jdbc.Driver"
	    jdbc.url: "jdbc:mysql://localhost:3306/ode"
	    jdbc.user: "root"
	    jdbc.password: ""
	    jdbc.gav: "mysql:mysql-connector-java:jar:5.1.26"
	    ode.dao: "org.apache.ode.daohib.bpel.BpelDAOConnectionFactoryImpl" # for Hibernate
	    #ode.dao: "org.apache.ode.dao.jpa.BPELDAOConnectionFactoryImpl" # for OpenJPA

In the same fashion, other database setups can be added. All database configuration parameters can also
be changed in tomcat/conf/resources.properties later on.

To create the pre-configured bundle, change the settings in `profiles.yaml` and then run

    buildr clean package -e mysql

`-e mysql` identifies the mysql profile. If you have added other profiles in your profiles.yaml, you can select them using the `-e` switch.

NOTE: Please make sure that Apache Buildr and the nokogiri gem is installed. I prefer JRuby, so with an installed JRuby, just run

    gem install nokogiri
    gem install buildr

and you're set.

## License
This build script, Apache ODE and Apache Tomcat are Apache-licensed. The generated bundle, however, will include the Bitronix Transaction Manager (LGPL) and possibly proprietary licensed JDBC drivers.

## Credits
This build script is based on Sathwik Bantwal Premakumar's [blog post](http://sathwikbp.blogspot.de/2013/09/apache-ode-on-tomcat-7-with-bitronix.html) on configuring ODE with Bitronix in Tomcat 7.
