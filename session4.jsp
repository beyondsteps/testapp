<%@ page language="java" contentType="text/html; charset=EUC-KR"

    pageEncoding="EUC-KR"%>

<%@ page import="java.util.*" %>

<%@ page import="java.net.InetAddress" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" " http://www.w3.org/TR/html4/loose.dtd">

<html>

<head>

<meta http-equiv="Content-Type" content="text/html; charset=EUC-KR">

<title>SessionTest</title>

</head>

<body>

<%

     String color = "";

     Integer count = (Integer)session.getAttribute("count");

     if(session.getAttribute("count")==null){

         count = new Integer(1);

     }else{

          count = new Integer(count.intValue()+1);

     }

%>

<%

session.setAttribute("count",count);

InetAddress iadr = InetAddress.getLocalHost();

out.println("Connect count : "+count+"<BR>");

out.println("<P>");

out.println("<H3>Session Information :</H3>");

out.println("<b>HostName</b> : "+System.getenv("HOSTNAME")+"<BR>");

out.println("<b>Session ID</b> : "+session.getId() + "<BR>");

out.println("<b>Session Is New</b> : "+session.isNew() + "<BR>");

out.println("<b>Session CreationTime</b> : "+new Date(session.getCreationTime()) + "<BR>");

out.println("<b>Session LastAccessedTime</b> : "+new Date(session.getLastAccessedTime()) + "<BR>");

out.println("<b>Session MaxInactiveInterval(s)</b> : "+session.getMaxInactiveInterval() + "<BR>");

%>

</body>

</html>