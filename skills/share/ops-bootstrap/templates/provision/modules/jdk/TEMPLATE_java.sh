# Java environment template for ops-bootstrap.
# Render JAVA_HOME from the selected JDK package or project config.

export JAVA_HOME="{{java_home|/usr/lib/jvm/java-17-openjdk-amd64}}"
export PATH="$JAVA_HOME/bin:$PATH"
