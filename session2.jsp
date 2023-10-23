<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.text.*"%>
<%@ page import="java.util.*"%>
<%
	String RsessionId = request.getRequestedSessionId();
	String sessionId = session.getId();
	boolean isNew = session.isNew();
	long creationTime = session.getCreationTime();
	long lastAccessedTime = session.getLastAccessedTime();
	int maxInactiveInterval = session.getMaxInactiveInterval();
	Enumeration e = session.getAttributeNames(); 
%> 
<html> 
<head> 
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> 
<title>Session Test</title> 
</head> 
<body>
<!-- Request Info -->
	<table border=1 bordercolor="gray" cellspacing=1 cellpadding=0	width="100%">
	<tr bgcolor="gray">
		<td colspan=2 align="center"><font color="white"><b>ServlertRequest API</b></font></td>
	</tr>
	<tr>
		<td>request.getRemoteAddr()</td>
		<td><%=request.getRemoteAddr()%></td>
	</tr>
	<tr>
		<td>request.getRemoteHost()</td>
		<td><%=request.getRemoteHost()%></td>
	</tr>
	<tr>
		<td>request.getRemoteHost()</td>
		<td><%=request.getRemotePort()%></td>
	</tr>
	
	<tr>
		<td>request.getLocalName()</td>
		<td><%=request.getLocalName()%></td>
	</tr>
	<tr>
		<td>request.getLocalAddr()</td>
		<td><%=request.getLocalAddr()%></td>
	</tr>
	<tr>
		<td>request.getLocalPort()</td>
		<td><%=request.getLocalPort()%></td>
	</tr>
	<tr>
		<td>request.getScheme()</td>
		<td><%=request.getScheme()%></td>
	</tr>
	<tr>
		<td>request.getServerName()</td>
		<td><%=request.getServerName()%></td>
	</tr>
	<tr>
		<td>request.getServerPort()</td>
		<td><%=request.getServerPort()%></td>
	</tr>	
	</table>
<!-- Header Info -->
	<table border=1 bordercolor="gray" cellspacing=1 cellpadding=0	width="100%">
	<tr bgcolor="gray">
		<td colspan=2 align="center"><font color="white"><b>Header Info</b></font></td>
	</tr>
<%
	Enumeration names = request.getHeaderNames();
	for(;names.hasMoreElements();)
	{
		String name = (String)names.nextElement();
%>
	<tr>
		<td><%=name %></td><td><%=request.getHeader(name) %></td>
	</tr>
<%
	}
%>
	</table> 
	
	<!-- Session Info -->
	<table border=1 bordercolor="gray" cellspacing=1 cellpadding=0
	width="100%">
	<tr bgcolor="gray">
		<td colspan=2 align="center"><font color="white"><b>Session
		Info</b></font></td>
	</tr>
	<tr>
		<td>Server HostName</td>
		<td><%=java.net.InetAddress.getLocalHost().getHostName()%></td>
	</tr>
	<tr>
		<td>Server IP</td>
		<td><%=java.net.InetAddress.getLocalHost()
									.getHostAddress()%></td>
	</tr>
	<tr>
		<td>Thread Name</td>
		<td><%=Thread.currentThread().getName() %></td>
	</tr>
	<tr>
		<td>Thread ID</td>
		<td><%=Thread.currentThread().getId() %></td>
	</tr>
	<tr>
		<td>Request SessionID</td>
		<td><%=RsessionId%></td>
	</tr>
	<tr>
		<td>SessionID</td>
		<td><%=sessionId%></td>
	</tr>
	<tr>
		<td>isNew</td>
		<td><%=isNew%></td>
	</tr>
	<tr>
		<td>Creation Time</td>
		<td><%=new Date(creationTime)%></td>
	</tr>
	<tr>
		<td>Last Accessed Time</td>
		<td><%=new Date(lastAccessedTime)%></td>
	</tr>
	<tr>
		<td>Max Inactive Interval (second)</td>
		<td><%=maxInactiveInterval%></td>
	</tr>
	<tr bgcolor="cyan">
		<td colspan=2 align="center"><b>Session Value List</b></td>
	</tr>
	<tr>
		<td align="center">NAME</td>
		<td align="center">VAULE</td>
	</tr>
	<%
		String name = null;
		while (e.hasMoreElements()) {
			name = (String) e.nextElement();
	%>
	<tr>
		<td align="left"><%=name%></td>
		<td align="left"><%=session.getAttribute(name)%></td>
	</tr>
	<%
		}
	%>
</table>
<iframe src="./setsession.jsp" width="100%" frameborder="0" />
</body>
</html>
