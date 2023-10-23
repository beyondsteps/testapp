<%@ page language="java" contentType="text/html;charset=euc-kr" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.sql.*" %>
<%@ page import="javax.naming.*" %>

<html>
<head><title>DataSource Connection Test</title></head>
<body>

<%
	Context ctx = null;
	DataSource ds = null;
	Connection con = null;
	PreparedStatement pstmt = null;
	ResultSet rs = null;
	try{
		ctx = new InitialContext();
		ds = (DataSource) ctx.lookup("java:jboss/datasources/mysqlDs");
		con = ds.getConnection();
		
		out.println("Con : " + con);
		out.println("<br>");
		
		
		String sql = "insert into ttt(no) value(5)";
		pstmt = con.prepareStatement(sql);
		
		pstmt.executeUpdate();
		// rs = pstmt.executeUpdate();
		
		// while(rs.next()){
		//	out.println(rs.getString(1));
		// }
	}catch(Exception e){
		e.printStackTrace();
	}finally{
		try{
		    // rs.close();
		    pstmt.close();
			 con.close();
			
		}catch(Exception ie){
			ie.printStackTrace();
		}
	}
	

%>

</body>
</html>