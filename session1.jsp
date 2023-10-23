<%@ page language="java" contentType="text/html; charset=EUC-KR"
	pageEncoding="EUC-KR"%>
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
<meta http-equiv="Content-Type" content="text/html; charset=EUC-KR">
<title>Session Test</title>
</head>
<body>
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
</body>
</html>