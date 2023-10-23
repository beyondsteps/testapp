<%
	long creationTime = session.getCreationTime();
	long lastAccessedTime = session.getLastAccessedTime();
	int maxInactiveInterval = session.getMaxInactiveInterval();
%>

<html>   
	<head>
		<title>Session Tracking Test</title> 
	</head>     
	<body>     
		<h1>Session Tracking Test 2</h1>     
		Session tracking with JSP is easy     
		<P> 
<%@ page session="true" %> 
<%       
	// Get the session data value     
	Integer ival = (Integer) session.getValue ("counter"); 
	if (ival == null) ival = new Integer (1); 
	else ival = new Integer (ival.intValue() + 1); 
	session.putValue ("counter", ival); 
%>     
	You have hit this page <%= ival %> times.<br> 
<%     
	out.println("Your Session ID is " + session.getId() +  "<br>"); 
	System.out.println("session=" + session.getId());
	
%>
	<tr>
		<td>request.getRemoteAddr()</td> : <td><%=request.getRemoteAddr()%></td>
	</tr>
	<br>
	<tr>
		<td>request.getRemoteHost()</td> : <td><%=request.getRemoteHost()%></td>
	</tr>
	<br>
	<tr>
		<td>request.getLocalName()</td> : <td><%=request.getLocalName()%></td>
	</tr>
	<br>
	<tr>
		<td>request.getLocalAddr()</td> : <td><%=request.getLocalAddr()%></td>
	</tr>
	<br>
	<tr>
		<td>Server HostName</td> : <td><%=java.net.InetAddress.getLocalHost().getHostName()%></td>
	</tr>
	<br>
	<tr>
		<td>Server IP</td> : <td><%=java.net.InetAddress.getLocalHost().getHostAddress()%></td>
	</tr>
	<br>
	<tr>
		<td>Thread Name</td> : <td><%=Thread.currentThread().getName() %></td>
	</tr>
	<br>
	<tr>
		<td>Thread ID</td> : <td><%=Thread.currentThread().getId() %></td>
	</tr>
    <br>
	<tr>
		<td>Max Inactive Interval (second)</td> : <td><%=session.getMaxInactiveInterval() %></td>
	</tr> 
	</body>
</html> 