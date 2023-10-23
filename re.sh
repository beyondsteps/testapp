#! /bin/sh
i=1
while [ $i -lt 100000 ]
do
        echo $i

        echo $i > /opt/jboss/server/test.war/bbb/aaa_$i.jsp
        echo $i > /opt/jboss/server/test.war/bbb/aaa_$i_a.jsp
        echo $i > /opt/jboss/server/test.war/bbb/bbb_$i.jsp
        echo $i > /opt/jboss/server/test.war/bbb/bbb_$i_b.jsp

        i=$(($i+1))
done
